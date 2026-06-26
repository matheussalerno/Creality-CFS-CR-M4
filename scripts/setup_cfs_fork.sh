#!/bin/bash
# ============================================================================
#  setup_cfs_fork.sh
#  Prepare Creality's K2 Klipper fork (with the CFS modules) to run on a
#  SonicPad-Debian host. Idempotent: safe to re-run.
#
#  Does NOT download/redistribute Creality code itself -- it clones Creality's
#  own public repo onto YOUR machine and applies the compatibility fixes.
#
#  Tested on: SonicPad-Debian (Debian 11, Python 3.9, armhf).
#  See docs/03-software-setup.md for the explanation of every step.
# ============================================================================
set -e

FORK_DIR="${1:-$HOME/k2_klipper}"
VENV="${KLIPPY_ENV:-$HOME/klippy-env}"

echo ">>> [1/5] Cloning Creality K2 Klipper fork into $FORK_DIR (if missing)"
if [ ! -d "$FORK_DIR/.git" ]; then
  git clone --depth 1 https://github.com/CrealityOfficial/K2_Series_Klipper.git "$FORK_DIR"
else
  echo "    already present, skipping clone"
fi

echo ">>> [2/5] Fixing SOABI tags: symlink *.cpython-39.so -> *.so"
cd "$FORK_DIR/klippy"
find . -name "*.cpython-39.so" | while read -r f; do
  ln -sf "$(basename "$f")" "${f%.cpython-39.so}.so"
done

echo ">>> [3/5] Installing numpy 1.x from Debian and linking into the venv"
if ! (cd /tmp && "$VENV/bin/python" -c "import numpy" >/dev/null 2>&1); then
  sudo apt-get install -y python3-numpy
  "$VENV/bin/pip" uninstall -y numpy 2>/dev/null || true
  rm -rf "$VENV"/lib/python3.9/site-packages/numpy "$VENV"/lib/python3.9/site-packages/numpy-*.dist-info
  ln -sfn /usr/lib/python3/dist-packages/numpy "$VENV/lib/python3.9/site-packages/numpy"
fi
(cd /tmp && "$VENV/bin/python" -c "import numpy; print('    numpy', numpy.__version__)")

echo ">>> [4/5] Stopping chelper from rebuilding (Creality withheld filament_change.c)"
cd "$FORK_DIR/klippy"
if ! grep -q "should_compile = False" chelper/__init__.py; then
  sed -i 's/^should_compile = check_gcc_exists()/should_compile = False/' chelper/__init__.py
fi
[ -f chelper/c_helper.so ] || (cd "$FORK_DIR" && git checkout klippy/chelper/c_helper.so)

echo ">>> [5/5] Creating CFS data files under /usr/data/creality/userdata"
sudo mkdir -p /usr/data/creality/userdata/box /usr/data/creality/userdata/config
for j in box/material_database.json box/tn_data.json config/system_config.json; do
  [ -f "/usr/data/creality/userdata/$j" ] || echo '{}' | sudo tee "/usr/data/creality/userdata/$j" >/dev/null
done
sudo touch /usr/data/creality/userdata/config/flushing_sign
sudo chown -R "$USER":"$USER" /usr/data/creality 2>/dev/null || true

echo
echo ">>> DONE. The K2 fork at $FORK_DIR is ready to run the CFS modules."
echo "    Next: build your printer.cfg (add [serial_485]/[auto_addr]/[box]) and run"
echo "    scripts/test_k2_fork.sh to verify it reaches 'Printer is ready'."
