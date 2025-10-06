#!/bin/bash

STATE_FILE="/tmp/.nextcloud_sync.json"
EXIT_FILE="/tmp/.nextcloud_sync.exit"
NEXTCLOUD_FOLDER="nextcloud_sync"
LOCAL_FOLDER="$HOME/$NEXTCLOUD_FOLDER"
DELAY_SEC=$((30 * 60))

CMD=(nextcloudcmd -n -s --path "$NEXTCLOUD_FOLDER" "$LOCAL_FOLDER" "https://cloud.zenembed.com")

FORCE_SYNC=0
[[ $1 == "-f" ]] && FORCE_SYNC=1

start_sync() {
    rm -f "$EXIT_FILE"
    mkdir -p "$LOCAL_FOLDER"
    (
        "${CMD[@]}"
        echo "$?" >"$EXIT_FILE"
    ) &
    local pid=$!
    local ts
    ts=$(date +%s)
    jq -n --arg pid "$pid" --arg ts "$ts" \
        '{pid: ($pid|tonumber), timestamp: ($ts|tonumber)}' >"$STATE_FILE"

    # notify-send -i nextcloud "Nextcloud" "Start Sync..."
    echo "󰔪"
}

# --- main ---

if [[ ! -f "$STATE_FILE" ]]; then
    start_sync
    exit 0
fi

pid=$(jq -r '.pid // empty' "$STATE_FILE" 2>/dev/null || echo "")
ts=$(jq -r '.timestamp // empty' "$STATE_FILE" 2>/dev/null || echo "")

# If nextcloudcmd running now
if kill -0 "$pid" 2>/dev/null; then
    echo "󰔪"

# If -f options was enabled
elif [[ "$FORCE_SYNC" -eq 1 ]]; then
    start_sync

# If time < DELAY_SEC
elif (($(($(date +%s) - ts)) <= DELAY_SEC)); then
    if (($(<"$EXIT_FILE") == 0)); then
        if find "$LOCAL_FOLDER" -type f -iname '*conflicted copy*' -printf . -quit | grep -q .; then
            notify-send -u critical -i nextcloud "Nextcloud" "Sync has conflicted file"
            echo "23" >"$EXIT_FILE"
        else
            # notify-send -u low -i nextcloud "Nextcloud" "Sync was finished."
            echo "55" >"$EXIT_FILE"
        fi
    fi

    if (($(<"$EXIT_FILE") == 23)); then
        echo "󰧠"
    elif (($(<"$EXIT_FILE") == 55)); then
        echo "󰅠"
    fi

# If time > DELAY_SEC
else
    start_sync
fi
