#!/usr/bin/env bash

addr_json="$(curl -4 -s --max-time 3 https://ipwho.is/ || echo '{}')"

ip=$(jq -r '.ip // "—"' <<<"$addr_json")
country=$(jq -r '.country // "—"' <<<"$addr_json")
country_iso=$(jq -r '.country_code // "—"' <<<"$addr_json")
city=$(jq -r '.city // "—"' <<<"$addr_json")
asn_org=$(jq -r '.connection.org // "—"' <<<"$addr_json")

text="${country_iso} ${ip}"

tooltip="${country_iso} -> ${ip}"
tooltip+=$'\n'"City: ${city}"
tooltip+=$'\n'"Country: ${country}"
tooltip+=$'\n'"ASN: ${asn_org}"

jq -n --unbuffered --compact-output \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  '{text:$text,
    tooltip: ($tooltip | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;"))}'