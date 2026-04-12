# Controller Design Diagrams

Visual guides to how the vibrating mesh nebulizer controller works. These diagrams render automatically on GitHub.

---

## Controller State Machine

How the controller moves between states from power-on to nebulization:

```mermaid
stateDiagram-v2
    [*] --> IDLE : Power on

    IDLE --> SWEEP : Button press

    SWEEP --> RUNNING : Resonance found
    SWEEP --> ERROR : No resonance\n(no cup?)

    RUNNING --> IDLE : Button press (manual stop)
    RUNNING --> IDLE : Dry cup detected\n(auto-stop)
    RUNNING --> IDLE : Timer expired\n(timed mode only)
    RUNNING --> SWEEP : Narrow re-sweep failed\n(full re-sweep needed)

    ERROR --> IDLE : Button press (retry)

    note right of IDLE : Red LED solid
    note right of SWEEP : Green LED blinking
    note right of RUNNING : Green LED solid
    note right of ERROR : Red LED blinking
```

---

## Circuit Block Diagram

How power and signals flow through the controller:

```mermaid
flowchart LR
    subgraph POWER ["Power Supply"]
        BAT["Battery / USB\n4.5-5V"] --> FUSE["1A Fuse"]
        FUSE --> BOOST["Boost Converter\n(discrete or module)"]
        BOOST --> VBOOST["VBOOST\n10-20V DC"]
    end

    subgraph MCU ["PIC16F1713"]
        NCO["NCO\n90-150 kHz"] 
        ADC["ADC\n10-bit"]
        LOGIC["State Machine\n+ Sweep Algorithm"]
    end

    subgraph OUTPUT ["Output Stage"]
        Q4["Q4 MOSFET\n(IRLML0100)"]
        LC["LC Circuit\nL2+L3+C7"]
        PZT["PZT Cup\n(Aerogen Solo)"]
    end

    subgraph SENSE ["Feedback"]
        ISENSE["Current\nSense R18"]
        VPEAK["Peak Voltage\nDetector"]
    end

    NCO -->|Square wave| Q4
    VBOOST --> Q4
    Q4 --> LC
    LC --> PZT
    PZT --> ISENSE
    LC --> VPEAK
    ISENSE -->|AN1| ADC
    VPEAK -->|AN2| ADC
    ADC --> LOGIC
    LOGIC --> NCO
```

---

## Frequency Sweep Algorithm

How the controller finds the PZT's resonant frequency:

```mermaid
flowchart TD
    START(["Button Pressed"]) --> CACHE{"Cached frequency\nin flash?"}

    CACHE -->|"Yes"| NARROW["Narrow sweep\n+/- 3 kHz around cache\n~150 ms"]
    CACHE -->|"No"| FULL["Full sweep\n90-150 kHz in 500 Hz steps\n~2.4 sec"]

    NARROW -->|"Peak above\nthreshold"| FOUND["Resonance Found"]
    NARROW -->|"No peak"| FULL

    FULL -->|"Peak above\nthreshold"| FOUND
    FULL -->|"No peak"| NOCUP["ERROR:\nNo cup detected"]

    FOUND --> SAVE["Save frequency\nto flash cache"]
    SAVE --> LOCK["Lock NCO onto\npeak frequency"]
    LOCK --> RUN(["Start Nebulizing"])

    NOCUP --> BLINK(["Blink red LED\nWait for retry"])

    style FOUND fill:#2d6,color:#fff
    style NOCUP fill:#d33,color:#fff
    style RUN fill:#2d6,color:#fff
```

---

## Treatment Session Flow

What happens during a complete nebulization session:

```mermaid
flowchart TD
    IDLE(["IDLE\nRed LED solid"]) -->|"Button\npress"| SWEEP["Frequency Sweep\n(~150 ms cached,\n~2.4 sec full)"]
    SWEEP -->|"Found"| NEB["Nebulizing\nGreen LED solid"]

    NEB --> TICK{"Every\n5 seconds"}
    TICK -->|"Current OK"| NEB
    TICK -->|"Current\ndropped"| DRIFT{"Below dry-cup\nthreshold?"}

    DRIFT -->|"No, just drift"| RESWEEP["Narrow Re-sweep\n~150 ms"]
    DRIFT -->|"Yes, sustained\n3 seconds"| DRY(["DRY CUP\nAuto-stop"])

    RESWEEP -->|"Re-locked"| NEB
    RESWEEP -->|"Failed"| FULLSWEEP["Full Re-sweep\n~2.4 sec"]
    FULLSWEEP -->|"Found"| NEB
    FULLSWEEP -->|"Failed"| ERR(["ERROR\nCup removed?"])

    NEB -->|"Button press"| STOP(["MANUAL STOP"])
    NEB -->|"Timer expired\n(timed mode)"| DONE(["TREATMENT\nCOMPLETE"])

    style DRY fill:#f90,color:#fff
    style STOP fill:#69c,color:#fff
    style DONE fill:#2d6,color:#fff
    style ERR fill:#d33,color:#fff
```

---

## Resonance Detection Concept

Why the frequency sweep works — the PZT draws maximum current at its resonant frequency:

```mermaid
flowchart LR
    subgraph BELOW ["Below Resonance"]
        B1["Drive at 100 kHz"] --> B2["Low current\n(high impedance)"]
        B2 --> B3["Weak vibration\nNo mist"]
    end

    subgraph AT ["At Resonance (~128 kHz)"]
        A1["Drive at 128 kHz"] --> A2["Peak current\n(min impedance)"]
        A2 --> A3["Strong vibration\nFine mist!"]
    end

    subgraph ABOVE ["Above Resonance"]
        C1["Drive at 145 kHz"] --> C2["Low current\n(high impedance)"]
        C2 --> C3["Weak vibration\nNo mist"]
    end

    style AT fill:#e8f5e9,stroke:#2d6
    style A3 fill:#2d6,color:#fff
```

---

## Power Path

How the boost module provides high-voltage DC to the output stage:

```mermaid
flowchart LR
    INPUT["USB 5V\nor\n3x AAA 4.5V"] --> FUSE["1A\nFuse"]
    FUSE --> MODULE["MT3608/XL6009\nBoost Module"]
    MODULE --> VBOOST["VBOOST\n~12V DC"]
    VBOOST --> OUTPUT["Output Stage\n(LC Circuit + PZT)"]
    TRIM["Trim pot\n(set once)"] -.->|"Voltage\nadjust"| MODULE

    style MODULE fill:#e8f5e9
```

---

## ADC Feedback Signals

What the MCU measures during operation:

```mermaid
flowchart TD
    subgraph SIGNALS ["ADC Channels"]
        AN1["AN1 (pin 3)\nOutput Current"]
        AN2["AN2 (pin 4)\nPeak Voltage"]
    end

    subgraph USAGE ["What They Tell Us"]
        U1["PRIMARY: Resonance\ndetection + dry cup"]
        U2["Output waveform\namplitude"]
    end

    AN1 --> U1
    AN2 --> U2

    style AN1 fill:#2d6,color:#fff
    style U1 fill:#2d6,color:#fff
```

**AN1 (output current) is the most important signal.** It's how the controller finds resonance, tracks resonance drift, and detects a dry cup. The sweep algorithm measures this at each frequency step — the frequency with the highest AN1 reading is the resonant frequency. (AN0 and AN3 are used only in discrete boost mode and are unused in the turnkey build.)

---

## Mechanical: What Happens Inside the Cup

```mermaid
flowchart TD
    A["PZT Ring\n(piezoelectric ceramic)"] -->|"Driven at\nresonant freq\n~128 kHz"| B["Ring vibrates\nin flexural mode"]
    B --> C["Perforated mesh\n(bonded to ring)\nvibrates up/down"]
    C --> D["Liquid forced through\n~3000 laser-drilled holes\n(~4 um diameter)"]
    D --> E["Fine aerosol\nMMAD ~3.4 um\n(reaches deep lung)"]

    F["Medication loaded\ninto cup reservoir"] --> D

    style E fill:#2d6,color:#fff
```

The two exposed contacts on the Aerogen Solo cup connect directly to the PZT ring. There's no polarity — it's an AC device. The controller's job is simply to generate the right frequency and voltage to make the ring vibrate optimally.
