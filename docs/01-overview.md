# 1 · Overview & Status

## The goal

Use a **Creality CFS** (the ready‑made 4‑spool AMS) on a printer Creality never intended it for — a **CR‑M4** — using a **Sonic Pad** as the Klipper host and a **USB‑to‑RS‑485 dongle** as the bridge to the CFS.

The appeal vs. a DIY multi‑material unit (e.g. BoxTurtle): **the CFS is a finished, tested product** — no kit assembly, no sourcing of dubious parts.

## How it's possible (one paragraph)

The CFS is an **autonomous RS‑485 device** (its own MCU, motors, sensors, RFID) — it only needs an RS‑485 master speaking its protocol. Creality's Klipper integration for it (the `[box]` module + friends) ships as **closed `cpython‑39` ARM `armhf` binaries** inside `K2_Series_Klipper`. A **Sonic Pad on Debian is the same `armhf` + Python 3.9 ABI**, so those binaries load and run there. You therefore run **Creality's K2 Klipper fork** on the Sonic Pad, point its `[serial_485]` at a USB‑RS‑485 dongle, and add the printer's own config. The filament‑change *logic* lives in Klipper macros — no proprietary touchscreen app required.

## What is proven vs. pending

| # | Claim | Evidence | State |
|---|-------|----------|-------|
| 1 | CFS `.so` blobs are ABI‑compatible with the Sonic Pad | `readelf`: ELF32 ARM hard‑float `cpython‑39`; `ldd` resolves all libs | ✅ |
| 2 | All CFS modules import | `box`, `serial_485`, `filament_rack`, `motor_control`, `auto_addr` + deps = 10/10 import | ✅ |
| 3 | A `CR‑M4 + CFS` config parses with 0 errors on the K2 fork klippy | klippy log: full config echoed, no `Config error` | ✅ |
| 4 | The `[box]` (CFS) object instantiates | klippy log: `box:load_config` reads all cut/clean/extrude positions | ✅ |
| 5 | Fork klippy reaches `ready` **with the real CR‑M4 board** | — | ⏳ pending |
| 6 | CFS answers over a real dongle | — | ⏳ pending dongle |
| 7 | Mechanical cutter on the CR‑M4 | — | 🔧 not started |

> The honest summary: **the software is de‑risked and validated up to the connect stage.** The last unknown is the standard Klipper MCU handshake on the fork with the real board (low risk — the CR‑M4's stock firmware is Creality, matching the fork better than mainline), plus the dongle and a cutter.

## Hardware compatibility note

The Sonic Pad's Allwinner R818 (Cortex‑A53) runs a **64‑bit kernel but a 32‑bit `armhf` userland** — which is exactly what makes it ABI‑compatible with Creality's K2 binaries (the K2 uses an Allwinner T113 / Cortex‑A7, also `armhf`, Python 3.9). This is the linchpin of the whole approach.

Continue to **[02 · Hardware](02-hardware.md)**.
