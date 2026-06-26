# 2 · Hardware — Dongle, Wiring, Cutter

## The USB‑to‑RS‑485 dongle (read this carefully)

The CFS bus is **RS‑485 @ 230400 baud** (up to 4 boxes daisy‑chained = 16 spools).

**The single most important requirement:** the dongle must do **RS‑485 transmit/receive direction switching in hardware (auto‑direction / "automatic flow control")**.

Why: Klipper's `serial_485` driver just does plain `read()`/`write()` on the tty — it does **not** toggle a DE/RE GPIO or assert RTS. A dongle that needs manual/RTS direction control will get stuck transmitting (or never enable TX) and the bus fails.

### Recommended (hardware auto‑direction)

| Rank | Dongle | Chipset | Why |
|------|--------|---------|-----|
| 🥇 | **Waveshare USB TO RS485 (isolated)** | FT232RNL + SP485, auto‑direction circuit | Documented "fully automatic transceiver, no delay"; isolation is ideal for the multi‑box daisy‑chain; in‑kernel `ftdi_sio`; 300–921600 bps |
| 🥈 | **FTDI USB‑RS485‑WE‑1800‑BT** | genuine FT232R, `TXDEN` auto‑direction | Rock‑solid `ftdi_sio` support; up to 3 Mbaud; bare flying leads (wire A/B/GND), no isolation |
| 🥉 | **CH340/CH343 with `TNOW`** | WCH CH340/CH343 | Creality's own CFS kit ships a CH340 ("HL‑340", USB `1a86:7523`) adapter — the known‑good cheap path. **Only if the board wires `TNOW`→DE**, not RTS. |

### Avoid

- **CP2102 / CP2102N** (e.g. DSD TECH SH‑U10) — no hardware auto‑TX‑enable pin.
- **Any "MAX485 + DE‑to‑RTS" board** — needs software direction toggling Klipper won't do.

### Wiring

CFS rear connector carries power + **2 RS‑485 lines (A/B) + GND**. Connect:

```
Dongle A (D+)  ── CFS A
Dongle B (D-)  ── CFS B
Dongle GND     ── CFS GND
```

It enumerates on the Sonic Pad as `/dev/ttyUSB0` (check `ls /dev/serial/by-id/`). Note: the printer's own board (CR‑M4) is *also* a USB‑serial device — make sure you point each config at the right `/dev/serial/by-id/...` path so they don't get swapped.

## The cutter (the real mechanical work)

The CFS performs a filament change by **ramming the strand into a fixed blade** at a known toolhead XY position, then retracting, loading the next spool, purging and wiping. From `box.cfg`:

```
pre_cut_pos_x/y, cut_pos_x/y   → toolhead pushes filament into a fixed cutter
clean_left/right_pos           → nozzle wipe (teflon wiper)
extrude_pos                    → purge ("poop") position
```

A K1/K2 has this blade built in; a **CR‑M4 does not**. To use the CFS you must add:

- A **fixed cutter blade** at a reachable, repeatable position on the bed/frame.
- A **purge + wipe zone**.
- Then set `cut_pos`, `clean_*_pos`, `extrude_pos` in `box.cfg` to match your geometry.

> Alternative to a blade: tip‑forming (no cutter), but the stock CFS flow is built around ramming‑cut, so a cutter is the path of least resistance.

This is the biggest open task and is left to the builder. Designs welcome via PR.

Continue to **[03 · Software setup](03-software-setup.md)**.
