# HDR playback on XMG

The main MO27Q28G output stays in HDR. Select **HDR Peak 1500** in the monitor's
menu. In this mode its EDID reports approximately 1532 nits peak and 295 nits
frame-average luminance. Hyprland and mpv use the nominal **1500-nit** peak,
while Hyprland retains the 295-nit average. These figures describe advertised
capabilities, not a measured calibration of this individual panel. The high
peak applies to small highlights, not a full white screen.

Start a fresh shell, then run:

```sh
mpv_hdr "/path/to/video.mkv"
```

Or run the profile directly, including from an existing shell:

```sh
mpv --no-config --include="$HOME/.config/dotfiles/mpv/hdr.conf" "/path/to/video.mkv"
```

This profile uses Vulkan on Wayland and lets mpv map the movie to a nominal
1500-nit output before sending BT.2020/PQ to Hyprland and selects HDMI-A-4
for playback. It avoids the hue and target overrides in the separate user mpv
configuration. It is intended for
the HDR monitor; its output remains PQ even for SDR files.

Press **Shift+I** during playback. In **Display**, expect `Primaries: bt.2020`
and `Transfer: pq`, with a 1500-nit display peak. The rendering target should
report `rgb10a2`, `bt.2020`, `pq`, and `max-luma=1500`.

## Monitor options

Keep HDR Peak 1500 selected when using this configuration. For a reference
comparison, start with HyperNits off if that option is available. If the image
is still too dim for your preference, compare HyperNits Medium; it intentionally
boosts brightness, rather than providing a more accurate calibration.

Gigabyte lists HDR EOTF improvements in firmware F06 and HyperNits in F07:
<https://www.aorus.com/gb/monitors/MO27Q28G/support/driver>
Check the installed firmware version in the monitor menu when evaluating HDR.
HyperNits is described at <https://www.gigabyte.com/Monitor/MO27Q28G?lan=en>.

The mpv profile's SDR reference white is 180 nits for SDR media played through
that profile. Desktop SDR white is controlled separately in Hyprland. Do not
raise either to 1500 to match the peak setting: they control ordinary SDR
content, not small HDR highlights.

## Comparing appearance

Compare the same scene at the same timestamp, one fullscreen player at a time
on HDMI-A-4. Check bright reflections, lights, and shadow detail rather than
requiring the entire frame to look brighter. A 60-second stock clip in BT.709
is not an HDR test, regardless of its resolution or codec bit depth.

The XMG profile uses `sdr_max_luminance=140`, a personal saturation boost of
`sdrsaturation=1.25`, and `cm_sdr_eotf=srgb` for desktop SDR content. The white
level and saturation are visual preferences, not calibration values. The earlier
forced gamma 2.2 interpretation has been removed. These settings are separate
from native HDR playback. Clients that supply their own color metadata can
respond differently to the desktop SDR controls.

If you select another monitor HDR preset, re-check its advertised capabilities
and update both `target-peak` here and the monitor luminance overrides in
`hypr/hypr_xmg.conf`. Accurate white balance, color, and PQ tracking require
measurements with an instrument suited to the OLED panel.
