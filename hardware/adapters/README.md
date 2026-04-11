# Nebulizer Cup Adapter System

3D-printable adapters that provide reliable, repeatable electrical contact between the controller and various vibrating mesh nebulizer cups.

**Read [DISCLAIMER.md](../../DISCLAIMER.md) before building any adapter.**

---

## Overview

Each nebulizer manufacturer uses a different cup form factor, but they all have the same basic requirement: two electrical contacts to the PZT piezoelectric ring. The adapter system solves this with:

1. **A cup-specific cradle** that holds the nebulizer cup in the correct position
2. **Spring-loaded pogo pins** that press against the cup's PZT contact pads
3. **A JST connector** for clean, repeatable connection to the controller

The adapter is designed to snap into the controller enclosure (see `../enclosure/`) or work standalone on a bench.

---

## Available Adapters

| File | Cup Model | Status |
|------|-----------|--------|
| `aerogen_solo_adapter.scad` | Aerogen Solo / Solo with Pro-X | Ready (needs your measurements) |
| `universal_adapter.scad` | OMRON MicroAir, PARI eFlow, others | Parametric template (needs measurements) |

Both files are **parametric OpenSCAD** designs. You measure your cup, enter the dimensions at the top of the file, and export an STL for printing.

---

## What You Need

### Hardware (per adapter)

| Qty | Item | Source | Cost |
|-----|------|--------|------|
| 2 | P75-B1 pogo pins (1.02mm dia, pointed tip) | Amazon/AliExpress "P75-B1 pogo pin" | ~$3/50-pack |
| 1 | JST-XH 2-pin connector + header pair | Amazon/DigiKey | ~$0.50 |
| 2 | Short lengths of stranded wire (24-28 AWG) | Any | ~$0 |
| 1 | 3D printed adapter body | Your printer or JLCPCB 3D printing | ~$1-3 |
| 2 | Small magnets 6x2mm (optional, for retention) | Amazon "6x2mm neodymium" | ~$2/20-pack |

### Tools

- 3D printer (PLA or PETG) or order from JLCPCB/Shapeways
- Soldering iron (to solder wires to pogo pins)
- Calipers or ruler (to measure your cup)
- Small Phillips screwdriver (optional, if using set screws)

---

## Measurement Guide

Before printing an adapter, you need to measure your specific nebulizer cup. Every measurement should be taken with calipers if possible. If you only have a ruler, add 0.5mm tolerance to cup dimensions.

### Aerogen Solo Measurements

Measure the following on your Aerogen Solo cup and enter them into `aerogen_solo_adapter.scad`:

```
        TOP VIEW (looking down at the cup)
        ===================================

              +-----------+
            /               \
           /                 \
          |                   |
          |     O       O     |    <-- contact pads (on bottom face)
          |   (pad1)  (pad2)  |
          |                   |
           \                 /
            \               /
              +-----------+

        SIDE VIEW
        ===================================

          |<-- cup_od -->|
          +----+   +----+
          |    |   |    |      ^
          |    |   |    |      | cup_height
          |    |   |    |      |
          |    +---+    |      v   <-- bottom face with contact pads
          +---+     +---+
              |     |          ^
              | lip |          | lip_height (if any)
              +-----+         v
```

#### Required Measurements

| Parameter | What to Measure | How |
|-----------|----------------|-----|
| `cup_outer_diameter` | Widest outer diameter of the cup body | Calipers around the cup at its widest point |
| `cup_height` | Total height from bottom face to top rim | Stand cup on a flat surface, measure to top |
| `contact_spacing` | Center-to-center distance between the two contact pads | Calipers or ruler between pad centers |
| `contact_diameter` | Diameter of each contact pad | Calipers across one pad |
| `contact_inset` | Distance from cup bottom face to contact pad surface | Is the pad flush? Recessed? If recessed, how deep? |
| `cup_lip_diameter` | If the cup has a narrower lip/rim on the bottom | Measure the lip diameter |
| `cup_lip_height` | Height of any bottom lip/step | Measure the step height |

#### Optional Measurements

| Parameter | What to Measure | Default |
|-----------|----------------|---------|
| `cup_taper_angle` | If the cup body tapers (not perfectly cylindrical) | 0 (cylindrical) |
| `flat_width` | If the cup has a flat section (D-shaped) for alignment | 0 (round) |
| `contact_offset_x` | Horizontal offset of contact pair center from cup center | 0 (centered) |
| `contact_offset_y` | Vertical offset of contact pair center from cup center | 0 (centered) |

### Other Cup Brands

For OMRON MicroAir, PARI eFlow, or other cups, you need the same measurements above plus:

| Parameter | What to Measure | Notes |
|-----------|----------------|-------|
| `contact_type` | Shape of the electrical contacts | "circular_pad", "ring", "pin", "strip" |
| `contact_width` | Width of strip/ring contacts (if not circular) | Only for non-circular contacts |
| `contact_ring_id` | Inner diameter of ring contact (if ring type) | Only for ring contacts |
| `contact_ring_od` | Outer diameter of ring contact (if ring type) | Only for ring contacts |

Use `universal_adapter.scad` for non-Aerogen cups. It supports all contact types.

---

## Assembly

### Step 1: Print the Adapter

1. Open the `.scad` file in [OpenSCAD](https://openscad.org/) (free)
2. Enter your measurements in the parameters section at the top
3. Press F5 to preview, F6 to render
4. Export STL: File > Export > Export as STL
5. Print with these settings:
   - **Material:** PETG recommended (more chemical resistant than PLA). PLA works for testing.
   - **Layer height:** 0.2mm
   - **Infill:** 30-50%
   - **Supports:** Yes, for the pogo pin channels
   - **Orientation:** Print with the cup opening facing up

### Step 2: Install Pogo Pins

1. Insert a P75-B1 pogo pin into each channel from the bottom of the adapter
2. The pin tip should protrude ~1mm above the cup contact surface when uncompressed
3. Solder a 24-28 AWG stranded wire to each pogo pin's solder cup (the bottom end)
4. Optionally apply a tiny drop of CA (super glue) to secure the pin body in the channel — don't get glue on the spring tip
5. Route wires through the cable channel

### Step 3: Connect JST Plug

1. Crimp or solder the two wires to a JST-XH 2-pin plug
2. The matching JST-XH 2-pin header goes on your controller PCB or breadboard
3. **No polarity requirement** — the PZT is an AC device, either wire to either pin

### Step 4: Test Fit

1. Place your nebulizer cup into the adapter cradle
2. The cup should seat firmly with the contacts aligned over the pogo pins
3. Press gently — you should feel the pogo pin springs compress
4. Measure continuity with a multimeter from the JST plug pins to the cup contacts
5. Resistance should be < 1 ohm through each pogo pin

---

## Design Philosophy

### Why Pogo Pins?

| Method | Pros | Cons |
|--------|------|------|
| Alligator clips | Cheap, easy | Slip off, scratch contacts, unreliable |
| Soldered wires | Permanent connection | Can't swap cups, damages contacts |
| Flat spring contacts | Simple | Hard to align, inconsistent pressure |
| **Pogo pins** | **Self-aligning, consistent pressure, thousands of cycles** | **Need a printed holder** |

The P75-B1 pogo pin is rated for 100,000+ cycles. At 6 treatments/day, that's 45+ years of use. The spring provides consistent contact pressure (~75g per pin) regardless of how firmly you seat the cup.

### Why Separate Adapter + Enclosure?

- **Swap adapters** when you change cup brands (Aerogen today, OMRON tomorrow)
- **Replace adapter** without replacing the controller if the pogo pins wear out
- **Iterate quickly** on adapter fit without reprinting the whole enclosure
- **Dovetail mount** connects adapter to enclosure with a simple slide-and-click

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| No continuity through pogo pin | Pin not making contact, or solder joint broke | Re-seat pin, re-solder wire |
| Cup doesn't sit flat in cradle | Measurements off, or print tolerance | Sand the cradle bore slightly, or adjust dimensions +0.3mm |
| Cup falls out of adapter | Cradle too loose | Decrease `cup_outer_diameter` by 0.2-0.5mm in the SCAD file, or add retention magnets |
| Intermittent contact during nebulization | Vibration loosening the cup | Add retention magnets or increase pogo pin spring preload by raising `pogo_preload` |
| Pogo pin stuck (doesn't spring back) | Medication residue in pin | Clean with isopropyl alcohol. Replace pin if spring is damaged. |
