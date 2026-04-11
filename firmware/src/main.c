/*
 * main.c — Vibrating Mesh Nebulizer Controller
 *
 * Firmware for PIC16F1713 to drive a PZT-based vibrating mesh nebulizer
 * (e.g., Aerogen Solo) via frequency sweep and resonance lock.
 *
 * State machine:
 *   IDLE     — waiting for button press, LEDs indicate ready
 *   SWEEP    — scanning 90-150 kHz for PZT resonant frequency
 *   RUNNING  — driving PZT at resonance, treatment timer active
 *   ERROR    — no resonance found or fault detected
 *
 * Based on Microchip AN2265 reference design.
 * Target: PIC16F1713-I/SP (DIP-28) on breadboard.
 * Compiler: Microchip XC8 (free mode).
 *
 * IMPORTANT: This is not an FDA-approved medical device.
 * See DISCLAIMER.md for safety information.
 */

#include <xc.h>
#include <stdint.h>
#include "config.h"
#include "peripherals.h"
#include "sweep.h"

/* ========================================================================
 * State machine
 * ======================================================================== */
typedef enum {
    STATE_IDLE,
    STATE_BOOST_RAMP,
    STATE_SWEEP,
    STATE_RUNNING,
    STATE_STOPPING,
    STATE_ERROR
} state_t;

static state_t          state;
static sweep_result_t   resonance;
static uint16_t         treatment_ticks;     /* Timer1 overflow counter */
static uint16_t         treatment_max_ticks; /* Ticks for full treatment duration */
static uint16_t         recheck_ticks;       /* Ticks since last resonance recheck */
static uint16_t         recheck_max_ticks;   /* Ticks per recheck interval */
static uint8_t          current_dac;         /* Current boost DAC level */

/*
 * Timer1 overflow period: ~131 ms (65536 * 8 / 4 MHz)
 * Ticks per second: ~7.63
 * Treatment ticks: TREATMENT_TIME_SEC * 1000 / 131
 */
#define TICKS_PER_SEC       8   /* approximate: 1000/131 ≈ 7.63, round up */
#define MS_TO_TICKS(ms)     ((uint16_t)((ms) / 131 + 1))

/* ========================================================================
 * Button debounce
 *
 * Simple polling debounce. Returns 1 on a clean button press (transition
 * from not-pressed to pressed, held for >50ms).
 * ======================================================================== */
static uint8_t button_debounced(void)
{
    static uint8_t last_state = 0;
    static uint8_t debounce_count = 0;
    uint8_t current = button_pressed();

    if (current && !last_state) {
        debounce_count++;
        if (debounce_count >= 5) {  /* 5 polls ≈ 50ms in main loop */
            last_state = 1;
            debounce_count = 0;
            return 1;               /* Button press detected */
        }
    } else if (!current) {
        last_state = 0;
        debounce_count = 0;
    }

    return 0;
}

/* ========================================================================
 * Boost voltage ramp
 *
 * Gradually increases the DAC from BOOST_STARTUP_DAC to BOOST_TARGET_DAC.
 * This prevents inrush current and gives the boost converter time to
 * stabilize at each voltage step.
 * ======================================================================== */
static uint8_t boost_ramp_step(void)
{
    if (current_dac < BOOST_TARGET_DAC) {
        current_dac++;
        dac_set_value(current_dac);
        return 0;   /* Still ramping */
    }
    return 1;       /* Ramp complete */
}

/* ========================================================================
 * LED patterns for each state
 * ======================================================================== */
static void update_leds(void)
{
    switch (state) {
        case STATE_IDLE:
            led_red_on();       /* Solid red = powered, idle */
            led_green_off();
            break;

        case STATE_BOOST_RAMP:
            led_red_on();
            led_green_off();    /* Red = ramping boost voltage */
            break;

        case STATE_SWEEP:
            led_red_off();      /* Green blinks during sweep (toggled in sweep.c) */
            break;

        case STATE_RUNNING:
            led_red_off();
            led_green_on();     /* Solid green = nebulizing */
            break;

        case STATE_STOPPING:
            led_red_off();
            led_green_off();    /* Both off briefly during shutdown */
            break;

        case STATE_ERROR:
            /* Blink red for error — toggled in main loop */
            led_green_off();
            break;
    }
}

/* ========================================================================
 * Stop nebulization — safe shutdown
 * ======================================================================== */
static void stop_nebulization(void)
{
    nco_disable();
    dac_set_value(0);
    current_dac = 0;
    timer1_stop();

    led_red_off();
    led_green_off();

    uart_send_string("STOP: nebulization ended\r\n");

    state = STATE_IDLE;
}

/* ========================================================================
 * Main
 * ======================================================================== */
void main(void)
{
    uint8_t error_blink_count = 0;

    /* Initialize all peripherals */
    system_init();

    /* Calculate timer tick counts */
    treatment_max_ticks = (uint16_t)((uint32_t)TREATMENT_TIME_SEC * TICKS_PER_SEC);
    recheck_max_ticks   = MS_TO_TICKS(RECHECK_INTERVAL_MS);

    /* Start in idle state */
    state = STATE_IDLE;
    current_dac = 0;

    /* Startup indication: blink red LED once */
    led_red_on();
    delay_ms(500);
    led_red_off();
    delay_ms(250);

    uart_send_string("\r\n=== VMN Controller v1.0 ===\r\n");
    uart_send_string("Ready. Press button to start.\r\n");

    /* ---- Main loop ---- */
    while (1) {

        /* Check for button press in any state */
        if (button_debounced()) {
            if (state == STATE_RUNNING || state == STATE_SWEEP || state == STATE_BOOST_RAMP) {
                /* Button during operation = stop */
                stop_nebulization();
                delay_ms(500);  /* Debounce delay after stop */
                continue;
            } else if (state == STATE_IDLE || state == STATE_ERROR) {
                /* Button in idle/error = start */
                uart_send_string("START: beginning boost ramp\r\n");
                current_dac = BOOST_STARTUP_DAC;
                dac_set_value(current_dac);
                state = STATE_BOOST_RAMP;
            }
        }

        /* ---- State machine ---- */
        switch (state) {

        case STATE_IDLE:
            /* Just wait for button press */
            break;

        case STATE_BOOST_RAMP:
            /* Gradually increase boost voltage to target */
            if (boost_ramp_step()) {
                /* Ramp complete — start frequency sweep */
                uart_send_string("RAMP: boost at target, starting sweep\r\n");
                state = STATE_SWEEP;
            } else {
                delay_ms(BOOST_RAMP_DELAY_MS);
            }
            break;

        case STATE_SWEEP:
            /* Scan for PZT resonant frequency */
            resonance = sweep_find_resonance();

            if (resonance.found) {
                /* Resonance found — start nebulizing */
                uart_send_string("RUN: nebulizing\r\n");

                /* Enable the CWG to drive the boost MOSFET */
                CWG1CON0bits.G1EN = 1;

                /* Start treatment timer */
                treatment_ticks = 0;
                recheck_ticks   = 0;
                timer1_start();

                state = STATE_RUNNING;
            } else {
                /* No resonance — error state */
                uart_send_string("ERROR: no cup detected\r\n");
                dac_set_value(0);
                current_dac = 0;
                state = STATE_ERROR;
                error_blink_count = 0;
            }
            break;

        case STATE_RUNNING:
            /* Count Timer1 overflows for treatment duration */
            if (timer1_overflow()) {
                timer1_clear_overflow();
                treatment_ticks++;
                recheck_ticks++;

                /* Check if treatment time is up */
                if (treatment_ticks >= treatment_max_ticks) {
                    uart_send_string("TIMER: treatment complete\r\n");
                    stop_nebulization();
                    break;
                }

                /* Periodically verify resonance is still locked */
                if (recheck_ticks >= recheck_max_ticks) {
                    recheck_ticks = 0;
                    uint16_t current = sweep_check_current(resonance.peak_inc);

                    if (current < (resonance.peak_adc - RESONANCE_MARGIN)) {
                        /* Current dropped — may have lost resonance.
                         * Could mean: cup is empty, frequency drifted,
                         * or cup was removed. Re-sweep to find it. */
                        uart_send_string("RECHECK: current dropped, re-sweeping\r\n");
                        state = STATE_SWEEP;
                    }
                }
            }
            break;

        case STATE_ERROR:
            /* Blink red LED — press button to retry */
            error_blink_count++;
            if (error_blink_count >= 10) {
                LED_RED_LAT = !LED_RED_LAT;
                error_blink_count = 0;
            }
            break;

        case STATE_STOPPING:
            stop_nebulization();
            break;
        }

        /* Update LED indicators */
        update_leds();

        /* Small delay to set main loop cadence (~10ms per iteration) */
        delay_ms(10);
    }
}
