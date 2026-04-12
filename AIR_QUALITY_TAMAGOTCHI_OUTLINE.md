# Lost Rabbit Digital — Air Quality Tamagotchi: Product Outline

---

## Store Description

> **Meet your new air buddy.** The Lost Rabbit is a pocket-sized air quality companion that lives and breathes the air around you — literally. Watch your rabbit thrive in clean environments or wilt when pollution creeps in. Clean up your air, earn upgrades, and keep your rabbit happy. It's wellness, gamified.

---

## 1. Product Overview

**Product Name:** Lost Rabbit  
**Brand:** Lost Rabbit Digital  
**Category:** Consumer Electronics / Wellness / Lifestyle  
**Form Factor:** Rounded handheld device (~65 × 55 × 22 mm), silicone bumper shell, 3-button interface, color OLED display  
**Target Audience:** Health-conscious consumers, parents, indoor plant enthusiasts, urban dwellers, gamers who respond to habit loops

---

## 2. Core Concept

The Lost Rabbit combines a real-time multi-sensor air quality monitor with a persistent virtual pet. The rabbit character lives on the OLED screen and its health, mood, and evolution state are directly driven by the measured air quality in the user's environment. Poor air degrades the rabbit; clean air causes it to grow, gain accessories, and unlock new animations. A small set of user-triggered actions (opening a window prompt, toggling a fan reminder, logging a clean-air walk) add agency without overwhelming the user.

The device is **not a phone app** — it is a standalone ambient object, always on, always watching, always reacting. The physical presence is the point.

---

## 3. Air Quality Sensing Suite

| Sensor | Measures | IC / Module | Notes |
|---|---|---|---|
| Particulate Matter | PM1.0, PM2.5, PM10 | Sensirion SPS30 or PMS5003 | Laser particle counter; primary health metric |
| CO2 | Carbon dioxide (ppm) | Sensirion SCD40 (NDIR) | True CO2, not eCO2 proxy |
| VOC / eCO2 | Volatile organic compounds index | Bosch BME688 | Detects cooking fumes, cleaning products, off-gassing |
| Carbon Monoxide | CO (ppm) | Figaro TGS5042 electrochemical | Safety-tier alert |
| Temperature & Humidity | °C / %RH | Included in BME688 | Context for other readings |
| Ambient Light | Lux | Onboard photodiode or BH1750 | Adjusts display brightness; correlates outdoor context |

### Composite Air Quality Index (AQI-R)
All sensor readings are fused into a single internal score (0–100) called the **Rabbit Air Index (RAI)**. The RAI directly drives the rabbit's life stage and mood. Individual sensor data is accessible on a secondary screen for users who want detail.

---

## 4. Hardware Architecture

### Microcontroller
- **ESP32-S3** (dual-core 240 MHz, Wi-Fi + BLE 5.0)
  - Low-power deep-sleep between sensor polls
  - BLE for optional companion app data export
  - No mandatory cloud dependency — all game logic runs on-device

### Display
- **1.54" color OLED** (240×240, SPI) — vivid black backgrounds make rabbit animations pop
- Optional: white OLED variant for lower cost SKU

### Power
- **500 mAh LiPo** battery
- **USB-C** charging (TP4056 or BQ25185)
- Estimated battery life: 18–36 hours continuous (sensor polling every 10 s, display dimmed)
- Low-power mode: 5–7 days (polling every 60 s, display off except for alerts and interactions)

### Physical Interface
- **3 buttons**: Left (back/cancel), Center (interact/confirm), Right (cycle screens)
- Long-press center: trigger a "user action" (see Section 6)
- Haptic feedback motor (ERM) for alerts and interactions

### Enclosure
- Injection-molded ABS body with **removable silicone bumper shell**
- Bumper available in: Sage Green, Lavender Blue, Charcoal, Cream
- Lanyard loop and magnetic desk stand accessory (sold separately)

### Connectivity (optional companion app)
- BLE export of historical RAI data and sensor logs
- App shows trends, earns bonus XP for sustained clean-air streaks
- App is optional — core product works fully without it

---

## 5. The Rabbit — Life Stages & States

### Life Stages (driven by long-term RAI average)

| Stage | Trigger | Appearance |
|---|---|---|
| **Egg** | New device / factory reset | Speckled egg with one blinking eye |
| **Kit** | RAI avg ≥ 60 for 24 h | Small baby rabbit, wide eyes |
| **Flop** (regression) | RAI avg < 40 for 48 h | Droopy, grey-tinted, slouched |
| **Sprout** | RAI avg ≥ 65 for 72 h | Energetic rabbit with leaf sprout on head |
| **Scout** | RAI avg ≥ 72 for 7 days | Rabbit with mini backpack, exploring animations |
| **Bloom** | RAI avg ≥ 80 for 14 days | Rabbit surrounded by small floating flowers |
| **Luminary** | RAI avg ≥ 88 for 30 days | Glowing aura, rare idle animations |
| **Lost** | RAI avg < 30 for 72 h | Rabbit fades to ghost/silhouette — reversible |

### Mood States (driven by current real-time RAI)

| RAI | Mood | Animation |
|---|---|---|
| 85–100 | Joyful | Binkies, spins, heart particles |
| 65–84 | Content | Slow breathing, occasional ear twitch |
| 45–64 | Uneasy | Nose wrinkle, looking around |
| 25–44 | Distressed | Coughing puff animation, red-tinged edges |
| 0–24 | Critical | Screen flashes, SOS pose, haptic alert |

### Alert Events (sensor-specific)
- **PM2.5 spike**: Rabbit pulls a tiny mask over its face
- **CO2 high**: Rabbit yawns excessively, eyelids droop
- **VOC detected**: Rabbit sniffs the air, wrinkles nose
- **CO alert**: Full-screen warning overrides pet display (safety priority)

---

## 6. Gamification Mechanics

### XP & Rabbit Points (RP)
- Device accumulates **Rabbit Points** passively while RAI is above 60
- RP rate scales with RAI: higher air quality = faster accumulation
- RP spent on cosmetic unlocks (hats, backgrounds, seasonal themes)

### User Actions (limited, deliberate)
Players can trigger one "active action" per hour. Actions don't cheat the sensor — they provide bonus RP if the environment actually improves afterward:

| Action | How to Trigger | Bonus Condition |
|---|---|---|
| Open a Window | Long-press center → "Fresh Air" | RAI improves within 20 min: +50 RP |
| Run the Purifier | Long-press → "Filter On" | PM2.5 drops >20% within 30 min: +75 RP |
| Go Outside | Long-press → "Walk Time" | Device enters "walk mode," logs outdoor baseline |
| Water Your Plants | Long-press → "Green Moment" | Humidity normalizes to 40–60%: +30 RP |
| Clean the Space | Long-press → "Deep Clean" | VOC index drops within 60 min: +60 RP |

Actions that don't produce measurable sensor improvement grant no bonus — the rabbit knows.

### Streak System
- **Daily Clean Streak**: RAI avg ≥ 65 for entire calendar day
- Streaks shown on secondary screen; milestone streaks unlock rare rabbit skins
- Breaking a streak by 1 day: streak paused, not reset (grace mechanic)

### Seasonal Events
- "Wildfire Season" event: device detects sustained PM2.5 >35 µg/m³, activates special "smoke bunny" survival mode with dedicated recovery challenges
- Holiday themes: Winter Wonderland (humidity + temp), Spring Bloom (VOC garden), etc.

---

## 7. Secondary Screens (button-navigated)

1. **Rabbit Home** — default, full-screen pet
2. **AQI Dashboard** — RAI score + individual sensor readouts with color coding
3. **Trend Graph** — 24-hour sparkline of RAI
4. **Stats** — current life stage, RP balance, active streak, time alive
5. **Shop** — spend RP on cosmetics (no real-money IAP)
6. **Settings** — alert thresholds, display brightness, BLE toggle, sensor calibration

---

## 8. Rabbit Mascot — Image Generation Prompt

```
A chibi-style cartoon rabbit mascot for a consumer electronics brand called
"Lost Rabbit Digital." The rabbit is small, round-bodied, with large expressive
eyes and oversized floppy ears that convey mood clearly. Its body is primarily
white with soft pastel shading. The character should look equally at home on
a digital OLED screen (simplified, ~32x32 px sprite version) and as a full-color
brand mascot illustration.

Design the rabbit in a neutral "content" pose: sitting upright, ears relaxed
slightly outward, one paw raised in a subtle wave. Expression is calm and warm,
not aggressive or overly cute-aggressive — approachable and trustworthy.

Include a small glowing particle or air bubble floating near the rabbit to hint
at the air quality theme without being clinical. Style reference: Tamagotchi
characters, Sanrio clean lines, Studio Ghibli softness. No text in the image.
Background: transparent or flat black to show OLED contrast. Color palette:
white body, blush pink inner ears, soft sky-blue or sage green accent glow.
```

---

## 9. Bill of Materials — Estimated Cost

| Component | Estimated Unit Cost (10k MOQ) |
|---|---|
| ESP32-S3 module | $2.50 |
| Sensirion SPS30 (PM2.5) | $7.00 |
| Sensirion SCD40 (CO2) | $6.50 |
| Bosch BME688 (VOC/T/H) | $2.50 |
| Figaro TGS5042 (CO) | $4.50 |
| 1.54" color OLED display | $4.00 |
| LiPo 500 mAh battery | $2.00 |
| USB-C charging IC + port | $1.00 |
| ERM haptic motor | $0.60 |
| PCB (4-layer, assembled) | $4.50 |
| ABS injection-molded body | $3.50 |
| Silicone bumper shell | $2.00 |
| Buttons, connectors, passives | $1.20 |
| Packaging (retail box, insert) | $1.50 |
| **Total BOM + assembly est.** | **~$43.30** |

> Costs above assume 10,000-unit run via a contract manufacturer (Shenzhen-tier).  
> First-run (1,000 units): expect ~$65–75/unit BOM. NRE (tooling, molds): ~$15,000–25,000 one-time.

### Suggested Retail Price: **$89 USD**

| Pricing Layer | Value |
|---|---|
| BOM + assembly (10k scale) | ~$43 |
| Landed cost (freight, duties, QA) | ~$52 |
| Distributor/retailer margin (40%) | ~$87 |
| **MSRP (rounded)** | **$89** |

At $89 MSRP with DTC (direct-to-consumer) channel, landed margin is approximately **42%** — healthy for a hardware product at this stage.  
A **$79 introductory / crowdfunding price** is recommended for the launch campaign.

---

## 10. Competitive Positioning

| Product | Price | Air Sensors | Gamification | Standalone |
|---|---|---|---|---|
| Airthings View Plus | $299 | Yes (6) | None | Yes |
| IQAir AirVisual Pro | $269 | Yes (PM + CO2) | None | Yes |
| Atmotube Pro | $119 | Yes (4) | None | Wearable |
| **Lost Rabbit** | **$89** | **Yes (5)** | **Core feature** | **Yes** |

The Lost Rabbit occupies an uncontested position: consumer-priced, sensor-complete, with a game loop that sustains engagement beyond the novelty window.

---

## 11. Lessons Applied from Vibrating Mesh Nebulizer Controller

| Nebulizer Lesson | Applied to Lost Rabbit |
|---|---|
| LiPo + USB-C charging with monitoring IC | Adopted directly — same charging architecture |
| HD44780-compatible character OLED | Upgraded to SPI color OLED; character display experience informs animation budget |
| Enclosure split into base + lid + configurable SCAD | Modular bumper shell design — same philosophy, consumer-friendly execution |
| Frequency sweep / closed-loop sensor feedback | Continuous sensor polling loop with adaptive sample rates in low-power mode |
| 3-button physical interface | Retained as proven minimal-UI pattern |

---

*Document version 0.1 — Lost Rabbit Digital, April 2026*
