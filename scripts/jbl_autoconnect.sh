#!/usr/bin/env bash
set -euo pipefail

DEV_NAME="JBL C5"
DEV_MAC="2C:FD:B4:4F:72:E0"

sleep 3

# Enable adapter and agent
bluetoothctl <<EOF >/dev/null
power on
agent on
default-agent
EOF

# Exit early if the device is already connected
if bluetoothctl info "$DEV_MAC" 2>/dev/null | grep -q "Connected: yes"; then
    echo "$DEV_NAME is already connected, exiting."
    exit 0
fi

# Note: this will only work reliably if the device is already paired and trusted
echo "Trying to connect to $DEV_NAME [$DEV_MAC]..."
if bluetoothctl connect "$DEV_MAC"; then
    echo "$DEV_NAME successfully connected."
    exit 0
else
    echo "Failed to connect to $DEV_NAME."
fi