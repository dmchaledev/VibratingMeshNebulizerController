# Firmware — Build and Flash Instructions

## Prerequisites

### Software (all free)

1. **MPLAB X IDE** — download from https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide
2. **XC8 Compiler** — download from https://www.microchip.com/en-us/tools-resources/develop/mplab-xc-compilers
   - Install in Free mode (no license needed)
   - The free mode generates slightly less optimized code but works perfectly fine

### Hardware

- **MPLAB Snap** (~$35, DigiKey PG164100-ND) or **PICkit 4** (~$60) or **PICkit 5** (~$90)
- 5-wire connection from programmer to PIC16F1713 ICSP pins (see [hardware/WIRING.md](../hardware/WIRING.md))

## Quick Start (Command Line)

If you prefer the command line over the IDE:

```bash
# Navigate to the firmware source directory
cd firmware/src

# Compile (adjust the XC8 path if needed)
xc8-cc -mcpu=16F1713 -O1 -o nebulizer.hex main.c peripherals.c sweep.c

# Program the chip (with MPLAB Snap connected via USB)
# Use MPLAB IPE (Integrated Programming Environment) or:
mdb.sh -e "device PIC16F1713; hwtool snap; program nebulizer.hex; quit"
```

## Using MPLAB X IDE

### Create a New Project

1. Open MPLAB X IDE
2. File > New Project
3. Select: Microchip Embedded > Standalone Project
4. Device: **PIC16F1713**
5. Tool: select your connected programmer (Snap, PICkit 4, etc.)
6. Compiler: **XC8 (latest version)**
7. Project name: `NebulizerController`
8. Finish

### Add Source Files

1. In the project tree, right-click "Source Files" > Add Existing Item
2. Add all `.c` files from this `src/` directory:
   - `main.c`
   - `peripherals.c`
   - `sweep.c`
3. Right-click "Header Files" > Add Existing Item
4. Add all `.h` files:
   - `config.h`
   - `peripherals.h`
   - `sweep.h`

### Compile

1. Click the **Build** button (hammer icon) or press F11
2. The output window should show `BUILD SUCCESSFUL`
3. If you get errors, verify:
   - XC8 compiler is selected (Project Properties > Compiler)
   - Device is set to PIC16F1713

### Program the Chip

1. Connect the programmer to the PIC16F1713 via the ICSP header
2. Connect the programmer to your computer via USB
3. Click **Make and Program Device** (green arrow with chip icon)
4. The output window should show programming succeeded

### Verify

After programming:
- The red LED should blink once at power-up (indicating the MCU is running)
- Press the button — the controller should begin sweeping (green LED will blink during sweep, then go solid when locked on resonance)

## Alternative: Download Microchip's Original AN2265 Source

If you'd rather use the original reference code:

1. Visit https://www.microchip.com/en-us/solutions/medical/demonstrations-and-design-files/vibrating-mesh-nebulizer
2. Download the source code ZIP
3. Open the included MPLAB X project directly
4. This is the exact code from the application note — it will compile for the SOIC package but works identically on the DIP version

## Source File Overview

| File | Purpose |
|------|---------|
| `config.h` | All tunable parameters — frequencies, voltages, timing. **Edit this first.** |
| `peripherals.h/c` | PIC16F1713 hardware initialization (oscillator, NCO, DAC, ADC, CWG, GPIO, UART) |
| `sweep.h/c` | Frequency sweep algorithm — scans for PZT resonance |
| `main.c` | State machine: idle → sweep → run → stop. Button handling, treatment timer, LED control |

## Adjusting Parameters

All user-adjustable parameters are in `config.h`. The most important ones:

| Parameter | What It Does | Default |
|-----------|-------------|---------|
| `SWEEP_FREQ_MIN_HZ` | Lower frequency bound | 90,000 Hz |
| `SWEEP_FREQ_MAX_HZ` | Upper frequency bound | 150,000 Hz |
| `SWEEP_STEP_HZ` | Frequency resolution | 500 Hz |
| `BOOST_TARGET_DAC` | Drive voltage level (**start low!**) | 16 |
| `TREATMENT_TIME_SEC` | Auto-shutoff timer | 600 (10 min) |

After changing `config.h`, rebuild and reprogram the chip.
