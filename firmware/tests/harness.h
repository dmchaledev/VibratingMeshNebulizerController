/*
 * harness.h — Tiny zero-dependency unit-test harness for firmware logic.
 *
 * Each test program calls TEST_BEGIN("name") at startup, then any number
 * of TEST_* assertions, then TEST_END() before returning.
 * TEST_END() prints a summary and returns the failure count.
 */

#ifndef FIRMWARE_TEST_HARNESS_H
#define FIRMWARE_TEST_HARNESS_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>

static int  th_total_   = 0;
static int  th_failed_  = 0;
static const char *th_name_ = "unnamed";

#define TEST_BEGIN(name)  do { th_name_ = (name); printf("=== %s ===\n", th_name_); } while (0)

#define TEST_END() (                                                   \
    printf("%s: %d/%d passed%s\n",                                     \
           th_name_, th_total_ - th_failed_, th_total_,                \
           th_failed_ == 0 ? " OK" : " FAIL"),                         \
    (th_failed_ == 0 ? 0 : 1))

#define TEST_EQ_U(actual, expected) do {                               \
    th_total_++;                                                       \
    unsigned long _a = (unsigned long)(actual);                        \
    unsigned long _e = (unsigned long)(expected);                      \
    if (_a != _e) {                                                    \
        th_failed_++;                                                  \
        fprintf(stderr,                                                \
            "  FAIL %s:%d  %s == %lu (expected %lu)\n",                \
            __FILE__, __LINE__, #actual, _a, _e);                      \
    }                                                                  \
} while (0)

#define TEST_TRUE(expr) do {                                           \
    th_total_++;                                                       \
    if (!(expr)) {                                                     \
        th_failed_++;                                                  \
        fprintf(stderr,                                                \
            "  FAIL %s:%d  expected true: %s\n",                       \
            __FILE__, __LINE__, #expr);                                \
    }                                                                  \
} while (0)

#define TEST_STR_EQ(actual, expected) do {                             \
    th_total_++;                                                       \
    if (strcmp((actual), (expected)) != 0) {                           \
        th_failed_++;                                                  \
        fprintf(stderr,                                                \
            "  FAIL %s:%d  %s = \"%s\" (expected \"%s\")\n",           \
            __FILE__, __LINE__, #actual, (actual), (expected));        \
    }                                                                  \
} while (0)

#define TEST_RANGE_U(actual, lo, hi) do {                              \
    th_total_++;                                                       \
    unsigned long _a = (unsigned long)(actual);                        \
    unsigned long _l = (unsigned long)(lo);                            \
    unsigned long _h = (unsigned long)(hi);                            \
    if (_a < _l || _a > _h) {                                          \
        th_failed_++;                                                  \
        fprintf(stderr,                                                \
            "  FAIL %s:%d  %s = %lu (expected in [%lu, %lu])\n",       \
            __FILE__, __LINE__, #actual, _a, _l, _h);                  \
    }                                                                  \
} while (0)

#endif /* FIRMWARE_TEST_HARNESS_H */
