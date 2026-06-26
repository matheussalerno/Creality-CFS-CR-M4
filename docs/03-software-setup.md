# 3 · Software Setup (step by step)

This is the core procedure: get Creality's K2 Klipper fork (with the CFS modules) running on a Sonic Pad. Every non‑obvious gotcha below was hit and solved during real testing — they will bite you otherwise.

> **Prerequisites:** A Sonic Pad running the [SonicPad‑Debian](https://github.com/Jpe230/SonicPad-Debian) port (Debian 11, **Python 3.9, `armhf`**). Default login on that image: `sonic` / `pad`. You also need a working `klippy-env` virtualenv (the image ships one).
>
> **Reminder:** the CFS modules require the **K2 fork** of Klipper — they do **not** run on mainline Klipper (they import `serial_485`, `base_info`, etc. that only exist in the fork). So this fork becomes your printer's Klipper.

The helper script [`scripts/setup_cfs_fork.sh`](../scripts/setup_cfs_fork.sh) automates steps 1‑5. Read them first so you understand what it does.

---

## Step 1 — Clone Creality's K2 fork

```bash
cd ~
git clone --depth 1 https://github.com/CrealityOfficial/K2_Series_Klipper.git ~/k2_klipper
```

This brings the CFS modules in `klippy/extras/` (`box.py`, `serial_485.py`, `auto_addr.py`, `filament_rack.py`, `motor_control.py`) and their compiled `*.cpython-39.so` blobs.

## Step 2 — Fix the `.so` name tags (SOABI mismatch)

The K2's Python tags its extension modules `*.cpython-39.so`. **Debian's Python 3.9 expects the full platform tag** `*.cpython-39-arm-linux-gnueabihf.so`, so it won't auto‑import the K2's files. Fix: add generic `.so` symlinks (Python always accepts plain `name.so`):

```bash
cd ~/k2_klipper/klippy
find . -name "*.cpython-39.so" | while read f; do
  ln -sf "$(basename "$f")" "${f%.cpython-39.so}.so"
done
```

This covers `extras/box_wrapper.so`, `extras/serial_485_wrapper.so`, `extras/filament_rack_wrapper.so`, `extras/motor_control_wrapper.so`, and `mymodule/mymovie.so`.

## Step 3 — Install numpy (the right way)

The `box` module needs **numpy 1.x** (it was built against the 1.x C ABI — numpy 2.x will fail). The piwheels wheel was found **broken** on this platform ("you should not try to import numpy from its source directory"). Use **Debian's** numpy and link it into the venv:

```bash
sudo apt-get install -y python3-numpy           # Debian build, 1.19.5, correct for armhf
# remove any broken pip numpy first:
~/klippy-env/bin/pip uninstall -y numpy 2>/dev/null
rm -rf ~/klippy-env/lib/python3.9/site-packages/numpy ~/klippy-env/lib/python3.9/site-packages/numpy-*.dist-info
# link the system numpy into the venv:
ln -sfn /usr/lib/python3/dist-packages/numpy ~/klippy-env/lib/python3.9/site-packages/numpy
# verify (from a clean dir):
cd /tmp && ~/klippy-env/bin/python -c "import numpy; print('numpy', numpy.__version__)"
```

## Step 4 — Stop the chelper from rebuilding (missing `filament_change.c`)

Creality **withheld `chelper/filament_change.c`** from the public repo (same as the `.so` blobs). The pre‑built `c_helper.so` already contains its compiled code. But on a Sonic Pad — which *has* a native `gcc` — the fork's `chelper/__init__.py` *deletes* the pre‑built `c_helper.so` and tries to recompile, which fails:

```
gcc: error: chelper/filament_change.c: No such file or directory
```

On the real K2 (cross‑compiler, no native gcc) it never rebuilds — it just uses the pre‑built `.so`. Make the Sonic Pad behave the same: force `should_compile = False`.

```bash
cd ~/k2_klipper/klippy
sed -i 's/^should_compile = check_gcc_exists()/should_compile = False/' chelper/__init__.py
# if a rebuild already deleted it, restore the pre-built blob:
[ -f chelper/c_helper.so ] || (cd ~/k2_klipper && git checkout klippy/chelper/c_helper.so)
```

## Step 5 — Create the CFS data files

The `box` module reads a few JSON files (hard‑coded path `/usr/data/creality/userdata/...`). Create them so it doesn't error:

```bash
sudo mkdir -p /usr/data/creality/userdata/box /usr/data/creality/userdata/config
echo '{}' | sudo tee /usr/data/creality/userdata/box/material_database.json >/dev/null
echo '{}' | sudo tee /usr/data/creality/userdata/box/tn_data.json >/dev/null
echo '{}' | sudo tee /usr/data/creality/userdata/config/system_config.json >/dev/null
sudo touch /usr/data/creality/userdata/config/flushing_sign
sudo chown -R sonic:sonic /usr/data/creality
```

## Step 6 — Build your `printer.cfg`

Use your printer's normal Klipper config (steppers, extruder, heaters, probe — for a CR‑M4 see [`config/`](../config/)). Then add the CFS sections from the fork's `config/<model>/box.cfg`:

- `[serial_485 serial485]` → set `serial: /dev/ttyUSB0` and `baud: 230400` (your dongle)
- `[auto_addr]`
- `[box]` → adapt `cut_pos`, `clean_*_pos`, `extrude_pos` to **your** cutter/purge geometry
- the `BOX_*` `gcode_macro`s (load/unload/cut sequences)

See [`config/box.cfg.example`](../config/box.cfg.example) for an annotated template.

> ⚠️ **Encoding gotcha:** Creality's `box.cfg` has **Chinese (GBK) comments**. Klipper reads config as UTF‑8 and will choke on a traceback if an error occurs. Strip non‑ASCII from any Creality config you include:
> `tr -cd '\11\12\15\40-\176' < box.cfg > box_clean.cfg`

## Step 7 — Run it / make it the host

Test it standalone first (without disturbing a running service) — see [`scripts/test_k2_fork.sh`](../scripts/test_k2_fork.sh):

```bash
# stop whatever klipper service currently owns the serial port, then:
cd ~/k2_klipper/klippy
~/klippy-env/bin/python klippy.py /path/to/printer.cfg -l /tmp/test.log -a /tmp/test.sock
# success = the log reaches "Printer is ready"
```

When happy, point your `klipper.service` (and Moonraker's paths) at `~/k2_klipper` and use a WebUI (Mainsail/Fluidd) normally.

### A nice side effect

If your printer's MCU still runs **Creality stock firmware**, it will match this fork's Klipper version far better than mainline (no "deprecated MCU code" warnings, often no re‑flash needed).

Continue to **[04 · Technical findings](04-technical-findings.md)**.
