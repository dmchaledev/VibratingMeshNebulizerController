/*
 * lcd.h — 16x2 HD44780 character LCD driver (I2C PCF8574 backpack)
 *
 * Simple software (bit-bang) I2C master targeting a 100 kHz bus,
 * driving an I2C-to-4-bit parallel backpack connected to a standard
 * HD44780 LCD module. The backpack pin map (PCF8574 P0..P7):
 *
 *     P0 = RS   (0 = command, 1 = data)
 *     P1 = RW   (tied low — we only write)
 *     P2 = EN   (latching strobe)
 *     P3 = BL   (backlight — active high)
 *     P4..P7 = LCD D4..D7 (4-bit mode)
 *
 * Usage:
 *     lcd_init();                      // once after system_init()
 *     lcd_set_cursor(0, 0);
 *     lcd_write_string("Hello");
 *
 * Display helpers render the fixed layout used by this project:
 *   Line 1: state + frequency
 *   Line 2: battery % + voltage + elapsed time
 */

#ifndef LCD_H
#define LCD_H

#include <stdint.h>
#include "config.h"

#if LCD_ENABLED

/* ---- Low-level control ---- */
uint8_t  lcd_init(void);                         /* Returns 1 on success, 0 if no ACK */
void     lcd_clear(void);
void     lcd_set_cursor(uint8_t row, uint8_t col);
void     lcd_write_char(char c);
void     lcd_write_string(const char *s);
void     lcd_backlight(uint8_t on);

/* ---- High-level formatted lines (pad to LCD_COLS = 16) ---- */
/* Write an integer decimal field, zero-padded to `width` columns. */
void     lcd_write_u16(uint16_t val, uint8_t width);

/* Render the "state + frequency" line for row 0.
 * state_label is a short ASCII tag like "READY", "SWEEP", "RUN", "ERR".
 * freq_hz is the currently locked output frequency (0 = none). */
void     lcd_show_status(const char *state_label, uint32_t freq_hz);

/* Render the "battery + elapsed time" line for row 1.
 * pct = 0..100, mv = millivolts, elapsed_sec = treatment time in seconds
 * (0xFFFF suppresses the elapsed field, e.g., for idle/sweep). */
void     lcd_show_battery(uint8_t pct, uint16_t mv, uint16_t elapsed_sec);

/* Convenience: show a short two-line message (e.g., startup banner).
 * Each argument should be at most 16 characters. */
void     lcd_show_message(const char *line1, const char *line2);

#else /* LCD_ENABLED == 0 — compile out all LCD calls */

#define  lcd_init()                             (1)
#define  lcd_clear()                            ((void)0)
#define  lcd_set_cursor(r, c)                   ((void)0)
#define  lcd_write_char(c)                      ((void)0)
#define  lcd_write_string(s)                    ((void)0)
#define  lcd_backlight(on)                      ((void)0)
#define  lcd_write_u16(v, w)                    ((void)0)
#define  lcd_show_status(lbl, f)                ((void)0)
#define  lcd_show_battery(p, mv, sec)           ((void)0)
#define  lcd_show_message(l1, l2)               ((void)0)

#endif /* LCD_ENABLED */

#endif /* LCD_H */
