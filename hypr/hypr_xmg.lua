local displays = require("xmg_monitors")
local layout = displays.plan(displays.read_topology())

if layout.desktop then
    -- The complete known desktop setup: Gigabyte + both Philips displays.
    local function set_gigabyte_hdr(enabled)
        hl.monitor({
            output = layout.main,
            mode = "2560x1440@59.95",
            position = "0x0",
            scale = 1,
            bitdepth = enabled and 10 or 8,
            cm = enabled and "hdr" or "srgb",

            -- HDR Peak 1500 overrides; SDR uses automatic display luminance.
            -- Nominal values, not measured calibration values.
            min_luminance = enabled and 0 or -1,
            max_luminance = enabled and 1500 or -1,
            max_avg_luminance = enabled and 295 or -1,

            -- Personal SDR-to-HDR preferences; defaults restored in SDR mode.
            sdr_min_luminance = enabled and 0 or 0.2,
            sdr_max_luminance = enabled and 140 or 80,
            sdrbrightness = 1.0,
            sdrsaturation = enabled and 1.25 or 1.0,
        })
    end

    -- Start in SDR, including after a configuration reload.
    set_gigabyte_hdr(false)
    hl.bind("SUPER + SHIFT + H", function()
        local monitor = hl.get_monitor(layout.main)
        if not monitor then return end
        local is_hdr = monitor.cm == "hdr" or monitor.cm == "hdredid"
        set_gigabyte_hdr(not is_hdr)
    end)

    hl.monitor({ output = layout.left, mode = "2560x1440@74.97", position = "-1440x-700", scale = 1, transform = 3 })
    hl.monitor({ output = layout.up, mode = "1920x1080@74.97", position = "0x-1080", scale = 1 })
    hl.monitor({ output = layout.internal, disabled = true })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
else
    -- Portable setup: internal SDR panel is the source for every external output.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1,
        transform = 0, bitdepth = 8, cm = "srgb", mirror = layout.internal })
    hl.monitor({ output = layout.internal, mode = "preferred", position = "0x0", scale = 1,
        transform = 0, bitdepth = 8, cm = "srgb", mirror = "", disabled = false })
end

hl.config({
    render = {
        cm_enabled = true,
        cm_auto_hdr = 0,
        -- Untagged SDR apps use sRGB; explicit client metadata is preserved.
        cm_sdr_eotf = "srgb",
    },
})
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

for workspace = 1, 10 do
    local monitor = layout.main
    local default = workspace == 1
    if layout.desktop then
        if workspace == 8 or workspace == 9 then monitor = layout.left end
        if workspace == 10 then monitor = layout.up end
        default = workspace == 1 or workspace == 8 or workspace == 10
    end
    -- Waybar reads these persistent rules instead of duplicating the layout.
    hl.workspace_rule({ workspace = tostring(workspace), monitor = monitor, default = default, persistent = true })
end

-- Debounce connector events. Reload only when physical topology changes;
-- enabling/disabling/mirroring a display must not cause a reload loop.
local function check_topology()
    local updated = displays.plan(displays.read_topology())
    if updated.signature ~= layout.signature then hl.exec_cmd("hyprctl reload") end
end

-- Create timers only after startup, when Hyprland's event loop is available.
local topology_check
local function schedule_topology_check()
    if topology_check then topology_check:set_enabled(false) end
    topology_check = hl.timer(check_topology, { timeout = 500, type = "oneshot" })
end
hl.on("hyprland.start", schedule_topology_check)
hl.on("monitor.added", schedule_topology_check)
hl.on("monitor.removed", schedule_topology_check)
hl.on("monitor.layout_changed", schedule_topology_check)

return {
    monitor = layout.main,
    cursor = layout.cursor,
    autostart = {
        "waybar -c $HOME/.config/waybar/conf_xmg.jsonc",
        "hyprpaper",
        "hypridle",
        "mako",
        "$HOME/.config/dotfiles/scripts/jbl_autoconnect.sh",
        "$HOME/.config/dotfiles/scripts/batt_check.sh",
    },
}
