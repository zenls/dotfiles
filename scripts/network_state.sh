#!/usr/bin/env bash

# Shared, read-only routing information for the IP widget and network watcher.
network_state_dir() {
    printf '%s' "${IP_CHECK_STATE_DIR:-${XDG_RUNTIME_DIR:-/tmp}/waybar-ip-$UID}"
}

network_snapshot() {
    local links route4 route6 rules4 rules6
    links=$(ip -j -d link show 2>/dev/null) || return 1
    route4=$(ip -j -4 route get 1.1.1.1 2>/dev/null) || route4='[]'
    route6=$(ip -j -6 route get 2606:4700:4700::1111 2>/dev/null) || route6='[]'
    rules4=$(ip -j -4 rule show 2>/dev/null) || return 1
    rules6=$(ip -j -6 rule show 2>/dev/null) || return 1
    jq -cnS --argjson links "$links" --argjson route4 "$route4" \
        --argjson route6 "$route6" --argjson rules4 "$rules4" --argjson rules6 "$rules6" '
        def route($r):
            if ($r[0].dev // "") == "" then null
            else $r[0] | {dev, source:(.prefsrc // .src // ""), gateway:(.gateway // "")}
            end;
        {ipv4:route($route4), ipv6:route($route6), rules4:$rules4, rules6:$rules6,
         tunnels:[$links[] | select((.flags // []) | index("UP")) |
             select((.linkinfo.info_kind // "") |
                 IN("wireguard", "amneziawg", "tun", "tap")) | .ifname] | sort}
    '
}

vpn_widget() {
    local snapshot
    if ! snapshot=$(network_snapshot); then
        printf '{"text":"?","class":"error","tooltip":"VPN ▸ ERR"}\n'
        return
    fi
    jq -cn --argjson network "$snapshot" '
        $network.tunnels as $tunnels |
        [$network.ipv4, $network.ipv6] | map(select(. != null)) as $routes |
        if ($tunnels | length) == 0 then
            {text:"", class:"warning", tooltip:"<span font_family=\"JetBrainsMono Nerd Font\"> VPN OFF</span>"}
        else
            [$routes[] | select(.dev as $dev | $tunnels | index($dev) | not)] as $direct |
            {text:"", class:(if ($direct | length) > 0 then "warning" else "connected" end),
             tooltip:(["┌  " + ($tunnels | join(", ")),
                 "├ 4 ▸ " + ($network.ipv4.dev // "--"),
                 "└ 6 ▸ " + ($network.ipv6.dev // "--")] | join("\n") | @html | "<span font_family=\"JetBrainsMono Nerd Font\">" + . + "</span>")}
        end
    '
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    if [[ ${1:-} == --vpn ]]; then vpn_widget; else network_snapshot; fi
fi
