-- Read the current kernel hostname; accept short names and FQDNs.
local hostname = ""
local hostname_file = io.open("/proc/sys/kernel/hostname", "r")
if hostname_file then
    hostname = (hostname_file:read("*l") or ""):lower():match("^[^.%s]+") or ""
    hostname_file:close()
end

local profiles = {
    xmg = "hypr_xmg",
    zenbook = "hypr_zenbook",
}
-- Unknown hosts use the laptop profile, which keeps the internal display on.
local profile = require(profiles[hostname] or "hypr_zenbook")

local terminal = "kitty"
local file_manager = "thunar"
local menu = "wofi --show drun"
local mod = "SUPER"

-- Avoid realtime timeout kills during DPMS/hotplug (Hyprland #16648).
hl.env("HYPRLAND_NO_RT", "1")    -- Check it after update
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("GTK_THEME", "Adwaita:dark")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    decoration = {
        rounding = 6,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true, force_split = 2 },
    master = { new_status = "master" },
    misc = {
        disable_hyprland_logo = false,
        disable_splash_rendering = true,
        force_default_wallpaper = 2,
    },
    input = {
        kb_layout = "us,ru",
        kb_variant = "",
        kb_model = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules = "",
        follow_mouse = 0,
        -- Focus inactive windows without passing the activating click to the app.
        swallow_focus_click = true,
        float_switch_override_focus = false,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
    cursor = { no_hardware_cursors = 2 },
})

-- Map the Bluetooth Wacom to the current profile's main display.
hl.device({
    name = "wacom-intuos-bt-s-pen",
    output = profile.monitor,
})

-- Preserve the existing animation curves, speeds, and styles.
local curves = {
    { "easeOutQuint", { 0.23, 1 }, { 0.32, 1 } },
    { "easeInOutCubic", { 0.65, 0.05 }, { 0.36, 1 } },
    { "linear", { 0, 0 }, { 1, 1 } },
    { "almostLinear", { 0.5, 0.5 }, { 0.75, 1.0 } },
    { "quick", { 0.15, 0 }, { 0.1, 1 } },
}
for _, curve in ipairs(curves) do
    hl.curve(curve[1], { type = "bezier", points = { curve[2], curve[3] } })
end

local animations = {
    { "global", 10, "default" },
    { "border", 5.39, "easeOutQuint" },
    { "windows", 4.79, "easeOutQuint" },
    { "windowsIn", 4.1, "easeOutQuint", "popin 87%" },
    { "windowsOut", 1.49, "linear", "popin 87%" },
    { "fadeIn", 1.73, "almostLinear" },
    { "fadeOut", 1.46, "almostLinear" },
    { "fade", 3.03, "quick" },
    { "layers", 3.81, "easeOutQuint" },
    { "layersIn", 4, "easeOutQuint", "fade" },
    { "layersOut", 1.5, "linear", "fade" },
    { "fadeLayersIn", 1.79, "almostLinear" },
    { "fadeLayersOut", 1.39, "almostLinear" },
    { "workspaces", 1.94, "almostLinear", "fade" },
    { "workspacesIn", 1.21, "almostLinear", "fade" },
    { "workspacesOut", 1.94, "almostLinear", "fade" },
}
for _, animation in ipairs(animations) do
    hl.animation({
        leaf = animation[1],
        enabled = true,
        speed = animation[2],
        bezier = animation[3],
        style = animation[4],
    })
end

-- Dispatchers are bound directly through the Lua API.
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + W", hl.dsp.window.close())
-- Bring the newest floating window to the current workspace.
hl.bind(mod .. " + SHIFT + W", function()
    local workspace = hl.get_active_workspace()
    if not workspace then return end

    local latest, latest_id = nil, -1
    for _, window in ipairs(hl.get_windows({ floating = true, mapped = true })) do
        -- Stable IDs are hexadecimal strings, so compare their numeric values.
        local id = tonumber(window.stable_id, 16)
        if id and id > latest_id then
            latest, latest_id = window, id
        end
    end
    if not latest then return end

    hl.dispatch(hl.dsp.window.move({ window = latest, workspace = workspace, follow = false }))
    hl.dispatch(hl.dsp.focus({ window = latest }))
    hl.dispatch(hl.dsp.window.center({ window = latest }))
end)
hl.bind(mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exit())

local directions = {
    { "left", -30, 0 },
    { "right", 30, 0 },
    { "up", 0, -30 },
    { "down", 0, 30 },
}
for _, direction in ipairs(directions) do
    local key = direction[1]
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = key }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = key }))
    hl.bind(mod .. " + CTRL + " .. key,
        hl.dsp.window.resize({ x = direction[2], y = direction[3], relative = true }))
end

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

local hardware_keys = {
    { "XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+" },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
    { "XF86MonBrightnessUp", "brightnessctl s 5%+" },
    { "XF86MonBrightnessDown", "brightnessctl s 5%-" },
}
for _, binding in ipairs(hardware_keys) do
    hl.bind(binding[1], hl.dsp.exec_cmd(binding[2]), { locked = true, repeating = true })
end
for _, binding in ipairs({
    { "XF86AudioNext", "playerctl next" },
    { "XF86AudioPause", "playerctl play-pause" },
    { "XF86AudioPlay", "playerctl play-pause" },
    { "XF86AudioPrev", "playerctl previous" },
}) do
    hl.bind(binding[1], hl.dsp.exec_cmd(binding[2]), { locked = true })
end

hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast --freeze save area - | satty -f -"))
hl.bind("Print", hl.dsp.exec_cmd("grimblast --freeze copy area"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("bash ~/.config/dotfiles/scripts/vpn.sh"))
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({
    name = "float-portal-dialogs",
    match = { class = "(?i)^xdg-desktop-portal-gtk$" },
    float = true,
    center = true,
})

-- Preserve the existing workarounds for menus with empty class/title values.
hl.window_rule({ name = "no-blur-empty-class", match = { class = "^()$" }, no_blur = true })
hl.window_rule({ name = "no-blur-empty-title", match = { title = "^()$" }, no_blur = true })
hl.window_rule({
    name = "kicad",
    match = { class = "^(kicad)$" },
    no_blur = true,
    no_shadow = true,
    border_size = 0,
    rounding = 0,
    no_anim = true,
    opacity = "1.0 override 1.0 override",
})
hl.window_rule({
    name = "gnu-radio-generated-windows",
    match = { class = "^(python3)$", title = "^(Not titled yet)$" },
    float = true,
    center = true,
    persistent_size = true,
})

-- Startup only: reloading the config must not restart programs or move focus.
hl.on("hyprland.start", function()
    local session_environment = "WAYLAND_DISPLAY DISPLAY GDK_BACKEND HYPRLAND_INSTANCE_SIGNATURE "
        .. "XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE GTK_THEME"
    hl.exec_cmd("dbus-update-activation-environment --systemd " .. session_environment
        .. " && systemctl --user start hyprland-session.target hyprpolkitagent.service")

    hl.dispatch(hl.dsp.focus({ monitor = profile.monitor }))
    hl.dispatch(hl.dsp.cursor.move({ x = profile.cursor[1], y = profile.cursor[2] }))
    for _, command in ipairs(profile.autostart) do
        hl.exec_cmd(command)
    end
    hl.exec_cmd("$HOME/.config/dotfiles/scripts/network_watch.sh")
end)
