# Nebulizer Cup Connector System

3D-printable connector plug and adapters that provide reliable electrical contact between the controller and nebulizer cups.

**Read [DISCLAIMER.md](../../DISCLAIMER.md) before building.**

---

## Overview

The Aerogen Solo cup has a small rectangular connector housing (~1/2" x 1/2") on its bottom face containing two protruding pins (the PZT leads). The connector plug mates with this housing and connects via a flexible cable to the controller enclosure.

1. **A connector plug** that inserts into the cup's pin housing and makes spring-loaded contact
2. **A flexible cable** (30-50cm stranded wire) connecting the plug to the controller
3. **A JST-XH connector** for clean, repeatable connection at the controller end

---

## Available Designs

| File | Cup Model | Status |
|------|-----------|--------|
| `aerogen_connector_plug.scad` | Aerogen Solo / Solo with Pro-X | Ready (approximate dimensions — update with calipers) |
| `universal_adapter.scad` | OMRON MicroAir, PARI eFlow, others | Parametric template (needs measurements) |

Both files are **parametric OpenSCAD** designs. Measure your cup, enter the dimensions, and export STL for printing.

---

## What You Need

### Hardware (per connector)

| Qty | Item | Source | Cost |
|-----|------|--------|------|
| 2 | P75-B1 pogo pin sockets (receptacles) | Amazon/AliExpress "P75-B1 pogo pin" | ~$3/50-pack |
| 1 | JST-XH 2-pin connector + header pair | Amazon/DigiKey | ~$0.50 |
| 1 | Flexible stranded wire, 30-50cm (24-28 AWG, 2 conductors) | Any | ~$0 |
| 1 | 3D printed connector plug | Your printer or JLCPCB 3D printing | ~$1-3 |
| 1 | Small zip tie (for strain relief) | Any | ~$0 |

### Tools

- 3D printer (PETG or SLA resin) or order from JLCPCB/Shapeways
- Soldering iron (to solder wires to pogo pin sockets)
- Calipers (to verify cup connector dimensions)
- JST crimp tool or solder

---

## Measurement Guide — Aerogen Solo

The connector housing on the bottom of the Aerogen Solo cup looks like this:

```
    BOTTOM VIEW (looking up at the cup base)
    ==========================================

         +------------------+
         |                  |
         |    o        o    |   <-- two protruding pins
         |  (pin 1)  (pin 2)|
         |                  |
         +------------------+
              ~1/2" wide

    SIDE VIEW (cross-section through connector)
    ==========================================

         Cup body
        +---------+
        |         |
        | housing |       ^
        |  +---+  |       | housing_height
        |  | o |  |       |  (pin recess depth)
        |  +---+  |       v
        +----+----+
             |  pin protrusion
             v
```

### Critical Measurements (use calipers)

| Parameter | What to Measure | Estimated Value |
|-----------|----------------|-----------------|
| `housing_width` | Width of the rectangular connector housing | ~12.7mm (1/2") |
| `housing_depth` | Depth of the rectangular connector housing | ~12.7mm (1/2") |
| `pin_spacing` | Center-to-center distance between the two pins | ~3.175mm (1/8") |
| `pin_diameter` | Diameter of each pin | ~1.0mm |
| `pin_length` | How far pins protrude from the housing floor | ~4.0mm |
| `housing_height` | Depth of the housing recess | ~6.0mm |

**The most critical measurement is `pin_spacing`.** If this is off by more than 0.2mm, the pogo sockets won't align with the pins. Measure this first and most carefully.

---

## Assembly

### Step 1: Print the Connector Plug

1. Open `aerogen_connector_plug.scad` in [OpenSCAD](https://openscad.org/) (free)
2. Update measurements with your caliper readings
3. Press F5 to preview, F6 to render
4. Export STL: File > Export > Export as STL
5. Print settings:
   - **Material:** SLA resin (best precision) or PETG
   - **Layer height:** 0.12-0.2mm (finer = better socket channel fit)
   - **Infill:** 50%+
   - **Supports:** Yes, for socket channels

### Step 2: Install Pogo Sockets

1. Insert a P75-B1 pogo socket (receptacle end up) into each channel from the bottom of the plug
2. The open bore of each socket should face the insertion face (toward the cup pins)
3. Optionally apply a tiny drop of CA glue to secure the socket barrel — avoid getting glue on the spring mechanism
4. Solder a 24-28 AWG stranded wire to each socket's solder cup

### Step 3: Route Cable

1. Route both wires through the cable channel to the cable exit
2. Thread the cable through the controller enclosure's cable gland **before** terminating
3. Crimp or solder wires to a JST-XH 2-pin plug
4. Secure cable with a zip tie in the strain relief slot

**Cable tips:**
- Use flexible silicone-insulated wire (survives repeated flexing)
- Keep cable 30-50cm (shorter = less noise pickup at 100+ kHz)
- Twist the two wires together to reduce EMI
- **No polarity requirement** — the PZT is an AC device

### Step 4: Test

1. Press the connector plug onto the Aerogen Solo cup's pins
2. You should feel slight resistance as the pins engage the pogo sockets
3. Measure continuity: < 1 ohm from each JST pin to the corresponding cup pin
4. Tug gently on the cable — the strain relief should hold

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Plug won't fit in housing | Plug too wide / deep | Increase `plug_clearance` by 0.1mm, reprint |
| Plug too loose in housing | Too much clearance | Decrease `plug_clearance` by 0.1mm |
| Pins don't align with sockets | `pin_spacing` measurement off | Re-measure with calipers, update, reprint |
| No continuity through socket | Solder joint broke or socket not seated | Re-solder wire, re-seat socket |
| Intermittent contact | Socket spring worn or medication residue | Clean with isopropyl alcohol, replace socket |
| Cable breaks at plug | Repeated flexing without strain relief | Secure cable with zip tie, use stranded wire |

---

## Design Notes

### Why Pogo Sockets (not clips or bare wire)?

The Aerogen Solo cup has a 28-day life, meaning regular cup changes. The connector plug needs to handle hundreds of connect/disconnect cycles reliably. Pogo pin sockets provide:

- **Self-centering** — spring mechanism guides the cup pin into alignment
- **Consistent contact force** — ~75g per pin regardless of insertion depth
- **100,000+ cycle rating** — effectively infinite for this application
- **Low contact resistance** — gold-plated tips, < 50 milliohm

### Why a Plug (not a Cradle)?

The previous adapter design used a cradle that the cup sat in. The plug design is better because:

- **Matches the actual connector** — the cup has pins in a housing, so we make a plug for that housing
- **Smaller and lighter** — just a small block on the end of a cable
- **More flexible positioning** — the cable lets you position the cup anywhere relative to the controller
- **Easier to print** — no large cradle to support during printing

### Cable Length

Keep the cable between 30-50cm. At the operating frequency of 100+ kHz:
- Longer cables act as antennas, picking up noise
- Cable capacitance can affect the output waveform
- The LC output circuit is tuned for a specific load — long cables add parasitic inductance
