# Contributing to Nimbus Nebulizer Controller

Thanks for your interest in improving this project. Because this is an
educational hardware project that drives a device used near patients, we
care about safety as much as code quality. Please read [DISCLAIMER.md](DISCLAIMER.md)
and [SECURITY.md](SECURITY.md) before contributing.

## Reporting Issues

**Use GitHub Issues for:** bug reports, feature requests, build problems,
documentation gaps, hardware compatibility reports.

**Do NOT use GitHub Issues for safety vulnerabilities** that could harm
a user (e.g. uncontrolled boost output, missing battery cutoff, runaway
treatment timer). Report these privately — see [SECURITY.md](SECURITY.md).

When filing a bug, include:

- Hardware revision (PCB rev or breadboard)
- Firmware version (`FIRMWARE_VERSION` in `firmware/src/config.h`)
- Cup brand/model
- Programmer used (Snap, PICkit 4/5)
- Steps to reproduce, expected vs. actual behaviour
- Serial debug output if available (`UART_ENABLED = 1` in `config.h`)

The issue templates in `.github/ISSUE_TEMPLATE/` will prompt for these.

## Pull Request Process

1. Fork and create a feature branch off `main`.
2. Make focused, single-purpose changes — split unrelated work into separate PRs.
3. Run the local checks (see below) before pushing.
4. Open a PR using the template in `.github/pull_request_template.md`.
5. CI must pass (firmware static analysis, OpenSCAD render, markdown lint).
6. A maintainer will review. Hardware and firmware changes get extra scrutiny.

### What goes in which area

| Area | Path | What changes here |
|------|------|-------------------|
| Firmware | `firmware/src/` | C source for the PIC16F1713 |
| Hardware | `hardware/` | KiCad files (when added), 3D models, wiring docs |
| Docs | `README.md`, `docs/`, `*.md` | User-facing documentation |
| CI | `.github/workflows/` | Build/lint pipelines |

## Local Checks

Install [pre-commit](https://pre-commit.com/) and the project hooks:

```bash
pip install pre-commit
pre-commit install
```

After that, every `git commit` runs:

- `markdownlint-cli2` on Markdown files
- `cppcheck` on changed firmware sources
- Trailing whitespace / large file / merge marker checks

You can run the full suite manually any time:

```bash
pre-commit run --all-files
```

To validate OpenSCAD models locally:

```bash
openscad -o /tmp/out.stl hardware/enclosure/controller_enclosure.scad
```

To build the firmware locally (requires Microchip XC8):

```bash
make -C firmware            # produces firmware/build/nebulizer.hex
```

## Code Style

### Firmware (C)

- Target: PIC16F1713 with XC8 in free mode.
- Follow the existing style: 4-space indent, `snake_case` for functions and
  variables, `UPPER_SNAKE_CASE` for macros.
- Keep `config.h` the single source of truth for tunable parameters.
- Don't introduce `malloc` / `free` — this MCU has 1 KB of RAM.
- Prefer `const` lookup tables over runtime computation where it saves cycles.
- Suppress cppcheck findings inline only with justification:

  ```c
  /* cppcheck-suppress unusedFunction ; called from ISR */
  ```

### OpenSCAD

- Pull shared dimensions from `hardware/enclosure/enclosure_config.scad`.
- Use `$fn` only inside leaf modules; set the global facet count via a
  top-level variable so renders stay reproducible in CI.
- Keep modules pure — no `echo()` side effects in committed code.

### Markdown

- Wrap is off (`MD013 = false`); use logical line breaks instead.
- Don't reuse the same heading at the same level inside one document.

## Testing Expectations

- **Firmware:** unit tests live under `firmware/tests/` and run on the host
  with the standard system compiler. Add or extend tests when you touch
  pure-logic code (sweep math, battery state, LCD formatting). Hardware
  register code is exempt — gate it behind `#ifdef PIC16F1713`.
- **Hardware/OpenSCAD:** open the affected `.scad` file, render (F6), and
  confirm no errors in the OpenSCAD console. CI does the same.
- **Manual smoke test:** for firmware changes, flash and run at least one
  full sweep + treatment + dry-cup-detect cycle on real hardware before
  marking the PR ready.

## Commit Messages

Use short, imperative subjects (≤ 72 chars). Reference issue numbers when
relevant. Example:

```
sweep: widen narrow re-sweep range to ±5 kHz

Aerogen Solo cups drift ~3 kHz with full medication load. The previous
±3 kHz window forced a full re-sweep mid-treatment. Closes #42.
```

## License

By contributing, you agree that your contributions are licensed under the
MIT License (see [LICENSE](LICENSE)).
