# Ghostty

`config` mirrors the appearance and explicit behavior in
[`../alacritty/alacritty.toml`](../alacritty/alacritty.toml): Hack Nerd Font at
12 pt, 70% background opacity, blur, an underline cursor without
blinking, all 16 ANSI colors, bright colors for bold text, 50,000 history lines,
and a scroll multiplier of 3. Requires Ghostty 1.4+ for the line-based scrollback
settings. Launch with `ghostty`; Hyprland's default terminal is now
[Kitty](../kitty/README.md).

Padding is 6 pt horizontally and 4 pt vertically for extra space around the text.

Ghostty trims history in internal pages, so the line count is approximate. The
byte limit is disabled to let the line limit control history retention. Memory
use depends on terminal width and output contents.

Server-side decorations match Alacritty's behavior under Hyprland; the compositor
provides the border. Ghostty's own rendering and font metrics can differ slightly.
Blur is handled by Hyprland, where `decoration.blur.enabled` is already enabled.
The Ghostty blur option also requests it on compositors with protocol support.

Shell integration remains enabled with its automatic cursor changes disabled.
Window titles remain dynamic. Ghostty uses its native `TERM=xterm-ghostty` rather
than advertising Alacritty's capabilities. Box drawing is built in.

Desktop notifications are enabled for commands that run for at least 5 seconds
and finish in an unfocused terminal. This includes builds and downloads and uses
Ghostty's shell integration. The minimum runtime and windowed startup use
Ghostty's defaults, so they are not repeated in `config`.

## Installation and validation

For a new setup, use the symlink in the root README. If `~/.config/ghostty`
already exists, preserve its files and link just `config` after backing up the
existing file. Check for `config.ghostty` too: Ghostty can load that file as well.

```sh
ghostty +validate-config --config-file="$HOME/.config/dotfiles/ghostty/config"
ghostty +show-config
```

Reload an open Ghostty window with `Ctrl + Shift + ,`. Some settings, including
scrollback limits and padding, only apply to new terminal surfaces.

## Useful features

These shortcuts are Ghostty 1.4's Linux defaults and require no extra bindings:

| Shortcut | Action |
| --- | --- |
| `Ctrl + Shift + F` | Search terminal output |
| `Ctrl + Shift + T` | New tab |
| `Ctrl + Tab` / `Ctrl + Shift + Tab` | Next / previous tab |
| `Ctrl + Shift + O` / `Ctrl + Shift + E` | Split right / down |
| `Ctrl + Alt + Arrow` | Focus a split |
| `Ctrl + Shift + Enter` | Zoom the current split |
| `Ctrl + Shift + Up` / `Down` | Jump to the previous / next prompt |
| `Ctrl + Shift + P` | Command palette |
| `Ctrl + +` / `Ctrl + -` / `Ctrl + 0` | Increase / decrease / reset font size |

Optional changes to consider, left disabled to preserve the current setup:

- `copy-on-select = clipboard` copies selected text to the system clipboard.
  By default, selection goes to the primary selection, leaving the clipboard alone.
- `background-opacity = 0.85` makes text easier to read over detailed wallpapers.
- `shell-integration-features = no-cursor,ssh-env` adds SSH compatibility by
  using `xterm-256color` remotely when Ghostty terminfo is unavailable. Keep the
  native terminal type locally.

References: [configuration options](https://ghostty.org/docs/config/reference),
[keybinding actions](https://ghostty.org/docs/config/keybind/reference).
