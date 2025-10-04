# MY DOTFILES

This repo contains config for this software:

```sh
sudo pacman -S mako 
```

- `mako` - native Wayland notifications.


For scripts to work you need to install dependencies:

```sh
sudo pacman -S libnotify adwaita-icon-theme papirus-icon-theme ttf-hack-nerd nextcloud-client
```

- `libnotify` - uses `notify-send` in script
- `adwaita-icon-theme papirus-icon-theme` - icons for notifications
- `ttf-hack-nerd` - font with icons
- `nextcloud-client` - software for Nextcloud sync

## Use

```shell
cd .config
git clone ...

ln -s ~/.config/dotfiles/mako ~/.config/mako

ln -s ~/.config/dotfiles/alacritty ~/.config/alacritty
ln -s ~/.config/dotfiles/hypr ~/.config/hypr
ln -s ~/.config/dotfiles/waybar ~/.config/waybar
ln -s ~/.config/dotfiles/wofi ~/.config/wofi
ln -s ~/.config/dotfiles/flameshot ~/.config/flameshot
ln -s ~/.config/dotfiles/.zshrc ~/.zshrc

```