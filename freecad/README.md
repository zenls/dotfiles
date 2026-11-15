# FreeCAD Flatpak

`FreeCAD.qss` is the stylesheet shipped with FreeCAD 1.1.4, with only the
`subcontrol-position` declarations removed from the spinbox up/down button
rules. This works around Qt's invisible Sketcher On-View Parameter text while
preserving the FreeCAD Dark theme and its color tokens.

Upstream report: https://github.com/FreeCAD/FreeCAD/issues/33676

The Flatpak user override is linked at:

```text
~/.var/app/org.freecad.FreeCAD/data/FreeCAD/v1-1/Gui/Stylesheets/FreeCAD.qss
```

FreeCAD searches this directory before the packaged stylesheets, so the
existing `FreeCAD.qss` preference needs no change. Restart FreeCAD to load it.

Verified with the installed Qt 6.11.3: the text area in a 95-pixel-wide
buttonless spinbox increases from 1 pixel to 90 pixels.

This override survives Flatpak updates. Remove the user-override symlink to
return to the packaged stylesheet once the Qt regression is fixed. Recheck
compatibility when upgrading to another FreeCAD release.
