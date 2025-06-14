#!/bin/bash
low_power=20
 
while [ true ]
do
    if (( `cat /sys/class/power_supply/BAT1/capacity` <= $low_power )) \
    && [[ `cat /sys/class/power_supply/BAT1/status` == Discharging ]]
    then
        notify-send -u critical -i computer-fail "System" "Battery empty."
    fi
    sleep 30
done
