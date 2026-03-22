# ZirconOS Luna Cursor Set

Original cursor designs for the ZirconOS Luna (Windows XP style) desktop theme.

## Design Language

All cursors share a consistent **Windows XP Classic** aesthetic:

- **Color palette**: White fill (#FFFFFF) with black outline (#000000)
- **Style**: Clean, simple geometric shapes — no transparency effects
- **Shadow**: Optional 1px grey shadow for depth
- **Outline**: 1px black outline for legibility on any background
- **Format**: SVG with `viewBox="0 0 32 32"` (32x32 logical pixels)

## Cursor Files

| File | Type | Description |
|------|------|-------------|
| `luna_arrow.svg` | Default pointer | White arrow with black outline, classic XP style |
| `luna_hand.svg` | Link / hand | Pointing hand cursor for hyperlinks |
| `luna_ibeam.svg` | Text / I-beam | I-beam for text selection and editing |
| `luna_wait.svg` | Busy / loading | Hourglass with sand animation frames |
| `luna_crosshair.svg` | Crosshair | Thin cross for precision selection |
| `luna_size_ns.svg` | Vertical resize | Double-headed vertical arrow |
| `luna_size_ew.svg` | Horizontal resize | Double-headed horizontal arrow |
| `luna_move.svg` | Move | Four-directional arrow cross |

## Cursor Mapping

Standard cursor names to ZirconOS file mapping for theme integration:

```
default          -> luna_arrow.svg
pointer          -> luna_hand.svg
text             -> luna_ibeam.svg
wait             -> luna_wait.svg
crosshair        -> luna_crosshair.svg
ns-resize        -> luna_size_ns.svg
ew-resize        -> luna_size_ew.svg
move             -> luna_move.svg
```

## Technical Notes

- Each SVG uses self-contained `<defs>` with unique gradient/filter IDs
- White fill with black stroke provides maximum contrast on all backgrounds
- Design follows classic Windows XP cursor proportions (12x19 for arrow)
- Compatible with standard SVG renderers

## Copyright

Copyright (C) 2024-2026 ZirconOS Project
Licensed under GNU Lesser General Public License v2.1

These cursor designs are **original creations** for ZirconOS and are NOT derived from,
copied from, or affiliated with any Microsoft Corporation products or any other
third-party cursor sets.
