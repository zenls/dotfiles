#!/usr/bin/env bash

BLOCKED_REAL_IPV4=""
ALLOW_IPV6="no"
API_URL="https://ipwho.is/"
CURL_OPTS=(-fsS --connect-timeout 1 --max-time 3)

for bin in curl jq; do
    command -v "$bin" >/dev/null 2>&1 || {
        jq -n --arg text "error" --arg class "warning" --arg tooltip "Missing dependency: $bin" \
          '{text:$text,class:$class,tooltip:$tooltip}'
        exit 1
    }
done

is_private_ipv4() {
    case "$1" in
        10.*|127.*|192.168.*|169.254.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

fetch_ip_json() {
    local family="$1"
    curl "-$family" "${CURL_OPTS[@]}" "$API_URL" 2>/dev/null || printf '{}'
}

addr4_json="$(fetch_ip_json 4)"

if [ "$ALLOW_IPV6" = "no" ]; then
    addr6_json="$(fetch_ip_json 6)"
else
    addr6_json='{}'
fi

IFS=$'\t' read -r ok4 ip4 country continent country_iso city asn_num asn_org <<EOF
$(jq -r '[
    (.success // true),
    (.ip // ""),
    (.country // "—"),
    (.continent // "—"),
    (.country_code // "—"),
    (.city // "—"),
    (.connection.asn // ""),
    (.connection.org // "—")
] | @tsv' <<<"$addr4_json")
EOF

ip6="$(jq -r '.ip // ""' <<<"$addr6_json")"

leak="no"
class="normal"
reasons=()

if [ "$ok4" != "true" ] || [ -z "$ip4" ]; then
    leak="yes"
    reasons+=("failed to detect public IPv4")
fi

if [ -n "$BLOCKED_REAL_IPV4" ] && [ "$ip4" = "$BLOCKED_REAL_IPV4" ]; then
    leak="yes"
    reasons+=("real IPv4 detected")
fi

if [ -n "$ip4" ] && is_private_ipv4 "$ip4"; then
    leak="yes"
    reasons+=("non-public IPv4 returned: $ip4")
fi

if [ "$ALLOW_IPV6" = "no" ] && [ -n "$ip6" ]; then
    leak="yes"
    reasons+=("IPv6 visible: $ip6")
fi

text="${country_iso} ${ip4:-—}"

if [ "$leak" = "yes" ]; then
    class="warning"
    text="${text} [LEAK]"
fi

tooltip="${country_iso} -> ${ip4:-—}"
tooltip+=$'\n'"City: ${city}"
tooltip+=$'\n'"Country: ${country}"
tooltip+=$'\n'"Continent: ${continent}"
tooltip+=$'\n'"ASN: AS${asn_num:-?} ${asn_org}"
tooltip+=$'\n'"IPv6: ${ip6:-not visible}"
tooltip+=$'\n'"Leak: ${leak}"

if [ "${#reasons[@]}" -gt 0 ]; then
    tooltip+=$'\n'"   ---  Reason(s)  ---"
    for r in "${reasons[@]}"; do
        tooltip+=$'\n'"- $r"
    done
fi

jq -n --unbuffered --compact-output \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  --arg class "$class" \
  '{text:$text,
    class:$class,
    tooltip: ($tooltip | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;"))}'