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

## Wire Color Guide

Use consistent wire colors to make the circuit easier to debug and maintain. This is especially important when the circuit will be handled daily in a nursery environment.

| Color | Signal | Notes |
|-------|--------|-------|
| **Red** | VDD (+4.5-5V) | Power supply positive rail |
| **Black** | GND | Ground rail |
| **Orange** | VBOOST (10-20V) | High-voltage DC rail — treat with respect |
| **Yellow** | NCO output (RC3 → Q4 gate) | High-frequency signal, keep short |
| **Green** | ADC sense lines (AN0-AN3) | Keep away from switching nodes |
| **Blue** | CWG output (RA4 → Q2 gate) | Boost MOSFET drive (discrete build only) |
| **White** | Output to Solo cup | The two leads to the nebulizer |
| **Purple/Gray** | UART TX/RX | Debug serial (optional) |

**Wire length matters.** Keep all wires in the output stage and boost stage as short as possible. Long wires at 100+ kHz act as antennas and create noise that can confuse the ADC readings. The wire from RC3 to Q4's gate should be under 3 cm.

---

## Common Mistakes

Things that have caused people trouble, roughly in order of frequency:

### 1. Wrong PIC package
The PIC16F1713 comes in SOIC-28 (-I/SO) and DIP-28 (-I/SP). You **must** order the **-I/SP** (DIP) variant for breadboard use. The SOIC version won't fit.

### 2. VBOOST too high on first power-up
Starting with `BOOST_TARGET_DAC = 16` (~12V) is fine, but if you've modified it higher, you can damage the PZT. **Always start low and work up.** If the Solo cup gets warm to the touch, you're overdriving it.

### 3. Missing bypass capacitors
The 0.1 uF cap between VDD (pin 20) and VSS (pin 8/19) is not optional. Without it, the MCU's ADC readings will be noisy and the NCO output may glitch. Place it as physically close to the chip pins as possible.

### 4. Reversed Schottky diode (D1)
The 1N5819 band marks the cathode. Cathode goes toward VBOOST. If it's backwards, the boost converter won't produce voltage and current will flow uncontrolled.

### 5. Wrong capacitor for C7
C7 (4.7 nF, 200V) is the LC resonant capacitor. This value is critical. A 4.7 uF cap (1000x too large) looks similar in parts bins. Verify the marking: **472** = 4.7 nF, **475** = 4.7 uF. Also, C7 must be rated for at least 200V.

### 6. Long leads on output stage
The L2-L3-C7-Q4 output network operates at 100+ kHz. Long breadboard jumper wires add parasitic inductance that shifts the resonant frequency. Keep leads short and the output stage compact.

### 7. Grounding issues
The boost stage switches large currents at high frequency. If the ground return for the boost MOSFET (Q2) shares a path with the ADC sense ground, you'll get noisy readings and the sweep may fail to find resonance. Run separate ground wires for the power stages and the analog sense lines back to the ground rail.

### 8. Breadboard contact degradation
After many insertions, breadboard contacts loosen. If the circuit worked yesterday and doesn't today, try reseating components and jumper wires. This is the #1 reason to graduate to a soldered build (see below).

---

## Test Points and Debugging

If things aren't working, check these signals with a multimeter or oscilloscope:

| Test Point | Expected Value | What It Means If Wrong |
|-----------|---------------|----------------------|
| VDD (pin 20) | 4.5-5.0V DC | Power supply issue |
| VBOOST rail | 10-20V DC (per DAC setting) | Boost converter not working |
| RC3 (pin 14, NCO) | Square wave 90-150 kHz during sweep | NCO not configured or pin not connected |
| RA4 (pin 6, CWG) | Square wave matching NCO | CWG not configured (discrete build) |
| AN1 (pin 3) after 4.7K | 0.1-0.9V during resonance | Current sense circuit issue |
| Red LED (RC0) | Solid red in IDLE | MCU not running |
| Green LED (RC1) | Solid green in RUNNING | Sweep failed to find resonance |

**UART debug output** is the most useful diagnostic. Connect a MCP2221 USB-UART bridge and open a terminal at 9600 baud. The firmware prints state transitions, sweep results, and resonance values. You'll see exactly where it's failing.

---

## Enclosure and Physical Protection

A bare breadboard will not survive daily use in a nursery. Here are practical enclosure options, from simplest to most robust.

### Option 1: Breadboard Case (Simplest)

Several companies make snap-on cases designed for standard 830-point breadboards:

- **Breadboard + mounting plate combo** — many breadboards come with a metal or plastic baseplate with screw holes. Mount this inside any project box.
- **Hammond 1591XXDSBK** (150 x 80 x 50 mm) — a general-purpose ABS project box. The breadboard (165 x 55 mm) fits diagonally, or trim the breadboard rails to fit. Drill holes for the button, LEDs, power input, and cup output wires.
- **Clear food storage container** — seriously. A small Rubbermaid or similar ~200 x 100 x 60 mm container with a snap lid works. Drill holes for wires, button, and LED visibility. The clear lid lets you see the LED status without opening it. Cost: ~$3.

For any enclosure:
1. **Drill holes** for: power input wires, Solo cup output wires, button access, LED visibility, and optional USB debug cable
2. **Mount the breadboard** with double-sided foam tape (3M VHB is excellent)
3. **Use cable glands** (PG7 or M12, ~$0.50 each) where wires exit the box to prevent strain on breadboard connections
4. **Label everything** — masking tape labels on the outside: POWER, OUTPUT, START/STOP

### Option 2: Perfboard Build (Recommended for Daily Use)

Once the breadboard prototype works reliably, solder the circuit onto a perfboard (also called protoboard or stripboard) for a permanent build:

- **What:** Same circuit, same components, but soldered instead of press-fit
- **Cost:** A perfboard is ~$2-3. No new components needed.
- **Why:** Soldered connections don't loosen. Perfboard can be cut to fit an enclosure exactly. This is the single best upgrade for reliability in daily use.
- **How:** Transfer components one section at a time (MCU first, then output stage, etc.), verifying each stage works before moving on. Use an IC socket for the PIC so you can remove it for reprogramming.

A perfboard build in a project box is robust enough for years of daily nursery use.

### Option 3: Custom PCB (Best Quality)

For the best possible build quality, order a custom PCB:

- **JLCPCB, PCBWay, or OSH Park** can manufacture 5 PCBs for ~$5-15 (shipped)
- You'd need to create a PCB layout (KiCad is free). The schematic is fully documented in this repository and the AN2265 reference design includes layout files.
- Surface-mount components can be used (smaller, cleaner) since they're soldered
- A custom PCB eliminates all wiring errors — just solder components to the marked pads

This is the path to making these for other families. If there's interest, a community-designed PCB could be shared openly.

---

## Nursery Environment: Making It Last

This device will live in a nursery with a child who needs 6+ nebulizer treatments per day. That's 2,000+ power cycles per year, with exposure to saline mist, medication, and the general chaos of a nursery. Here's how to make it survive.

### Moisture Protection

Saline and medication mist will drift. Over time, salt deposits corrode exposed copper.

- **Conformal coating spray** (MG Chemicals 422B or similar, ~$12/can) — spray a thin coat over the soldered perfboard (NOT the breadboard — it'll glue the contacts). This seals the copper traces against moisture and salt. Mask the button, LEDs, and any connectors before spraying.
- **Keep the controller away from the mist output.** The cup generates a fine aerosol that drifts. Position the controller at least 30 cm (12") from the cup, or better, below it where mist doesn't settle.
- **Wipe down weekly** with a dry cloth. If salt deposits accumulate on the enclosure, dampen the cloth slightly. Never let liquid into the enclosure.

### Strain Relief

The wires to the Solo cup will be connected and disconnected with every cup change (at least every 28 days). Without strain relief, this repeated flexing will break wires at the solder joint.

- **Cable glands** at the enclosure exit points (PG7 size fits most wire pairs)
- **Hot glue** a small blob where wires connect to the perfboard/breadboard
- **Leave a service loop** — 10-15 cm of slack inside the enclosure so tugging the external wire doesn't stress the internal connection
- **Use stranded wire** (not solid core) for anything that will be flexed. Solid core is fine on the board; stranded for any external runs

### Cup Connection

The Solo cup contacts need reliable, repeatable electrical connection:

- **Spring-loaded pogo pins** (P75-B1 or similar, 1mm tip) — the best option for repeated connect/disconnect. Mount two in a small holder at the correct spacing for the Solo cup contacts. These last thousands of cycles.
- **JST-XH connectors** — solder a JST plug to the pogo pin leads, and a JST socket to the controller output. This gives you a clean disconnect point that doesn't stress the board.
- **Avoid alligator clips for daily use** — they work for bench testing but they slip, scratch the contacts, and wear out.

### Physical Durability

- **Velcro strips** on the bottom of the enclosure and on the nursery surface (crib rail, IV pole, shelf) to prevent it from being knocked off
- **Foam padding** inside the enclosure around the board to dampen vibration
- **Short external cable** — keep the cable from controller to cup under 50 cm. Longer cables pick up more noise and are easier to snag
- **No exposed metal** — make sure all wire ends are insulated or inside the enclosure

### Spares to Keep on Hand

| Item | Why | Cost |
|------|-----|------|
| Aerogen Solo cups (2-3 extra) | 28-day life, you never want to run out | ~$40 each |
| Pre-programmed spare PIC16F1713 | In case the MCU dies (rare) | ~$3 |
| Spare boost module (if simplified build) | They're cheap, keep one ready | ~$2 |
| Spare fuse | If the fuse blows, you need to be up and running fast | ~$0.50 |
| Jumper wires / hookup wire | For repairs | ~$5 kit |

### When to Rebuild

Signs the controller needs attention:

- **Intermittent mist** (starts and stops) — loose connection, reseat or re-solder
- **Takes multiple button presses to start** — button or debounce issue, replace button
- **Red LED blinks on startup but no sweep** — MCU issue, reprogram or replace
- **Weaker mist than usual** — check VBOOST with multimeter. If low, check boost module or feedback divider.
- **No mist, green LED never lights** — sweep isn't finding resonance. Connect UART debug to see what the sweep is reporting.

---

## Visual Guides

See **[DIAGRAMS.md](DIAGRAMS.md)** for mermaid diagrams of:
- Controller state machine
- Circuit block diagram and signal flow
- Frequency sweep algorithm (with caching fast path)
- Treatment session flow with dry-cup and re-sweep logic
- Resonance detection concept
- Power path comparison (discrete vs. module build)

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
