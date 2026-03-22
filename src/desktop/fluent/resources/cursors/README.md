# ZirconOS Fluent Cursors

Cursor set for ZirconOS Fluent theme.
Design follows Fluent Design cursor guidelines:
- Clean, monochrome silhouettes (white body, dark outline)
- Subtle drop shadow for depth
- Crisp edges suitable for high-DPI displays

## Cursor Inventory

| Cursor | File | ID | Description |
|--------|------|----|-------------|
| Arrow | `zircon_arrow.svg` | 1 | Default pointer |
| Text | `zircon_text.svg` | 2 | I-beam for text selection |
| Busy | `zircon_busy.svg` | 3 | Spinning circle (system busy) |
| Working | `zircon_working.svg` | 4 | Arrow + circle (app starting) |
| Link | `zircon_link.svg` | 5 | Hand pointer for hyperlinks |
| Move | `zircon_move.svg` | 6 | Four-directional arrow |
| NS Resize | `zircon_ns.svg` | 7 | Vertical resize |
| EW Resize | `zircon_ew.svg` | 8 | Horizontal resize |
| Unavailable | `zircon_unavail.svg` | 9 | Crossed circle (not allowed) |

## Smooth Cursor

The Fluent theme implements DWM smooth cursor interpolation:
- `SmoothEnabled=1` — subpixel cursor tracking
- `LerpFactor=220` — interpolation weight (64-255)
- `SubpixelPrecision=256` — fixed-point units per pixel

Cursor logic is in `cursor.zig`; rendering from embedded pixel data.
