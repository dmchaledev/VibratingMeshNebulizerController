# Aerogen Solo DIY Controller — Breadboard Build

> **WARNING: THIS IS NOT AN FDA-APPROVED MEDICAL DEVICE.**
> This project is a research workaround for educational and investigational purposes only.
> It has not been evaluated, cleared, or approved by the FDA or any regulatory body.
> It is not intended to diagnose, treat, cure, or prevent any disease. Building and using
> this circuit is done entirely at your own risk. See [DISCLAIMER.md](DISCLAIMER.md) for
> full safety and legal information.

An open-source controller for vibrating mesh nebulizers, built on a breadboard for under $75. Based on [Microchip AN2265](https://static5.arrow.com/pdfs/2016/10/27/10/14/17/387/mcp_/manual/82300002265a.pdf) vibrating mesh nebulizer reference design.

## Why This Exists

The Aerogen Solo is a medical-grade vibrating mesh nebulizer used in ICUs and home ventilator circuits. The controller that drives it — the Aerogen Pro-X — costs **$2,700 out of pocket** and is not always covered by insurance. The nebulizer cup itself is ~$40 and has two simple electrical contacts: the leads of a piezoelectric ring. All the controller does is generate the right AC signal to make it vibrate.

This project provides everything you need to build a working controller on a breadboard using off-the-shelf parts from DigiKey, a $3 microcontroller, and free development tools from Microchip.

## How It Works

The Aerogen Solo cup contains a PZT (Lead Zirconate Titanate) piezoelectric ring bonded to a perforated stainless steel mesh. When driven at its resonant frequency (~90-150 kHz) with ~30-60 Vpp, the mesh vibrates and pushes liquid through thousands of laser-drilled holes, creating a fine aerosol (MMAD ~3.4 um).

The controller:
1. **Boosts** battery/USB voltage up to ~10-20V
2. **Generates** a high-voltage AC waveform at 30-60 Vpp
3. **Sweeps** frequency from ~90-150 kHz to find the PZT's resonant peak
4. **Locks** onto that frequency and runs until medication is nebulized

## Vibrating Mesh Nebulizer Compatibility

This controller drives a PZT piezoelectric ring at its resonant frequency — the same fundamental mechanism used by all vibrating mesh nebulizers. The frequency sweep approach means it is **not hard-coded to a single device** and can, in principle, find the resonant frequency of any PZT-based mesh nebulizer cup.

| Brand | Product Line | Likely Compatible | Notes |
|-------|-------------|:-----------------:|-------|
| **Aerogen** | Solo, Solo with Pro-X | Yes | Primary target of this project. ~128 kHz typical resonance. |
| **OMRON** | MicroAir (U22, U100) | Likely | Uses PZT mesh, similar frequency range. Different cup form factor — will need custom contact adapter. |
| **PARI Pharma** | eFlow / eFlow Rapid | Likely | PZT mesh design. Resonant frequency may differ — the sweep range in `config.h` may need widening. |
| **Philips Respironics** | InnoSpire Go | Possible | Vibrating mesh type. Limited public data on drive parameters. Test with caution. |
| **Drive DeVilbiss** | Aerogen-based devices | Yes | Several DeVilbiss ventilator-integrated nebulizers use Aerogen Solo cups internally. |

**Key caveats:**
- Each manufacturer's cup has a different mechanical form factor — you'll need to figure out how to make electrical contact with the two PZT leads for non-Aerogen cups
- Resonant frequencies vary by manufacturer and even unit-to-unit. The firmware sweeps 90-150 kHz by default; adjust `SWEEP_FREQ_MIN_HZ` and `SWEEP_FREQ_MAX_HZ` in `config.h` if your cup resonates outside that range
- Drive voltage requirements differ. **Always start with low voltage** and increase gradually
- This project has only been tested against Aerogen Solo cups. Compatibility with other brands is inferred from the shared operating principle, not from direct testing

## Repository Structure

```
├── README.md                 ← You are here
├── DISCLAIMER.md             ← Safety and legal notice (READ THIS FIRST)
├── docs/
│   ├── BUILD_GUIDE.md        ← Complete breadboard build guide
│   └── BOM.csv               ← Bill of materials (DigiKey part numbers)
├── firmware/
│   ├── README.md             ← How to compile and flash
│   └── src/
│       ├── main.c            ← Main program and state machine
│       ├── config.h          ← Tunable parameters (frequencies, voltages)
│       ├── peripherals.h     ← Peripheral function declarations
│       ├── peripherals.c     ← PIC16F1713 hardware initialization
│       ├── sweep.h           ← Frequency sweep declarations
│       └── sweep.c           ← Resonant frequency sweep algorithm
└── hardware/
    └── WIRING.md             ← Pin-by-pin wiring reference
```

## Quick Start

1. **Read [DISCLAIMER.md](DISCLAIMER.md)** — understand what you're building
2. **Order parts** from [docs/BOM.csv](docs/BOM.csv) — ~$38 without programmer, ~$73 with
3. **Wire the breadboard** following [hardware/WIRING.md](hardware/WIRING.md)
4. **Compile and flash** firmware per [firmware/README.md](firmware/README.md)
5. **First power-up** following the procedure in [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)

## Key Reference Documents

| Resource | Description |
|----------|-------------|
| [AN2265 Application Note (PDF)](https://static5.arrow.com/pdfs/2016/10/27/10/14/17/387/mcp_/manual/82300002265a.pdf) | Microchip's reference design this project is based on |
| [Microchip Demo Page](https://www.microchip.com/en-us/solutions/medical/demonstrations-and-design-files/vibrating-mesh-nebulizer) | Official source code download |
| [PIC16F1713 Datasheet](https://www.microchip.com/en-us/product/pic16f1713) | MCU datasheet |
| [Arrow Reference Design](https://www.arrow.com/en/reference-designs/vibrating-mesh-nebulizer-reference-design/f2a9476a8ee42cf52a40b74023c3b682227100c55cf2) | Arrow's page for the AN2265 design |
| [MDPI: Frequency & Voltage Effects](https://www.mdpi.com/2076-3417/11/3/1296) | Research on mesh nebulizer drive parameters |

## Estimated Cost

| Category | Cost |
|----------|------|
| All electronic components | ~$38 |
| Programmer (MPLAB Snap, one-time) | ~$35 |
| **Total** | **~$73** |

Most parts ship next-day from DigiKey.

## License

MIT — see [LICENSE](LICENSE).

*Based on Microchip AN2265 Rev B and publicly available research.*
