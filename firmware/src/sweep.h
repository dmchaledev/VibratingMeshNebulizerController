/*
 * sweep.h — Frequency sweep algorithm declarations
 *
 * The sweep scans the NCO frequency across the configured range,
 * measuring output current at each step. The PZT draws maximum current
 * at its series resonant frequency — that's the peak we're looking for.
 */

#ifndef SWEEP_H
#define SWEEP_H

#include <stdint.h>

/* Result of a frequency sweep */
typedef struct {
    uint16_t peak_inc;      /* NCO increment value at resonant frequency */
    uint16_t peak_adc;      /* ADC reading at the resonant peak */
    uint8_t  found;         /* 1 if a valid resonance was found, 0 if not */
} sweep_result_t;

/*
 * Perform a full frequency sweep from SWEEP_FREQ_MIN to SWEEP_FREQ_MAX.
 *
 * At each step:
 *   1. Set NCO to the current frequency
 *   2. Wait SWEEP_DWELL_MS for the output to settle
 *   3. Read the output current sense ADC (averaged over SWEEP_AVG_SAMPLES)
 *   4. Track the maximum reading and its corresponding NCO increment
 *
 * Returns a sweep_result_t with the peak frequency and whether it exceeded
 * RESONANCE_THRESHOLD.
 */
sweep_result_t sweep_find_resonance(void);

/*
 * Quick re-check: read the current sense ADC at the given NCO increment.
 * Used during operation to verify we're still at resonance without
 * doing a full sweep.
 *
 * Returns the averaged ADC reading.
 */
uint16_t sweep_check_current(uint16_t nco_inc);

#endif /* SWEEP_H */
