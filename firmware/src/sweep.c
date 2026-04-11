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
