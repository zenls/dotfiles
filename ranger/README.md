# Ranger image previews

`rc.conf` enables images in the right preview pane using the Kitty graphics
protocol. Pillow (`python-pillow` on Arch) is required and is already installed
on XMG. Ghostty keeps its native `TERM=xterm-ghostty`.

Only ranger's built-in preview renderer is used. The standard configuration and
bundled `scope.sh` remain in use. `zi` toggles image previews within ranger.

For a new setup:

```sh
ln -s ~/.config/dotfiles/ranger ~/.config/ranger
```

If that directory already exists, link just `rc.conf`
after preserving any existing configuration.

Upstream reports: [Ghostty detection](https://github.com/ranger/ranger/issues/3035),
[temporary-file previews](https://github.com/ranger/ranger/issues/3193).
