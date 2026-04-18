# Security and Safety Disclosure Policy

This project is **not** an FDA-approved medical device — see
[DISCLAIMER.md](DISCLAIMER.md). However, because people may build and use
this controller around themselves, family members, or patients, we treat
safety-impacting bugs as security issues and want to fix them quickly and
responsibly.

## Scope

We consider the following categories in scope for private disclosure:

- **Safety hazards in firmware** — uncontrolled boost output, missing
  battery cut-off, runaway treatment timer, ESD/over-current paths.
- **Safety hazards in hardware** — schematic or BOM errors that can
  expose users to mains voltage, cause battery thermal runaway, or
  expose live PZT contacts.
- **Build-guide errors** that can cause the above when followed literally.
- **Supply-chain risks** — credentials accidentally committed, malicious
  dependencies pulled by CI.
- **Repository compromise** — unauthorized writes, account takeovers.

Out of scope (please open a public GitHub Issue instead):

- Cosmetic bugs, typos, or non-safety functional bugs.
- Compatibility limitations with non-Aerogen cups.
- Performance optimizations that don't affect safety.

## How to Report

Please **do not** open a public GitHub Issue for safety or security
problems. Instead, use one of:

1. GitHub's private vulnerability reporting:
   <https://github.com/dmchaledev/VibratingMeshNebulizerController/security/advisories/new>
2. Email the maintainer listed in the repository's GitHub profile with
   the subject line `SECURITY: Nimbus Nebulizer`.

Include in your report:

- Affected firmware version, hardware revision, and configuration
- A clear description of the issue and the impact (what can go wrong?)
- Steps to reproduce, or a proof-of-concept circuit / log capture
- Whether you've already shared the report with anyone else
- How you'd like to be credited in the fix (or "anonymous" is fine)

## Our Response

- We aim to **acknowledge** new reports within 5 business days.
- We aim to **triage and confirm** within 14 days.
- We aim to **publish a fix and advisory** within 90 days of confirmation,
  earlier for actively exploitable safety issues.
- For high-severity safety issues we will publish a brief alert in
  `CHANGELOG.md` and pin a notice on `README.md` while a fix is in flight.

If you do not receive a response within 14 days, please escalate by opening
a (non-detailed) GitHub Issue saying "I sent a private security report on
DATE and have not heard back" — without disclosing the vulnerability.

## Coordinated Disclosure

We prefer coordinated disclosure: we'll work with you on a release date
and credit you in the advisory. Please give us a reasonable window before
publishing details. If there is active harm in the wild, we will move
faster.

## Hardening Notes for Builders

These are baked into the default firmware/hardware design, but if you
fork or modify, please preserve them:

- `BOOST_MAX_DAC` in `firmware/src/config.h` caps the boost feedback DAC.
- `BATTERY_CRIT_MV` triggers an auto-stop and refuses re-start until the
  battery recovers.
- `TREATMENT_TIME_SEC` enforces a hard upper bound on continuous runs.
- `DRY_CUP_THRESHOLD` / `DRY_CUP_CONFIRM_MS` shut down a dry mesh before
  it overheats.
- The DW01A on the TP4056 module provides hardware over-charge,
  over-discharge, and short-circuit protection independent of firmware.

If your modification weakens any of these, please document it loudly in
your fork's README.
