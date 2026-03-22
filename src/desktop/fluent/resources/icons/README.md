# ZirconOS Fluent Icons

Fluent Design icon set for ZirconOS Fluent theme.
All icons are original SVG designs with Fluent Design language characteristics:
- Outlined/filled dual-mode icons
- Consistent 32x32 viewport
- Accent-aware color tokens (#0078d4 primary, #60cdff highlight)
- Dark theme optimized with subtle depth

## Icon Inventory

| Icon | File | ID | Description |
|------|------|----|-------------|
| Computer | `computer.svg` | 1 | Desktop PC / This PC |
| Documents | `documents.svg` | 2 | User documents folder |
| Recycle Bin | `recycle_bin.svg` | 3 | Deleted items container |
| Terminal | `terminal.svg` | 4 | Command-line terminal |
| File Manager | `file_manager.svg` | 5 | File Explorer |
| Browser | `browser.svg` | 6 | Web browser |
| Settings | `settings.svg` | 7 | System settings gear |
| Calculator | `calculator.svg` | 8 | Calculator app |
| Network | `network.svg` | 9 | Network connections |
| Store | `store.svg` | 10 | Application store |
| Mail | `mail.svg` | 11 | Email client |
| Calendar | `calendar.svg` | 12 | Calendar app |

## Design Notes

Icons use a consistent Fluent-dark palette:
- Background fills: `#2d2d2d`, `#383838`
- Accent: `#0078d4`
- Highlight: `#60cdff`
- Stroke: `#555`, `#444`

Icons are registered by `resource_loader.zig` and rendered at runtime
from embedded bitmaps for kernel-mode display.
