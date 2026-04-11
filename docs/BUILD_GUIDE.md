# Breadboard Build Guide

Complete guide to building an Aerogen Solo controller on a breadboard using the Microchip AN2265 reference design.

**Read [DISCLAIMER.md](../DISCLAIMER.md) before starting.**

---

## What You're Building

A controller that drives the piezoelectric ring inside an Aerogen Solo nebulizer cup. The circuit has three main stages:

1. **Boost converter** — steps up 4.5V battery/USB power to ~10-20V DC
2. **Output stage** — converts the DC into a high-voltage AC waveform via an LC resonant circuit
3. **Frequency sweep** — the MCU scans 90-150 kHz to find the PZT's resonant frequency, then locks on

The two exposed contacts on the Aerogen Solo cup are simply the two leads of the PZT ring actuator.

---

## Tools Required

- Solderless breadboard (830 tie-point, full-size)
- Jumper wire kit (M-M for breadboard)
- Multimeter
- Oscilloscope or frequency counter (strongly recommended)
- Current-limited bench power supply (strongly recommended for first power-up)
- MPLAB Snap or PICkit 4/5 programmer
- Computer with MPLAB X IDE and XC8 compiler installed

---

## SMD-to-Breadboard Adaptation

The AN2265 design uses surface mount components. For breadboard prototyping:

| Original SMD Part | Breadboard Substitute | Notes |
|---|---|---|
| PIC16F1713-I/SO (SOIC-28) | **PIC16F1713-I/SP (DIP-28)** | Must order the -I/SP variant |
| MCP2221-I/SL (SOIC-14) | **MCP2221-I/P (DIP-14)** | Optional, for debug UART |
| SS14 (SMA Schottky) | **1N5819** (DO-41) | Same 1A/40V Schottky specs |
| 1N4148 (SOD-123) | **1N4148** (DO-35) | Same part, through-hole |
| IRLML0100 (SOT-23) | Use SOT-23 breakout board | SparkFun BOB-13655 or similar, ~$1 |
| IRLML6402 (SOT-23) | Use SOT-23 breakout board | Same breakout works |
| RJP020N06 (SOT-89) | Solder leads or use breakout | SOT-89 breakout boards exist |
| 0603 resistors | 1/4W axial through-hole | Same values |
| 0603/0805/1206 caps | Radial ceramic or film caps | Match value and voltage rating |
| SRN6045 inductors | Radial shielded inductors | Match inductance and current rating |

---

## Assembly — Stage by Stage

### Stage 1: Power and MCU

Wire these first and verify the MCU is alive before adding the high-voltage stages.

1. Place the **PIC16F1713-I/SP** in the center of the breadboard straddling the channel
2. Connect **VDD** (pin 20) to +4.5V rail
3. Connect both **VSS** pins (pin 8, pin 19) to ground rail
4. Connect a **0.1 uF** bypass cap between VDD and VSS, as close to the chip as possible
5. Connect **MCLR** (pin 1) to VDD through a **10K** pull-up resistor
6. Wire the **ICSP header** for programming:
   - Pin 1 (MCLR/VPP) → Programmer MCLR
   - Pin 27 (RB6/ICSPCLK) → Programmer PGC
   - Pin 28 (RB7/ICSPDAT) → Programmer PGD
   - VDD → Programmer VDD
   - VSS → Programmer VSS
7. Connect a **tactile switch** between **RB0** (pin 21) and ground, with a **10K pull-up** to VDD
8. Connect **red LED** through a **270 ohm** resistor to **RC0** (pin 11)
9. Connect **green LED** through a **270 ohm** resistor to **RC1** (pin 12)

**Test:** Program the MCU. If it programs successfully, the MCU and power are good.

### Stage 2: Boost Converter

The boost converter steps up the 4.5V supply to ~10-20V for the output stage.

1. Wire **L1 (22 uH)** from VDD to the drain of **Q2 (RJP020N06)**
2. Connect the source of Q2 to ground through **R9 (0.33 ohm)** current sense resistor
3. Connect the **gate of Q2** to **CWG1A output** (pin 6, RA4) through a **100 ohm** gate resistor
4. Connect the junction of L1 and Q2 drain to the anode of **D1 (1N5819)**
5. Connect the cathode of D1 to the VBOOST rail
6. Place **C2 (10 uF, 25V)** between VBOOST and ground
7. Place **C9 (2.2 uF, 100V)** between VBOOST and ground
8. Wire the voltage feedback divider:
   - **R5 (221K)** from VBOOST to the divider midpoint
   - **R8 (15K)** from the divider midpoint to ground
   - Connect the midpoint to **AN3** (pin 5, RA3) for ADC reading
9. Wire the current sense:
   - Connect the junction of Q2 source and R9 to **AN0** (pin 2, RA0) through a **4.7K** resistor
   - Place a **0.1 uF** filter cap from AN0 to ground

**Test:** Power up with bench supply at 4.5V, 200mA current limit. Measure VBOOST — it should ramp to the target voltage set by DAC1 in firmware (start with ~10V).

### Stage 3: Output Stage

This stage generates the high-frequency AC waveform that drives the piezo.

1. Connect **L2 (150 uH)** from VBOOST to the drain of **Q4 (IRLML0100)**
2. Connect the source of Q4 to ground through **R18 (1.8 ohm)** current sense
3. Connect the **gate of Q4** to the **NCO output** (pin 14, RC3) through a **100 ohm** gate resistor
4. Connect **L3 (150 uH)** from VBOOST to one side of **C7 (4.7 nF, 200V)**
5. Connect the other side of C7 to the junction of L2 and Q4 drain
6. Place **C5 (0.1 uF, 100V)** DC blocking cap in series with the output
7. The output connects to the Aerogen Solo contacts through C5

### Stage 4: Feedback Sensing

The firmware needs to measure the output to find resonance.

1. Wire the peak voltage detector:
   - **D2 (1N4148)** from the output node (cathode toward detector)
   - **C12 (1 nF)** from the detector node to ground
   - Voltage divider: **R13 (360K)** from detector to midpoint, **R12 (110K)** from midpoint to ground
   - Connect midpoint to **AN2** (pin 4, RA2) for ADC reading
2. Wire the output current sense:
   - Connect junction of Q4 source and R18 to **AN1** (pin 3, RA1) through a **4.7K** resistor
   - Place a **0.1 uF** filter cap from AN1 to ground

---

## Connecting to the Aerogen Solo

The Solo cup has two spring-loaded contacts. Options for prototyping:

- **Pogo pin test probes** — spring-loaded test pins that press against the contacts
- **Small alligator clips** — if the contacts are accessible
- **Thin wire + tape** — temporary but functional for bench testing

**Polarity:** The PZT is an AC device. The two contacts have no specific polarity requirement.

---

## First Power-Up Procedure

1. **DO NOT connect the Aerogen Solo cup yet**
2. Set bench supply to 4.5V, current limit to 200mA
3. Power the circuit
4. Verify with multimeter:
   - VBOOST should ramp up to ~10-12V (initially — start conservative)
   - Current draw should be under 150mA with no load
5. Verify with oscilloscope on the NCO output pin (RC3):
   - Should see a square wave sweeping from 90-150 kHz
6. If all looks good, increase current limit to 500mA
7. Fill an Aerogen Solo cup with **normal saline** (not medication)
8. Connect the Solo cup to the output
9. Press the start button
10. You should see fine mist within seconds as the sweep finds resonance
11. The green LED should illuminate when resonance is locked

### If No Mist

- Check all wiring connections
- Verify VBOOST is reaching target voltage
- Try increasing the DAC1 value in `config.h` for higher drive voltage (carefully, in small steps)
- Verify the NCO output is present on RC3
- Check the output waveform across the Solo contacts with an oscilloscope
- Ensure the Solo cup has liquid in it and the mesh is not clogged

---

## Adjusting Parameters

All tunable parameters are in `firmware/src/config.h`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SWEEP_FREQ_MIN_HZ` | 90000 | Lower bound of frequency sweep (Hz) |
| `SWEEP_FREQ_MAX_HZ` | 150000 | Upper bound of frequency sweep (Hz) |
| `SWEEP_STEP_HZ` | 500 | Frequency step size during sweep (Hz) |
| `BOOST_TARGET_DAC` | 16 | DAC value controlling boost voltage (0-31). **Start low.** |
| `TREATMENT_TIME_SEC` | 600 | Treatment duration in seconds (default 10 min) |
| `RESONANCE_THRESHOLD` | 100 | Minimum ADC reading to consider as resonance |

---

## Alternative: Quick Bench Test

If you have a function generator and want to verify the Solo cup works before building the full circuit:

1. Set function generator to sine wave output
2. Set frequency to ~100-130 kHz, amplitude to ~30-50 Vpp
3. Connect directly to the Solo's two contacts
4. Sweep frequency slowly while watching for mist
5. The frequency where mist peaks is your resonant frequency

This confirms the cup works and gives you the target frequency.

---

## Power Supply Options

| Option | Voltage | Notes |
|--------|---------|-------|
| 3x AAA batteries | 4.5V nominal | The design is built for this |
| USB 5V | 5.0V | Via USB cable or breakout board |
| Bench power supply | 4.5V | **Recommended for prototyping** — set current limit to 500mA |

---

## Safety Reminders

- **Start with normal saline** — never medication until operation is stable and repeatable
- **Current-limit your power supply** during development
- **Don't overdrive the PZT** — start with lower DAC1 values and increase gradually
- **Monitor temperature** — if the Solo cup gets warm, you're overdriving it
- **The Solo cup has a 28-day intermittent life** — this doesn't change with a DIY controller
- **Keep away from ventilator circuit** during testing — only integrate once reliable
