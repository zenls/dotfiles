#!/bin/bash

STATE_FILE="/tmp/.nextcloud_sync.json"
EXIT_FILE="/tmp/.nextcloud_sync.exit"
CMD=(nextcloudcmd -n -s --path nextcloud ~/nextcloud "https://cloud.zenembed.com")
DELAY_SEC=$((30 * 60))

FORCE_SYNC=0
[[ $1 == "-f" ]] && { FORCE_SYNC=1; }

start_sync() {
  rm -f "$EXIT_FILE"
  (
    "${CMD[@]}" >/dev/null 2>&1
    echo "$?" > "$EXIT_FILE"
  ) &
  local pid=$!
  local ts
  ts=$(date +%s)
  jq -n --arg pid "$pid" --arg ts "$ts" \
    '{pid: ($pid|tonumber), timestamp: ($ts|tonumber)}' > "$STATE_FILE"
}

# --- main ---

if [[ ! -f "$STATE_FILE" ]]; then
  start_sync
  echo "󰔪"
  exit 0
fi

pid=$(jq -r '.pid // empty' "$STATE_FILE" 2>/dev/null || echo "")
ts=$(jq -r '.timestamp // empty' "$STATE_FILE" 2>/dev/null || echo "")

if [[ -z "$pid" || -z "$ts" ]]; then
  echo "󰨹"
  exit 0
fi

if kill -0 "$pid" 2>/dev/null; then
  echo "󰔪"
elif [[ "$FORCE_SYNC" -eq 1 ]]; then
  start_sync
elif (( $(( $(date +%s) - ts )) <= DELAY_SEC )); then
  if [[ -f "$EXIT_FILE" ]]; then
    exit_code=$(<"$EXIT_FILE")
    if (( $exit_code == 0 )); then
      echo "󰅠"
    else
      echo "󰧠"
    fi
  else
    echo "󰔪"
  fi
else
  start_sync
fi
