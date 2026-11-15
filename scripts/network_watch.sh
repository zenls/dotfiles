#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
source "$SCRIPT_DIR/network_state.sh"

main() {
    local state_dir previous current event monitor_pid='' burst_end
    state_dir=$(network_state_dir)
    umask 077
    mkdir -p -- "$state_dir" || return 1
    exec 9>"$state_dir/watcher.lock"
    flock -n 9 || return 0
    trap '[[ -z $monitor_pid ]] || kill "$monitor_pid" 2>/dev/null || true' EXIT
    trap 'exit 0' INT TERM
    previous=$(network_snapshot) || previous=''
    while :; do
        # The child must not retain the singleton lock if this shell exits.
        exec 3< <(exec ip monitor link address route rule 9>&-)
        monitor_pid=$!
        while IFS= read -r event <&3; do
            # Wait for two quiet seconds, but cap a continuous event burst at ten.
            burst_end=$((SECONDS + 10))
            while (( SECONDS < burst_end )) && IFS= read -r -t 2 event <&3; do :; done
            current=$(network_snapshot) || continue
            if [[ $current != "$previous" ]]; then
                previous=$current
                pkill -RTMIN+8 -u "$UID" -x waybar 2>/dev/null || true
            fi
        done
        exec 3<&-
        wait "$monitor_pid" 2>/dev/null || true
        monitor_pid=''
        sleep 5
    done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main; fi
