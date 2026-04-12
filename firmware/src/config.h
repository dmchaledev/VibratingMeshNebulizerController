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

/* Boost hardware mode:
 *   DISCRETE — use the on-board boost converter (L1, Q2, D1, etc.).
 *              Full DAC-controlled feedback loop. Original AN2265 design.
 *   MODULE   — use a pre-built adjustable boost module (MT3608, XL6009, etc.).
 *              Set the module's output voltage to ~12V with its trim pot.
 *              Eliminates L1, Q2, D1, R9, R5, R8, C2, C9, and all boost
 *              firmware (DAC ramp, CWG drive). Much simpler to build.
 *              See docs/BUILD_GUIDE.md for details. */
#define BOOST_MODE_DISCRETE     0
#define BOOST_MODE_MODULE       1
#define BOOST_MODE              BOOST_MODE_MODULE   /* Turnkey build uses pre-built boost module */

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

/* Narrow re-sweep: when resonance drifts during operation, try a fast
 * narrow sweep around the last known frequency before falling back to
 * a full sweep. ~150ms vs ~2.4 sec for a full sweep. */
#define NARROW_SWEEP_RANGE_HZ   3000UL  /* Scan +/- this many Hz around last known */
#define NARROW_SWEEP_STEP_HZ    200UL   /* Finer step size for narrow sweep */

/* Frequency caching: save the last successful resonant frequency to the
 * PIC16F1713's High-Endurance Flash (HEF). On next power-up, the controller
 * tries the cached frequency first — near-instant startup if the same cup
 * is still attached.
 *
 * Disable (set to 0) if you frequently swap between different cup types. */
#define FREQ_CACHE_ENABLED      1

/* =========================================================================
 * TREATMENT TIMER
 *
 * Default treatment duration. The controller stops automatically after this.
 * Press the button again to stop early.
 * ========================================================================= */
#define TREATMENT_TIME_SEC  1800        /* 30 minutes default (was 10 min) */

/* Treatment mode:
 *   TIMED      — auto-stop after TREATMENT_TIME_SEC (original behavior).
 *   CONTINUOUS — run until button press or dry-cup detection.
 *
 * Use CONTINUOUS for heavy nebulization schedules (100+ mL/day).
 * The controller still monitors for dry cup and will auto-stop
 * if no medication remains, so it's safe to leave running. */
#define TREATMENT_MODE_TIMED        0
#define TREATMENT_MODE_CONTINUOUS   1
#define TREATMENT_MODE              TREATMENT_MODE_CONTINUOUS

/* Dry-cup auto-stop: during nebulization, if the output current stays
 * below DRY_CUP_THRESHOLD for DRY_CUP_CONFIRM_MS continuously, the
 * controller assumes the cup is empty and stops automatically.
 *
 * This prevents running dry, which overheats the mesh and wastes the cup's
 * 28-day lifespan. Set DRY_CUP_THRESHOLD above your ADC noise floor but
 * well below the normal operating current. */
#define DRY_CUP_THRESHOLD      30      /* ADC counts — below this = likely empty */
#define DRY_CUP_CONFIRM_MS     3000    /* Must stay low this long to confirm (ms) */

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
