#!/bin/bash
# ============================================================================
#  test_k2_fork.sh
#  Run the K2 fork klippy against a printer.cfg and report whether it reaches
#  "Printer is ready". Stops the currently-running klipper service first so
#  the serial port is free, then runs the fork klippy standalone for 25s.
#
#  Usage:  ./test_k2_fork.sh [/path/to/printer.cfg] [/path/to/k2_klipper]
#  Revert: ./revert_mainline.sh   (or: sudo systemctl start klipper)
# ============================================================================
CFG="${1:-$HOME/printer_data/config/printer.cfg}"
FORK_DIR="${2:-$HOME/k2_klipper}"
VENV="${KLIPPY_ENV:-$HOME/klippy-env}"
LOG="/tmp/k2fork_test.log"

echo ">>> printer board connected?"
ls -l /dev/serial/by-id/ 2>&1

echo ">>> stopping current klipper service (frees the serial port)..."
sudo systemctl stop klipper 2>/dev/null
sleep 2

echo ">>> running K2 fork klippy for 25s against: $CFG"
cd "$FORK_DIR/klippy" || exit 1
rm -f "$LOG"
timeout 25 "$VENV/bin/python" klippy.py "$CFG" -l "$LOG" -a /tmp/k2fork_test.sock >/dev/null 2>&1

echo
echo "================= RESULT ================="
if grep -qa "Printer is ready" "$LOG"; then
  echo "  *** SUCCESS: the K2 fork reached READY ***"
else
  echo "  *** did NOT reach ready -- see key log lines below ***"
fi
echo "---- key log lines ----"
grep -aE "Starting Klippy|Loaded MCU|Printer is ready|mcu 'mcu':|Unable to open|deprecated|Config error|box:load_config|serial_485:|Protocol error|Unknown|shutdown" "$LOG" | tail -30
echo "=========================================="
echo "Full log: $LOG    |    Revert: ./revert_mainline.sh"
