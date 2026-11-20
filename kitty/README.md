# Kitty

`kitty.conf` carries over the font, all 16 ANSI colors, background and foreground,
70% background opacity, non-blinking underline cursor, 50,000 scrollback lines,
and scroll multiplier of 3 from Alacritty. Kitty keeps its native
`TERM=xterm-kitty`, dynamic titles and built-in box drawing.

`text_composition_strategy 1.5 0` increases the perceived stroke thickness of
dark text on bright backgrounds, including the Git prompt segment.

The background is `#010101` so Kitty keeps Agnoster's ANSI-black user/host
segment opaque while the rest of the terminal remains transparent.

Window padding is zero on all sides. The cell grid is anchored at the
top left, so resizing adds any leftover space only at the bottom and right.
Desktop notifications appear when commands run for more than
5 seconds and finish in an unfocused window. Shell integration remains enabled,
with automatic cursor changes disabled. Hyprland provides background blur;
`background_blur` also requests it on supporting Wayland compositors.
Selected text is copied to the system clipboard, and the audio bell is disabled.

There is one deliberate limitation to the migration: Kitty does not support
Alacritty's `draw_bold_text_with_bright_colors`. Bold text uses the bold font;
bright colors are available when an application explicitly selects ANSI 8-15.
Font metrics and high-precision scrolling can differ between terminals.

## Installation

For a new setup, use the directory symlink in the root README with
`ln -sfn`; without `-n`, re-running the command follows an existing
symlink-to-directory and nests a self-referential link. If `~/.config/kitty`
is a real directory, back up `kitty.conf` and link just that file, or remove
the directory first (`-n` does not apply to real directories). Hyprland
launches Kitty with `SUPER + Enter` on both hosts.

Ranger uses its native Kitty renderer with the two settings in
[`../ranger/rc.conf`](../ranger/rc.conf). No local preview plugin is needed.

## Useful defaults and optional settings

| Shortcut or command             | Action                                          |
| ------------------------------- | ----------------------------------------------- |
| `Ctrl + Shift + Enter`          | New terminal pane in the current tab            |
| `Ctrl + Shift + T`              | New tab                                         |
| `Ctrl + Shift + L`              | Cycle layouts                                   |
| `Ctrl + Shift + Z` / `X`        | Jump to the previous / next prompt              |
| `Ctrl + Shift + G`              | View the last command's output in a pager       |
| `Ctrl + Shift + H`              | View scrollback in a pager                      |
| `Ctrl + Shift + F5`             | Reload configuration                            |
| `Ctrl + Shift + F3`             | Search available actions in the command palette |
| `Ctrl + Shift + E`              | Open a visible URL using keyboard hints         |
| `Ctrl + Shift + P`, then `F`    | Insert a visible file path at the prompt        |
| `kitten icat image.png`         | Display an image in the terminal                |
| `kitten ssh host`               | SSH with Kitty shell/terminfo integration       |
| `kitten diff old.conf new.conf` | Compare two files side by side                  |

Optional changes, not enabled in the config:

- `enabled_layouts splits,stack` limits layouts to explicit splits and a single
  visible pane. Add `map ctrl+shift+backslash launch --location=vsplit` and
  `map ctrl+shift+- launch --location=hsplit` for vertical/horizontal splits.
- `scrollback_pager_history_size 100` keeps an additional 100 MB of history for
  the scrollback pager, separate from the interactive scrollback limit.

References: [configuration](https://sw.kovidgoyal.net/kitty/conf/),
[shell integration](https://sw.kovidgoyal.net/kitty/shell-integration/).
