/*
 * test_battery.c — Verify battery_percent() in firmware/src/peripherals.c.
 *
 * battery_percent() is a pure piecewise-linear function of millivolts.
 * It's defined alongside hardware register code, so we can't compile the
 * whole peripherals.c on the host. Instead, we paste the function under
 * test verbatim and add a comment to keep the two copies in sync.
 *
 * If you change the implementation in peripherals.c, copy the new body
 * here and re-run `make -C firmware/tests`.
 */

#include <stdint.h>
#include "harness.h"

#define BATTERY_FULL_MV 4150     /* mirror of config.h */

/* === BEGIN MIRROR of firmware/src/peripherals.c:battery_percent === */
static uint8_t battery_percent(uint16_t mv)
{
    if (mv >= BATTERY_FULL_MV)       return 100;
    if (mv >= 3950) return (uint8_t)(75 + ((uint16_t)(mv - 3950) * 25) / 200);
    if (mv >= 3800) return (uint8_t)(50 + ((uint16_t)(mv - 3800) * 25) / 150);
    if (mv >= 3600) return (uint8_t)(25 + ((uint16_t)(mv - 3600) * 25) / 200);
    if (mv >  3000) return (uint8_t)(((uint16_t)(mv - 3000) * 25) / 600);
    return 0;
}
/* === END MIRROR === */

int main(void)
{
    TEST_BEGIN("battery");

    /* Endpoints clamp correctly. */
    TEST_EQ_U(battery_percent(0),     0);
    TEST_EQ_U(battery_percent(2999),  0);
    TEST_EQ_U(battery_percent(3000),  0);
    TEST_EQ_U(battery_percent(4150),  100);
    TEST_EQ_U(battery_percent(5000),  100);

    /* Knee points must produce monotonically non-decreasing SOC. */
    uint8_t prev = 0;
    for (uint16_t mv = 3000; mv <= 4200; mv += 25) {
        uint8_t pct = battery_percent(mv);
        TEST_TRUE(pct >= prev);
        prev = pct;
    }

    /* Spot-check the documented knee values. The piecewise-linear curve
     * is anchored at: 3000=0, 3600=25, 3800=50, 3950=75, 4150=100. */
    TEST_EQ_U(battery_percent(3600), 25);
    TEST_EQ_U(battery_percent(3800), 50);
    TEST_EQ_U(battery_percent(3950), 75);

    /* Result always fits in [0, 100]. */
    for (uint16_t mv = 0; mv < 5000; mv += 17) {
        TEST_RANGE_U(battery_percent(mv), 0, 100);
    }

    return TEST_END();
}
