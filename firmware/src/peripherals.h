/*
 * peripherals.h — PIC16F1713 peripheral initialization declarations
 *
 * Initializes the on-chip peripherals used by the nebulizer controller:
 *   - Oscillator (16 MHz internal)
 *   - NCO (Numerically Controlled Oscillator) for frequency generation
 *   - DAC for boost voltage reference
 *   - ADC for feedback measurements
 *   - CWG (Complementary Waveform Generator) for boost MOSFET drive
 *   - Timer1 for treatment timing
 *   - GPIO for LEDs and button
 *   - EUSART for optional debug output
 */

#ifndef PERIPHERALS_H
#define PERIPHERALS_H

#include <xc.h>
#include <stdint.h>
#include "config.h"

/* ---- Initialization ---- */
void     system_init(void);         /* Call once at startup — inits everything */

/* ---- NCO control ---- */
void     nco_set_increment(uint16_t inc);   /* Set NCO frequency via increment register */
void     nco_enable(void);
void     nco_disable(void);

/* ---- DAC control ---- */
void     dac_set_value(uint8_t val);        /* Set DAC1 output (0-31, 5-bit) */

/* ---- ADC ---- */
uint16_t adc_read(uint8_t channel);         /* Read 10-bit ADC on given channel */

/* ---- Battery monitoring ---- */
#if BATTERY_ENABLED
/* Read battery voltage in millivolts. Works by reading the internal FVR
 * (Fixed Voltage Reference) with VDD as the ADC reference, then back-
 * calculating VDD = Vbat. No external divider required. Returns 0 if the
 * ADC reading is implausible. */
uint16_t battery_read_mv(void);

/* Convert millivolts to a 0-100% state-of-charge estimate using a
 * piecewise-linear approximation of a typical LiPo discharge curve. */
uint8_t  battery_percent(uint16_t mv);
#endif

/* ---- Timer ---- */
void     timer1_start(void);
void     timer1_stop(void);
uint8_t  timer1_overflow(void);             /* Returns 1 if Timer1 overflowed */
void     timer1_clear_overflow(void);

/* ---- GPIO ---- */
void     led_red_on(void);
void     led_red_off(void);
void     led_green_on(void);
void     led_green_off(void);
uint8_t  button_pressed(void);              /* Returns 1 if button is pressed (active low) */

/* ---- UART debug (optional) ---- */
#if UART_ENABLED
void     uart_send_char(char c);
void     uart_send_string(const char *str);
void     uart_send_uint16(uint16_t val);
#else
#define  uart_send_char(c)       ((void)0)
#define  uart_send_string(s)     ((void)0)
#define  uart_send_uint16(v)     ((void)0)
#endif

/* ---- Delays ---- */
void     delay_ms(uint16_t ms);

/* ---- HEF (High-Endurance Flash) — non-volatile storage ---- */
#if FREQ_CACHE_ENABLED
uint16_t hef_read_word(uint16_t addr);
void     hef_erase_row(uint16_t row_addr);
void     hef_write_words(uint16_t start_addr, const uint16_t *data, uint8_t count);
#endif

#endif /* PERIPHERALS_H */
