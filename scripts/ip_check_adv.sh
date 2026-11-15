#!/usr/bin/env bash

# Free API: 1,000 requests/day per public IP; HTTP 429 includes Retry-After.
# https://ipwhois.io/documentation#rate-limits
API_URL="https://ipwho.is/"
# Waybar owns the 300-second poll; this short cache deduplicates panel instances.
CACHE_SECONDS=30
CURL_OPTS=(-sS --noproxy '*' --connect-timeout 3 --max-time 8)

SCRIPT_DIR=$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)
source "$SCRIPT_DIR/network_state.sh"

emit_error() {
    jq -cn --arg message "$1" \
        '{text:"IP error", class:"error", tooltip:(("ERR ▸ " + $message | @html) | "<span font_family=\"JetBrainsMono Nerd Font\">" + . + "</span>")}'
}

valid_address() {
    local family=$1 address=$2 octet
    local -a octets
    if [[ $family == 4 ]]; then
        [[ $address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
        IFS=. read -r -a octets <<< "$address"
        for octet in "${octets[@]}"; do (( 10#$octet <= 255 )) || return 1; done
        case "$address" in
            0.*|10.*|127.*|169.254.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 1 ;;
        esac
        (( 10#${octets[0]} < 224 )) || return 1
        if (( 10#${octets[0]} == 100 && 10#${octets[1]} >= 64 && 10#${octets[1]} <= 127 )); then return 1; fi
    else
        [[ $address == *:* && $address =~ ^[0-9a-fA-F:]+$ ]] || return 1
        [[ $address != ::* && $address != [fF][cCdD]* && $address != [fF][eE][89aAbB]* ]] || return 1
    fi
}

fetch_family() {
    local family=$1 route=$2 cache="$state_dir/ipv$1.json"
    local cached='{}' checked=0 retry_until=0 ttl=60 cached_network
    local body headers errors meta http remote rc data='null' address='' error='' retry=0 line
    if [[ $route == null ]]; then
        jq -cn --arg family "IPv$family" '{ok:false, offline:true, error:($family + ": no route")}'
        return
    fi
    [[ -r $cache ]] && cached=$(jq -ce 'select(type == "object")' "$cache" 2>/dev/null)
    cached=${cached:-'{}'}
    checked=$(jq -r '.checked_at // 0' <<< "$cached")
    retry_until=$(jq -r '.retry_until // 0' <<< "$cached")
    cached_network=$(jq -r '.network // ""' <<< "$cached")
    if [[ $cached_network == "$fingerprint" ]]; then
        if (( retry_until > now )); then printf '%s\n' "$cached"; return; fi
        [[ $(jq -r '.ok // false' <<< "$cached") == true ]] && ttl=$CACHE_SECONDS
        if (( now - checked < ttl && (force == 0 || now - checked < 15) )); then
            printf '%s\n' "$cached"
            return
        fi
    fi

    body="$state_dir/body-$family" headers="$state_dir/headers-$family" errors="$state_dir/errors-$family"
    # Direct requests measure this host's egress rather than an inherited HTTP proxy.
    meta=$(curl "-$family" "${CURL_OPTS[@]}" -o "$body" -D "$headers" \
        -w '%{http_code} %{remote_ip}' "$API_URL" 2>"$errors")
    rc=$?
    read -r http remote <<< "$meta"
    http=${http:-000}
    if (( rc != 0 )); then
        error="$(<"$errors")"
        error=${error:-"Network request failed (curl $rc)"}
    elif [[ $http == 429 ]]; then
        retry=86400
        while IFS= read -r line; do
            line=${line%$'\r'}
            if [[ ${line,,} == retry-after:* ]]; then
                line=${line#*:}
                line=${line//[[:space:]]/}
                [[ $line =~ ^[0-9]{1,8}$ ]] && retry=$((10#$line))
            fi
        done < "$headers"
        (( retry >= 60 )) || retry=60
        error="API rate limit reached (HTTP 429); backoff: $retry seconds"
    elif [[ $http != 200 ]]; then
        error="IP API returned HTTP $http"
    else
        data=$(jq -cs 'if length == 1 and (.[0] | type == "object") then .[0] else null end' "$body" 2>/dev/null)
        data=${data:-null}
        if ! jq -e '.success == true and (.ip | type == "string") and .type == $type' \
            --arg type "IPv$family" <<< "$data" >/dev/null; then
            error=$(jq -r '.message // "Invalid or unsuccessful IP API response"' <<< "$data")
        else
            address=$(jq -r '.ip' <<< "$data")
            if ! valid_address "$family" "$address"; then
                error="IP API returned an invalid or non-public IPv$family address"
            fi
        fi
    fi
    cached=$(jq -cn --argjson at "$now" --arg network "$fingerprint" \
        --argjson data "$data" --arg error "$error" --argjson retry "$((retry > 0 ? now + retry : 0))" \
        --arg remote "${remote:-}" \
        '{checked_at:$at, network:$network, ok:($error == ""), data:$data,
          error:$error, remote:$remote, retry_until:$retry}')
    printf '%s\n' "$cached" > "$cache.tmp"
    mv -f -- "$cache.tmp" "$cache"
    printf '%s\n' "$cached"
}

with_route() {
    local family=$1 result=$2 remote route='[]'
    remote=$(jq -r '.remote // ""' <<< "$result")
    if [[ -n $remote ]] && [[ $(jq -r '.ok' <<< "$result") == true ]]; then
        route=$(ip -j "-$family" route get "$remote" 2>/dev/null) || route='[]'
    fi
    jq -c --argjson routes "$route" --argjson tunnels "$snapshot" '
        .route = ($routes[0].dev // "") |
        .via_vpn = (.route as $dev | ($tunnels.tunnels | index($dev)) != null)
    ' <<< "$result"
}

render_widget() {
    jq -cn --argjson network "$snapshot" --argjson v4 "$result4" --argjson v6 "$result6" '
        def value: if type == "string" and length > 0 then . else "--" end;
        def short_error:
            if test("HTTP [0-9]+") then capture("(?<code>HTTP [0-9]+)").code
            elif test("(?i)timeout|timed out|\\(28\\)") then "TIMEOUT"
            elif test("\\(6\\)") then "DNS"
            elif test("\\(7\\)") then "UNREACH"
            elif test("\\(35\\)|\\(60\\)") then "TLS"
            else "API ERR" end;
        def family($name; $r):
            $name + " " +
            (if $r.offline then "--"
             elif $r.ok then $r.data.ip + " ▸ " +
                 (if $r.route == "" then "?" else $r.route end)
             else "! " + ($r.error | short_error) end);
        [$v4, $v6] as $results |
        ($results | map(select(.ok))) as $good |
        ($network.tunnels | length > 0) as $vpn |
        ($good | map(select(.route != "" and (.via_vpn | not))) | length > 0) as $direct |
        ($results | map(select((.offline | not) and (.ok | not))) | length > 0) as $failed |
        ($good | map(select(.route == "")) | length > 0) as $unknown_route |
        ($vpn and $direct) as $bypass |
        # Direct public IPv6 is exposed even when no VPN tunnel is active.
        ($v6.ok and $v6.route != "" and ($v6.via_vpn | not)) as $v6_exposed |
        (($v6.ok | not) and ($v6.offline | not)) as $v6_unknown |
        ($good[0].data // {}) as $geo |
        ($geo.connection | if type == "object" then . else {} end) as $connection |
        (if $v6_exposed then " 6"
         elif $bypass then " "
         elif ($good | length) == 0 then ""
         elif $v6_unknown then "?6"
         elif $unknown_route or $failed then "?"
         elif $vpn then "" else "" end) as $icon |
        (if $v6_exposed then "V6 EXPOSED"
         elif $bypass then "BYPASS"
         elif $v4.offline and $v6.offline then "OFFLINE"
         elif ($good | length) == 0 then "ERR"
         elif $unknown_route or $failed then "PARTIAL"
         elif $vpn then "VPN" else "DIRECT" end) as $status |
        {text:(if ($good | length) == 0 then
                    if $v4.offline and $v6.offline then "Offline" else "IP error" end
               else ($geo.country_code | value) + " " + $geo.ip +
                    (if $v6_exposed then " [IPv6]"
                     elif $bypass then " [BYPASS]" else "" end) end),
         class:(if $bypass or $v6_exposed then "warning"
                elif ($good | length) == 0 then
                    if $v4.offline and $v6.offline then "disconnected" else "error" end
                elif $failed or $unknown_route then "unknown"
                elif $vpn then "normal" else "direct" end),
         tooltip:([
             "┌ [" + $icon + "] " + $status,
             "├ " + family("4"; $v4),
             (if ($good | length) > 0 then "├ " else "└ " end) + family("6"; $v6)] +
             (if ($good | length) > 0 then [
                 "└ " + ($geo.city | value) + " · " + ($geo.country_code | value) + " · " +
                 (if ($connection.asn | type) == "number" then "AS" + ($connection.asn | tostring) else "AS?" end)]
              else [] end) | join("\n") | @html | "<span font_family=\"JetBrainsMono Nerd Font\">" + . + "</span>")}
    '
}

main() {
    local state_dir snapshot fingerprint now force=0 result4 result6
    for bin in jq curl ip flock; do
        if ! command -v "$bin" >/dev/null 2>&1; then
            if command -v jq >/dev/null 2>&1; then emit_error "Missing dependency: $bin"
            else printf '{"text":"IP error","class":"error","tooltip":"Missing dependency: jq"}\n'; fi
            return 1
        fi
    done
    state_dir=$(network_state_dir)
    umask 077
    mkdir -p -- "$state_dir" || { emit_error "Cannot create IP widget state directory"; return 1; }
    if [[ ${1:-} == --refresh ]]; then
        touch "$state_dir/refresh"
        pkill -RTMIN+8 -u "$UID" -x waybar 2>/dev/null || true
        return
    fi
    exec 9>"$state_dir/check.lock"
    flock 9
    if ! snapshot=$(network_snapshot); then emit_error "Cannot read network interfaces or routing rules"; return; fi
    fingerprint=$snapshot
    now=$(date +%s)
    if [[ -f $state_dir/refresh ]]; then force=1; rm -f -- "$state_dir/refresh"; fi
    result4=$(fetch_family 4 "$(jq -c '.ipv4' <<< "$snapshot")")
    result6=$(fetch_family 6 "$(jq -c '.ipv6' <<< "$snapshot")")
    result4=$(with_route 4 "$result4")
    result6=$(with_route 6 "$result6")
    render_widget
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
