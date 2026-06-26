# Creality CFS → CR‑M4 (and other Klipper printers) via Sonic Pad

**Running the Creality Filament System (CFS) — the ready‑made 4‑spool AMS from the K2 Plus / Creality Hi — on a non‑K2 printer (a Creality CR‑M4) using a Creality Sonic Pad as the host.**

> ⚠️ **STATUS: Proof‑of‑Concept / Work‑In‑Progress.** The **software path is validated** on real hardware (the closed‑source Creality CFS Klipper modules load and instantiate on a Sonic Pad). The **final end‑to‑end test with the physical CR‑M4 + CFS is still pending** (see [Status](#status)). This repo documents the path so others can build on it — it is **not** a "flash‑and‑forget" guide yet.

---

## Why this exists

Creality's **CFS** is a great, *ready‑made* AMS (no kit to assemble, no questionable parts to source — the usual pain of DIY units like BoxTurtle). The catch: Creality only officially supports it on the **K2 Plus** and **Creality Hi**.

This project answers: **can you drive a CFS from a Sonic Pad and bolt it onto another Klipper printer (e.g. a CR‑M4)?**

Short answer so far: **the software side is feasible and proven; the rest is hardware integration.**

## The key discoveries (the "how")

1. **The CFS is a self‑contained device.** Each box has its own MCU (GD32F303 + RT‑Thread), 4 feed motors, RFID readers and sensors. It talks **RS‑485 @ 230400 baud** and just needs an RS‑485 *master*. It does **not** need the K2 mainboard. → so a **Sonic Pad + a USB‑to‑RS‑485 dongle** is electrically enough.
2. **The CFS Klipper integration is closed‑source.** In `CrealityOfficial/K2_Series_Klipper` (and `Hi_Klipper`), the CFS lives in `klippy/extras/` as **compiled `*.cpython-39.so` blobs** (`box`, `filament_rack`, `motor_control`, `serial_485`) — the `.py` files are 2‑line shims. So you can't port it to mainline Klipper; you run **Creality's K2 fork** of Klipper.
3. **The Sonic Pad is binary‑compatible.** The Sonic Pad's Debian userland is **ARMv7 hard‑float (`armhf`) + Python 3.9** — the *same ABI* the K2 blobs were built for. They load. (Proven: all 10 CFS modules import and the `[box]` object instantiates.)
4. **The filament‑change orchestration is in Klipper**, not the touchscreen app — `box.cfg` defines the load/unload sequence as `gcode_macro`s built from `BOX_*` commands the blob registers. So you do **not** need Creality's proprietary UI to drive it.
5. **The real remaining gap is mechanical:** the CFS changes filament by **ramming the strand into a fixed blade** (cutter) at a known toolhead position. A CR‑M4 has no cutter — you must add one (or use tip‑forming).

See **[docs/04-technical-findings.md](docs/04-technical-findings.md)** for the full reverse‑engineering notes.

## Architecture

```
 CR-M4 board (Klipper MCU) ──USB──┐
                                  ├── Sonic Pad  (Debian + Creality K2 Klipper fork)
 CFS  ──RS-485 (230400)──[USB-RS485 dongle, /dev/ttyUSB0]──┘
                                          │
                          one klippy host: printer config + [box]/[serial_485] CFS modules
```

## What you need (hardware)

| Item | Notes |
|------|-------|
| Creality **CFS** unit | the AMS itself |
| **USB‑to‑RS‑485 dongle** | **must have hardware auto‑direction** (Klipper's `serial_485` does not toggle DE). See [docs/02-hardware.md](docs/02-hardware.md). **Recommended: Waveshare FT232RNL isolated**, or genuine **FTDI USB‑RS485‑WE**. Avoid CP2102 (DSD TECH SH‑U10) and any "MAX485 + DE‑to‑RTS". |
| **Sonic Pad** | running the [SonicPad‑Debian](https://github.com/Jpe230/SonicPad-Debian) port (Python 3.9, armhf) |
| **Filament cutter** on the printer | a fixed blade + purge/wipe zone (the CFS rams filament to cut). The hard mechanical part. |

## Quick map of the guide

1. [Overview & status](docs/01-overview.md)
2. [Hardware: dongle, wiring, cutter](docs/02-hardware.md)
3. [Software setup, step by step](docs/03-software-setup.md) ← the core procedure
4. [Technical findings / reverse engineering](docs/04-technical-findings.md)
5. [Status, risks & licensing](docs/05-status-and-license.md)

Helper scripts live in [`scripts/`](scripts/); a config template in [`config/`](config/).

## Status

| Step | State |
|------|-------|
| CFS modules load on Sonic Pad (ABI compatible) | ✅ proven |
| `CR‑M4 + CFS` config parses (0 errors) on the K2 fork klippy | ✅ proven |
| `[box]` (CFS) object instantiates | ✅ proven |
| K2 fork klippy reaches `ready` **with the real CR‑M4 board** | ⏳ pending hardware test |
| CFS responds over a real USB‑RS‑485 dongle | ⏳ pending dongle |
| Filament cutter on the CR‑M4 | 🔧 mechanical, not started |

## ⚖️ Licensing — please read

This repository contains **only original documentation and helper scripts** (MIT — see [LICENSE](LICENSE)).

It does **NOT** redistribute any Creality code or the closed CFS `.so` binaries. The setup scripts operate on **your own clone** of [`CrealityOfficial/K2_Series_Klipper`](https://github.com/CrealityOfficial/K2_Series_Klipper). Creality publishes that firmware as open‑source (with the CFS pieces shipped as compiled blobs). Get it from them directly.

## Credits / Contributing

Built from hands‑on testing on a Sonic Pad + CR‑M4. PRs and field reports very welcome — especially anyone who completes the **real‑printer test** or adds a **cutter** design. Related reverse‑engineering: [`fake-name/cfs-reverse-engineering`](https://github.com/fake-name/cfs-reverse-engineering), [`ityshchenko/klipper-cfs`](https://github.com/ityshchenko/klipper-cfs).
