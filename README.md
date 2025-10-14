# MY DOTFILES

## Key cheatsheet

Hyprland:

- `mod + enter` - terminal -> `alacritty`
- `mod + space` - app menu -> `wofi`
- `printscr` - screenshot -> `flameshot`
- `mod + shift + p` - color picker -> `hyprpicker`
- `mod + shift + v` - change vpn

Console:

- `ctrl + '+'` - fount zoom up
- `ctrl + '-'` - fount zoom down

# Instaletion

This repo contains config for this software:

```sh
sudo pacman -S mako hyprland hyprpaper hyprpicker
```

- `hyprland` - desktop environment
- `hyprpaper` - wallpapers controll
- `hyprpicker` - color picker
- `mako` - native Wayland notifications.


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
ln -s ~/.config/dotfiles/wofi ~/.config/wofi
ln -s ~/.config/dotfiles/mako ~/.config/mako
ln -s ~/.config/dotfiles/flameshot ~/.config/flameshot
```