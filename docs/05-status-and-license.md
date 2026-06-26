# 5 · Status, Risks & Licensing

## Current status (be honest with yourself)

This is a **proof‑of‑concept in progress**. Do not start buying/cutting based on a promise it "just works" — here is exactly what is and isn't done:

✅ **Proven on real hardware (a Sonic Pad):**
- The closed CFS Klipper modules are ABI‑compatible and load (10/10).
- A combined printer + CFS config parses with zero errors on the K2 fork.
- The `[box]` (CFS) object instantiates and Klipper reaches the MCU‑connect stage.

⏳ **Pending (needs the physical printer / dongle):**
- The K2 fork klippy reaching `ready` **with the real printer MCU connected**.
- Real RS‑485 comms with a CFS through a USB‑RS‑485 dongle.

🔧 **Not started (mechanical):**
- A filament **cutter** + purge/wipe zone on the CR‑M4.

## Risks & unknowns

- **MCU handshake on the fork:** standard Klipper, low risk. A Creality‑stock‑firmware board should match the fork *better* than mainline.
- **Closed binaries:** if a `.so` misbehaves you cannot debug or patch it — you're limited to what Creality compiled.
- **Per‑printer tuning:** all the `box.cfg` positions, retract/extrude lengths and flush volumes must be tuned to *your* machine.
- **Firmware updates:** updating the K2 fork later may replace the blobs/`c_helper.so`; you may have to re‑apply the symlink and `should_compile` fixes.

## Licensing & legal

- **This repository:** original documentation + helper scripts only, **MIT** ([LICENSE](../LICENSE)).
- **It contains no Creality code or binaries.** The scripts operate on *your own* clone of [`CrealityOfficial/K2_Series_Klipper`](https://github.com/CrealityOfficial/K2_Series_Klipper), which Creality publishes (CFS parts as compiled blobs).
- **Do not commit** the `.so` blobs or Creality config to a fork of *this* repo — the `.gitignore` blocks them by default.
- The CFS binaries' closed‑source status is a known GPLv3 concern raised in the Klipper community; that is between Creality and the FSF/community, not something this repo resolves.

## Prior art / collaborators

- [`fake-name/cfs-reverse-engineering`](https://github.com/fake-name/cfs-reverse-engineering) — CFS hardware + RS‑485 protocol notes, CAN interposer idea.
- [`ityshchenko/klipper-cfs`](https://github.com/ityshchenko/klipper-cfs) — a clean‑room, open‑source Python reimplementation of the CFS protocol (WIP — message framing only so far). If completed, this would remove the need for Creality's blobs entirely. **Contribute there too.**

## How you can help

1. Run the **real‑printer test** and report whether the fork reaches `ready` (open an issue with your log).
2. Share a **cutter design** for the CR‑M4 (or other printers).
3. Document the `box.cfg` values for your machine.
4. Help finish the open `klipper-cfs` driver so this can run on **mainline** Klipper without closed blobs.
