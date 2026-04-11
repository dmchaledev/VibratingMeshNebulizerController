/*
 * config.h — Tunable parameters for the vibrating mesh nebulizer controller
 *
 * Adjust these values to match your specific nebulizer cup and power supply.
 * START CONSERVATIVE (low voltage, wide sweep) and dial in from there.
 *
 * Based on Microchip AN2265 reference design for PIC16F1713.
 */

#ifndef CONFIG_H
#define CONFIG_H

/* =========================================================================
 * CLOCK CONFIGURATION
 * The PIC16F1713 internal oscillator runs at 16 MHz (HFINTOSC).
 * All frequency calculations below assume Fosc = 16 MHz.
 * ========================================================================= */
#define _XTAL_FREQ          16000000UL  /* 16 MHz internal oscillator */

/* =========================================================================
 * FREQUENCY SWEEP PARAMETERS
 *
 * The controller sweeps across this range to find the PZT resonant frequency.
 * Aerogen Solo cups typically resonate around 128 kHz, but this varies
 * unit-to-unit and with liquid loading.
 *
 * If using a different brand of VMN cup, you may need to widen this range.
 * See README.md compatibility table.
 * ========================================================================= */
#define SWEEP_FREQ_MIN_HZ   90000UL     /* Lower sweep bound (Hz) */
#define SWEEP_FREQ_MAX_HZ   150000UL    /* Upper sweep bound (Hz) */
#define SWEEP_STEP_HZ       500UL       /* Step size during sweep (Hz) */

/*
 * NCO increment register calculation:
 *   NCO_INC = (freq_hz * 2^20) / Fosc
 *   NCO_INC = (freq_hz * 1048576) / 16000000
 *   NCO_INC = freq_hz * 65.536 / 1000
 *   Simplified: NCO_INC = (freq_hz * 65536UL) / 1000000UL  (close approx)
 *
 * At 90 kHz:  NCO_INC = 5898
 * At 128 kHz: NCO_INC = 8389
 * At 150 kHz: NCO_INC = 9830
 * Step of 500 Hz: NCO_STEP = ~33
 */
#define NCO_INC_MIN         ((uint16_t)((SWEEP_FREQ_MIN_HZ * 65536UL) / 1000000UL))
#define NCO_INC_MAX         ((uint16_t)((SWEEP_FREQ_MAX_HZ * 65536UL) / 1000000UL))
#define NCO_INC_STEP        ((uint16_t)((SWEEP_STEP_HZ * 65536UL) / 1000000UL))

/* Dwell time at each frequency step during sweep (milliseconds).
 * Longer dwell = more accurate peak detection but slower sweep. */
#define SWEEP_DWELL_MS      5

/* Number of ADC samples to average at each frequency step.
 * More samples = less noise but slower sweep. */
#define SWEEP_AVG_SAMPLES   4

/* =========================================================================
 * BOOST CONVERTER PARAMETERS
 *
 * DAC1 controls the boost output voltage via a feedback comparator.
 * The PIC16F1713 has a 5-bit DAC (0-31).
 *
 * WARNING: Start with a LOW value and increase gradually.
 * Too much voltage will damage or depolarize the PZT element.
 *
 * Approximate VBOOST vs DAC value (depends on your voltage divider):
 *   DAC  8  -> ~6V
 *   DAC 12  -> ~9V
 *   DAC 16  -> ~12V
 *   DAC 20  -> ~15V
 *   DAC 24  -> ~18V
 *
 * These are rough estimates. Measure VBOOST with a multimeter and adjust.
 * ========================================================================= */
#define BOOST_TARGET_DAC    16          /* Start at ~12V. Range: 0-31. */
#define BOOST_STARTUP_DAC   8           /* Soft-start value — ramps up from here */
#define BOOST_RAMP_DELAY_MS 50          /* Delay between DAC increments during ramp */
#define BOOST_MAX_DAC       24          /* Safety limit — never exceed this */

/* =========================================================================
 * RESONANCE DETECTION
 *
 * The sweep measures output current (via ADC on the current sense resistor).
 * The PZT draws maximum current at its series resonant frequency.
 *
 * RESONANCE_THRESHOLD: minimum ADC reading to accept as a valid resonance.
 *   If the sweep finds no reading above this, it reports "no cup detected."
 *   Set this above your noise floor but below expected resonance peak.
 *
 * RESONANCE_MARGIN: during operation, if the current drops below
 *   (peak_value - margin), the controller re-sweeps to re-lock.
 * ========================================================================= */
#define RESONANCE_THRESHOLD 100         /* Minimum ADC counts for valid resonance */
#define RESONANCE_MARGIN    50          /* ADC counts below peak to trigger re-sweep */
#define RECHECK_INTERVAL_MS 5000        /* How often to verify resonance during run */

/* =========================================================================
 * TREATMENT TIMER
 *
 * Default treatment duration. The controller stops automatically after this.
 * Press the button again to stop early.
 * ========================================================================= */
#define TREATMENT_TIME_SEC  600         /* 10 minutes default */

/* =========================================================================
 * PIN ASSIGNMENTS — PIC16F1713 DIP-28
 *
 * These match the wiring guide in hardware/WIRING.md.
 * Change only if you've modified the physical wiring.
 * ========================================================================= */

/* Analog inputs (ADC channels) */
#define ADC_CH_BOOST_ISENSE 0           /* AN0 = RA0 (pin 2)  — boost current sense */
#define ADC_CH_OUT_ISENSE   1           /* AN1 = RA1 (pin 3)  — output current sense */
#define ADC_CH_PEAK_VDETECT 2           /* AN2 = RA2 (pin 4)  — peak voltage detector */
#define ADC_CH_BOOST_VFDBK  3           /* AN3 = RA3 (pin 5)  — boost voltage feedback */

/* Digital outputs */
#define LED_RED_LAT         LATCbits.LATC0      /* RC0 (pin 11) */
#define LED_GREEN_LAT       LATCbits.LATC1      /* RC1 (pin 12) */

/* Digital inputs */
#define BUTTON_PORT         PORTBbits.RB0       /* RB0 (pin 21) */

/* Peripheral output pins (directly controlled by hardware peripherals) */
/* RA4 (pin 6)  = CWG1A output — drives boost MOSFET Q2 gate */
/* RC3 (pin 14) = NCO1 output  — drives output MOSFET Q4 gate */

/* =========================================================================
 * UART DEBUG (optional)
 *
 * If MCP2221 is connected, debug messages are sent at this baud rate.
 * Set to 0 to disable UART and save a few bytes of flash.
 * ========================================================================= */
#define UART_BAUD_RATE      9600
#define UART_ENABLED        1           /* Set to 0 to disable */

#endif /* CONFIG_H */
