# 6 · Real‑Printer Test Results & FAQ

Results from running Creality's **K2 Klipper fork on a Sonic Pad wired to a real CR‑M4**, plus answers to the questions everyone asks.

## ✅ The fork RUNS the CR‑M4 (proven on hardware)

Running the K2 fork's `klippy.py` against the CR‑M4's own `printer.cfg` (Cartesian, 450×450), the full successful Klipper startup happened:

```
mcu: Configured MCU 'mcu' (1024 moves)
verify_heater: Starting heater checks for heater_bed
verify_heater: Starting heater checks for extruder
Stats ... print_stats: standby  heater_bed: temp=24.1  extruder: temp=23.8  bytes_retransmit=0 bytes_invalid=0  freq=84000833
```

- MCU configured (`MCU=stm32f401xc CLOCK_FREQ=84000000 STEPPER_BOTH_EDGE=1`)
- Heaters verified, **temperatures reading**, clean comms, **standby** (operational) state
- The CR‑M4's stock **v0.10.0** board firmware connected to the fork klippy fine (`Loaded MCU 'mcu' 100 commands (v0.10.0...)`)

> The literal string "Printer is ready" is not logged by this fork — it goes straight to periodic `Stats`/`standby`. Don't grep for it; look for `Configured MCU` + running `Stats`.

### The CFS is optional (you can run without it)
The fork's `stepper.py` looks up the `box` object to set the X min to the cutter position — **but it's wrapped in `try/except`** (it only logs `Unknown config object 'box'` and continues). The K2 itself ships without a CFS, so the fork must run CFS‑less — and it does. **You do not need `[box]` to print.**

### Known noise (benign)
The CR‑M4 stock firmware spams `wxlinsert_timer1` async messages the fork doesn't recognize (`handle_default`). It did **not** prevent the printer reaching standby. Log noise, not a blocker.

---

## FAQ

### Q: Does running the K2 fork force K2 settings — bed size, kinematics, etc.? The CR‑M4 is Cartesian, not CoreXY, with a different bed.
**No. Everything geometric comes from your `printer.cfg`, not the fork.** Verified: the fork ran the CR‑M4 as `kinematics: cartesian`, 450×450, with the CR‑M4's steppers/probe — exactly as configured. There are **no hardcoded** CoreXY or bed‑size assumptions in the fork's Creality modules (checked). The fork is just the Klipper engine + the CFS modules + a few Creality core patches; you supply the printer definition. A Cartesian CR‑M4 with its own bed size is a non‑issue.

### Q: Can I run Creality's touchscreen UI on the Sonic Pad?
**No — not realistically.** Creality's UI (the K2's, or the Sonic Pad's stock one) is a closed Qt "display‑server" app bound to the stock **Tina/OpenWrt** firmware and K2 hardware (it even talks to the CFS over RS‑485 itself, bypassing Klipper). It's blob‑dependent, has no source release, and no one has ported it. Flashing SonicPad‑Debian wipes the stock UI; it only returns by reflashing stock firmware (giving up Debian/Klipper).
**Use instead:** **KlipperScreen** (open touchscreen UI — ships in SonicPad‑Debian, runs on the Pad's 7" screen) and **Fluidd/Mainsail** (web). HelixScreen is a lighter touchscreen alternative.

### Q: Can I buy the CFS alone, or do I need the K1 adapter kit?
**Buy the CFS box standalone — you do NOT need the K1 kit** (for our dongle‑based approach).

- **CFS box (~$319, SKU 760777)** ships complete: the 4‑spool dry box, **the filament buffer**, PTFE tube set, a 485 cable, power cable, and spare cutter blades. The **buffer is in the box** — not a separate purchase.
- The **"K1 CFS Upgrade Kit" (~$52)** is a *printer‑side* adapter: a K1‑specific extruder with integrated cutter+runout sensor, a **USB‑to‑485 cable**, and PTFE. It does **not** include the CFS or buffer. Its only generically‑useful part is the USB‑to‑485 cable — **which our Waveshare/FTDI USB‑RS485 dongle replaces**. The K1 extruder/cutter won't fit a CR‑M4 anyway.
- Get the **plain CFS (RS‑485)**, not the **CFS‑C** (a CAN‑based K1 retrofit with external cutter+buffer) — we're doing RS‑485 via the dongle.

#### Shopping list (CR‑M4 DIY)
| Item | ~Price | Why |
|------|--------|-----|
| **Creality CFS box** (plain, RS‑485) | ~$319 | the AMS; includes buffer + PTFE + 485 cable + power |
| **USB‑RS485 dongle** (Waveshare FT232RNL isolated) | ~$15–30 | the Sonic Pad ↔ CFS bridge (see [02‑hardware](02-hardware.md)) |
| **DIY cutter + runout sensor + brackets** on the CR‑M4 toolhead | — | the CFS needs a tip‑cut to swap; CR‑M4 has none |
| *(skip)* K1 CFS Upgrade Kit | ~$52 | not needed — dongle replaces its cable; its extruder doesn't fit |

> **Note vs. the general community view:** most CFS‑on‑other‑printer write‑ups call the *software* the showstopper (closed RS‑485 protocol, no driver). This project shows otherwise: the K2 fork's CFS modules **load and run on the Sonic Pad**, and the fork **runs the CR‑M4**. The remaining real work is the **mechanical cutter** + **field bring‑up with the real CFS over the dongle** — not "there's no software path."

---

## Updated status

| Step | State |
|------|-------|
| CFS modules load on Sonic Pad | ✅ proven |
| Config parses + `[box]` instantiates on the fork | ✅ proven |
| **Fork runs the CR‑M4 (Cartesian, 450×450), reaches standby** | ✅ **proven on real hardware** |
| Fork imposes no K2 geometry | ✅ confirmed (config‑driven) |
| CFS responds over a real USB‑RS485 dongle | ⏳ pending dongle + CFS |
| Filament cutter on the CR‑M4 | 🔧 mechanical, DIY |
