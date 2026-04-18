# Firmware Host-Side Unit Tests

These tests exercise the **pure-logic** parts of the firmware on the
build host (any C99 compiler — `gcc` or `clang`). They cover:

| Test file | What it verifies |
|-----------|------------------|
| `test_config_math.c` | The NCO ↔ Hz conversion macros in `config.h` |
| `test_battery.c` | `battery_percent()` SOC mapping in `peripherals.c` |
| `test_lcd_format.c` | `lcd_show_status()` and `lcd_show_battery()` formatting in `lcd.c` |

Hardware register access lives in `peripherals.c` and is **not**
covered here — those functions only run on the PIC. The convention is:

- A function with no PIC-specific dependencies (no `xc.h`, no SFR
  reads/writes) belongs in a host-testable form.
- Anything that touches `LATx`, `PORTx`, `ADCONx`, etc. lives behind a
  guard and is exercised on hardware only.

## Running the tests

From the repo root:

```bash
make -C firmware/tests          # build and run all tests
make -C firmware/tests clean
```

CI runs the same target via `.github/workflows/firmware-check.yml`.

## Pattern for adding a new test

1. Create `firmware/tests/test_<feature>.c`.
2. Use the helpers in `harness.h` (`TEST_EQ_U`, `TEST_TRUE`, `TEST_STR_EQ`).
3. Add the test name to the `TESTS :=` list in `Makefile`.
4. Each test program should `return 0` on success, non-zero on failure.

## Why some tests duplicate production code

`peripherals.c` and `lcd.c` include `<xc.h>` which only exists in the XC8
compiler toolchain, so they cannot be compiled directly with the host
compiler. To keep the test self-contained, two strategies are used:

- **Macro re-evaluation** (`test_config_math.c`): include `config.h`
  directly — it has no `<xc.h>` dependency.
- **Stubbed transclusion** (`test_battery.c`, `test_lcd_format.c`): the
  test file `#define`s out the hardware-only blocks, then `#include`s
  the production `.c` source so the **same** code under test runs.

If a refactor moves a tested function, update the include path in the
corresponding test rather than copying the implementation.
