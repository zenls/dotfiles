# MY DOTFILES

Hyprland 0.55+ uses `hypr/hyprland.lua` and selects a device profile by hostname:

- `xmg` → `hypr_xmg.lua`.
- `zenbook` and unknown hostnames → `hypr_zenbook.lua` (keeps the internal display on).

Matching ignores case and the domain suffix (`xmg.example.org` matches `xmg`).
To add another hostname, edit the `profiles` table in `hyprland.lua`. Both profiles
use the shared keybindings, appearance, and startup handler from that file.

`hyprland.lua` sets `HYPRLAND_NO_RT=1` via `hl.env`. Hyprland 0.57 reads this
variable after loading the config, before requesting realtime scheduling.
This works around the realtime timeout crashes described in
[Hyprland #16648](https://github.com/hyprwm/Hyprland/discussions/16648) while
keeping automatic display power-off enabled. A config reload does not change
the running compositor's scheduling policy; the environment setting takes
effect on the next login. To remove the workaround, delete that export and log
in again.

On XMG, the complete Gigabyte MO27Q28G + Philips PHL27E1N5600H + Philips
PHL24E1N5300 setup uses the desktop layout. The Gigabyte starts in SDR at 8 bits;
`mod + shift + h` toggles it between SDR and HDR at 10 bits with the HDR Peak 1500
settings. Configuration reloads return it to SDR. Displays are
identified by their EDID model and serial, so connector renumbering is supported.
If any of those three displays is missing, the internal panel becomes the main
SDR display and all external outputs mirror it. Workspaces 1–10 then belong to
the internal panel. Monitor connection changes automatically reload the layout
after a short debounce; ordinary reloads do not restart applications.

The display identities and physical connector detection are in
`hypr/xmg_monitors.lua`; modes, HDR settings, and workspace placement are in
`hypr/hypr_xmg.lua`.

The Bluetooth Wacom Intuos BT S pen is mapped to the active profile's main
display via `hl.device`: the Gigabyte in the complete XMG desktop setup, or the
internal panel in portable mode. To read its battery percentage:

```sh
upower -i /org/freedesktop/UPower/devices/battery_wacom_battery_0
```

Waybar uses connector names for output selection: the full desktop bar is on
`HDMI-A-4`, and XMG's portable full bar is on `eDP-1`. Zenbook uses a full-size
bar with a 16-thread CPU graph and brightness on `eDP-1`. Secondary desktop
outputs have a minimal bar. XMG workspaces 1–10 are persistent in Hyprland;
Waybar reads their monitor assignments from those rules instead of maintaining
another copy. Waybar separates shared module options from full and
minimal layouts; see [its configuration guide](waybar/README.md).

`hypridle.conf` and `hyprpaper.conf` use their applications' own configuration
formats and remain separate from the Hyprland Lua configuration.
Hyprpaper matches the two Philips displays by description and serial, so
connector renumbering does not swap or remove their wallpapers. The main display,
internal panel, and other outputs use the fallback wallpaper.

To check the configuration without starting a session:

```sh
Hyprland --verify-config --config "$HOME/.config/hypr/hyprland.lua"
```

## Key cheatsheet

Hyprland:

- `mod + enter` - terminal -> `kitty`
- `mod + space` - app menu -> `wofi`
- `printscr` - capture a selected area to the clipboard -> `grimblast --freeze copy area`
- `shift + printscr` - capture a selected area and open it in `satty` -> `grimblast --freeze save area - | satty -f -`
- `mod + shift + p` - color picker -> `hyprpicker`
- `mod + shift + v` - change vpn
- `mod + shift + h` - toggle Gigabyte SDR/HDR (XMG desktop setup)

Console:

- `ctrl + '+'` - fount zoom up
- `ctrl + '-'` - fount zoom down

# Instaletion

This repo contains config for this software:

```sh
sudo pacman -S mako hyprland hyprpaper hyprpicker kitty ghostty ranger python-pillow
```

- `hyprland` - desktop environment
- `hyprpaper` - wallpapers controll
- `hyprpicker` - color picker
- `mako` - native Wayland notifications.
- `kitty` - default terminal emulator; see [its configuration guide](kitty/README.md).
- `ghostty` - terminal emulator; see [its configuration guide](ghostty/README.md).
- `ranger` - terminal file manager; see [preview settings](ranger/README.md).


For scripts to work you need to install dependencies:

```sh
sudo pacman -S libnotify adwaita-icon-theme papirus-icon-theme ttf-hack-nerd ttf-jetbrains-mono-nerd nextcloud-client jq curl
```

- `libnotify` - uses `notify-send` in script
- `adwaita-icon-theme papirus-icon-theme` - icons for notifications
- `ttf-hack-nerd` - font with icons
- `ttf-jetbrains-mono-nerd` - font for waybar
- `nextcloud-client` - software for Nextcloud sync
- `jq` - json generator
- `curl` - site loader

## Use

```shell
cd .config
git clone ...

ln -s ~/.config/dotfiles/.zshrc ~/.zshrc
ln -s ~/.config/dotfiles/hypr ~/.config/hypr
ln -s ~/.config/dotfiles/waybar ~/.config/waybar
ln -s ~/.config/dotfiles/alacritty ~/.config/alacritty
ln -s ~/.config/dotfiles/kitty ~/.config/kitty
ln -s ~/.config/dotfiles/ghostty ~/.config/ghostty
ln -s ~/.config/dotfiles/ranger ~/.config/ranger
ln -s ~/.config/dotfiles/wofi ~/.config/wofi
ln -s ~/.config/dotfiles/mako ~/.config/mako
ln -s ~/.config/dotfiles/satty ~/.config/satty
```

The Zsh configuration loads the tracked theme from `zsh/agnoster.zsh-theme`.
Its Git segment counts staged files (`2`) and unstaged/untracked files (`3`)
separately. A file changed again after staging counts in both groups. Untracked
files are counted individually, including files inside new directories.
Conflicts are counted separately in a red `!2` block after the Git segment,
at the end of the left prompt. A right-hand block shows the last command's duration when it exceeds
5 seconds. Both blocks disappear when they do not apply. Powerline arrows are
defined separately as `LEFT_SEPARATOR` (``) and `RIGHT_SEPARATOR` (``).
