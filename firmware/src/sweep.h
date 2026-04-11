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

/*
 * Narrow sweep around a known frequency.
 *
 * Scans +/- NARROW_SWEEP_RANGE_HZ around center_inc with finer step size.
 * Much faster than a full sweep (~150ms vs ~2.4 sec). Used when:
 *   - Resonance has drifted during a long treatment (temperature, liquid level)
 *   - Checking a cached frequency on startup
 *
 * Returns a sweep_result_t, same as sweep_find_resonance().
 * Falls through to the caller if no resonance is found (caller can
 * then try a full sweep as fallback).
 */
sweep_result_t sweep_narrow(uint16_t center_inc);

/*
 * Frequency caching — save/load the last successful resonant frequency
 * to/from the PIC16F1713's High-Endurance Flash (HEF).
 *
 * sweep_save_cached_freq() writes the NCO increment to HEF.
 * sweep_load_cached_freq() returns the cached increment, or 0 if invalid.
 */
#if FREQ_CACHE_ENABLED
void     sweep_save_cached_freq(uint16_t nco_inc);
uint16_t sweep_load_cached_freq(void);
#endif

#endif /* SWEEP_H */
