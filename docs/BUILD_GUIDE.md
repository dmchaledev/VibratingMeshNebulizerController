# Breadboard Build Guide

Complete guide to building an Aerogen Solo controller on a breadboard using the Microchip AN2265 reference design.

**Read [DISCLAIMER.md](../DISCLAIMER.md) before starting.**

---

## Choose Your Build

There are two ways to build this controller:

| | Full Build | Simplified Build |
|---|---|---|
| **Parts cost** | ~$38 | ~$20 |
| **Component count** | ~40 parts | ~25 parts |
| **Hardest part** | Discrete boost converter wiring | Adjusting boost module trim pot |
| **Boost converter** | Discrete (L1, Q2, D1, feedback) | Pre-built module (MT3608/XL6009) |
| **BOM file** | [BOM.csv](BOM.csv) | [BOM_SIMPLIFIED.csv](BOM_SIMPLIFIED.csv) |
| **Firmware config** | `BOOST_MODE = BOOST_MODE_DISCRETE` | `BOOST_MODE = BOOST_MODE_MODULE` |

**Recommendation:** If this is your first build, start with the **Simplified Build**. The discrete boost converter is the most complex and error-prone part of the circuit. The pre-built module costs $1-2 and eliminates 8+ components and the hardest wiring. You can always build the discrete version later.

The **Simplified Build** section is at the end of this guide. The main guide below covers the full discrete build.

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
| `BOOST_MODE` | `BOOST_MODE_DISCRETE` | `DISCRETE` for on-board boost, `MODULE` for pre-built module |
| `TREATMENT_MODE` | `TREATMENT_MODE_CONTINUOUS` | `CONTINUOUS` runs until button/dry-cup, `TIMED` auto-stops |
| `TREATMENT_TIME_SEC` | 1800 | Treatment duration in TIMED mode (default 30 min) |
| `RESONANCE_THRESHOLD` | 100 | Minimum ADC reading to consider as resonance |
| `DRY_CUP_THRESHOLD` | 30 | ADC reading below which cup is considered empty |
| `FREQ_CACHE_ENABLED` | 1 | Save last frequency to flash for faster next startup |

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

---

## Simplified Build (Pre-Built Boost Module)

This section describes an easier, cheaper build that replaces the discrete boost converter with a pre-built adjustable boost module. **This eliminates the most complex part of the circuit.**

### What Changes

The discrete boost converter (Stage 2 in the full build above) is replaced entirely:

| Eliminated Components | Replaced By |
|---|---|
| L1 (22 uH inductor) | One pre-built boost module |
| Q2 (RJP020N06 MOSFET + breakout) | (MT3608, XL6009, or similar) |
| D1 (1N5819 Schottky) | |
| R9 (0.33 ohm current sense) | Module cost: ~$1-2 |
| R5 (221K feedback divider) | |
| R8 (15K feedback divider) | |
| C2 (10 uF filter cap) | |
| C9 (2.2 uF filter cap) | |

You also replace the P-MOSFET reverse polarity protection (Q1, Q3) with a single series diode (simpler).

**Parts list:** See [BOM_SIMPLIFIED.csv](BOM_SIMPLIFIED.csv)

### Choosing a Boost Module

Any adjustable DC-DC boost converter module that accepts 4.5-5V input and outputs 10-20V will work:

- **MT3608** module — smallest, cheapest (~$0.50-1), widely available
- **XL6009** module — higher current capability, slightly larger
- **SDB628** module — similar to MT3608

These are all available from Amazon, eBay, AliExpress, etc. They come with a small trim potentiometer to set the output voltage.

### Setting the Boost Module Output Voltage

**Before connecting to the circuit:**

1. Connect the boost module's input to your 4.5-5V power supply
2. Connect a multimeter to the module's output
3. Turn the trim pot (small Phillips screwdriver) until the output reads **~12V**
4. Disconnect power

This replaces the DAC-controlled voltage ramp in the discrete design. The module maintains a steady output voltage on its own.

### Simplified Wiring

Follow Stage 1 (Power and MCU) from the full build guide above — it's identical.

**Skip Stage 2 entirely.** Instead:

1. Connect the boost module's **VIN+** to your 4.5-5V power rail (through the fuse)
2. Connect the boost module's **VIN-** to ground
3. Connect a **1N5819 diode** in series with VIN+ for reverse polarity protection (anode toward power supply, cathode toward module input)
4. Connect the boost module's **VOUT+** to the VBOOST rail on your breadboard
5. Connect the boost module's **VOUT-** to ground

Then continue with **Stage 3 (Output Stage)** and **Stage 4 (Feedback Sensing)** exactly as described above.

**Important:** Since the boost module is not controlled by the MCU, you do not need to wire:
- CWG1A output (pin 6, RA4) — leave unconnected
- AN0 (pin 2, RA0) boost current sense — leave unconnected
- AN3 (pin 5, RA3) boost voltage feedback — leave unconnected

### Firmware Configuration

Before compiling, change one line in `firmware/src/config.h`:

```c
#define BOOST_MODE              BOOST_MODE_MODULE
```

This tells the firmware to skip the DAC voltage ramp and CWG initialization, since the boost module handles it independently.

### Simplified Build Cost Estimate

| Category | Cost |
|----------|------|
| PIC16F1713 + passives + output stage | ~$18 |
| Boost module (MT3608) | ~$2 |
| **Parts total** | **~$20** |
| Programmer (MPLAB Snap, one-time) | ~$35 |
| **Total with programmer** | **~$55** |

### Tradeoffs vs. Full Build

| | Full Build | Simplified Build |
|---|---|---|
| **Soft-start voltage ramp** | Yes (DAC-controlled) | No (module output is instant) |
| **Software voltage control** | Yes (can adjust VBOOST via firmware) | No (set once with trim pot) |
| **Component count** | ~40 | ~25 |
| **Wiring complexity** | Higher (boost circuit is fiddly) | Lower (module is self-contained) |
| **Cost** | ~$38 parts | ~$20 parts |
| **Board space** | Larger | Smaller (module is compact) |

The soft-start ramp in the full build gently increases the boost voltage to avoid inrush current. With the module build, the boost output comes up to ~12V immediately when powered. This is fine for most use cases — the output LC circuit provides some inherent current limiting, and the PZT isn't driven until the sweep starts.
