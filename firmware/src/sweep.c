/*
 * sweep.c — Frequency sweep algorithm for PZT resonance detection
 *
 * The PZT (piezoelectric) element inside a vibrating mesh nebulizer has a
 * specific resonant frequency where it draws maximum current and produces
 * optimal mesh vibration. This frequency varies by:
 *   - Manufacturer and cup model
 *   - Individual unit (manufacturing tolerances)
 *   - Liquid loading (empty vs. full cup)
 *   - Temperature
 *   - Cup age/wear
 *
 * The sweep algorithm scans the NCO frequency across the configured range,
 * measuring the output current at each step. The frequency that produces
 * the highest current reading is the series resonant frequency of the PZT.
 *
 * Based on Microchip AN2265 reference design approach.
 */

#include <xc.h>
#include <stdint.h>
#include "config.h"
#include "peripherals.h"
#include "sweep.h"

/*
 * Read the output current sense ADC, averaged over SWEEP_AVG_SAMPLES.
 * This reduces noise in the measurement, giving a more reliable peak.
 */
static uint16_t read_current_avg(void)
{
    uint32_t sum = 0;
    uint8_t i;

    for (i = 0; i < SWEEP_AVG_SAMPLES; i++) {
        sum += adc_read(ADC_CH_OUT_ISENSE);
    }

    return (uint16_t)(sum / SWEEP_AVG_SAMPLES);
}

/*
 * Perform a full frequency sweep.
 *
 * Algorithm:
 *   1. Start at SWEEP_FREQ_MIN (NCO_INC_MIN)
 *   2. At each step, set the NCO frequency, wait for settling, read ADC
 *   3. Track the maximum ADC reading and its corresponding NCO increment
 *   4. Step up by SWEEP_STEP_HZ until reaching SWEEP_FREQ_MAX
 *   5. If the peak exceeds RESONANCE_THRESHOLD, report it as found
 *
 * The NCO is enabled at the start and left enabled at the peak frequency
 * if resonance is found, or disabled if not found.
 */
sweep_result_t sweep_find_resonance(void)
{
    sweep_result_t result;
    uint16_t current_inc;
    uint16_t current_adc;

    result.peak_inc = NCO_INC_MIN;
    result.peak_adc = 0;
    result.found    = 0;

    /* Enable NCO output — this starts driving the output MOSFET */
    nco_enable();

    uart_send_string("SWEEP: start\r\n");

    /* Scan from min to max frequency */
    for (current_inc = NCO_INC_MIN; current_inc <= NCO_INC_MAX; current_inc += NCO_INC_STEP) {

        /* Set the NCO to the current frequency */
        nco_set_increment(current_inc);

        /* Wait for the output LC circuit to settle at the new frequency.
         * The LC resonant circuit has a Q factor that means it takes a few
         * cycles to reach steady state. SWEEP_DWELL_MS should be long enough
         * for the output amplitude to stabilize. */
        delay_ms(SWEEP_DWELL_MS);

        /* Read the output current (averaged) */
        current_adc = read_current_avg();

        /* Track the peak */
        if (current_adc > result.peak_adc) {
            result.peak_adc = current_adc;
            result.peak_inc = current_inc;
        }

        /* Toggle green LED during sweep for visual feedback */
        LED_GREEN_LAT = !LED_GREEN_LAT;
    }

    /* Evaluate result */
    if (result.peak_adc >= RESONANCE_THRESHOLD) {
        result.found = 1;

        /* Lock NCO onto the resonant frequency */
        nco_set_increment(result.peak_inc);

        uart_send_string("SWEEP: found at INC=");
        uart_send_uint16(result.peak_inc);
        uart_send_string(" ADC=");
        uart_send_uint16(result.peak_adc);
        uart_send_string("\r\n");
    } else {
        /* No resonance found — disable output */
        nco_disable();

        uart_send_string("SWEEP: no resonance (peak ADC=");
        uart_send_uint16(result.peak_adc);
        uart_send_string(")\r\n");
    }

    led_green_off();

    return result;
}

/*
 * Quick resonance check at a specific NCO increment.
 *
 * Used during operation to verify the PZT is still at resonance
 * without doing a full sweep. If the current has dropped significantly,
 * the main loop will trigger a re-sweep.
 */
uint16_t sweep_check_current(uint16_t nco_inc)
{
    nco_set_increment(nco_inc);
    delay_ms(SWEEP_DWELL_MS);
    return read_current_avg();
}

/*
 * Narrow sweep around a known frequency.
 *
 * Scans +/- NARROW_SWEEP_RANGE_HZ around center_inc with finer steps.
 * Typically completes in ~150ms (vs ~2.4 sec for a full sweep).
 *
 * This is used for:
 *   - Re-acquiring resonance that has drifted slightly during operation
 *   - Validating a cached frequency on startup
 *
 * The NCO must already be enabled before calling this function.
 */
#define NARROW_INC_RANGE  ((uint16_t)((NARROW_SWEEP_RANGE_HZ * 65536UL) / 1000000UL))
#define NARROW_INC_STEP   ((uint16_t)((NARROW_SWEEP_STEP_HZ * 65536UL) / 1000000UL))

sweep_result_t sweep_narrow(uint16_t center_inc)
{
    sweep_result_t result;
    uint16_t start_inc, end_inc;
    uint16_t current_inc;
    uint16_t current_adc;

    result.peak_inc = center_inc;
    result.peak_adc = 0;
    result.found    = 0;

    /* Calculate narrow sweep bounds, clamped to valid range */
    start_inc = (center_inc > NARROW_INC_RANGE + NCO_INC_MIN)
                ? (center_inc - NARROW_INC_RANGE) : NCO_INC_MIN;
    end_inc   = (center_inc + NARROW_INC_RANGE < NCO_INC_MAX)
                ? (center_inc + NARROW_INC_RANGE) : NCO_INC_MAX;

    nco_enable();

    uart_send_string("NARROW: around INC=");
    uart_send_uint16(center_inc);
    uart_send_string("\r\n");

    for (current_inc = start_inc; current_inc <= end_inc; current_inc += NARROW_INC_STEP) {
        nco_set_increment(current_inc);
        delay_ms(SWEEP_DWELL_MS);
        current_adc = read_current_avg();

        if (current_adc > result.peak_adc) {
            result.peak_adc = current_adc;
            result.peak_inc = current_inc;
        }
    }

    if (result.peak_adc >= RESONANCE_THRESHOLD) {
        result.found = 1;
        nco_set_increment(result.peak_inc);

        uart_send_string("NARROW: found at INC=");
        uart_send_uint16(result.peak_inc);
        uart_send_string(" ADC=");
        uart_send_uint16(result.peak_adc);
        uart_send_string("\r\n");
    } else {
        nco_disable();

        uart_send_string("NARROW: miss (peak ADC=");
        uart_send_uint16(result.peak_adc);
        uart_send_string(")\r\n");
    }

    return result;
}

/* ========================================================================
 * Frequency caching — HEF-based persistent storage
 *
 * Layout in HEF Row 0 (0x1F80):
 *   Word 0: Magic value (0x005A) — indicates valid data
 *   Word 1: NCO increment of last successful resonance
 * ======================================================================== */
#if FREQ_CACHE_ENABLED

#define HEF_ROW_ADDR    0x1F80
#define HEF_MAGIC_WORD  0x005A

void sweep_save_cached_freq(uint16_t nco_inc)
{
    uint16_t data[2];
    data[0] = HEF_MAGIC_WORD;
    data[1] = nco_inc;

    hef_erase_row(HEF_ROW_ADDR);
    hef_write_words(HEF_ROW_ADDR, data, 2);

    uart_send_string("CACHE: saved INC=");
    uart_send_uint16(nco_inc);
    uart_send_string("\r\n");
}

uint16_t sweep_load_cached_freq(void)
{
    uint16_t magic = hef_read_word(HEF_ROW_ADDR);
    if (magic != HEF_MAGIC_WORD)
        return 0;   /* No valid cache */

    uint16_t cached_inc = hef_read_word(HEF_ROW_ADDR + 1);

    /* Validate: must be within configured sweep range */
    if (cached_inc < NCO_INC_MIN || cached_inc > NCO_INC_MAX)
        return 0;

    uart_send_string("CACHE: loaded INC=");
    uart_send_uint16(cached_inc);
    uart_send_string("\r\n");

    return cached_inc;
}

#endif /* FREQ_CACHE_ENABLED */
