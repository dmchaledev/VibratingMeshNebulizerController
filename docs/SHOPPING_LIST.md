# Nimbus Nebulizer Controller — Shopping List

Everything you need to build one Nimbus controller, organised by
supplier so you can copy/paste a cart. Quantities are for a **single
finished unit**, with a "5-pack" column for the JLCPCB minimum
batch (build one, keep spares).

**Read [DISCLAIMER.md](../DISCLAIMER.md) before ordering anything.**

---

## TL;DR — Cheapest Path (≈ $40 + programmer)

If you already own a soldering iron and a 3D printer:

| Source | Spend | What you get |
|--------|-------|--------------|
| JLCPCB (PCB + SMT assembly) | ~$50–80 | 5 populated boards |
| Amazon / AliExpress | ~$20–30 | LiPo, TP4056 pack, boost pack, LCD, pogos, cables |
| Home 3D printer | ~$3 | Enclosure + connector plug (PETG) |
| DigiKey (one-time) | ~$35 | MPLAB Snap programmer |
| **First-build total** | **~$80–115** | Programmer is reusable forever |
| **Per-board after first build** | **~$15–25** | Because the programmer is amortised |

Compare to an Aerogen Pro-X: **$2,700 out of pocket**.

---

## 1. PCB + SMT Assembly (JLCPCB)

You upload the gerbers + BOM + CPL once. JLCPCB ships populated boards.
See [JLCPCB_ORDERING_GUIDE.md](JLCPCB_ORDERING_GUIDE.md) for the full
walk-through.

| Item | Qty | LCSC / JLCPCB P/N | Unit | 5-pack |
|------|-----|-------------------|------|--------|
| PCB fab, 2-layer FR4, HASL | 5 | (gerbers) | – | $2–5 |
| SMT assembly (all SMD parts on [BOM_TURNKEY.csv](BOM_TURNKEY.csv)) | 5 | (BOM+CPL) | – | $40–75 |
| PIC16F1713-I/SO | 1 | **C507376** | ~$1 | on BOM |
| IRLML0100TRPBF MOSFET | 1 | **C414017** | ~$0.20 | on BOM |
| Inductor 150 µH (SMD 1210/1812) | 2 | **C341521** | ~$0.30 | on BOM |
| Cap 4.7 nF 200 V C0G 1206 | 1 | **C106225** | ~$0.10 | on BOM |
| Cap 0.1 µF 100 V 1206 | 1 | **C307331** | – | on BOM |
| 1N4148WS SOD-323 | 1 | **C81598** | – | on BOM |
| SS14 Schottky | 1 | **C2480** | – | on BOM |
| All 0603 R/C (1.8 Ω, 4.7 kΩ, 10 kΩ, 110 kΩ, 360 kΩ, 270 Ω, 100 Ω, 0.1 µF) | qty per BOM | see BOM | – | on BOM |
| 0603 SMD LED red + green | 1 + 1 | **C84256 / C72043** | – | on BOM |
| JST-PH TH header 2-pin (BAT IN) | 1 | **C265061** | – | on BOM |
| JST-XH TH header 2-pin (cup + boost in) | 2 | **C158012** | – | on BOM |
| 1×5 pin header (ICSP) | 1 | **C358687** | – | on BOM |
| 1×4 pin header (LCD) | 1 | **C124378** | – | on BOM |
| Tactile switch 6×6 mm | 1 | **C318884** | – | on BOM |

> **The single most commonly miscategorised part is C7 = 4.7 nF
> (not µF). 200 V C0G. If JLCPCB flags it as out-of-stock, pick an
> exact-spec substitute; don't accept a µF replacement.**

---

## 2. Amazon / AliExpress — User-Supplied Parts

These plug into the PCB after you receive it. Many ship in multi-packs,
so **a 5-board batch needs ~5 of most of these** — order once, sit on
the spares.

### Core plug-ins

| Item | Qty/unit | Qty for 5 units | How to search | Known SKU | Cost |
|------|---------:|----------------:|---------------|-----------|------|
| MT3608 (or XL6009) boost module | 1 | 5 (comes in 5-packs) | `MT3608 boost module 5 pack` | — | $5 / 5-pack |
| 1S LiPo 103450 pouch, ≥ 2000 mAh, JST-PH pigtail | 1 | 5 | `103450 2000mAh LiPo JST` | **Amazon B07BTWK13N** | $8–12 |
| TP4056 + DW01A USB-C charger module | 1 | 15 (cheapest pack) | `TP4056 Type-C DW01A` | **Amazon B0CWNXKR4X** | $0.50 ea in 15-pack |
| 16×2 character display (pick one of A/B/C below) | 1 | 5 | see display section | — | $3–28 |
| USB-C cable | already own | – | – | – | $0 |

### Cables and connectors

| Item | Qty/unit | Qty for 5 units | How to search | Cost |
|------|---------:|----------------:|---------------|------|
| JST-XH 2-pin **pre-crimped** pigtail, 150 mm | 2 (boost + cup) | 10 | `JST XH 2 pin pigtail 150mm` — most packs include 10 | $3 / 10-pack |
| JST-PH 2-pin **pre-crimped** pigtail, 100 mm | 1 (battery) | 5 | `JST PH 2 pin pigtail 100mm` | $3 / 10-pack |
| 4-wire female-female Dupont ribbon, ≥ 100 mm (LCD I²C) | 1 | 5 | `Dupont jumper wire 4-pin female 100mm` | $3 / 40-pack |

> Buying **pre-crimped** pigtails saves ~$40 of crimp-tool spend per
> first-timer. Only place you need to solder is the pogo pin tails in
> the connector plug.

### Mechanical

| Item | Qty/unit | Qty for 5 units | How to search | Cost |
|------|---------:|----------------:|---------------|------|
| P75-B1 pogo pins (receptacle + plunger) | 2 | 10 (50-pack) | `P75-B1 pogo pin 50 pack` | ~$3 |
| M2.5 × 6 mm panhead machine screws (PCB mount) | 4 | 20 | `M2.5 x 6mm Phillips screw kit` | $5 / assortment |
| M3 × 6 mm panhead machine screws (LCD mount) | 4 | 20 | `M3 x 6mm Phillips screw kit` | $5 / assortment |
| Double-sided 3M foam tape (TP4056 + LiPo hold-down) | ~5 cm | – | `3M foam tape 3mm thick` | $3 |
| Cable zip ties, 100 mm, small (strain relief) | 1 | 5 | `small zip ties 100mm` | $2 / 100-pack |

### Bench / service parts (strongly recommended to have on hand)

| Item | Why | Search | Cost |
|------|-----|--------|------|
| MG Chemicals 422B conformal coating spray | Protects PCB against saline mist | `MG 422B conformal coating 340g` | ~$14 |
| Isopropyl alcohol ≥ 99 % | Clean flux, clean pogo pins, clean mesh | `99% isopropyl alcohol 500ml` | ~$10 |
| Pre-saturated IPA swabs | Weekly nursery cleaning | `IPA swabs 99% 100 pack` | ~$6 |
| Aerogen Solo cups (medical supply) | 28-day life — always keep ≥ 2 spare | `Aerogen Solo cup` (medical supplier) | ~$40 ea |

---

## 3. DigiKey / Mouser — Precision Parts

Use DigiKey or Mouser for the few items where **provenance matters**:
the programmer, the optional character OLED, and the MCP2221 debug
bridge. They cost a little more but you don't risk a counterfeit on a
chip you're going to trust near a patient.

| Item | P/N | Where | Cost | Notes |
|------|-----|-------|------|-------|
| MPLAB Snap programmer | **PG164100-ND** (DigiKey) / PG164100 (Mouser) | DigiKey / Mouser | ~$35 | One-time. Flashes the PIC and every future rework. |
| Winstar WEH001602ALPP5N Character OLED 16×2 | **WEH001602ALPP5N00000** | DigiKey / Mouser | ~$22–28 | `LCD_IS_OLED = 1`. Recommended default. |
| Newhaven NHD-0216AW-IB3 Character OLED 16×2 (I²C native) | **NHD-0216AW-IB3** | DigiKey / Mouser | ~$25–32 | `LCD_IS_OLED = 1`. No backpack needed. |
| MCP2221A USB-UART/I²C bridge DIP-14 | **MCP2221A-I/P** | DigiKey / Mouser | ~$5 | Optional debug. Shows state transitions + sweep logs. |
| PICkit 4 (faster, better debug than Snap) | **PG164140** | DigiKey / Mouser | ~$60–90 | Pick one — Snap is enough for flashing. |

> Why not use the same supplier for *everything*? DigiKey prices for
> screws, zip-ties, foam tape, and generic LiPo cells are 3–5× Amazon /
> AliExpress. Split the cart: precision parts here, bulk commodities
> from the big marketplaces.

---

## 4. Pick-a-Display

You must pick exactly one of these. The firmware driver is identical
for all three; only `LCD_IS_OLED` in `firmware/src/config.h` changes.

| Option | P/N | Where | Cost | config.h | Pros | Cons |
|--------|-----|-------|------|----------|------|------|
| **A — cheap** | Generic 1602 LCD + **LCD1602 IIC** PCF8574 backpack | Amazon / AliExpress | $3–5 | `LCD_IS_OLED = 0` | Cheapest; backlight readable in dark | Contrast sags under 3.7 V |
| **B — default** | **Winstar WEH001602ALPP5N** + PCF8574 backpack | DigiKey / Mouser | $22–28 | `LCD_IS_OLED = 1` | Rated 3.0–5.5 V; crisp at every battery level | More expensive |
| **C — integrated** | **Newhaven NHD-0216AW-IB3** | DigiKey / Mouser | $25–32 | `LCD_IS_OLED = 1` | I²C on-board, one fewer part | Slightly larger PCB |

The firmware **auto-probes** PCF8574 I²C addresses 0x27 (NXP) and 0x3F
(TI) at boot, so you don't need to know which variant your backpack is.

---

## 5. 3D Prints

You can print these at home (PETG recommended) or outsource to
JLCPCB's 3D-printing service. Set them all to ship in the same order
as the PCBs to save on freight.

| Part | File | Home filament | JLCPCB / service | Cost |
|------|------|---------------|------------------|------|
| Enclosure base | `hardware/enclosure/controller_enclosure.scad` → STL | PETG, 0.2 mm, 30 % infill | MJF nylon or SLA | $2–5 |
| Enclosure lid | `hardware/enclosure/controller_enclosure_lid.scad` → STL | PETG, 0.2 mm, 30 % infill | MJF nylon or SLA | $2–5 |
| Connector plug (Aerogen Solo) | `hardware/adapters/aerogen_connector_plug.scad` → STL | **SLA resin** (best) or PETG 0.12 mm layers | SLA resin | $1–3 |
| Universal adapter (other cups) | `hardware/adapters/universal_adapter.scad` → STL | PETG | SLA | $1–3 |

> Render STL from OpenSCAD GUI (`F6` → File > Export > STL) or:
> `openscad -o part.stl path/to/part.scad`.

---

## 6. One-Unit Build Checklist (copy/paste into a note app)

```text
[ ] Gerbers + BOM + CPL uploaded to JLCPCB (5 boards, SMT assembly on)
[ ] MT3608 boost module 5-pack
[ ] 1S LiPo pouch 103450 2000 mAh with JST-PH pigtail
[ ] TP4056 + DW01A USB-C charger (15-pack)
[ ] 16x2 display (pick: LCD $3 / Winstar OLED $25 / Newhaven $28)
[ ] JST-XH 2-pin pigtails, 150 mm (10-pack)
[ ] JST-PH 2-pin pigtails, 100 mm (10-pack)
[ ] 4-pin Dupont F-F ribbon, 100 mm (40-pack)
[ ] P75-B1 pogo pins (50-pack)
[ ] M2.5 x 6mm + M3 x 6mm screw assortment
[ ] 3M foam tape
[ ] 100 mm zip ties
[ ] MG Chemicals 422B conformal coating
[ ] Isopropyl alcohol 99% + swabs
[ ] MPLAB Snap (PG164100-ND, one-time, reuse forever)
[ ] Download MPLAB X IDE + XC8 (free)
[ ] STL files rendered from OpenSCAD for base + lid + connector plug
[ ] ≥ 2 Aerogen Solo cups on hand (medical supply)
```

---

## 7. Batch Build (5 Units) Checklist

5 complete controllers + spares. JLCPCB minimum order is 5 anyway, so
this is the natural sweet spot.

- 1 × JLCPCB order (5 assembled PCBs)
- 1 × MT3608 5-pack
- 5 × LiPo 103450 cells
- 1 × TP4056 15-pack (10 left for future builds or giveaways)
- 5 × displays of your chosen option
- 1 × each cable multi-pack (covers all 5 builds)
- 1 × pogo pin 50-pack
- 1 × screw assortment
- 1 × MPLAB Snap (reused across all 5)
- 5 × printed enclosure bases / lids / connector plugs
- 5 × Aerogen Solo cups on hand (plus 2 rotating spares)

---

## 8. Notes on Sourcing Safely

- **Always verify LiPo polarity with a multimeter** before plugging in.
  The JST-PH keying on the PCB prevents reversal, but cheap cells ship
  with the wrong wire colours occasionally.
- **Do not** buy "Aerogen-compatible" cups from AliExpress. The
  resonant frequency and piezo specs can differ enough to damage the
  cup or the controller. Use real Aerogen Solo cups from a medical
  supplier.
- **PIC16F1713** should come from Microchip's authorised channel
  (DigiKey, Mouser, Arrow, or JLCPCB via LCSC). Counterfeit PICs do
  exist on eBay and AliExpress.
- When ordering 3D prints from a service, request **FDA-grade** or
  "medical-grade" resin only if the part contacts medication. The
  enclosure and connector plug do not, so standard PETG / MJF is fine.
