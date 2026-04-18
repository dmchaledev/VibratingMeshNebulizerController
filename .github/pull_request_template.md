<!-- Thanks for contributing! Please fill out the sections below. -->

## Summary

<!-- 1-3 sentences. What does this PR change and why? -->

## Type of change

- [ ] Bug fix (no API or hardware change)
- [ ] Firmware feature
- [ ] Hardware change (schematic, PCB, BOM, 3D model)
- [ ] Documentation only
- [ ] CI / build / tooling

## Areas touched

- [ ] `firmware/`
- [ ] `hardware/`
- [ ] `docs/` or top-level Markdown
- [ ] `.github/` workflows or templates

## Safety review

- [ ] This PR does not weaken any safety guard listed in `SECURITY.md`
      (boost cap, battery cutoff, treatment timer, dry-cup detect).
- [ ] If a guard *is* changed, the rationale is explained in the summary
      and `CHANGELOG.md` is updated.

## Verification

How did you verify the change? Tick everything that applies.

- [ ] `make -C firmware/tests` passes locally
- [ ] `cppcheck firmware/src/` is clean
- [ ] OpenSCAD models render without errors (F6 in the GUI or
      `openscad -o /tmp/x.stl path/to/file.scad`)
- [ ] `markdownlint-cli2 '**/*.md'` is clean
- [ ] Flashed to real hardware and ran a sweep + treatment cycle
- [ ] N/A (docs / tooling only)

## Notes for the reviewer

<!-- Anything you want the reviewer to focus on, follow-ups for later, etc. -->
