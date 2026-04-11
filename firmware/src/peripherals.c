/*
 * peripherals.c — PIC16F1713 peripheral initialization
 *
 * Configures all on-chip peripherals for the vibrating mesh nebulizer controller.
 * This file targets the PIC16F1713 using the Microchip XC8 compiler.
 *
 * Peripherals used:
 *   HFINTOSC  — 16 MHz internal oscillator (no external crystal needed)
 *   NCO1      — Numerically Controlled Oscillator for ~90-150 kHz output
 *   DAC1      — 5-bit DAC for boost voltage reference
 *   ADC       — 10-bit ADC for current/voltage sensing
 *   CWG1      — Complementary Waveform Generator for boost MOSFET drive
 *   Timer1    — Treatment duration timing
 *   EUSART    — Optional debug UART at 9600 baud
 *   GPIO      — LEDs and button
 */

#include <xc.h>
#include <stdint.h>
#include "config.h"
#include "peripherals.h"

/* ========================================================================
 * PIC16F1713 Configuration Bits
 *
 * These are burned into the chip during programming. They configure
 * fundamental chip behavior that can't be changed at runtime.
 * ======================================================================== */
#pragma config FOSC    = INTOSC    /* Internal oscillator, I/O on RA6/RA7 */
#pragma config WDTE    = OFF       /* Watchdog timer off (enable for production) */
#pragma config PWRTE   = ON        /* Power-up timer on — gives supply time to stabilize */
#pragma config MCLRE   = ON        /* MCLR pin enabled (needed for ICSP programming) */
#pragma config CP      = OFF       /* Code protection off */
#pragma config BOREN   = ON        /* Brown-out reset on — resets if VDD drops too low */
#pragma config CLKOUTEN = OFF      /* Clock out disabled */
#pragma config IESO    = OFF       /* Internal/external switchover off */
#pragma config FCMEN   = OFF       /* Fail-safe clock monitor off */

#pragma config WRT     = OFF       /* Flash write protection off */
#pragma config PPS1WAY = ON        /* PPS one-way lock — peripherals locked after first config */
#pragma config ZCDDIS  = ON        /* Zero-cross detect disabled */
#pragma config PLLEN   = OFF       /* PLL disabled (we use 16 MHz directly) */
#pragma config STVREN  = ON        /* Stack overflow/underflow reset enabled */
#pragma config BORV    = LO        /* Brown-out reset at low trip point */
#pragma config LPBOR   = OFF       /* Low-power brown-out off */
#pragma config LVP     = ON        /* Low-voltage programming enabled */

/* ========================================================================
 * Oscillator — 16 MHz HFINTOSC
 * ======================================================================== */
static void osc_init(void)
{
    /* OSCCON: select 16 MHz HFINTOSC */
    OSCCONbits.IRCF = 0b1111;  /* 16 MHz */
    OSCCONbits.SCS  = 0b00;    /* Clock determined by FOSC config bits */

    /* Wait for oscillator to stabilize */
    while (!OSCSTATbits.HFIOFR)
        ;
}

/* ========================================================================
 * GPIO — Pin directions, analog/digital, pull-ups
 * ======================================================================== */
static void gpio_init(void)
{
    /* Default all pins to digital */
    ANSELA = 0x00;
    ANSELB = 0x00;
    ANSELC = 0x00;

    /* Set analog pins: RA0-RA3 (AN0-AN3) are analog inputs */
    ANSELAbits.ANSA0 = 1;  /* AN0 — boost current sense */
    ANSELAbits.ANSA1 = 1;  /* AN1 — output current sense */
    ANSELAbits.ANSA2 = 1;  /* AN2 — peak voltage detector */
    ANSELAbits.ANSA3 = 1;  /* AN3 — boost voltage feedback */

    /* Port A direction: RA0-RA3 inputs (analog), RA4-RA5 outputs (CWG) */
    TRISA = 0b00001111;     /* RA0-RA3 input, RA4-RA7 output */

    /* Port B direction: RB0 input (button), RB6-RB7 for ICSP */
    TRISB = 0b11000001;     /* RB0 input, RB1-RB5 output, RB6-RB7 ICSP */

    /* Port C direction: RC0-RC1 output (LEDs), RC3 output (NCO),
     * RC6 output (TX), RC7 input (RX) */
    TRISC = 0b10000000;     /* RC7 input, rest output */

    /* Initialize outputs low */
    LATA = 0x00;
    LATB = 0x00;
    LATC = 0x00;

    /* Enable weak pull-up on RB0 (button) */
    OPTION_REGbits.nWPUEN = 0;  /* Enable individual pull-ups */
    WPUBbits.WPUB0 = 1;        /* Pull-up on RB0 */
}

/* ========================================================================
 * NCO1 — Numerically Controlled Oscillator
 *
 * Generates the ~90-150 kHz square wave that drives the output MOSFET.
 * Output on RC3 (pin 14).
 *
 * Frequency = (NCO1INC * Fosc) / 2^20
 *           = (NCO1INC * 16000000) / 1048576
 * ======================================================================== */
static void nco_init(void)
{
    /* Route NCO1 output to RC3 via PPS (Peripheral Pin Select) */
    RC3PPS = 0b11001;       /* NCO1 output -> RC3 */

    /* NCO1 clock source = Fosc (16 MHz) */
    NCO1CLKbits.N1CKS = 0b00;  /* Clock source = Fosc */

    /* Set initial increment to minimum sweep frequency */
    NCO1INCH = (uint8_t)(NCO_INC_MIN >> 8);
    NCO1INCL = (uint8_t)(NCO_INC_MIN & 0xFF);

    /* NCO1 control: Fixed Duty Cycle mode, output enabled, active high */
    NCO1CONbits.N1PFM = 0;     /* Fixed Duty Cycle mode (50% square wave) */
    NCO1CONbits.N1POL = 0;     /* Active high */
    NCO1CONbits.N1EN  = 0;     /* Start disabled — enabled during sweep */
}

void nco_set_increment(uint16_t inc)
{
    NCO1INCH = (uint8_t)(inc >> 8);
    NCO1INCL = (uint8_t)(inc & 0xFF);
}

void nco_enable(void)
{
    NCO1CONbits.N1EN = 1;
}

void nco_disable(void)
{
    NCO1CONbits.N1EN = 0;
}

/* ========================================================================
 * DAC1 — 5-bit Digital-to-Analog Converter
 *
 * Output on RA2 (pin 4). Used as a voltage reference for the boost
 * converter feedback comparator. Higher DAC value = higher VBOOST.
 * ======================================================================== */
static void dac_init(void)
{
    /* DAC1: output enabled, positive source = VDD, negative source = VSS */
    DAC1CON0bits.DAC1EN  = 1;   /* Enable DAC */
    DAC1CON0bits.DAC1OE1 = 1;   /* Output on DAC1OUT1 pin (RA2) */
    DAC1CON0bits.DAC1PSS = 0b00; /* Positive source = VDD */
    DAC1CON0bits.DAC1NSS = 0;    /* Negative source = VSS */

    /* Start at soft-start value */
    DAC1CON1 = BOOST_STARTUP_DAC;
}

void dac_set_value(uint8_t val)
{
    if (val > BOOST_MAX_DAC)
        val = BOOST_MAX_DAC;    /* Safety clamp */
    DAC1CON1 = val & 0x1F;     /* 5-bit DAC: mask to 0-31 */
}

/* ========================================================================
 * ADC — 10-bit Analog-to-Digital Converter
 *
 * Reads voltage on analog input channels. Used for:
 *   AN0: Boost current sense
 *   AN1: Output current sense (primary resonance detection signal)
 *   AN2: Peak voltage detector
 *   AN3: Boost voltage feedback
 * ======================================================================== */
static void adc_init(void)
{
    /* ADC clock = Fosc/32 = 500 kHz (within recommended range) */
    ADCON1bits.ADCS = 0b010;    /* Fosc/32 */
    ADCON1bits.ADFM = 1;        /* Right-justified result */
    ADCON1bits.ADPREF = 0b00;   /* Positive reference = VDD */
    ADCON1bits.ADNREF = 0;      /* Negative reference = VSS */

    ADCON0bits.ADON = 1;        /* Enable ADC */
}

uint16_t adc_read(uint8_t channel)
{
    /* Select channel */
    ADCON0bits.CHS = channel & 0x1F;

    /* Acquisition delay — ~10 us for input to settle */
    __delay_us(10);

    /* Start conversion */
    ADCON0bits.GO_nDONE = 1;

    /* Wait for completion */
    while (ADCON0bits.GO_nDONE)
        ;

    /* Return 10-bit result */
    return (uint16_t)((ADRESH << 8) | ADRESL);
}

/* ========================================================================
 * CWG1 — Complementary Waveform Generator
 *
 * Takes the NCO1 output as its input source and generates the boost
 * MOSFET gate drive signal on RA4 (CWG1A, pin 6).
 *
 * In this design, CWG passes the NCO signal through to the boost MOSFET
 * with configurable dead-band control to prevent shoot-through.
 * ======================================================================== */
static void cwg_init(void)
{
    /* Route CWG1A output to RA4 via PPS */
    RA4PPS = 0b01100;      /* CWG1A -> RA4 */

    /* CWG data input = NCO1 output */
    CWG1ISbits.IS = 0b0100;    /* Input source = NCO1OUT */

    /* Dead-band: 2 counts on both rising and falling edge */
    CWG1DBR = 2;            /* Rising edge dead-band */
    CWG1DBF = 2;            /* Falling edge dead-band */

    /* CWG control */
    CWG1CON0bits.G1EN   = 0;   /* Start disabled */
    CWG1CON0bits.G1OEA  = 1;   /* Output A enabled (RA4) */
    CWG1CON0bits.G1OEB  = 0;   /* Output B disabled */
    CWG1CON0bits.G1POLA = 0;   /* Output A not inverted */
    CWG1CON0bits.G1POLB = 0;   /* Output B not inverted */
    CWG1CON0bits.G1CS0  = 0;   /* Clock source = Fosc */

    CWG1CON1 = 0x00;           /* No auto-shutdown */
    CWG1CON2 = 0x00;           /* No auto-restart */
}

/* ========================================================================
 * Timer1 — Treatment Duration Timer
 *
 * Timer1 runs as a free-running counter. With Fosc/4 clock and 1:8
 * prescaler, it overflows every ~131 ms. The main loop counts overflows
 * to track treatment time.
 *
 * Timer1 period = (65536 * prescaler) / (Fosc/4)
 *               = (65536 * 8) / 4000000
 *               = 0.131 seconds per overflow
 * ======================================================================== */
static void timer1_init(void)
{
    T1CONbits.TMR1CS = 0b00;   /* Clock source = Fosc/4 */
    T1CONbits.T1CKPS = 0b11;   /* Prescaler 1:8 */
    T1CONbits.TMR1ON = 0;      /* Start disabled */

    TMR1H = 0;
    TMR1L = 0;
    PIR1bits.TMR1IF = 0;       /* Clear overflow flag */
}

void timer1_start(void)
{
    TMR1H = 0;
    TMR1L = 0;
    PIR1bits.TMR1IF = 0;
    T1CONbits.TMR1ON = 1;
}

void timer1_stop(void)
{
    T1CONbits.TMR1ON = 0;
}

uint8_t timer1_overflow(void)
{
    return PIR1bits.TMR1IF;
}

void timer1_clear_overflow(void)
{
    PIR1bits.TMR1IF = 0;
}

/* ========================================================================
 * EUSART — Debug UART (optional)
 *
 * TX on RC6 (pin 17), RX on RC7 (pin 18).
 * Configured for 9600 baud, 8N1, transmit-only for debug output.
 * Connect to MCP2221 USB-UART bridge for PC serial monitor.
 * ======================================================================== */
#if UART_ENABLED
static void uart_init(void)
{
    /* Route EUSART TX to RC6 via PPS */
    RC6PPS = 0b10100;          /* TX -> RC6 */
    RXPPSbits.RXPPS = 0b10111; /* RX <- RC7 */

    /* Baud rate: 9600 at 16 MHz, BRGH=1, BRG16=1
     * SPBRG = (Fosc / (4 * baud)) - 1 = (16000000 / 38400) - 1 = 416 */
    TX1STAbits.BRGH = 1;
    BAUD1CONbits.BRG16 = 1;
    SP1BRGH = 0x01;            /* 416 >> 8 = 1 */
    SP1BRGL = 0xA0;            /* 416 & 0xFF = 160 (0xA0) */

    /* Enable transmitter and serial port */
    TX1STAbits.TXEN = 1;       /* Enable transmit */
    TX1STAbits.SYNC = 0;       /* Asynchronous mode */
    RC1STAbits.SPEN = 1;       /* Enable serial port */
}

void uart_send_char(char c)
{
    while (!PIR1bits.TXIF)      /* Wait for transmit buffer empty */
        ;
    TX1REG = c;
}

void uart_send_string(const char *str)
{
    while (*str) {
        uart_send_char(*str++);
    }
}

void uart_send_uint16(uint16_t val)
{
    char buf[6];
    int8_t i = 4;

    buf[5] = '\0';
    if (val == 0) {
        uart_send_char('0');
        return;
    }
    while (val > 0 && i >= 0) {
        buf[i--] = '0' + (val % 10);
        val /= 10;
    }
    uart_send_string(&buf[i + 1]);
}
#endif /* UART_ENABLED */

/* ========================================================================
 * GPIO convenience functions
 * ======================================================================== */
void led_red_on(void)       { LED_RED_LAT = 1; }
void led_red_off(void)      { LED_RED_LAT = 0; }
void led_green_on(void)     { LED_GREEN_LAT = 1; }
void led_green_off(void)    { LED_GREEN_LAT = 0; }

uint8_t button_pressed(void)
{
    /* Button is active-low with pull-up */
    return (BUTTON_PORT == 0) ? 1 : 0;
}

/* ========================================================================
 * Delay
 * ======================================================================== */
void delay_ms(uint16_t ms)
{
    while (ms--) {
        __delay_ms(1);
    }
}

/* ========================================================================
 * System init — call once at startup
 * ======================================================================== */
void system_init(void)
{
    osc_init();
    gpio_init();
    nco_init();
    dac_init();
    adc_init();
    cwg_init();
    timer1_init();

#if UART_ENABLED
    uart_init();
#endif
}
