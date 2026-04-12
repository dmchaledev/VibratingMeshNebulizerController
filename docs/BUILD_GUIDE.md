# Build Guide — Turnkey (JLCPCB Pre-Assembled)

Complete guide to assembling the Aerogen Solo controller from a JLCPCB pre-assembled PCB.

**Read [DISCLAIMER.md](../DISCLAIMER.md) before starting.**

---

## What You're Building

A controller that drives the piezoelectric ring inside an Aerogen Solo nebulizer cup. The circuit has two main stages:

1. **Boost converter** — a pre-built module (MT3608/XL6009) steps up 5V USB power to ~12V DC
2. **Output stage** — converts the DC into a high-voltage AC waveform via an LC resonant circuit, driven by the MCU's frequency sweep

The two exposed connector pins on the Aerogen Solo cup are simply the two leads of the PZT ring actuator. The controller scans 90-150 kHz to find the resonant frequency, then locks on.

---

## What You Need

### From JLCPCB

Order the pre-assembled PCB following [JLCPCB_ORDERING_GUIDE.md](JLCPCB_ORDERING_GUIDE.md). JLCPCB solders all surface-mount components. You receive a completed board ready for firmware programming.

### User-Supplied Parts

See [BOM_TURNKEY.csv](BOM_TURNKEY.csv) for the complete list. The key items you supply:

| Item | Source | Cost |
|------|--------|------|
| MT3608 or XL6009 boost module | Amazon/AliExpress | ~$1-2 |
| USB-C cable (power) | Any | ~$0 (you have one) |
| JST-XH 2-pin cable | Amazon/DigiKey | ~$1 |
| P75-B1 pogo pins (2) | Amazon/AliExpress | ~$3/50-pack |
| M2.5x6mm screws (4) | Amazon/hardware store | ~$1 |
| MPLAB Snap programmer | DigiKey PG164100-ND | ~$35 (one-time) |

### 3D-Printed Parts

Print from the OpenSCAD files in this repo (or order from JLCPCB 3D printing):

| Part | File | Material |
|------|------|----------|
| Connector plug | `hardware/adapters/aerogen_connector_plug.scad` | PETG or SLA resin |
| Enclosure base | `hardware/enclosure/controller_enclosure.scad` | PETG |
| Enclosure lid | `hardware/enclosure/controller_enclosure.scad` | PETG |

Print settings: 0.2mm layer height, 30-50% infill, supports enabled.

### Tools

- MPLAB Snap or PICkit 4/5 programmer
- Computer with MPLAB X IDE and XC8 compiler (both free from Microchip)
- Multimeter
- Soldering iron (only for 2 pogo pin wire joints in the connector plug)
- Small Phillips screwdriver (for boost module trim pot)

---

## Assembly

### Step 1: Flash Firmware

1. Install MPLAB X IDE and XC8 compiler (free from Microchip)
2. Open the firmware project from `firmware/`
3. The default `config.h` is already set for the turnkey build (`BOOST_MODE = BOOST_MODE_MODULE`)
4. Connect the MPLAB Snap to the board's ICSP header (5-pin)
5. Click "Make and Program Device" in MPLAB X
6. Programming takes ~10 seconds

### Step 2: Set Boost Module Voltage

1. Connect the MT3608/XL6009 module's input to a 5V source (USB charger works)
2. Measure the output with a multimeter
3. Turn the trim pot until output reads **~12V**
4. Disconnect

### Step 3: Assemble Connector Plug

See [hardware/adapters/README.md](../hardware/adapters/README.md) for detailed instructions.

1. Print the connector plug from `aerogen_connector_plug.scad`
2. Insert P75-B1 pogo pins into the two channels
3. Solder short stranded wires to each pogo pin solder cup
4. Route wires through the cable channel
5. Crimp or solder wires to a JST-XH 2-pin plug
6. Test-fit with an Aerogen Solo cup — pins should compress when cup seats

### Step 4: Final Assembly

1. **Mount PCB** in enclosure base using M2.5 screws
2. **Connect boost module** to the JST header labeled "BOOST IN" on the PCB
3. **Connect connector plug** JST cable to the output header
4. **Insert batteries** (3x AAA) into the battery compartment, or connect USB-C power
5. **Snap on enclosure lid**

### Step 5: First Power-Up

1. **Do NOT connect a nebulizer cup yet**
2. Power the circuit (USB-C or batteries)
3. Red LED should illuminate (IDLE state)
4. Measure VBOOST on the boost module output — should read ~12V
5. Press the start button — red LED should blink (searching for cup)
6. After ~3 seconds with no cup, it should error (blinking red) — this is correct
7. Fill an Aerogen Solo cup with **normal saline** (not medication)
8. Seat the cup in the connector plug
9. Press start — green LED should light when resonance is found
10. Fine mist should appear within seconds

---

## If No Mist

- Check that the boost module output reads ~12V
- Verify the pogo pins make contact (multimeter continuity from JST plug to cup pads)
- Try increasing `BOOST_TARGET_DAC` in `config.h` for higher drive voltage (carefully, in small steps)
- Ensure the Solo cup has liquid and the mesh is not clogged
- Connect UART debug for detailed diagnostics (see below)

---

## Adjusting Parameters

All tunable parameters are in `firmware/src/config.h`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SWEEP_FREQ_MIN_HZ` | 90000 | Lower bound of frequency sweep (Hz) |
| `SWEEP_FREQ_MAX_HZ` | 150000 | Upper bound of frequency sweep (Hz) |
| `SWEEP_STEP_HZ` | 500 | Frequency step size during sweep (Hz) |
| `BOOST_TARGET_DAC` | 16 | DAC value controlling boost voltage (0-31). **Start low.** |
| `TREATMENT_MODE` | `TREATMENT_MODE_CONTINUOUS` | `CONTINUOUS` runs until button/dry-cup, `TIMED` auto-stops |
| `TREATMENT_TIME_SEC` | 1800 | Treatment duration in TIMED mode (default 30 min) |
| `RESONANCE_THRESHOLD` | 100 | Minimum ADC reading to consider as resonance |
| `DRY_CUP_THRESHOLD` | 30 | ADC reading below which cup is considered empty |
| `FREQ_CACHE_ENABLED` | 1 | Save last frequency to flash for faster next startup |

---

## Power Supply Options

| Option | Voltage | Notes |
|--------|---------|-------|
| **3x AAA batteries** | 4.5V nominal | Fits in enclosure battery compartment. Best for portable use. |
| **USB 5V** | 5.0V | Via USB-C connector on enclosure. Best for bedside use. |

Both options work simultaneously — USB power takes priority when connected.

---

## Test Points and Debugging

If things aren't working, check these signals with a multimeter:

| Test Point | Expected Value | What It Means If Wrong |
|-----------|---------------|----------------------|
| VDD (pin 20) | 4.5-5.0V DC | Power supply issue |
| VBOOST (module output) | ~12V DC | Boost module not set correctly |
| Red LED (RC0) | Solid red in IDLE | MCU not running |
| Green LED (RC1) | Solid green in RUNNING | Sweep failed to find resonance |

**UART debug output** is the most useful diagnostic. Connect a MCP2221 USB-UART bridge to the ICSP/debug header and open a terminal at 9600 baud. The firmware prints state transitions, sweep results, and resonance values.

---

## Safety Reminders

- **Start with normal saline** — never medication until operation is stable and repeatable
- **Don't overdrive the PZT** — start with lower DAC1 values and increase gradually
- **Monitor temperature** — if the Solo cup gets warm, you're overdriving it
- **The Solo cup has a 28-day intermittent life** — this doesn't change with a DIY controller
- **Keep away from ventilator circuit** during testing — only integrate once reliable

---

## Nursery Environment: Making It Last

This device will live in a nursery with a child who needs 6+ nebulizer treatments per day. That's 2,000+ power cycles per year, with exposure to saline mist, medication, and the general chaos of a nursery. Here's how to make it survive.

### Moisture Protection

Saline and medication mist will drift. Over time, salt deposits corrode exposed copper.

- **Conformal coating spray** (MG Chemicals 422B or similar, ~$12/can) — spray a thin coat over the assembled PCB. Mask the button, LEDs, and connectors before spraying.
- **Keep the controller away from the mist output.** Position the controller at least 30 cm (12") from the cup, or below it where mist doesn't settle. The flexible cable between the connector plug and enclosure makes this easy.
- **Wipe down weekly** with a dry cloth. If salt deposits accumulate on the enclosure, dampen the cloth slightly.

### Strain Relief

The cable between the connector plug and controller will flex with every cup change. The JST connectors and cable glands in the enclosure design handle this, but:

- **Use stranded wire** (not solid core) for the connector cable
- **Leave a service loop** inside the enclosure
- **Keep cable length under 50 cm** — longer cables pick up noise at 100+ kHz

### Spares to Keep on Hand

| Item | Why | Cost |
|------|-----|------|
| Aerogen Solo cups (2-3 extra) | 28-day life, you never want to run out | ~$40 each |
| Pre-programmed spare PCB | You ordered 5 from JLCPCB — keep one as backup | ~$0 (already have it) |
| Spare boost module | They're cheap, keep one ready | ~$2 |
| Spare pogo pins | In case one stops springing back | ~$0.10 each |

### When Something Goes Wrong

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Intermittent mist | Pogo pin not making contact | Clean pins with isopropyl alcohol, check continuity |
| No mist, green LED on | VBOOST too low or cup is dry | Check boost module voltage, refill cup |
| No mist, red LED blinking | Sweep can't find resonance | Check pogo pin contact, try fresh cup |
| Takes multiple presses to start | Button issue | Check button connection |
| Weaker mist than usual | VBOOST drifting | Re-measure and adjust boost module trim pot |

---

## Visual Guides

See **[DIAGRAMS.md](DIAGRAMS.md)** for visual diagrams of:
- Controller state machine
- Circuit block diagram and signal flow
- Frequency sweep algorithm (with caching fast path)
- Treatment session flow with dry-cup and re-sweep logic

---

## Connector Plug and Enclosure

- **[Connector Plug](../hardware/adapters/aerogen_connector_plug.scad)** — Plugs onto the Aerogen Solo cup's 2-pin connector, with flexible cable to the controller
- **[Universal Adapter](../hardware/adapters/universal_adapter.scad)** — Configurable adapter for OMRON, PARI, Philips, and other cups
- **[Enclosure](../hardware/enclosure/controller_enclosure.scad)** — Houses the PCB with battery compartment, USB-C port, and cable gland for the connector cable

See [hardware/adapters/README.md](../hardware/adapters/README.md) for measurement guides and assembly instructions.
