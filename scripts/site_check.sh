#!/usr/bin/env bash

sites=(zenembed.com work.zenembed.com git.zenembed.com)
path="/"

connect_timeout=3
max_time=5

get_code() {
    local url="$1"
    curl -sS -o /dev/null -w '%{http_code}' -L \
        --connect-timeout "$connect_timeout" --max-time "$max_time" \
        "$url" 2>/dev/null || echo 000
}

text=""
tooltip="Check status"
has_error=0

for host in "${sites[@]}"; do
    code=$(get_code "https://${host}${path}")
    if [[ "$code" =~ ^[0-9]{3}$ && "$code" -ge 200 && "$code" -lt 400 ]]; then
        sym=""
    else
        sym=""
        has_error=1
    fi
    text+="$sym "
    tooltip+=$'\n'" - [${sym}] ${host}"
done

text="${text% }"

class=""
[[ $has_error -eq 1 ]] && class="warning"

jq -n --unbuffered --compact-output \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text:$text, tooltip:$tooltip, class:$class}'
