#!/bin/bash
# Restart the normal (mainline) klipper service after a fork test.
sudo systemctl start klipper
echo "klipper service restarted."
systemctl is-active klipper
