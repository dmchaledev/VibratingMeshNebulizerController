/*
 * test_lcd_format.c — Verify the formatting functions in firmware/src/lcd.c.
 *
 * lcd_show_status() and lcd_show_battery() each render exactly one
 * 16-column row. Off-by-one bugs here would produce visible glitches on
 * the device but don't show up in cppcheck. We validate them by
 * stubbing the low-level I/O (lcd_set_cursor / lcd_write_char) to
 * append to an in-memory buffer, then comparing against expected text.
 *
 * The format functions are pasted verbatim from lcd.c. Keep them in
 * sync with the production source — see firmware/tests/README.md.
 */

#include <stdint.h>
#include <string.h>
#include "harness.h"

/* ---- In-memory frame buffer that emulates a 16x2 character display ---- */
#define LCD_ROWS 2
#define LCD_COLS 16
static char     fb_[LCD_ROWS][LCD_COLS + 1];
static uint8_t  cur_row_, cur_col_;

static void fb_reset(void)
{
    for (int r = 0; r < LCD_ROWS; r++) {
        for (int c = 0; c < LCD_COLS; c++) fb_[r][c] = '?';
        fb_[r][LCD_COLS] = '\0';
    }
    cur_row_ = cur_col_ = 0;
}

static void lcd_set_cursor(uint8_t row, uint8_t col)
{
    cur_row_ = row >= LCD_ROWS ? LCD_ROWS - 1 : row;
    cur_col_ = col >= LCD_COLS ? LCD_COLS - 1 : col;
}

static void lcd_write_char(char c)
{
    if (cur_row_ < LCD_ROWS && cur_col_ < LCD_COLS) {
        fb_[cur_row_][cur_col_++] = c;
    }
}

static void lcd_write_string(const char *s)
{
    while (*s) lcd_write_char(*s++);
}

static void lcd_pad_to(uint8_t current_col, uint8_t to)
{
    while (current_col < to) {
        lcd_write_char(' ');
        current_col++;
    }
}

static void lcd_write_u16(uint16_t val, uint8_t width)
{
    char buf[6];
    int8_t i = 5;
    int8_t digits;

    buf[5] = '\0';
    if (val == 0) {
        buf[--i] = '0';
    } else {
        while (val > 0 && i > 0) {
            buf[--i] = (char)('0' + (val % 10));
            val /= 10;
        }
    }
    digits = (int8_t)(5 - i);
    while (digits < width) {
        lcd_write_char(' ');
        digits++;
    }
    lcd_write_string(&buf[i]);
}

/* === BEGIN MIRROR of firmware/src/lcd.c:lcd_show_status === */
static void lcd_show_status(const char *state_label, uint32_t freq_hz)
{
    uint8_t col = 0;
    lcd_set_cursor(0, 0);

    while (*state_label && col < 6) {
        lcd_write_char(*state_label++);
        col++;
    }
    while (col < 6) {
        lcd_write_char(' ');
        col++;
    }

    if (freq_hz > 0) {
        uint16_t khz_x10 = (uint16_t)((freq_hz + 50UL) / 100UL);
        uint16_t int_khz = khz_x10 / 10;
        uint16_t dec_khz = khz_x10 % 10;

        if (int_khz >= 100)  lcd_write_char((char)('0' + (int_khz / 100) % 10));
        else                 lcd_write_char(' ');
        lcd_write_char((char)('0' + (int_khz / 10) % 10));
        lcd_write_char((char)('0' + (int_khz % 10)));
        lcd_write_char('.');
        lcd_write_char((char)('0' + dec_khz));
        lcd_write_string("kHz");
        col += 8;
    }
    lcd_pad_to(col, 16);
}
/* === END MIRROR === */

/* === BEGIN MIRROR of firmware/src/lcd.c:lcd_show_battery === */
static void lcd_show_battery(uint8_t pct, uint16_t mv, uint16_t elapsed_sec)
{
    uint8_t col = 0;
    lcd_set_cursor(1, 0);

    lcd_write_string("Bat ");
    col += 4;

    if (pct >= 100) {
        lcd_write_string("100");
        col += 3;
    } else if (pct >= 10) {
        lcd_write_char((char)('0' + pct / 10));
        lcd_write_char((char)('0' + pct % 10));
        col += 2;
    } else {
        lcd_write_char(' ');
        lcd_write_char((char)('0' + pct));
        col += 2;
    }
    lcd_write_char('%');
    col += 1;

    lcd_write_char(' ');
    col += 1;

    if (elapsed_sec != 0xFFFF) {
        uint16_t mm = elapsed_sec / 60;
        uint16_t ss = elapsed_sec % 60;
        if (mm > 99) mm = 99;
        lcd_write_char((char)('0' + (mm / 10) % 10));
        lcd_write_char((char)('0' + mm % 10));
        lcd_write_char(':');
        lcd_write_char((char)('0' + (ss / 10) % 10));
        lcd_write_char((char)('0' + ss % 10));
        col += 5;
    } else {
        uint16_t v_whole = mv / 1000;
        uint16_t v_hund  = (mv % 1000) / 10;
        lcd_write_char((char)('0' + v_whole % 10));
        lcd_write_char('.');
        if (v_hund < 10) lcd_write_char('0');
        lcd_write_u16(v_hund, 0);
        lcd_write_char('V');
        col += 5;
    }

    lcd_pad_to(col, 16);
}
/* === END MIRROR === */

int main(void)
{
    TEST_BEGIN("lcd_format");

    /* Status line — running at 128.5 kHz */
    fb_reset();
    lcd_show_status("RUN", 128500);
    TEST_EQ_U(strlen(fb_[0]), 16);
    TEST_STR_EQ(fb_[0], "RUN   128.5kHz  ");

    /* Status line — sweeping (no frequency yet) */
    fb_reset();
    lcd_show_status("SWEEP", 0);
    TEST_STR_EQ(fb_[0], "SWEEP           ");

    /* Status line — frequency rounding (90,049 Hz → 90.0; 90,050 → 90.1) */
    fb_reset();
    lcd_show_status("RUN", 90049);
    TEST_STR_EQ(fb_[0], "RUN    90.0kHz  ");
    fb_reset();
    lcd_show_status("RUN", 90050);
    TEST_STR_EQ(fb_[0], "RUN    90.1kHz  ");

    /* Status line — long label is truncated at 6 chars */
    fb_reset();
    lcd_show_status("OVERFLOW", 100000);
    TEST_STR_EQ(fb_[0], "OVERFL100.0kHz  ");

    /* Battery line — running with elapsed time */
    fb_reset();
    lcd_show_battery(87, 3850, 14 * 60 + 32);
    TEST_EQ_U(strlen(fb_[1]), 16);
    TEST_STR_EQ(fb_[1], "Bat 87% 14:32   ");

    /* Battery line — idle, voltage shown */
    fb_reset();
    lcd_show_battery(100, 4150, 0xFFFF);
    TEST_STR_EQ(fb_[1], "Bat 100% 4.15V  ");

    /* Battery line — single-digit % is space-padded so layout is stable */
    fb_reset();
    lcd_show_battery(5, 3100, 0xFFFF);
    TEST_STR_EQ(fb_[1], "Bat  5% 3.10V   ");

    /* Battery line — elapsed clamps at 99:59 */
    fb_reset();
    lcd_show_battery(50, 3700, 60 * 100 + 5);   /* 100 minutes 5 seconds */
    TEST_STR_EQ(fb_[1], "Bat 50% 99:05   ");

    return TEST_END();
}
