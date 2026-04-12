# Changelog

All notable changes to this project will be documented in this file.

## [3.1] — 2026-04-12 (updated 2026-04-12)

Quality-of-life build for daily nursery use: rechargeable cell, USB-C
charging, and a status display.

### Added
- 1S LiPo pouch cell (103450, ~2000 mAh) powering MCU + boost module
  directly (3.0-4.2 V rail)
- TP4056 + DW01A USB-C charging module with over-charge, over-discharge
  and short-circuit protection
- 16x2 character display driver (`firmware/src/lcd.c`) with bit-bang
  I2C over RC4/RC5 and auto-probing PCF8574 backpack address
- `LCD_IS_OLED` config flag — same driver handles cheap HD44780 LCDs
  (~$3) and premium character OLEDs like Winstar WEH001602, Newhaven
  NHD-0216AW, and Matrix Orbital MOP-AO162 (~$25)
- Battery monitoring via the PIC's Fixed Voltage Reference — reads VDD
  with zero external parts (`peripherals.c::battery_read_mv`)
- Piecewise-linear LiPo state-of-charge curve
- Soft battery cutoff at 3.1 V — warns the user and auto-stops any
  running treatment before the DW01A hardware cutoff trips
- Splash screen showing firmware version on power-up
- Status line showing state + resonant frequency, and battery percent +
  elapsed time while running
- `enclosure_config.scad` — shared dimensions used by both base and
  lid SCAD files
- `controller_enclosure_lid.scad` — separate lid file with a 16x2
  viewing window, four M3 standoffs and a wire-pass slot
- LiPo + TP4056 bay in the enclosure base with USB-C aperture on the
  front wall and an internal shelf that stacks the TP4056 above the
  pouch cell
- New BOM rows and cost estimates for the LiPo, TP4056, and display
  options (~$30-45 with LCD, ~$45-70 with character OLED)

### Changed
- `controller_enclosure.scad` now renders only the base and `include`s
  the shared config file. PCB component clearance bumped from 12 mm to
  18 mm so the LCD backpack has room to hang down from the lid.
- PCB USB-C receptacle replaced with a JST-PH BAT IN header — the
  USB-C port now lives on the TP4056 module
- RC4/RC5 reassigned from "unused" to software I2C for the display
- Firmware banner bumped to v3.1
- Build guide rewritten with new steps for LiPo bay prep, display
  mounting, and a first power-up sequence that includes the splash
  and status screens

### Changed (post-audit)
- Device named **Nimbus Nebulizer Controller**. LCD splash, UART banner,
  README title, and build guide updated. Filenames and branch unchanged.
- `LCD_IS_OLED` now defaults to `1` (character OLED). Character OLEDs
  operate down to 3.0 V, matching the full LiPo discharge range. The cheap
  HD44780 LCD remains supported via `LCD_IS_OLED = 0`.

### Fixed
- ICSP cutout Y-coordinate bug in `controller_enclosure.scad` that
  mixed X and Y values
- **Elapsed-time drift** — `TICKS_PER_SEC=8` made the display 4.8% fast
  (30 min session showed 30:00 at only 28:34 elapsed; TIMED mode ended
  86 s early). Replaced with `TIMER1_MS_PER_TICK=131` integer arithmetic
  for < 0.1% error.
- **Boost voltage diagnostic** — in `BOOST_MODE_MODULE`, a failed
  frequency sweep now reads the AN3 boost-feedback ADC. If the reading
  is below `BOOST_VFDBK_MIN_ADC` (default 50 counts), the UART prints
  `ERROR: Vboost too low — check module` and the display shows
  `ERR Vboost low / Check boost mod` instead of the generic `ERR no cup`.
- **Battery sag false-trip** — a single below-threshold battery sample
  during a high-load draw could latch `batt_critical_latched` and abort
  the treatment prematurely. Now requires two consecutive sub-`BATTERY_CRIT_MV`
  readings before the flag latches.
- **`BATTERY_ENABLED=0` display** — `lcd_show_battery(0, 0, 0xFFFF)` was
  called unconditionally, showing "Bat 0% 0.00V" in headless builds. Line 2
  is now left unchanged when battery monitoring is disabled.

## [3.0] — 2026-04-12

Consolidated to a single turnkey build path. No more choosing between build tiers.

### Added
- JLCPCB pre-assembled PCB option (~$15-25/board)
- 3D-printable controller enclosure with battery compartment
- 3D-printable Aerogen Solo connector plug (pogo pin contact)
- Universal adapter template for other VMN cup brands
- Dry-cup auto-stop detection (shuts down when cup is empty)
- Frequency caching to flash (near-instant startup with same cup)
- Smart narrow re-sweep for resonance drift (~150ms vs 2.4s full sweep)
- JLCPCB ordering guide with step-by-step walkthrough
- Mermaid state machine, block, and signal flow diagrams
- Build quality and nursery durability guide
- GitHub Actions CI (static analysis, docs linting, OpenSCAD validation)

### Changed
- Default treatment mode changed from TIMED to CONTINUOUS
- Default treatment time increased from 600s to 1800s
- Boost mode defaults to MODULE (pre-built MT3608) instead of DISCRETE
- Firmware version string updated to v3.0

## [2.0] — 2026-02-15

Simplified controller with continuous treatment support.

### Added
- Continuous treatment mode for long nebulization sessions
- Boost module option (eliminates discrete boost components)
- UART debug output (optional, via MCP2221)

### Changed
- Simplified from three build tiers to two (breadboard + PCB)
- Reduced component count by ~40% with boost module option

## [1.0] — 2026-01-20

Initial release — complete breadboard build from scratch.

### Added
- Full frequency sweep algorithm (90-150 kHz)
- PIC16F1713 firmware with state machine (idle, sweep, run, error)
- Discrete boost converter with DAC-controlled feedback
- Timed treatment mode (10-minute default)
- Complete wiring guide and BOM
- Based on Microchip AN2265 reference design
