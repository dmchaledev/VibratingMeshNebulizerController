# Hardware

This directory holds everything needed to build the physical controller:
the wiring map, 3D-printable parts, and pointers to the schematic and
PCB sources.

## Contents

```text
hardware/
├── WIRING.md              ← Pin-by-pin reference for the breadboard build
├── adapters/              ← 3D-printable nebulizer cup connector
│   ├── README.md
│   ├── aerogen_connector_plug.scad
│   └── universal_adapter.scad
├── enclosure/             ← 3D-printable controller enclosure (split for v3.1)
│   ├── enclosure_config.scad     ← Shared dimensions for base + lid
│   ├── controller_enclosure.scad ← Base with LiPo + TP4056 bay
│   └── controller_enclosure_lid.scad
└── openscad/              ← Optional vendored OpenSCAD AppImage (Linux x86_64)
```

## Schematic and PCB Sources

The PCB this project ships against is the **Microchip AN2265 reference
design** with the modifications described in `docs/BUILD_GUIDE.md`. Two
ways to get the design files:

1. **Microchip / Arrow** — original reference design (PDF schematic,
   gerbers, BOM):
   - <https://www.microchip.com/en-us/solutions/medical/demonstrations-and-design-files/vibrating-mesh-nebulizer>
   - <https://www.arrow.com/en/reference-designs/vibrating-mesh-nebulizer-reference-design/f2a9476a8ee42cf52a40b74023c3b682227100c55cf2>
2. **JLCPCB-ready bundle** — see `docs/JLCPCB_ORDERING_GUIDE.md` for the
   pre-modified gerbers and a step-by-step ordering walkthrough.

Native KiCad sources (`.kicad_sch` / `.kicad_pcb`) for the v3.1 board
are **not yet** in this repo. Track <https://github.com/dmchaledev/VibratingMeshNebulizerController/issues>
for the open issue or open one if you'd like to help port the gerbers.

## Working with the OpenSCAD Models

Every printable part is a parametric `.scad` file. Two ways to render:

```bash
# GUI: open the file, F5 preview, F6 render, then File > Export > STL
openscad hardware/enclosure/controller_enclosure.scad

# Command line: produce an STL non-interactively
openscad -o /tmp/enclosure.stl hardware/enclosure/controller_enclosure.scad
```

Shared dimensions for the enclosure base and lid live in
`enclosure/enclosure_config.scad`. Edit those constants to retune both
parts at once instead of duplicating values.

CI renders every `.scad` in this directory on push (see
`.github/workflows/openscad.yml`). Files matching `*_config.scad` /
`*_common.scad` are treated as include-only and rendered indirectly by
their consumers — don't put a top-level `module` call in those files.

## About `openscad/OpenSCAD-2021.01-x86_64.AppImage`

A copy of the Linux OpenSCAD AppImage is vendored here for offline
builders. It is large (~40 MB) and not required if you've installed
OpenSCAD from your distribution's package manager or from
<https://openscad.org/downloads.html>.

> **Note:** vendoring binaries in Git inflates clone size for everyone.
> A future cleanup will move this into a release artifact instead. If
> you don't need the offline copy, install OpenSCAD via your package
> manager and ignore this directory.
