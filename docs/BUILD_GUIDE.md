# Nimbus Build Guide — Turnkey (JLCPCB Pre-Assembled)

Complete guide to assembling the Nimbus Nebulizer Controller from a JLCPCB pre-assembled PCB.

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

### User-Supplied Parts (v3.1)

See [BOM_TURNKEY.csv](BOM_TURNKEY.csv) for the complete list. The key items you supply:

| Item | Source | Cost |
|------|--------|------|
| MT3608 or XL6009 boost module | Amazon/AliExpress | ~$1-2 |
| 1S LiPo pouch cell, 2000 mAh (103450) | Amazon B07BTWK13N | ~$8-12 |
| TP4056 + DW01A Type-C charger | Amazon B0CWNXKR4X (15-pack) | ~$0.50-2 |
| 16x2 character display (LCD default, OLED optional) | see below | ~$3 (LCD) or ~$25 (OLED) |
| USB-C cable (charging) | Any | ~$0 (you have one) |
| JST-XH 2-pin cable (cup output) | Amazon/DigiKey | ~$1 |
| JST-PH 2-pin cable (battery pigtail) | Amazon/DigiKey | ~$1 |
| 4-wire Dupont ribbon (LCD) | Amazon/DigiKey | ~$0.50 |
| P75-B1 pogo pins (2) | Amazon/AliExpress | ~$3/50-pack |
| M2.5x6mm screws (4, PCB mount) | Amazon/hardware store | ~$1 |
| M3x6mm screws (4, LCD mount) | Amazon/hardware store | ~$1 |
| MPLAB Snap programmer | DigiKey PG164100-ND | ~$35 (one-time) |

#### Picking a Display

v3.1 supports any 16x2 character display with an HD44780-compatible
command set driven by a PCF8574 I2C backpack. Three popular choices:

| Option | Part | Cost | Notes |
|--------|------|------|-------|
| **A** | Generic 1602 LCD + "LCD1602 IIC" backpack | ~$3-5 | `LCD_IS_OLED = 0`. Works in the dark thanks to its backlight; contrast may be dim below ~3.7 V battery. |
| **B (default)** | Winstar WEH001602A + PCF8574 backpack | ~$22-28 | `LCD_IS_OLED = 1`. Character OLED with WS0010 controller. Rated 3.0-5.5 V — stays crisp at any battery level. |
| **C** | Newhaven NHD-0216AW-IB3 | ~$25-32 | `LCD_IS_OLED = 1`. Has I2C built in — no external backpack needed. |

The firmware driver is the same for all three; only the `LCD_IS_OLED`
flag in `firmware/src/config.h` changes. If you already have the PCB
and want to upgrade the display later, you can do so without any
hardware changes.

### 3D-Printed Parts

v3.1 splits the enclosure into separate base and lid files so you can
iterate on either without re-rendering the other.

| Part | File | Material |
|------|------|----------|
| Connector plug | `hardware/adapters/aerogen_connector_plug.scad` | PETG or SLA resin |
| Enclosure base | `hardware/enclosure/controller_enclosure.scad` | PETG |
| Enclosure lid | `hardware/enclosure/controller_enclosure_lid.scad` | PETG |

Shared dimensions live in `hardware/enclosure/enclosure_config.scad` —
edit it once and both base and lid stay in sync.

Print settings: 0.2mm layer height, 30-50% infill, supports disabled
(both files are orientation-friendly).

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

### Step 4: Prepare the LiPo + TP4056 Bay (v3.1)

1. **Inspect the LiPo cell.** Check the JST-PH pigtail polarity with
   a multimeter — the red lead must be +, black must be -. Do NOT
   trust the wire colors on a cheap cell without verifying.
2. **Pre-charge the cell** by connecting USB-C to the TP4056 module
   with its BAT pads still disconnected. The red charging LED should
   light. Unplug USB.
3. **Solder two short (~50 mm) wires** from the TP4056 BAT+ / BAT-
   pads to a matching JST-PH 2-pin plug that will mate with the PCB's
   BAT IN header. Double-check polarity — the PCB BAT IN header is
   keyed but the solder pads on the TP4056 are not.
4. **Seat the LiPo** in the enclosure battery bay (flat on the floor).
5. **Drop the TP4056** onto the internal shelf above the cell, USB-C
   socket facing the front aperture. Light double-sided foam tape
   keeps it from rattling.

### Step 5: Mount the LCD/OLED on the Lid

1. Feed the 4-pin Dupont ribbon through the lid's LCD wire slot.
2. Connect one end to the LCD backpack: VCC → VCC, GND → GND,
   SDA → SDA, SCL → SCL.
3. Position the LCD PCB over the four standoffs inside the lid,
   glass side facing out through the viewing window.
4. Secure with four M3 x 6 mm screws.
5. Peel off any protective film from the glass only AFTER all
   screws are tight — it's easy to scratch before the bezel seats.

### Step 6: Final Assembly

1. **Mount PCB** in the enclosure base using 4x M2.5x6 mm screws
2. **Connect boost module** to the JST header labeled "BOOST IN"
3. **Connect connector plug** JST cable to the cup output header
4. **Connect the LiPo pigtail** from the TP4056 BAT pads to the
   PCB's BAT IN JST-PH header
5. **Connect the LCD ribbon** from the lid to the PCB's 1x4 LCD
   header (match VCC/GND/SDA/SCL)
6. **Close the lid** — the standoffs should seat cleanly on the
   lid lip. Give the ribbon some slack so it isn't pinched.

### Step 7: First Power-Up

1. **Do NOT connect a nebulizer cup yet**
2. **Charge the cell** — plug USB-C into the TP4056 aperture until
   the red charge LED on the module turns off (~1-2 hours)
3. **Unplug USB**. The display should show the splash:
   ```
   Nimbus Nebulizer
    Controller v3.1
   ```
   After ~1.5 s it switches to the status line:
   ```
   READY  128.5kHz
   Bat 98%  4.13V
   ```
4. Red LED should also illuminate (IDLE state)
5. Measure VBOOST on the boost module output — should read ~12V
6. Press the start button — LCD should show `SWEEP...` then either
   `RUN 128.5kHz MM:SS` or `ERR no cup`
7. After ~3 seconds with no cup it should error — this is correct
8. Fill an Aerogen Solo cup with **normal saline** (not medication)
9. Seat the cup in the connector plug
10. Press start — `RUN 128.5kHz 00:01` should appear and fine mist
    should start within seconds

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

## Power Supply (v3.1)

v3.1 uses a rechargeable 1S LiPo pouch cell charged through a
TP4056/DW01A USB-C module. There is no separate 5V rail — the MCU
and the boost module both run directly off the cell (3.0-4.2 V).

| Path | Voltage | Notes |
|------|---------|-------|
| **LiPo 1S** | 3.0-4.2 V (3.7 V nominal) | Powers MCU + boost module. Runtime ~3-5 treatments per charge. |
| **USB-C (TP4056)** | 5 V in → 4.2 V CV charge | Plug in to recharge. You can also run from USB while charging. |

The firmware continuously monitors battery voltage via the PIC's Fixed
Voltage Reference and shows percent + millivolts on the LCD. A soft
cutoff at 3.1 V warns the user and stops any running treatment before
the DW01A hardware protection (2.5 V) trips.

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
