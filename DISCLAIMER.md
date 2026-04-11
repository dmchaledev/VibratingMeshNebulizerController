# Disclaimer and Safety Notice

## Read This Before You Build Anything

This project documents the construction of an electronic controller for a vibrating mesh nebulizer based on publicly available reference designs and datasheets. It is provided for **educational and informational purposes**.

## This Is Not a Medical Device

- This is **not** an FDA-cleared or CE-marked medical device
- It has **not** been tested or validated by any regulatory body
- It has **not** undergone electromagnetic compatibility (EMC) testing
- It has **not** been evaluated for electrical safety (IEC 60601)

## If You Build This

You are accepting personal responsibility for:

- **Verifying** the circuit operates correctly before connecting to a nebulizer cup
- **Testing** with normal saline first, never medication, until operation is stable and repeatable
- **Monitoring** the nebulizer cup temperature during operation — warmth indicates overdriving
- **Current-limiting** your power supply during development to prevent damage
- **Starting with low drive voltages** and increasing gradually — excess voltage can depolarize or crack the piezoelectric element
- **Keeping the circuit isolated** from any ventilator circuit during testing
- **Understanding** the electrical and clinical risks you are accepting

## Aerogen Solo Cup Lifespan

The Aerogen Solo cup has a manufacturer-specified 28-day intermittent-use life. This does not change with a DIY controller. Do not attempt to extend cup life beyond manufacturer specifications.

## Electrical Safety

- The boost converter in this circuit produces voltages up to 20V DC and the output stage generates 30-60 Vpp AC at ultrasonic frequencies
- While these voltages are not typically dangerous to adults, exercise standard electronics safety practices
- Never operate the circuit near water or conductive liquids other than what's in the nebulizer cup
- Keep the prototype away from children when powered

## Why This Exists

This project exists because the healthcare system sometimes fails people. When a child needs a $40 nebulizer cup driven by a simple AC signal, and the only legal way to get the controller costs $2,700 out of pocket, some parents have no choice but to learn the electronics themselves. This repository attempts to make that path as safe and informed as possible.

None of that changes the risks above. Be careful. Test thoroughly. When in doubt, ask for help.

## License

This project is released under the MIT License. The authors and contributors accept no liability for any damages arising from the use of this information. See [LICENSE](LICENSE).
