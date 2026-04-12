/*
 * lcd.c — Bit-bang I2C + HD44780 driver for a 16x2 LCD with PCF8574 backpack
 *
 * The backpack exposes the LCD's 4-bit parallel interface over I2C:
 *     I2C_byte = D7 D6 D5 D4 BL EN RW RS
 *
 * Writing one 8-bit command to the LCD takes two I2C bytes (high nibble
 * then low nibble), each pulsed by raising and lowering EN. At 100 kHz
 * bit-banged I2C this is plenty fast to refresh a 32-character display
 * several times per second without blocking the main control loop.
 *
 * Bus electrical requirements: SDA and SCL must be pulled high externally
 * to VDD (1-10 kΩ). All common PCF8574 backpacks include 4.7 kΩ pull-ups
 * on board, so no additional components are needed in this project.
 */

#include <xc.h>
#include <stdint.h>
#include "config.h"
#include "peripherals.h"
#include "lcd.h"

#if LCD_ENABLED

/* ------------------------------------------------------------------ */
/* Bit-bang I2C primitives                                             */
/* ------------------------------------------------------------------ */

/* Open-drain outputs: to drive a line low we set LAT=0 and TRIS=0.
 * To release (float high), we set TRIS=1 and let the backpack's
 * external pull-ups pull the line high. */
static inline void sda_low(void)  { LCD_SDA_LAT = 0; LCD_SDA_TRIS = 0; }
static inline void sda_high(void) { LCD_SDA_TRIS = 1; }
static inline void scl_low(void)  { LCD_SCL_LAT = 0; LCD_SCL_TRIS = 0; }
static inline void scl_high(void) { LCD_SCL_TRIS = 1; }
static inline uint8_t sda_read(void) { return LCD_SDA_PORT; }

/* ~2.5us quarter-bit delay gives ~100 kHz bit rate at 16 MHz Fosc. */
static inline void i2c_qd(void) { __delay_us(3); }

static void i2c_start(void)
{
    sda_high();
    scl_high();
    i2c_qd();
    sda_low();
    i2c_qd();
    scl_low();
    i2c_qd();
}

static void i2c_stop(void)
{
    sda_low();
    i2c_qd();
    scl_high();
    i2c_qd();
    sda_high();
    i2c_qd();
}

/* Transmit one byte MSB-first. Returns 1 if slave ACKed, 0 otherwise. */
static uint8_t i2c_write_byte(uint8_t b)
{
    uint8_t i;
    uint8_t ack;

    for (i = 0; i < 8; i++) {
        if (b & 0x80) sda_high();
        else          sda_low();
        i2c_qd();
        scl_high();
        i2c_qd();
        scl_low();
        i2c_qd();
        b <<= 1;
    }

    /* 9th clock: sample ACK from slave. Release SDA first. */
    sda_high();
    i2c_qd();
    scl_high();
    i2c_qd();
    ack = (sda_read() == 0) ? 1 : 0;
    scl_low();
    i2c_qd();
    return ack;
}

/* ------------------------------------------------------------------ */
/* PCF8574 single-byte write (S + addr + data + P)                     */
/* ------------------------------------------------------------------ */

static uint8_t lcd_i2c_addr;       /* Resolved at init time */
static uint8_t lcd_bl_state;       /* Current backlight bit (LCD_BL_BIT or 0) */

static uint8_t pcf_write(uint8_t data)
{
    uint8_t ok;
    i2c_start();
    ok  = i2c_write_byte((uint8_t)(lcd_i2c_addr << 1));    /* Write bit = 0 */
    ok &= i2c_write_byte(data);
    i2c_stop();
    return ok;
}

/* Probe the bus for an ACK at a given 7-bit address. */
static uint8_t pcf_probe(uint8_t addr7)
{
    uint8_t ok;
    i2c_start();
    ok = i2c_write_byte((uint8_t)(addr7 << 1));
    i2c_stop();
    return ok;
}

/* ------------------------------------------------------------------ */
/* LCD 4-bit nibble/byte writes                                        */
/* ------------------------------------------------------------------ */

#define LCD_RS    0x01
#define LCD_EN    0x04

/* Push a 4-bit nibble into the LCD. `nibble` occupies the low 4 bits. */
static void lcd_write_nibble(uint8_t nibble, uint8_t rs)
{
    uint8_t base = (uint8_t)((nibble & 0x0F) << 4) | lcd_bl_state |
                   (rs ? LCD_RS : 0);

    pcf_write(base | LCD_EN);     /* EN high */
    __delay_us(2);
    pcf_write(base);              /* EN low  — data latched */
    __delay_us(50);
}

static void lcd_send(uint8_t val, uint8_t rs)
{
    lcd_write_nibble((uint8_t)(val >> 4), rs);
    lcd_write_nibble((uint8_t)(val & 0x0F), rs);
}

static void lcd_cmd(uint8_t c)  { lcd_send(c, 0); }
static void lcd_data(uint8_t c) { lcd_send(c, 1); }

/* ------------------------------------------------------------------ */
/* Public API                                                          */
/* ------------------------------------------------------------------ */

uint8_t lcd_init(void)
{
    /* Ensure both lines start released (high). The gpio_init() already
     * set them as inputs, but LAT might still be 1 from reset — force 0
     * so that future TRIS=0 drives them low. */
    LCD_SDA_LAT = 0;
    LCD_SCL_LAT = 0;
    sda_high();
    scl_high();
    delay_ms(5);

    /* Auto-detect the backpack address. Most boards are 0x27, but the
     * Sainsmart/TI-style boards are 0x3F. */
    lcd_i2c_addr = LCD_I2C_ADDR_7BIT;
    if (!pcf_probe(lcd_i2c_addr)) {
        lcd_i2c_addr = LCD_I2C_ADDR_ALT_7BIT;
        if (!pcf_probe(lcd_i2c_addr)) {
            return 0;              /* No LCD detected on the bus */
        }
    }

    lcd_bl_state = LCD_BL_BIT;     /* Backlight on */

    /* HD44780 power-on initialization sequence for 4-bit mode.
     * Per the datasheet we must wait >40ms after VDD, then issue
     * three "function set" nibbles in 8-bit mode before switching
     * to 4-bit mode. */
    delay_ms(50);
    lcd_write_nibble(0x03, 0);  delay_ms(5);
    lcd_write_nibble(0x03, 0);  __delay_us(150);
    lcd_write_nibble(0x03, 0);  __delay_us(150);
    lcd_write_nibble(0x02, 0);  __delay_us(150);    /* 4-bit mode */

    lcd_cmd(0x28);              /* Function set: 4-bit, 2 lines, 5x8 font */
    lcd_cmd(0x0C);              /* Display ON, cursor OFF, blink OFF */
    lcd_cmd(0x06);              /* Entry mode: increment, no shift */
    lcd_cmd(0x01);              /* Clear display */
    delay_ms(3);
    return 1;
}

void lcd_clear(void)
{
    lcd_cmd(0x01);
    delay_ms(2);
}

void lcd_set_cursor(uint8_t row, uint8_t col)
{
    static const uint8_t row_offset[2] = { 0x00, 0x40 };
    uint8_t r = (row >= LCD_ROWS) ? (LCD_ROWS - 1) : row;
    lcd_cmd((uint8_t)(0x80 | (row_offset[r] + col)));
}

void lcd_write_char(char c)
{
    lcd_data((uint8_t)c);
}

void lcd_write_string(const char *s)
{
    while (*s) {
        lcd_data((uint8_t)*s++);
    }
}

void lcd_backlight(uint8_t on)
{
    lcd_bl_state = on ? LCD_BL_BIT : 0;
    pcf_write(lcd_bl_state);       /* Nop-byte to update the BL line */
}

/* ------------------------------------------------------------------ */
/* Tiny formatting helpers — avoid pulling in stdio                    */
/* ------------------------------------------------------------------ */

/* Write `val` as decimal digits, padded on the left with spaces to
 * exactly `width` characters. Supports values up to 65535. */
void lcd_write_u16(uint16_t val, uint8_t width)
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

/* Pad the remainder of a 16-column row with spaces up to col `to`. */
static void lcd_pad_to(uint8_t current_col, uint8_t to)
{
    while (current_col < to) {
        lcd_write_char(' ');
        current_col++;
    }
}

/* ------------------------------------------------------------------ */
/* High-level line renderers                                           */
/* ------------------------------------------------------------------ */

void lcd_show_status(const char *state_label, uint32_t freq_hz)
{
    uint8_t col = 0;
    lcd_set_cursor(0, 0);

    /* Label portion: up to 6 chars, space-padded. */
    while (*state_label && col < 6) {
        lcd_write_char(*state_label++);
        col++;
    }
    while (col < 6) {
        lcd_write_char(' ');
        col++;
    }

    /* Frequency portion: "XXX.X kHz" (9 chars) if available, else blanks. */
    if (freq_hz > 0) {
        uint16_t khz_x10 = (uint16_t)((freq_hz + 50UL) / 100UL);  /* tenths */
        uint16_t int_khz = khz_x10 / 10;
        uint16_t dec_khz = khz_x10 % 10;

        /* Hundreds digit (or space if < 100 kHz) */
        if (int_khz >= 100)  lcd_write_char((char)('0' + (int_khz / 100) % 10));
        else                 lcd_write_char(' ');
        lcd_write_char((char)('0' + (int_khz / 10) % 10));
        lcd_write_char((char)('0' + (int_khz % 10)));
        lcd_write_char('.');
        lcd_write_char((char)('0' + dec_khz));
        lcd_write_string("kHz");     /* 3 chars */
        col += 8;                    /* 5 digits/dot + 3 "kHz" = 8 */
    }
    lcd_pad_to(col, 16);
}

void lcd_show_battery(uint8_t pct, uint16_t mv, uint16_t elapsed_sec)
{
    uint8_t col = 0;
    lcd_set_cursor(1, 0);

    /* "Bat " (4) */
    lcd_write_string("Bat ");
    col += 4;

    /* "XX%" right-aligned in 3 cols (0..100 — 100 prints as "100") */
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

    /* Space (1), then either voltage "X.XXV" (5) or elapsed "MM:SS" (5) */
    lcd_write_char(' ');
    col += 1;

    if (elapsed_sec != 0xFFFF) {
        /* Show MM:SS while running (elapsed takes priority) */
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
        /* Show voltage while idle/sweeping */
        uint16_t v_whole = mv / 1000;
        uint16_t v_hund  = (mv % 1000) / 10;    /* two decimal places */
        lcd_write_char((char)('0' + v_whole % 10));
        lcd_write_char('.');
        if (v_hund < 10) lcd_write_char('0');
        lcd_write_u16(v_hund, 0);
        lcd_write_char('V');
        col += 5;
    }

    lcd_pad_to(col, 16);
}

void lcd_show_message(const char *line1, const char *line2)
{
    uint8_t col;

    lcd_set_cursor(0, 0);
    col = 0;
    while (*line1 && col < 16) { lcd_write_char(*line1++); col++; }
    lcd_pad_to(col, 16);

    lcd_set_cursor(1, 0);
    col = 0;
    while (*line2 && col < 16) { lcd_write_char(*line2++); col++; }
    lcd_pad_to(col, 16);
}

#endif /* LCD_ENABLED */
