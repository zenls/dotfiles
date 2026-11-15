#!/usr/bin/env bash

# A Bluetooth device can disappear between any two sysfs reads.
read_value() {
    local value=""
    { IFS= read -r value < "$1"; } 2>/dev/null
    printf '%s' "$value"
}

main() {
    local battery_pattern=${1:?Usage: hid_battery.sh BATTERY_GLOB}
    local supply_root=${2:-/sys/class/power_supply}
    local supply capacity device key value name status state class tooltip
    local hid_id hid_name hid_uniq bus connection serial manufacturer

    for supply in "$supply_root"/*; do
        [[ ${supply##*/} == $battery_pattern ]] || continue
        [[ -d $supply ]] || continue
        [[ $(read_value "$supply/present") != 0 ]] || continue
        capacity=$(read_value "$supply/capacity")
        [[ $capacity =~ ^[0-9]{1,3}$ ]] || continue
        capacity=$((10#$capacity))
        (( capacity <= 100 )) || continue

        # Resolve the battery symlink, then find its parent HID device.
        device=$(cd -P -- "$supply" 2>/dev/null && pwd -P) || continue
        hid_id="" hid_name="" hid_uniq=""
        while [[ -n $device && $device != / ]]; do
            if [[ -r $device/uevent ]]; then
                {
                    while IFS='=' read -r key value; do
                        case "$key" in
                            HID_ID) hid_id=$value ;;
                            HID_NAME) hid_name=$value ;;
                            HID_UNIQ) hid_uniq=$value ;;
                        esac
                    done < "$device/uevent"
                } 2>/dev/null
            fi
            [[ -n $hid_id ]] && break
            device=${device%/*}
        done

        name=$(read_value "$supply/model_name")
        name=${name:-$hid_name}
        [[ -n $name ]] || continue
        status=$(read_value "$supply/status")
        case "$status" in
            Charging) state="Charging"; class="charging" ;;
            Discharging) state="Discharging"; class="discharging" ;;
            Full) state="Fully charged"; class="full" ;;
            'Not charging') state="Not charging"; class="unknown" ;;
            Unknown|'') state="Unknown"; class="unknown" ;;
            *) state=$status; class="unknown" ;;
        esac
        # Some drivers report a full battery as "Not charging".
        if (( capacity == 100 )) && [[ $status != Charging ]]; then
            class="full"
        fi
        tooltip="$name"$'\n'"Battery: $capacity%"$'\n'"Status: $state"

        bus=${hid_id%%:*}
        connection=""
        case "$bus" in
            0005) connection="Bluetooth" ;;
            0003) connection="USB" ;;
        esac
        [[ -n $connection ]] && tooltip+=$'\n'"Connection: $connection"
        serial=$(read_value "$supply/serial_number")
        serial=${serial:-$hid_uniq}
        if [[ -n $serial ]]; then
            if [[ $bus == 0005 ]]; then
                tooltip+=$'\n'"Bluetooth address: $serial"
            else
                tooltip+=$'\n'"Serial number: $serial"
            fi
        fi
        manufacturer=$(read_value "$supply/manufacturer")
        [[ -n $manufacturer ]] && tooltip+=$'\n'"Manufacturer: $manufacturer"

        [[ -d $supply && $(read_value "$supply/present") != 0 ]] || continue
        jq -cn --arg text "$capacity%" --arg tooltip "$tooltip" --arg class "$class" \
            --argjson percentage "$capacity" \
            '{text:$text, percentage:$percentage, class:$class, tooltip:($tooltip | @html)}'
        return
    done

    printf '{"text":"","tooltip":""}\n'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
