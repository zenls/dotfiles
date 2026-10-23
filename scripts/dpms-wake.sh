#!/usr/bin/env bash
set -euo pipefail

# Turn DPMS on for all outputs first
hyprctl dispatch dpms on
sleep 0.2

# NVIDIA-attached monitor to wake after restoring the saved configuration
NVIDIA_MONITOR="HDMI-A-4"

# Restore the complete monitorv2 rule, including HDR and luminance settings.
hyprctl reload
sleep 0.2

# One more DPMS on to ensure the output is marked active
hyprctl dispatch dpms on "$NVIDIA_MONITOR"
