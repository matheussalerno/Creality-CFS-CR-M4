# 4 · Technical Findings (reverse‑engineering notes)

Raw notes from inspecting `CrealityOfficial/K2_Series_Klipper`, `Hi_Klipper`, and probing the binaries on a real Sonic Pad.

## Where the CFS lives in Klipper

| File (`klippy/extras/`) | Type | Role |
|---|---|---|
| `box.py` | 2‑line shim | loads `MultiColorMeterialBoxWrapper` — this **is** the CFS ("material box") |
| `box_wrapper.cpython-39.so` | **closed blob** | the CFS state machine: load/unload, cut, retract, flush, RFID, remaining‑length |
| `serial_485.py` + `serial_485_wrapper.cpython-39.so` | shim + **closed blob** | the RS‑485 multi‑drop transport (not in mainline Klipper) |
| `auto_addr.py` + `auto_addr_wrapper.py` | **open** | RS‑485 node discovery/addressing (the one readable CFS file) |
| `filament_rack.py` + `*_wrapper.so` | shim + blob | the 4‑spool rack |
| `motor_control.py` + `*_wrapper.so` | shim + blob | CFS feed/tension motors |

Present in **K2** and **Hi** forks. **Absent from K1.** Not in upstream Klipper.

## The bus

RS‑485, **230400 baud** (some variants 460800). `auto_addr_wrapper.py` documents the device types on the bus:

```
DEV_TYPE_MB = 1   # Material box  (料盒)
DEV_TYPE_CLM = 2  # Closed-loop motor (闭环电机)
DEV_TYPE_BTM = 3  # Belt-tension motor (皮带张紧电机)
BROADCAST_ADDR = 0xFF ...
```

The CFS itself is a self‑contained device — per `fake-name/cfs-reverse-engineering`: MCU **GD32F303VET6** running **RT‑Thread 5.0.2**, 4 feed motors (AT8236), 1 hub motor (MS3791), magnetic odometer, 2 RFID readers, AHT temp/humidity, photoelectric sensors. **The K2 mainboard is only the RS‑485 master.**

## The blobs are closed (GPL note)

`box_wrapper`, `filament_rack_wrapper`, `motor_control_wrapper`, `serial_485_wrapper` are all `cpython-39.so` with **no published source** (the `.py` files are stubs). This is a documented GPLv3 concern in the Klipper community. We **use** them as Creality ships them; we do not redistribute them here.

## Orchestration is in Klipper (not the touchscreen)

`box.cfg` defines the change sequence as `gcode_macro`s:

```ini
[gcode_macro BOX_LOAD_MATERIAL_WITH_MATERIAL]
gcode:
  M104
  BOX_CHECK_MATERIAL
  BOX_CUT_MATERIAL
  BOX_RETRUDE_MATERIAL
  BOX_EXTRUDE_MATERIAL
  BOX_EXTRUDER_EXTRUDE
  BOX_MATERIAL_FLUSH
```

`box_wrapper.so` registers ~40 `BOX_*` primitives (`BOX_CUT_MATERIAL`, `BOX_GET_RFID`, `BOX_GET_REMAIN_LEN`, `BOX_GENERATE_FLUSH_ARRAY`, `BOX_ENABLE_CFS_PRINT`, …) **plus `register_endpoint` / `webhooks`** → Creality's display app is a *client* of Klipper's API, it does not control the CFS in parallel (the RS‑485 device is opened exclusively by Klipper). **Conclusion: you don't need Creality's UI for the change logic.**

## Sonic Pad binary compatibility (the linchpin)

| | K2 host | Sonic Pad |
|---|---|---|
| SoC | Allwinner T113 (Cortex‑A7) | Allwinner R818 (Cortex‑A53) |
| Userland | `armhf` (32‑bit) | **`armhf` (32‑bit)** (64‑bit kernel) |
| Python | 3.9 | 3.9 |

Blobs are `ELF32 ARM, Version5 EABI, hard-float ABI`, `cpython-39`. `ldd` resolves every dependency on the Sonic Pad. **They load.** Proven: 10/10 modules import; `klippy.py` parses a `CR‑M4 + CFS` config with 0 errors and the `[box]` object instantiates (logs all cut/clean/extrude positions), reaching the MCU‑connect stage.

## Gotchas encountered (and fixed)

| Symptom | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: box_wrapper` | Debian Python wants full SOABI tag | symlink `*.cpython-39.so` → `*.so` |
| `import numpy from its source directory` | broken piwheels numpy / numpy 2.x ABI | use Debian `python3-numpy` (1.19.5), link into venv |
| `gcc: filament_change.c: No such file` | Creality withheld that C source; native gcc triggers a rebuild | `should_compile = False` in `chelper/__init__.py` (use pre‑built `c_helper.so`) |
| `box: No such file ... tn_data.json` | missing data files | create `/usr/data/creality/userdata/box/*.json` |
| `UnicodeDecodeError 0xc8` | Chinese GBK comments in `box.cfg` | strip non‑ASCII |

Continue to **[05 · Status & License](05-status-and-license.md)**.
