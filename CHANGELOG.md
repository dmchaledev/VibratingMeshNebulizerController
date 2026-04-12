# Changelog

All notable changes to this project will be documented in this file.

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
