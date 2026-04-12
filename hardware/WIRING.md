# Wiring Reference — PIC16F1713 DIP-28 Breadboard Build

Pin-by-pin wiring guide for the AN2265-based vibrating mesh nebulizer controller.

---

## PIC16F1713-I/SP (DIP-28) Pinout

```
                  ┌────────────┐
   MCLR/RE3  1 ──┤            ├── 28  RB7/ICSPDAT
    AN0/RA0  2 ──┤            ├── 27  RB6/ICSPCLK
    AN1/RA1  3 ──┤            ├── 26  RB5/AN13
    AN2/RA2  4 ──┤            ├── 25  RB4/AN11
   AN3/RA3   5 ──┤            ├── 24  RB3/AN9
  CWG1A/RA4  6 ──┤ PIC16F1713 ├── 23  RB2/AN8
  CWG1B/RA5  7 ──┤   DIP-28   ├── 22  RB1/AN10
        VSS  8 ──┤            ├── 21  RB0/AN12/INT
   OSC1/RA7  9 ──┤            ├── 20  VDD
   OSC2/RA6 10 ──┤            ├── 19  VSS
        RC0 11 ──┤            ├── 18  RC7/RX
        RC1 12 ──┤            ├── 17  RC6/TX
   CCP1/RC2 13 ──┤            ├── 16  RC5/CWG1A
   NCO1/RC3 14 ──┤            ├── 15  RC4
                  └────────────┘
```

---

## Pin Assignments

| Pin | Name | Direction | Function | Connects To |
|-----|------|-----------|----------|-------------|
| 1 | RE3/MCLR | Input | Master Clear / Programming | 10K pull-up to VDD + Programmer MCLR |
| 2 | RA0/AN0 | Input (Analog) | Boost current sense ADC | R9 junction via 4.7K filter resistor |
| 3 | RA1/AN1 | Input (Analog) | Output current sense ADC | R18 junction via 4.7K filter resistor |
| 4 | RA2/AN2 | Input (Analog) | Peak voltage detector ADC | R12/R13 voltage divider midpoint |
| 5 | RA3/AN3 | Input (Analog) | Boost voltage feedback ADC | R5/R8 voltage divider midpoint |
| 6 | RA4/CWG1A | Output | Boost MOSFET gate drive | Q2 gate via 100 ohm resistor |
| 7 | RA5/CWG1B | Output | (Complementary, unused) | Leave unconnected |
| 8 | VSS | Power | Ground | Ground rail |
| 9 | RA7/OSC1 | — | Unused (internal osc) | Leave unconnected |
| 10 | RA6/OSC2 | — | Unused (internal osc) | Leave unconnected |
| 11 | RC0 | Output | Red LED (power/error) | Red LED anode via 270 ohm to ground |
| 12 | RC1 | Output | Green LED (resonance lock) | Green LED anode via 270 ohm to ground |
| 13 | RC2/CCP1 | Output | PWM for boost control | Alternative boost drive (see firmware config) |
| 14 | RC3/NCO1 | Output | NCO frequency output | Q4 gate via 100 ohm resistor |
| 15 | RC4 | — | Unused | Leave unconnected |
| 16 | RC5 | — | Unused | Leave unconnected |
| 17 | RC6/TX | Output | UART TX (debug) | MCP2221 RX (optional) |
| 18 | RC7/RX | Input | UART RX (debug) | MCP2221 TX (optional) |
| 19 | VSS | Power | Ground | Ground rail |
| 20 | VDD | Power | +3.0-4.2V supply | LiPo + rail (directly from TP4056 BAT+) |
| 21 | RB0/INT | Input | Start/stop button | Tactile switch to GND + 10K pull-up to VDD |
| 22-26 | RB1-RB5 | — | Unused | Leave unconnected |
| 27 | RB6/ICSPCLK | Prog | Programming clock | Programmer PGC |
| 28 | RB7/ICSPDAT | Prog | Programming data | Programmer PGD |

Note on pin 14 (RC3): remains NCO1 output driving Q4.
Note on pins 15-16 (RC4, RC5): v3.1 reassigns these to the LCD/OLED
I2C bus — RC4 = SDA, RC5 = SCL. They run as open-drain (driven low
or released high) and are pulled up by the 4.7 kΩ resistors on the
PCF8574 backpack. See the LCD section below.

---

## Boost Converter Wiring

```
                                    D1 (1N5819)
  VDD (+4.5V) ──── L1 (22uH) ────┬────>|────── VBOOST Rail
                                  │
                              Q2 Drain          R5 (221K)
                              (RJP020N06)   VBOOST ──┤
                              Q2 Gate ◄── 100R ── RA4 (pin 6)     ├── AN3 (pin 5)
                              Q2 Source         R8 (15K)
                                  │                 ├── GND
                              R9 (0.33R)
                                  │             C2 (10uF) ┤├ GND
                                 GND            C9 (2.2uF) ┤├ GND
                                  │
                          (to AN0 via 4.7K + 0.1uF filter)
```

### Boost Voltage Feedback
The voltage divider R5/R8 scales VBOOST down to ADC range:
- V_adc = VBOOST x R8 / (R5 + R8) = VBOOST x 15K / 236K
- At VBOOST = 15V: V_adc = 0.95V (within 0-4.5V ADC range)

---

## Output Stage Wiring

```
                    L2 (150uH)
  VBOOST ──────────────┬──────────── Solo Contact A
                       │                    │
                   Q4 Drain             C7 (4.7nF)
                   (IRLML0100)              │
                   Q4 Gate ◄── 100R ── RC3 (pin 14)
                   Q4 Source            Solo Contact B
                       │                    │
                   R18 (1.8R)           L3 (150uH)
                       │                    │
                      GND              VBOOST
                       │
               (to AN1 via 4.7K + 0.1uF filter)
```

### Peak Voltage Detector
```
  Output Node ──── D2 (1N4148) ────┬──── R13 (360K) ────┬──── GND
                   (cathode →)     │                     │
                               C12 (1nF)            R12 (110K)
                                   │                     │
                                  GND              AN2 (pin 4)
```

---

## ICSP Programming Header

Connect your MPLAB Snap or PICkit to these 5 signals:

```
  Programmer          PIC16F1713
  ──────────          ──────────
  MCLR/VPP  ──────── Pin 1  (RE3/MCLR)
  VDD       ──────── Pin 20 (VDD)
  VSS/GND   ──────── Pin 8 or 19 (VSS)
  PGD/ICSPDAT ────── Pin 28 (RB7)
  PGC/ICSPCLK ────── Pin 27 (RB6)
```

The MPLAB Snap has a standard 8-pin header. Only these 5 pins are used. Check your programmer's pinout documentation for the exact header positions.

---

## Optional: UART Debug (MCP2221)

If you want serial debug output:

```
  PIC16F1713            MCP2221-I/P (DIP-14)
  ──────────            ────────────────────
  RC6/TX (pin 17) ───── RXD (pin 6)
  RC7/RX (pin 18) ───── TXD (pin 5)
  VDD (pin 20) ──────── VDD (pin 14)
  VSS (pin 8) ────────── VSS (pin 7)
                         USB D+ (pin 12) ── USB cable
                         USB D- (pin 11) ── USB cable
```

The MCP2221 appears as a USB serial port on your computer. Use any terminal program (PuTTY, minicom, screen) at 9600 baud 8N1 to see debug output.

---

## Power Supply (v3.1 — LiPo + TP4056)

v3.1 drops the 3x AAA / USB dual-path in favour of a rechargeable
1S LiPo pouch cell charged through a TP4056/DW01A module. USB-C on
the TP4056 module is the user-facing charging port; the old
PCB-mounted USB-C receptacle is removed.

```
  USB-C (5V in)                                       VBOOST (~12V)
       │                                                    ▲
       ▼                                                    │
  ┌─────────┐      ┌─────────┐      ┌─────────┐     ┌──────────┐
  │ TP4056  │ BAT+ │  LiPo   │ +    │  PCB    │ PWR │  MT3608  │
  │ charger │──────│ 1S 1S   │──────│ BAT IN  │─────│  boost   │
  │ + DW01A │ BAT- │ ~2000   │ -    │ (JST-2) │     │  module  │
  │ protect │──────│  mAh    │──────│         │     └──────────┘
  └─────────┘      └─────────┘      └─────────┘           │
                                           │               ▼
                                        VDD=Vbat       (output stage)
                                   (3.0-4.2V to MCU)
```

Key points:

- **MCU VDD tracks the battery voltage** (3.0 V to 4.2 V). The PIC16F1713
  is rated 1.8-5.5 V so this is well within spec.
- **Battery measurement needs no external parts.** The firmware enables
  the Fixed Voltage Reference at 2.048 V and reads it via ADC channel 31.
  Because the ADC reference is VDD, the ratio gives VDD directly:
  `Vbat_mV = 2048 * 1023 / adc_reading`. See `peripherals.c::battery_read_mv()`.
- **TP4056 protects the cell** against over-charge (4.2 V cutoff), over-
  discharge (2.5 V cutoff) and over-current / short. The firmware adds a
  second software cutoff at 3.1 V so the device warns and shuts down
  before the hardware protection trips and makes the pack look "dead".
- **Do not reverse the LiPo polarity.** The TP4056 does not have reverse
  protection on the BAT pads. Use a keyed JST-PH 2-pin connector.
- **USB and LiPo at the same time is fine** — when USB is connected,
  the TP4056 charges the cell and simultaneously powers the load.

### Optional: Bench Supply (Prototyping Only)

If you want to test the PCB without a LiPo, you can substitute a
bench supply directly on the BAT IN header:

```
  Bench (+) ──── BAT IN + (JST-2)
  Bench (-) ──── BAT IN -
  Set: 3.7 V nominal, current limit 800 mA
```

Disconnect the TP4056 module when doing this — feeding the BAT pads
while USB is live can damage the charger IC.

---

## LCD / OLED Wiring (v3.1)

A 16x2 character display (LCD or OLED, see `config.h::LCD_IS_OLED`)
mounts on the lid of the enclosure and connects to the PCB via a
4-wire ribbon:

```
  LCD Backpack (PCF8574)        PCB LCD Header (1x4)
  ────────────────────          ─────────────────────
  VCC  ────────────── VDD   (+3.3-4.2 V, same as MCU VDD)
  GND  ────────────── GND
  SDA  ────────────── RC4   (pin 15 — bit-bang I2C SDA)
  SCL  ────────────── RC5   (pin 16 — bit-bang I2C SCL)
```

- The PCF8574 backpack has 4.7 kΩ pull-ups to VCC on SDA/SCL, so no
  external pull-up resistors are needed.
- Bus speed is ~100 kHz, driven in software at 10 ms main-loop
  cadence. Refresh is ~2 Hz.
- The backpack I2C address is auto-detected between 0x27 (NXP
  PCF8574) and 0x3F (TI PCF8574A) at boot.
- Most 1602 character OLEDs (Winstar WEH001602, Newhaven NHD-0216AW,
  Matrix Orbital MOP-AO162) are pin-compatible with the same
  backpack and drop in with `LCD_IS_OLED = 1` in `config.h`.

---

## Breadboard Layout Tips

1. **Place the PIC in the center** — it has the most connections
2. **Keep boost components close together** — L1, Q2, D1, C2/C9 should be near each other to minimize parasitic inductance
3. **Keep output stage on one side** — L2, L3, Q4, C7 together, with short leads to the Solo cup connections
4. **Bypass caps as close to IC as possible** — the 0.1 uF caps on VDD should be right next to pin 20/8
5. **Star ground if possible** — route high-current ground returns (boost, output) separately from analog sense grounds
6. **Keep analog sense wires away from switching nodes** — the NCO output and boost switching are noisy; route ADC sense wires away from them
