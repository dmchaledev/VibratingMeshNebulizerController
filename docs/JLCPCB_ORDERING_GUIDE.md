# JLCPCB Ordering Guide — Pre-Assembled Nebulizer Controller

Step-by-step guide to ordering a fully assembled controller PCB from JLCPCB. This eliminates nearly all soldering — you receive a completed board, plug in a boost module and cup adapter, flash the firmware, and you're done.

**Read [DISCLAIMER.md](../DISCLAIMER.md) before building.**

---

## Overview

JLCPCB offers both PCB fabrication and SMT assembly. You upload design files, they manufacture the boards and solder all the surface-mount components. What you get back is a populated, tested PCB ready for firmware programming.

### What JLCPCB Assembles For You

All surface-mount components on the board:
- PIC16F1713 microcontroller (SOIC-28)
- Output MOSFETs, diodes, inductors
- All resistors, capacitors
- LEDs (SMD)
- Reverse polarity protection
- Fuse
- Connectors (USB-C, JST headers)

### What You Do After Receiving The Board

1. **Flash firmware** via the ICSP header (one-time, ~2 minutes)
2. **Set the boost module** output to ~12V with its trim pot
3. **Plug in** the boost module via JST connector
4. **Plug in** the cup adapter via JST connector
5. **Plug in** USB-C power

No soldering required for normal assembly. The only soldering is attaching wires to the pogo pins inside the 3D-printed cup adapter (two solder joints).

---

## What You Need Before Ordering

### 1. PCB Design Files (Gerbers)

You need Gerber files for the PCB layout. Two options:

**Option A: Use the AN2265 reference layout (recommended starting point)**
- The original Microchip reference design PCB files are in `Nebulizer Reference Design/Board Layout/`
- These need modification to add JST connectors and the boost module header
- If you have KiCad experience, this is a ~2 hour modification

**Option B: Community PCB design**
- If a KiCad project is added to this repo in `hardware/pcb/`, use those Gerber files directly
- Check the repo for updates — a turnkey-optimized PCB layout is planned

### 2. Bill of Materials

Use `docs/BOM_TURNKEY.csv` — it includes JLCPCB-compatible part numbers (LCSC numbers starting with "C").

### 3. Pick-and-Place File (CPL)

This tells JLCPCB where to place each component on the board. It's generated from the PCB design tool (KiCad: Fabrication Outputs > Component Placement).

---

## Step-by-Step JLCPCB Ordering

### Step 1: Upload Gerbers

1. Go to JLCPCB's order page
2. Click **"Add gerber file"**
3. Upload your Gerber ZIP file
4. The system auto-detects board dimensions and layers

### Step 2: Configure PCB Options

Use these settings for best results:

| Setting | Value | Notes |
|---------|-------|-------|
| **Base Material** | FR-4 | Standard, cheapest |
| **Layers** | 2 | Two-layer board is sufficient |
| **Dimensions** | (auto-detected) | ~50x70mm expected |
| **PCB Qty** | 5 | Minimum order. Extra boards = spares |
| **PCB Thickness** | 1.6mm | Standard |
| **PCB Color** | Any | Green is cheapest. Black looks professional. |
| **Surface Finish** | HASL (lead-free) | Good for hand-soldering if needed later |
| **Copper Weight** | 1 oz | Standard |
| **Delivery Format** | Single PCB | Not panelized |

**PCB cost: ~$2-5 for 5 boards**

### Step 3: Enable SMT Assembly

1. Toggle **"PCB Assembly"** on
2. Select:
   - **Assembly Side:** Top (or both if your design has bottom components)
   - **Assembly Qty:** How many boards to assemble (2-5 recommended)
   - **Tooling Holes:** "Added by JLCPCB" (let them add tooling holes automatically)

### Step 4: Upload BOM and CPL

1. Click **"Add BOM File"** — upload the BOM CSV
2. Click **"Add CPL File"** — upload the component placement file
3. JLCPCB will match your BOM parts to their LCSC inventory

### Step 5: Review Part Matching

JLCPCB shows a parts confirmation page. Check each part:

| Your Part | What to Verify |
|-----------|----------------|
| PIC16F1713-I/SO | Correct package (SOIC-28), correct part number |
| IRLML0100 | SOT-23, correct MOSFET |
| C7 (4.7nF 200V) | **Critical** — verify this is 4.7 **nano**farads, not microfarads |
| Inductors (150uH) | Verify value and current rating |

**Common issues:**
- If a part shows "No stock", click the part to search for alternatives. For resistors and standard caps, JLCPCB has many equivalent parts.
- The PIC16F1713 may be listed as an "Extended" part (extra $3 setup fee for extended parts, charged once per order).

### Step 6: Review Placement Preview

JLCPCB shows a 3D preview of component placement. Verify:
- IC orientation (pin 1 dot matches)
- Connector positions
- No overlapping parts

### Step 7: Order

1. Add to cart
2. Select shipping (DHL Express is ~$20-30, takes 4-7 business days)
3. Pay

### Cost Summary

| Item | Cost (typical) |
|------|---------------|
| PCB fabrication (5 boards) | $2-5 |
| SMT assembly (per board) | $8-15 |
| Extended part fee (PIC16F1713) | $3 (one-time) |
| Components (LCSC parts) | $3-8 per board |
| Shipping (DHL) | $20-30 |
| **Total for 5 assembled boards** | **~$50-80** |
| **Per-board cost** | **~$10-16** |

This is remarkably cheap. For context, the Aerogen Pro-X controller costs $2,700.

---

## After You Receive The Boards

### Step 1: Visual Inspection

- Check that all components are present and properly soldered
- Look for solder bridges (especially on the SOIC-28 MCU pins)
- Verify the USB-C connector is seated flat

### Step 2: Flash Firmware

You need the MPLAB Snap (or PICkit 4/5) programmer. This is a one-time purchase (~$35) that works for all future boards.

1. Install MPLAB X IDE and XC8 compiler (both free from Microchip)
2. Open the firmware project from `firmware/`
3. **Edit `firmware/src/config.h`:**
   ```c
   #define BOOST_MODE    BOOST_MODE_MODULE
   ```
4. Connect the MPLAB Snap to the board's ICSP header (5-pin)
5. Click "Make and Program Device" in MPLAB X
6. Programming takes ~10 seconds

### Step 3: Prepare the Boost Module

1. Connect the MT3608/XL6009 module's input to a 5V source (USB charger works)
2. Measure the output with a multimeter
3. Turn the trim pot until output reads **~12V**
4. Disconnect

### Step 4: Assemble

1. **Mount PCB** in enclosure using M2.5 screws (see `hardware/enclosure/`)
2. **Connect boost module** to the JST header labeled "BOOST IN" on the PCB
3. **Connect cup adapter** JST cable to the output header
4. **Snap on enclosure lid**
5. **Slide adapter** onto dovetail dock

### Step 5: First Power-Up Test

1. **Do NOT connect a nebulizer cup yet**
2. Plug in USB-C power
3. Red LED should illuminate (IDLE state)
4. Measure VBOOST on the boost module output — should read ~12V
5. Press the start button — red LED should blink (searching for cup)
6. After ~3 seconds with no cup, it should error (blinking red) — this is correct
7. Fill a cup with **normal saline**, seat it in the adapter
8. Press start — green LED should light when resonance is found
9. Fine mist should appear within seconds

---

## JLCPCB 3D Printing Service

JLCPCB also offers 3D printing. You can order the cup adapter and enclosure at the same time as the PCB.

### Ordering 3D Prints

1. On JLCPCB, go to **"3D Printing"** (top menu)
2. Upload the STL files:
   - `hardware/adapters/aerogen_solo_adapter.stl` (export from OpenSCAD first)
   - `hardware/enclosure/controller_enclosure_base.stl`
   - `hardware/enclosure/controller_enclosure_lid.stl`
3. Select material:
   - **SLA (resin):** Smoother surface, better detail for pogo pin channels. ~$3-8 per part.
   - **MJF (nylon):** More durable, better for the enclosure. ~$5-12 per part.
   - **FDM:** Cheapest but roughest. Fine for the enclosure, marginal for adapter. ~$2-5.
4. For the **cup adapter**, SLA resin is recommended — the pogo pin channels need precision
5. For the **enclosure**, any process works. MJF nylon is most durable.

### Material Recommendations

| Part | Best Material | Why |
|------|---------------|-----|
| Cup adapter | SLA resin (or PETG if home printing) | Precision for pogo pin fit |
| Enclosure base | MJF nylon or PETG | Durability, chemical resistance |
| Enclosure lid | MJF nylon or PETG | Same as base |

---

## Comparison: All Three Build Tiers

| | Breadboard (Full) | Simplified (Boost Module) | **Turnkey (JLCPCB)** |
|---|---|---|---|
| **Parts cost** | ~$38 | ~$20 | ~$15-25/board |
| **Component count (you handle)** | ~40 parts | ~25 parts | **~5 plug-in items** |
| **Soldering required** | Lots (or breadboard) | Moderate (or breadboard) | **2 joints (pogo pins only)** |
| **Total cost (first build)** | ~$73 | ~$55 | **~$50-60** |
| **Cost for additional units** | ~$38 each | ~$20 each | **~$15-25 each** |
| **Build time** | 4-8 hours | 2-4 hours | **~30 minutes** (after delivery) |
| **Reliability** | Low (breadboard) | Low-Medium | **High (factory-soldered)** |
| **Durability** | Needs enclosure work | Needs enclosure work | **Integrated enclosure** |
| **Skill required** | Electronics knowledge | Basic electronics | **Plug connectors, flash firmware** |
| **BOM file** | `BOM.csv` | `BOM_SIMPLIFIED.csv` | **`BOM_TURNKEY.csv`** |

**Recommendation for daily nursery use: the Turnkey build.** Factory-soldered connections don't loosen. The 3D-printed enclosure and adapter dock provide a clean, durable package. And at ~$15-25 per unit after the first build, you can easily make spares.

---

## Ordering Checklist

- [ ] Export Gerber files from PCB design (ZIP format)
- [ ] Export BOM in JLCPCB format (CSV with LCSC part numbers)
- [ ] Export CPL/pick-and-place file (CSV)
- [ ] Upload all three to JLCPCB
- [ ] Verify part matching (especially C7 = 4.7nF, PIC16F1713 = SOIC-28)
- [ ] Order PCBs + assembly
- [ ] Order boost module(s) from Amazon/AliExpress
- [ ] Export STL files from OpenSCAD for adapter and enclosure
- [ ] Order 3D prints (JLCPCB, or print at home)
- [ ] Order P75-B1 pogo pins
- [ ] Order JST-XH cables and M2.5 screws
- [ ] Have MPLAB Snap programmer ready
- [ ] Download and install MPLAB X IDE + XC8 compiler

---

## FAQ

**Q: Can JLCPCB pre-program the PIC16F1713 firmware?**
A: No, JLCPCB doesn't offer microcontroller programming. You need the MPLAB Snap (~$35, one-time) to flash the firmware yourself. This takes about 2 minutes per board.

**Q: What if a component is out of stock at LCSC?**
A: For passive components (resistors, caps), JLCPCB will suggest alternatives with identical specs. For the PIC16F1713 or specific MOSFETs, you may need to wait for restock or order those parts separately and solder them yourself (just 1-2 parts).

**Q: Can I order just 1 board?**
A: PCB minimum is 5 boards (but they cost ~$0.50 each). Assembly minimum is typically 2 boards. The marginal cost of assembling all 5 is small — do it and keep spares.

**Q: Do I need the original BOM (full discrete) at all?**
A: No. The full discrete BOM exists for educational purposes and for anyone who wants to understand every component in the circuit. For practical daily use, the Turnkey build is superior in every way — cheaper, more reliable, faster to build, and more durable.

**Q: Can I use PCBWay or OSH Park instead of JLCPCB?**
A: Yes. Any PCB fabricator that offers SMT assembly will work. JLCPCB tends to be the cheapest for small quantities. PCBWay is comparable. OSH Park doesn't offer assembly but makes excellent bare PCBs if you want to solder yourself.
