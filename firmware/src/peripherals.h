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

#endif /* PERIPHERALS_H */
