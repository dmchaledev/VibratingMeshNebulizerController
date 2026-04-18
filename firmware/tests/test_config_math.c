/*
 * test_config_math.c — Verify the NCO ↔ Hz conversion macros in config.h.
 *
 * The PIC16F1713's NCO produces an output frequency of:
 *     f_out = NCO_INC * Fosc / 2^20
 * The macros in config.h compute the inverse for the configured sweep
 * range. A regression here would silently shift the swept frequency.
 */

#include <stdint.h>
#include "harness.h"
#include "../src/config.h"

int main(void)
{
    TEST_BEGIN("config_math");

    /* Bounds of the default sweep range. Reference values were
     * computed by hand from f * 2^20 / 16e6 with rounding to integer. */
    TEST_EQ_U(NCO_INC_MIN, 5898u);     /*  90 kHz */
    TEST_EQ_U(NCO_INC_MAX, 9830u);     /* 150 kHz */
    TEST_EQ_U(NCO_INC_STEP, 32u);      /* 500 Hz step (≈ 32.768) */

    /* Round-trip through NCO_INC_TO_HZ should land within one step. */
    uint32_t round_min = NCO_INC_TO_HZ(NCO_INC_MIN);
    uint32_t round_max = NCO_INC_TO_HZ(NCO_INC_MAX);
    TEST_RANGE_U(round_min, SWEEP_FREQ_MIN_HZ - SWEEP_STEP_HZ,
                            SWEEP_FREQ_MIN_HZ + SWEEP_STEP_HZ);
    TEST_RANGE_U(round_max, SWEEP_FREQ_MAX_HZ - SWEEP_STEP_HZ,
                            SWEEP_FREQ_MAX_HZ + SWEEP_STEP_HZ);

    /* The Aerogen Solo's typical resonant frequency. */
    uint16_t aerogen_inc = (uint16_t)((128000UL * 65536UL) / 1000000UL);
    TEST_EQ_U(aerogen_inc, 8388u);
    TEST_RANGE_U(NCO_INC_TO_HZ(aerogen_inc), 127500u, 128500u);

    /* The narrow-sweep window must be a multiple of the narrow step
     * (otherwise the loop overshoots/undershoots the range). */
    TEST_TRUE(NARROW_SWEEP_RANGE_HZ % NARROW_SWEEP_STEP_HZ == 0);

    /* Battery thresholds must be strictly ordered: full > nominal > low > crit. */
    TEST_TRUE(BATTERY_FULL_MV > BATTERY_NOMINAL_MV);
    TEST_TRUE(BATTERY_NOMINAL_MV > BATTERY_LOW_MV);
    TEST_TRUE(BATTERY_LOW_MV > BATTERY_CRIT_MV);

    /* DAC safety: the runtime target must not exceed the safety cap. */
    TEST_TRUE(BOOST_TARGET_DAC <= BOOST_MAX_DAC);
    TEST_TRUE(BOOST_STARTUP_DAC <= BOOST_TARGET_DAC);

    return TEST_END();
}
