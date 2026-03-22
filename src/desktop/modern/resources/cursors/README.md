# ZirconOS Modern Cursor Set

Original flat cursor designs for the ZirconOS Modern desktop theme.

## Design Language

All cursors share a consistent **Metro Flat** aesthetic:

- **Color palette**: White fill (#FFFFFF) with dark outline (#000000)
- **Flat design**: No gradients, no glass effects, no glow
- **Clean outline**: 1px dark border for legibility on any background
- **Minimal**: Simple geometric shapes, no decorative elements
- **Format**: SVG with `viewBox="0 0 32 32"` (32x32 logical pixels)

## Cursor Files

| File | Type | Description |
|------|------|-------------|
| `modern_arrow.svg` | Default pointer | Clean white arrow with black outline |
| `modern_hand.svg` | Link / hand | Flat hand with pointing finger |
| `modern_ibeam.svg` | Text / I-beam | Simple I-beam for text selection |
| `modern_wait.svg` | Busy / loading | Flat circle spinner |
| `modern_crosshair.svg` | Crosshair | Simple cross target |
| `modern_size_ns.svg` | Vertical resize | Double-headed vertical arrow |
| `modern_size_ew.svg` | Horizontal resize | Double-headed horizontal arrow |
| `modern_move.svg` | Move | Four-directional arrow cross |

## Cursor Mapping

Standard cursor names to ZirconOS file mapping:

```
default          -> modern_arrow.svg
pointer          -> modern_hand.svg
text             -> modern_ibeam.svg
wait             -> modern_wait.svg
crosshair        -> modern_crosshair.svg
ns-resize        -> modern_size_ns.svg
ew-resize        -> modern_size_ew.svg
move             -> modern_move.svg
```

## Technical Notes

- Each SVG uses self-contained definitions to avoid ID conflicts
- White fill ensures visibility on Metro accent-colored backgrounds
- Dark outline provides legibility on white/light window surfaces

## Copyright

Copyright (C) 2024-2026 ZirconOS Project
Licensed under GNU Lesser General Public License v2.1

These cursor designs are **original creations** for ZirconOS and are NOT derived from,
copied from, or affiliated with any Microsoft Corporation products or any other
third-party cursor sets.
