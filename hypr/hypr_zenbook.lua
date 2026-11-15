hl.monitor({ output = "eDP-1", mode = "1920x1200@60.00", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1200@60.00", position = "0x0", scale = 1, mirror = "eDP-1" })
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", default = true })

return {
    monitor = "eDP-1",
    cursor = { 960, 600 },
    autostart = {
        "waybar -c $HOME/.config/waybar/conf_zenbook.jsonc",
        "mako",
        "$HOME/.config/dotfiles/scripts/batt_check.sh",
    },
}
