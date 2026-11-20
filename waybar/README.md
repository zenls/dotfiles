# Waybar configuration

Start with `conf_xmg.jsonc` or `conf_zenbook.jsonc`, as configured in the
corresponding Hyprland profile.

| File                 | Edit here to change                                                    |
| -------------------- | ---------------------------------------------------------------------- |
| `modules.jsonc`      | Module formats, polling intervals, commands, calendar and tray options |
| `conf_common.jsonc`  | Full panel geometry and module order                                   |
| `conf_minimal.jsonc` | Secondary panel: workspaces, OpenCode status, and clock with date     |
| `conf_xmg.jsonc`     | XMG output names and 32-thread CPU graph                               |
| `conf_zenbook.jsonc` | Zenbook full-size internal panel, 16-thread CPU graph and brightness    |
| `style.css`          | Shared colors and spacing                                              |
| `power_menu.xml`     | Power-menu items; their commands are in `modules.jsonc`                |

Layouts inherit the full panel, which imports the shared module options.
Waybar merges objects recursively and the **first defined value wins**:
values in a device profile override its layout, and layout values override
`modules.jsonc`. Arrays such as `modules-right` are replaced as a whole.
Defining a module's options does not display it; only the layout's module lists do.

Outputs are selected by their connector names (`HDMI-A-4`, `eDP-1`), without
numeric monitor IDs or serial-number descriptions. Zenbook uses the full-size
panel on `eDP-1` and the minimal panel on every other output; XMG uses the full
panel on both `HDMI-A-4` and `eDP-1`.
Every full panel displays the laptop's built-in display brightness. Calendar actions are
shared by every clock, including the secondary panels. The tray discovers icons
dynamically. XMG workspace assignments come from Hyprland's persistent rules.
The workspace module shows all workspaces assigned to each panel's monitor,
including inactive and empty persistent workspaces (`active-only` is disabled).
Workspace hover tooltips are disabled. Scrolling over the panel cycles through
the current monitor's workspaces using Waybar's built-in handler
(`enable-bar-scroll`), while modules with their own scroll actions retain them.

`custom/tablet_battery` follows the OpenCode widget in the full panel's right group.
It shows a Nerd Font icon and the connected Wacom's battery percentage.
`custom/dualsense_battery` follows it with the `󰊴` icon and the connected
PlayStation controller's percentage. Both use `scripts/hid_battery.sh`, with
separate battery-name patterns, to read the drivers' live sysfs
power-supply and HID attributes every 5 seconds; no model name or Bluetooth
address is hardcoded. The tooltip includes the reported model, charge,
charging state, connection type and serial/Bluetooth address when available.
Each module is hidden completely when its device is disconnected or its battery
data is unavailable. The battery widgets are not included on secondary panels.
The script uses Bash and the same `jq` dependency as the other status scripts;
it does not require Python or UPower.
The widget text is orange-red while charging, green when full, and blue while
discharging. A 100% battery is treated as full unless it is still charging.

## OpenCode 2

One widget (`custom/opencode`) starts the right group on every full and minimal
panel, using the same settings. It displays one colored dot per monitored
session, without numbers or a fixed slot limit.
The same session opened in multiple clients appears only once. Agent child
sessions contribute to their parent session's status. With no sessions, the
widget is hidden.

Colors: yellow means a pending permission or question, red means active work,
green means idle, and gray means the status cannot be verified. Waiting takes
priority over working. The compact monospace tooltip matches the IP widget:
`OC` and the session count, then a colored dot, root folder name, short status
(`WAIT`, `RUN`, `IDLE`, `ERR`) and session title. `!2` means two pending approvals;
`?1` means one pending question. Paths, PIDs and session IDs are omitted.
API-provided text is escaped for Pango markup; long titles are shortened.

Waybar runs `scripts/opencode_waybar.sh` directly as a continuous JSON producer
and restarts it after five seconds if it exits. There is no separate collector
service, shared cache, heartbeat or refresh signal. `scripts/opencode_waybar.jq`
groups sessions and propagates child-session status to their parent.

The script discovers live VS Code OpenCode clients every two seconds and reads
the shared OpenCode 2 service registration from
`${XDG_STATE_HOME:-~/.local/state}/opencode/service.json`. Repeated clients with
the same project/session scope are queried once. Historical sessions without a
live client are omitted. It never launches OpenCode or submits model prompts.

Each displayed widget subscribes to filtered `/api/event` SSE events. Relevant
changes are coalesced to at most one snapshot per second, with a 30-second
fallback. Token deltas are excluded. Requests have timeouts, failed streams
reconnect, and credentials are only sent to the registered loopback server.
The private temporary credential file and stream are removed when the script
exits. Dependencies are Bash, `jq`, `curl`, `pgrep` and coreutils.

Without `--session`, the script uses the project's most recently viewed root
session and active work in that project. The API does not expose the selected
TUI tab per client. `--standalone` and custom servers are shown as unavailable.
The endpoints were verified against the installed OpenCode 2.2.7 and the
[v2 API reference](https://opencode.ai/docs/api). Inspect a single snapshot with:

```sh
bash ~/.config/dotfiles/scripts/opencode_waybar.sh --once | jq
```

## Public IP and VPN status

`custom/ext_ip_check` runs `scripts/ip_check_adv.sh` every 300 seconds. It also
accepts signal 8 (`SIGRTMIN+8`). Clicking the widget requests one refresh rather
than launching a second API query. Requests use `ipwho.is`, whose free limit is
1,000 requests per day per public IP. IPv4 and IPv6 are checked independently
when their routes exist; at one poll per five minutes this is at most 288
requests per address family per day, before event/manual refreshes.

`scripts/network_watch.sh` listens for interface, address, route and routing-rule
events. It waits for two quiet seconds and compares the selected egress routes,
source addresses, policy rules and active tunnel interfaces before signaling
Waybar. Unchanged state, such as an ordinary DHCP renewal, does not trigger an
API query. The watcher starts once per session from the shared Hyprland startup
handler; its lock prevents duplicate watchers. Run it manually after installing
the configuration into an already-running session:

```sh
~/.config/dotfiles/scripts/network_watch.sh
```

`scripts/network_state.sh` supplies the same routing information to both widgets.
It detects WireGuard, AmneziaWG and TUN/TAP interfaces by kernel type instead of
matching `wg` in their names, so Amnezia's `amn0` is supported.

The IP checker shares its cache and lock across panels in
`$XDG_RUNTIME_DIR/waybar-ip-$UID` (or a private per-user directory under `/tmp`).
Successful results are shared for 30 seconds to avoid duplicate requests, and
failed requests for 60 seconds. Manual refreshes are throttled to 15 seconds.
HTTP 429 respects `Retry-After`, defaulting to a 24-hour pause if it is absent;
changing network state permits a fresh check for the new egress connection.

The panel keeps the country-code-and-IP format, with `[IPv6]` for confirmed
public IPv6 on a direct connection, even when the VPN is off. A successful
check outside an active tunnel is marked `[BYPASS]`. The four-line monospace
tooltip uses compact status badges and contains IPv4/IPv6 peers and
interfaces, then city/country/ASN. Error labels are abbreviated to `TIMEOUT`,
`DNS`, `TLS`, `UNREACH`, `HTTP nnn` or `API ERR`.

VPN checks are mint, direct IPv4 is cyan, incomplete checks are orange, and
errors or confirmed exposure/bypass are pink-red. The IP widget keeps its
normal background in every state; only the text color changes.
The check uses
the route to the actual API peer, not just the default route, and ignores HTTP
proxy environment variables. It does not certify DNS or all application traffic.
State and comments are in English. Dependencies are Bash, `curl`, `jq`, `ip`
and `flock`, all already used or installed on this system.

## Reload configuration

After changing the configuration or stylesheet, reload all Waybar panels for
the current user:

```sh
pkill -USR2 -u "$USER" -x waybar
```

Waybar handles `SIGUSR2` by recreating its panels and loading the updated files.
