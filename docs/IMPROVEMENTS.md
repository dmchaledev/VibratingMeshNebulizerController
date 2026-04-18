# Nimbus Nebulizer Controller — Improvement Suggestions

An external engineer's assessment of the repo at v3.1, with concrete
suggestions ordered by "bang for the buck." Written from the
perspective of someone looking at this project for the first time with
fresh eyes.

**Context.** This is a personal-use, educational build for a nursery
device driven 6+ times per day. It's not FDA-approved and is not
intended for distribution. That framing matters — some suggestions
below are worth it only if you want to make the design more accessible
to *other* builders; others are worth it just to make your own build
cheaper and faster.

**Scope.** This memo does not second-guess safety decisions already
made in the firmware. The soft LiPo cutoff, dry-cup auto-stop, and
max-DAC clamp are all clearly right. Suggestions are additive to those.

---

## TL;DR — Top 5 Concrete Wins

Ranked by impact ÷ effort. Each is expanded later in the doc.

| # | Suggestion | Effort | Payoff |
|---|-----------|-------:|--------|
| 1 | **Swap the $22–28 character OLED for a $3 SSD1306 0.96" OLED** | ~1 day firmware work | **Saves ~$20–25 per unit.** Single biggest line-item win. Adds graphical capability as a bonus. |
| 2 | **Publish pre-rendered STL + pre-built HEX as GitHub Release artifacts** | ~2 hr of CI glue | Removes the MPLAB X + OpenSCAD install barrier for anyone who doesn't need to modify. First-build wall-clock time drops ~1 hr. |
| 3 | **Evict root clutter: move PNG/PDF to `docs/images/` and `docs/references/`, rename `Nebulizer Reference Design/` (no space), drop the 39 MB vendored OpenSCAD AppImage** | ~1 hr | 40 MB lighter clone. Root directory becomes instantly scannable. Fixes the dir-name-with-space that your own `hardware/README.md` already flagged. |
| 4 | **Add an absolute-max treatment-time safety cap (e.g., 60 min) in CONTINUOUS mode** | ~20 LOC | Defense-in-depth. `CONTINUOUS + dry-cup-miss + silent sweep fail` is currently unbounded. |
| 5 | **Add `docs/GLOSSARY.md` + a single "Which build path is for me?" decision doc at root** | ~2 hr | First-time visitors currently hit PZT, NCO, CWG, HEF, FVR, MMAD, ICSP, HD44780, PCF8574, TP4056, DW01A, WS0010 within 10 pages. A one-pager demystifies all of them. |

Everything below is supporting detail and lower-priority items.

---

## 8. Prioritised Backlog

If I were picking up this repo Monday morning and had a week:

**Day 1 — free wins (no risk):**

- Move root PNGs → `docs/images/`, PDF → `docs/references/`, delete
  the vendored 39 MB OpenSCAD AppImage (publish as release asset
  instead), rename `Nebulizer Reference Design/` → `docs/references/
  an2265_reference/`. (§1.1)
- Add `docs/GLOSSARY.md` and `docs/CHOOSE_YOUR_PATH.md`. (§1.2, §1.3)
- Collapse cost tables into a single `docs/COSTS.md` linked from the
  rest. (§1.4)
- Add top-level `Makefile` with `firmware`, `stl`, `test`, `check`
  targets that delegate to the existing sub-Makefiles. (§1.7)

**Day 2 — release hygiene:**

- GitHub Actions workflow that publishes pre-rendered STLs and a
  default `.hex` on every tag. (§2.3)
- Surface `firmware/tests/` in README. (§1.6)

**Day 3 — safety adds:**

- `TREATMENT_HARD_MAX_SEC` cap (§5.1), `BOOST_VFDBK_MAX_ADC` trip
  (§5.2), resonance plausibility window (§5.3), power-on self-test
  (§5.4). All ~100 LOC of firmware, fully host-testable.

**Day 4–5 — BOM optimisation (requires PCB rev):**

- Swap character OLED for SSD1306 0.96" (§2.1).
- Standardise on JST-XH + M3 (§2.2).
- Panelise the PCB for 10-up on JLCPCB.

**Day 6 — architecture rethink (optional):**

- USB-C PD trigger path in parallel with the MT3608 (§2.5).

**Beyond:** RP2040 port, logging, kit fulfilment — all §7 items are
separate projects in their own right.

## 9. Cross-References

- `docs/SHOPPING_LIST.md` — concrete per-supplier cart list for every
  part in the current v3.1 BOM, organised to minimise shipping trips.
- `docs/BOM_TURNKEY.csv` — authoritative BOM; SHOPPING_LIST is the
  "how to buy it" layer on top.
- `CHANGELOG.md` — history of what was tried and why. Read this
  before proposing anything that sounds like a revert.

---

*This memo was written as an external review and reflects one
reader's judgement. The maintainer's priorities and safety decisions
take precedence.*


### 6.1  Things that are notably well done — don't regress

Worth calling out explicitly so future contributors know what *not* to
"simplify away":

- **Stubbed-transclusion test pattern** in `firmware/tests/`
  (`#define` around hardware blocks, then `#include` the `.c`). Lets
  the host compiler run the same source that ships. Clean solution to
  the "`xc.h` isn't a host header" problem.
- **`LCD_IS_OLED` single driver for three different 1602 modules.**
  One codepath, three displays, $3–$28 price range. Nice.
- **FVR-as-ADC-reference battery meter** — zero external parts for
  battery voltage read. Elegant.
- **HEF frequency caching** with narrow re-sweep fallback —
  measurable UX improvement (150 ms vs 2.4 s cold start).

### 6.2  Config drift between docs and code

`config.h`'s pin comments and `hardware/WIRING.md`'s pin table are
duplicates that can drift. Two options:

- Generate `WIRING.md` from `config.h` with a short Python script in CI
- Or just add a comment at the top of each: "source of truth:
  `config.h`" vs "source of truth: `WIRING.md`", and link reciprocally

I'd go with the second — lighter touch.

### 6.3  Bit-bang I²C vs hardware MSSP

`lcd.c` bit-bangs I²C on RC4/RC5. The PIC16F1713 has an MSSP module
that could run hardware I²C at 100 or 400 kHz with less CPU overhead.
Given that the LCD refresh is only 2 Hz, this is **not** worth
touching — the bit-bang is simpler and works. Flag for future
contributors: don't "optimise" this unless you're freeing CPU for
something else.

### 6.4  UART debug default

`UART_ENABLED = 1` by default is good for debugging; consider flipping
to 0 for tagged releases to save a handful of bytes of flash and
reduce the chance of someone confused by UART traffic they didn't
intend to see. `BUILD_GUIDE.md` already documents enabling it when
needed.

## 7. Bigger Bets — Worth Considering, Not Recommending

Each of these is a larger architectural shift. They're listed for
completeness, not as near-term proposals.

### 7.1  Port firmware to Raspberry Pi Pico (RP2040)

- **Pros.** $4 board with native USB mass-storage bootloader — no
  $35 programmer ever again. Free GCC toolchain. More RAM/flash.
  Easier for hobbyist contributors to get into.
- **Cons.** Complete firmware rewrite. Abandons the AN2265 lineage
  that underpins the project's credibility. PIO makes frequency
  generation straightforward but PIO assembly is a new thing to
  learn. The RP2040 family is younger and has a fresher supply chain
  risk profile.
- **Verdict.** Interesting as a **parallel** target, not a
  replacement. A `firmware-rp2040/` alongside `firmware/` would let
  contributors pick.

### 7.2  Arduino Nano "breadboard try-before-you-buy" target

A stripped-down firmware that runs on an Arduino Nano with a single
MOSFET and a boost module, producing mist on a benchtop without any
PCB fabrication. Aimed at people who want to validate the concept in
an evening before committing to JLCPCB. Fires the NCO via AVR
Timer1/OC1A at ~100 kHz.

- **Pros.** On-ramp for hobbyists.
- **Cons.** Divergent codepath, more maintenance. Probably not worth
  it unless the project wants to broaden its audience.

### 7.3  WiFi-connected variant (ESP32-C3) for treatment logging

Log every treatment (start time, resonance frequency found, elapsed
duration, battery at start, dry-cup trigger vs manual stop) to a
local MQTT broker or a file on SD. For a chronic-care nursery use
case, that's a real clinical-value add.

- **Pros.** Observability. Lets a parent or care team notice "cup is
  getting less efficient" before the mesh fully fails.
- **Cons.** Wildly out of scope for v3.1. Security becomes a concern.
  Probably a v5 discussion.

### 7.4  Sell pre-assembled kits

Nothing about this project would be hard to fulfill at ~$60/unit as
a kit including a flashed PCB, printed parts, and all cables. There's
demand — Aerogen Pro-X at $2,700 has priced out most home users. But
taking money for a medical-adjacent device opens FDA/CE/liability
questions that aren't worth touching as an individual maintainer.
Note it exists, don't pursue it.

 — Concrete Per-Unit Savings

Starting from v3.1's ~$60 midpoint BOM with character OLED:

| Change | Before | After | Saving |
|--------|-------:|------:|-------:|
| SSD1306 OLED (§2.1) | $25 | $3 | **−$22** |
| All-JST-XH + all-M3 kits (§2.2) | $8 | $3 | **−$5** |
| Panelize 5 boards → 10 in one JLCPCB order | $14/board | $11/board | **−$3/board** |
| USB-C PD trigger in place of MT3608 (§2.5) | $2 | $2 | $0 direct, but removes the mis-calibration failure mode |
| Drop the vendored AppImage | — | — | No $ saving, but 40 MB clone saving |
| **Net per-unit savings if you do §2.1 + §2.2 + panelize** | | | **~$30 / unit** |

Put differently: the **same budget** that bought 5 v3.1 units now
buys 10.

## 4. Speed-to-Build — Friction Inventory

Actual wall-clock time for a first-time builder, broken down:

| Step | Today | With the proposals |
|------|------:|-------------------:|
| MPLAB X + XC8 install | ~45 min | 0 (use pre-built `.hex`, §2.3) |
| OpenSCAD install + render | ~20 min | 0 (use pre-rendered STL, §2.3) |
| MT3608 trim-pot calibration | ~10 min + a multimeter | 0 (USB-C PD trigger, §2.5) |
| JLCPCB lead time | 4–10 business days | unchanged |
| 3D print base + lid + plug | 3 × separate queues | 1 plate print (§2.7) |
| PIC flash via Snap | ~2 min | unchanged |
| Enclosure assembly | ~30 min | unchanged |

**Before:** roughly 2 hours active work + 1 week lead time for a
first build, assuming nothing goes wrong.

**After §2.3 alone:** 1 hour active work + 1 week lead time. The
"download MPLAB" yak is gone for casual builders.

## 5. Safety-Robustness Additions

These are additive to existing safety features, not replacements.

### 5.1  Absolute-max treatment-time cap regardless of mode

`TREATMENT_MODE_CONTINUOUS` runs until button-press, dry-cup
detection, or battery cutoff. That's correct **when those detections
fire.** In the (low-probability) case where the cup is wet but low-
fill and the dry-cup detection is marginal, the treatment could run
indefinitely.

Add an absolute ceiling:

```c
/* firmware/src/config.h — new */
#define TREATMENT_HARD_MAX_SEC   3600   /* 60 min absolute cap, any mode */
```

In `main.c`, the treatment-time tick comparison already exists in
TIMED mode — just also run it in CONTINUOUS with `TREATMENT_HARD_MAX_SEC`.
Fewer than 20 LOC and meaningful defense-in-depth.

### 5.2  VBOOST overvoltage trip (MODULE mode)

If the MT3608 trim-pot drifts or is bumped, the boost output can
swing up to ~28 V. The PZT can be damaged or depolarised at those
levels. You already read VBOOST via `ADC_CH_BOOST_VFDBK` for the
"Vboost too low" diagnostic — also trip on "Vboost too high."

```c
/* in sweep.c / main.c VBOOST check path */
if (boost_v_adc > BOOST_VFDBK_MAX_ADC) {
    lcd_show_error("VBOOST HIGH", "Check trim pot");
    state = STATE_ERROR;
    /* Don't start sweep; PZT protection */
}
```

Pick `BOOST_VFDBK_MAX_ADC` at ~15 V scaled through R5/R8 — leaves
margin above nominal 12 V but trips cleanly below any level
concerning for the PZT.

### 5.3  Resonance-implausibility guard

The firmware currently accepts any peak above `RESONANCE_THRESHOLD`
anywhere in the sweep range. If EMI or ADC noise produces a false
peak at, say, 91 kHz for an Aerogen Solo cup (which resonates ~128
kHz), the controller happily "locks" and drives the PZT off-resonance,
heating the mesh without producing mist.

Add a plausibility window: reject peaks that fall outside
`[PLAUSIBLE_MIN_HZ, PLAUSIBLE_MAX_HZ]` (per-brand) or outside ±10 kHz
of the cached frequency if one exists. Prompts a full re-sweep
instead of a bad lock.

### 5.4  Power-on self-test

On boot, before the first button press:

1. Measure VDD (you already do this)
2. Measure VBOOST (already supports this)
3. Drive NCO at a low-duty known frequency for 10 ms with no cup and
   confirm current-sense stays below an idle threshold

If any check fails, splash screen shows `SELFTEST FAIL` with a code
rather than silently proceeding. ~40 LOC.



Each idea here has a **trade-off** named explicitly. None are free.

### 2.1  Replace character OLED with SSD1306 0.96" I²C OLED  *(recommended)*

**Current.** Winstar WEH001602A or Newhaven NHD-0216AW character
OLED + PCF8574 backpack: ~$22–28 per unit.

**Proposed.** Generic SSD1306 0.96" 128×64 monochrome OLED, I²C
0x3C: ~$3 per unit.

| Dimension | Character OLED | SSD1306 |
|-----------|---------------|---------|
| Unit cost | $22–28 | ~$3 |
| Voltage range | 3.0–5.5 V | 3.3–5 V (works down to ~3.0 V on most modules) |
| Readable in dark | ✔ | ✔ (self-emissive) |
| I²C, same PCB header | ✔ | ✔ |
| Info density | 32 chars, 2 lines | Full graphics — frequency dial, SOC bar, waveform |
| Firmware cost | Existing ~280 LOC in `lcd.c` | +200 LOC for a minimal font + primitives, *or* reuse a public SSD1306 driver |
| LCD-fallback path | HD44780 option exists | Would be a separate `#if LCD_IS_OLED == 2` branch |

**Trade-off.** More firmware code (rendering, font table). Worth it:
saves > $20 every build and opens the door to a live frequency graph /
battery curve on the lid.

**Safety note.** SSD1306 draws more current than a character LCD (full
screen ~20 mA). That's still < 1 % of a treatment-cycle budget, so
battery runtime is unaffected.

### 2.2  Standardise connector families: all JST-XH, all M3

**Current.** The BOM mixes JST-XH (cup, boost) with JST-PH (battery),
and M2.5 (PCB mount) with M3 (LCD mount). Two cable kits, two screw
kits, two crimp pin types.

**Proposed.**

- All JST-XH, everywhere. The battery header becomes JST-XH 2-pin with
  the same 2.5 mm pitch as the others. JST-XH is rated to 3 A vs
  JST-PH's 2 A — better margin for the 500 mA peak cup draw anyway.
- All M3 screws. Widen the PCB mount holes from 2.7 mm (M2.5 clearance)
  to 3.2 mm (M3 clearance). One screw pack, one driver tip.

**Savings.** ~$5 per first build (one fewer kit), and the end-of-build
"I have the wrong screw in my hand" moment goes away.

**Trade-off.** JST-PH is slightly smaller — if your enclosure is
already tight at the battery bay, verify the JST-XH header fits in the
x-y footprint. It should: JST-XH is ~7.5 × 5.5 mm vs JST-PH's
~5.0 × 4.0 mm per 2-pin module.

### 2.3  Pre-rendered STL + pre-built `.hex` as GitHub Release artifacts

**Current.** Every builder must:

- Install OpenSCAD (~100 MB) to render three STLs
- Install MPLAB X (~1.5 GB) + XC8 (~500 MB) to produce one `.hex`

The firmware is entirely driven by `config.h` defaults for the
turnkey build — most builders never edit a line of C.

**Proposed.** On every tagged release, CI produces:

- `nimbus_enclosure_base.stl`, `nimbus_enclosure_lid.stl`,
  `aerogen_connector_plug.stl` rendered from the committed SCAD
- `nimbus_default_v3.1.hex` built with default `config.h`
- Bundled as a GitHub Release under `v3.1`

**Savings.** Removes a 2 GB install for non-modifying builders. First-
build wall-clock time drops by ~1 hour.

**Trade-off.** Anyone wanting a non-default `SWEEP_FREQ_MAX_HZ`,
`TREATMENT_MODE`, or `LCD_IS_OLED` still needs the toolchain — that's
fine. Document "default build is in Releases, build from source if you
need to change `config.h`."

### 2.4  Containerise the firmware build  *(alternative to 2.3 for source modifiers)*

**Current.** A builder who *does* want to change `config.h` goes
through a ~45 minute Microchip account + MPLAB X + XC8 installation.

**Proposed.** A `Dockerfile` at `firmware/Dockerfile` that installs
XC8 inside a container. Then:

```bash
docker build -t nimbus-fw firmware/
docker run --rm -v $PWD/firmware:/src nimbus-fw make
```

Microchip's XC8 installer is Linux-capable and works fine headless.
The PIC Snap still has to run on the host (USB passthrough), but
compilation is the 45-minute step, not flashing.

**Trade-off.** XC8's license terms for redistribution must be read
carefully before publishing the Dockerfile. Distributing the installer
is typically forbidden; distributing a Dockerfile that *downloads* it
at build time is typically fine.

### 2.5  Eliminate the boost converter with a USB-C PD trigger  *(bigger bet)*

**Current.** USB → LiPo → MT3608 boost module @ manually-tuned 12 V →
output stage. The MT3608 trim-pot adjustment is the single
most-common first-build error (set the trim wrong, get no mist and
scratch your head).

**Proposed.** In wall-powered mode, drive the output stage directly
from a USB-C PD trigger module (CH224K, IP2721, etc.). Any modern
20 W+ USB-C PD wall brick negotiates 12 V ± 5 % — better than a
hand-tuned trim-pot. Module is ~$2.

Keep the LiPo + TP4056 path for portable operation, but add a diode-
OR so USB-C-PD power takes priority when plugged in:

```
   USB-C PD ──── 12 V ────┬─── Output stage
                          │
   LiPo ── MT3608 ── 12 V ┘
```

**Savings.** Removes one manual calibration step. Moves the nursery
use case (device plugged in overnight) to a factory-tight 12 V supply.

**Trade-off.** Architectural change. Needs PCB rev. Worth doing at
the same time as the SSD1306 swap if you're going to respin the board
anyway.

### 2.6  Collapse the TP4056 + DW01A + MT3608 chain into a single IP5306  *(bigger bet)*

**Current.** Three modules in the battery path: charging IC + protection
IC + boost IC. All cheap but all discrete.

**Proposed.** IP5306 (the chip inside every $5 USB power bank) does
charge + over/under-voltage protection + step-up to 5 V in one
package. Pair with a second small boost from 5 V to 12 V *or* drive
the output stage at 5 V with a different LC tuning.

**Trade-off.** This is a clean-sheet rewrite of the power path. It
collapses three modules to one and makes the BOM stupider-simple, but
it abandons the AN2265 reference inheritance on the charger side.
Only worth it if you're already rev'ing the PCB.

### 2.7  Ship one print file that stages base + lid + plug on one plate

**Current.** Three separate SCAD → STL files. Three separate
print-job setups.

**Proposed.** Add `hardware/enclosure/plate.scad` that imports all
three parts oriented flat and spaced for a single 220 × 220 mm print
bed. One click, one print.

**Trade-off.** Someone with a smaller bed (e.g., Prusa Mini at
180 × 180 mm) still needs the individual files — keep them.



### 1.1  Root-directory cleanup

The repo root currently holds 2.6 MB of mixed binary assets alongside
governance docs:

```
connector_plug.png               65 KB   ← move to docs/images/
nimbus_enclosure.png            108 KB   ← move to docs/images/
nimbus_enclosure_lid.png        113 KB   ← move to docs/images/
vibrating_mesh_nebulizer_design.pdf   2.3 MB  ← move to docs/references/
Nebulizer Reference Design/     9.6 MB  ← rename (drop space), move to references/
hardware/openscad/…AppImage     39 MB   ← delete, publish as release asset
```

Why it matters: a first-time visitor landing on GitHub sees 12+ top-
level items of very uneven importance. The AppImage alone makes clones
40 MB heavier than they need to be — `hardware/README.md` already
flags this; just do it.

Proposed layout:

```
/
├── README.md
├── DISCLAIMER.md   SECURITY.md   CONTRIBUTING.md   LICENSE   CHANGELOG.md
├── docs/
│   ├── images/               (PNGs currently at root)
│   ├── references/           (AN2265 PDF + the vendored reference bundle)
│   ├── BUILD_GUIDE.md  JLCPCB_ORDERING_GUIDE.md  DIAGRAMS.md
│   ├── BOM_TURNKEY.csv  SHOPPING_LIST.md  IMPROVEMENTS.md
│   ├── GLOSSARY.md           (new — see §1.3)
│   └── CHOOSE_YOUR_PATH.md   (new — see §1.4)
├── firmware/
└── hardware/
```

### 1.2  "Choose your path" decision doc

The README's Quick Start assumes JLCPCB turnkey. That's the right
default — but someone arriving with an existing breadboard or with no
3D printer wants a decision aid, not a guess-and-backtrack through
seven docs.

A short decision matrix at root or in `docs/CHOOSE_YOUR_PATH.md`:

| Starting point | Recommended path | Time to first mist |
|----------------|-----------------|-------------------:|
| Nothing but a laptop | JLCPCB turnkey + home-print *or* JLCPCB 3D print service | ~1 week (lead time) |
| Own 3D printer, no soldering | JLCPCB turnkey (PCB only), home-print adapter/enclosure | ~1 week |
| Soldering iron + protoboard skills | Hand-solder the AN2265 SOIC-28 board | ~1 weekend |
| "Just want to see it work" | Breadboard + DIP PIC16F1713 from DigiKey | ~1 evening |

### 1.3  Add `docs/GLOSSARY.md`

Every acronym used across the docs defined in one place. At minimum:
PZT, VMN, MMAD, NCO, CWG, HEF, FVR, SOC, ICSP, MPLAB, XC8, HD44780,
WS0010, US2066, PCF8574, JST-XH, JST-PH, TP4056, DW01A, MT3608, DAC,
ADC, DIP/SOIC, FR-4, HASL, SMT/SMD.

### 1.4  Single source of truth for cost numbers

Cost tables appear in README.md, BUILD_GUIDE.md, BOM_TURNKEY.csv, and
JLCPCB_ORDERING_GUIDE.md — I counted four slightly-different versions.
Pick one canonical table (the CSV or a new `docs/COSTS.md`), and have
the others link to it. This drifts every time prices change.

### 1.5  Images referenced from the README

The three PNGs currently at root are not visibly embedded in any
markdown doc I can see. If they're rendered OpenSCAD previews, embed
them in `README.md` under a "Gallery" section so they justify their
presence. Otherwise delete.

### 1.6  Surface the test harness

`firmware/tests/` is excellent but almost invisible from the README.
A one-line "This project has host-side unit tests — see
`firmware/tests/README.md`" near the Repository Structure section
flags the quality bar for new contributors.

### 1.7  Consider a top-level `Makefile` or `justfile`

Common flows — `build-firmware`, `build-stls`, `test`, `lint`, `clean`
— are currently spread across `firmware/Makefile`,
`firmware/tests/Makefile`, shell invocations of `openscad`, and
`pre-commit run`. A single top-level entrypoint (`make firmware`,
`make stl`, `make test`, `make check`) is the single strongest onboarding
signal in an open repo.


