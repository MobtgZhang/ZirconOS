# ZirconOS Sun Valley

A modern desktop theme for ZirconOS featuring Mica translucency, rounded geometry,
centered taskbar layout, snap regions, and a layered depth shadow system.

## Features

- **Mica Material**: Wallpaper-sampled tint behind window chrome with multi-pass blur
- **Acrylic Material**: Background blur + noise overlay + luminosity blend for panels
- **Rounded Corners**: 8px configurable corner radius on all windows and flyouts
- **Centered Taskbar**: Icons centered with pill-shaped active indicators
- **Start Menu**: Centered flyout with pinned apps grid and recommended section
- **Snap Layout Assist**: Multi-zone window snapping with visual overlay
- **Widget Panel**: Side panel with customizable info cards
- **Quick Settings**: Bottom-right flyout with system toggles and sliders
- **Light/Dark Mode**: Full dual-mode support with distinct color schemes
- **Virtual Desktops**: Multiple workspace support with smooth transitions
- **Depth Shadows**: Multi-layer spread shadows for window elevation

## Architecture

```
src/
├── root.zig              # Library entry, re-exports all modules
├── main.zig              # Executable entry / integration test
├── theme.zig             # Colors, layout, DWM configuration constants
├── dwm.zig               # Mica/Acrylic compositor (blur, tint, shadows, corners)
├── desktop.zig           # Desktop manager (wallpaper, icons, context menu)
├── taskbar.zig           # Centered taskbar with pinned apps
├── startmenu.zig         # Start menu with pinned grid + recommended
├── window_decorator.zig  # Window chrome with Mica titlebar + snap layout
├── shell.zig             # Shell orchestrator (session lifecycle)
├── controls.zig          # UI controls (buttons, text, toggles, sliders, rings)
├── winlogon.zig          # Login/lock screen manager
├── widget_panel.zig      # Widget panel with info cards
└── quick_settings.zig    # Quick settings flyout
```

## Building

```bash
zig build
```

## License

Original ZirconOS project code. No third-party copyrighted material included.
