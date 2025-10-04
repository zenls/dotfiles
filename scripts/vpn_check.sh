#! /bin/bash

addr=$(curl -4 -s ifconfig.net/json)
ip=$(echo $addr | jq -r '.ip')
con=$(echo $addr | jq -r '.country_iso')
echo $con $ip
