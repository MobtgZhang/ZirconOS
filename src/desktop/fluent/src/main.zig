//! ZirconOS Fluent Desktop — Executable Entry Point
//! Default UEFI boot target (ZBM and GRUB both supported).
//! Initializes all subsystems and prints a diagnostic report,
//! mimicking the ReactOS NT6 boot sequence:
//!   UEFI → smss.exe → csrss.exe → winlogon.exe → explorer.exe (shell)
//!
//! Integration:
//!   - ZirconOSFluent/resources/  : Primary Fluent UI assets
//!   - ZirconOSAero/resources/    : Fallback graphical window chrome
//!   - ZirconOSFonts/fonts/       : System fonts (NotoSans, SourceCodePro, CJK, etc.)
//!   - ZirconOS/src               : OS interfaces (Core, CMD, PowerShell — minimized)
//!
//! Rendering follows win10Desktop.md architecture:
//!   Visual Tree → Z-order → per-node Transform → Clip → Effect → Blend
//!   → DirectComposition → Present → VSync

const std = @import("std");
const root = @import("root.zig");
const theme = @import("theme.zig");
const resource_loader = @import("resource_loader.zig");
const font_loader = @import("font_loader.zig");
const theme_loader = @import("theme_loader.zig");
const compositor = @import("compositor.zig");
const cursor = @import("cursor.zig");
const shell = @import("shell.zig");
const dwm = @import("dwm.zig");
const desktop = @import("desktop.zig");
const taskbar = @import("taskbar.zig");
const renderer = @import("renderer.zig");
const action_center = @import("action_center.zig");
const input = @import("input.zig");

fn p(out: anytype, comptime fmt: []const u8, args: anytype) void {
    out.print(fmt, args) catch {};
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buf);
    const stdout = &file_writer.interface;

    try stdout.print("=== ZirconOS {s} v{s} ===\n", .{ root.theme_name, root.theme_version });
    try stdout.print("Boot: {s}\n", .{root.boot_method});
    try stdout.print("Compositor: {s}\n", .{root.compositor_backend});
    try stdout.print("Kernel: {s}\n\n", .{root.compatible_kernel});

    try stdout.print("{s}\n\n", .{root.theme_description});

    // ═══ UEFI Boot Phase ═══
    try stdout.print("── UEFI Boot ──\n", .{});
    try stdout.print("  Boot method     : UEFI (ZBM + GRUB dual support)\n", .{});
    try stdout.print("  ZBM path        : \\Boot\\zbm.efi\n", .{});
    try stdout.print("  GRUB entry      : desktop=fluent (default)\n", .{});
    try stdout.print("  Kernel cmdline  : desktop=fluent\n\n", .{});

    // ═══ Phase 1: Resource Loading (smss.exe equivalent) ═══
    try stdout.print("── Phase 1: Resource Loading (smss.exe) ──\n", .{});
    resource_loader.init();
    try stdout.print("  Fluent assets   : {d}\n", .{resource_loader.getFluentResourceCount()});
    try stdout.print("  Aero fallback   : {d}\n", .{resource_loader.getAeroResourceCount()});
    try stdout.print("  Wallpapers      : {d}\n", .{resource_loader.getWallpaperCount()});
    try stdout.print("  Icons           : {d}\n", .{resource_loader.getIconCount()});
    try stdout.print("  Cursors         : {d}\n", .{resource_loader.getCursorCount()});
    try stdout.print("  Theme files     : {d}\n", .{resource_loader.getThemeFileCount()});
    try stdout.print("  Total assets    : {d}\n\n", .{resource_loader.getTotalResourceCount()});

    // ═══ Phase 2: Font Subsystem (csrss.exe equivalent) ═══
    try stdout.print("── Phase 2: Font Subsystem (csrss.exe) ──\n", .{});
    font_loader.init();
    try stdout.print("  Font search     : {s}\n", .{font_loader.getFontSearchPath()});
    try stdout.print("  Registered fonts: {d}\n", .{font_loader.getFontCount()});
    const df = font_loader.getDefaultFont();
    try stdout.print("  Default (UI)    : {s}\n", .{df.name[0..df.name_len]});
    const mf = font_loader.getMonospaceFont();
    try stdout.print("  Monospace       : {s}\n", .{mf.name[0..mf.name_len]});
    const sf = font_loader.getSerifFont();
    try stdout.print("  Serif           : {s}\n", .{sf.name[0..sf.name_len]});
    const cf = font_loader.getCjkFont();
    try stdout.print("  CJK             : {s}\n", .{cf.name[0..cf.name_len]});

    const sans_cat = font_loader.findFontsByCategory(.sans_serif);
    const mono_cat = font_loader.findFontsByCategory(.monospace);
    const serif_cat = font_loader.findFontsByCategory(.serif);
    const cjk_cat = font_loader.findFontsByCategory(.cjk);
    try stdout.print("  Sans-serif      : {d} families\n", .{sans_cat.count});
    try stdout.print("  Monospace       : {d} families\n", .{mono_cat.count});
    try stdout.print("  Serif           : {d} families\n", .{serif_cat.count});
    try stdout.print("  CJK             : {d} families\n\n", .{cjk_cat.count});

    // ═══ Phase 3: Theme & DWM (winlogon.exe equivalent) ═══
    try stdout.print("── Phase 3: Theme & DWM (winlogon.exe) ──\n", .{});
    theme_loader.init();

    inline for ([_]theme.ColorScheme{ .dark, .light }) |cs| {
        _ = theme_loader.loadBuiltinTheme(cs);
        const mode_name = switch (cs) {
            .dark => "Dark",
            .light => "Light",
        };
        try stdout.print("  [{s} Mode]\n", .{mode_name});
        try stdout.print("    Desktop bg    : 0x{X:0>6}\n", .{root.getDesktopBackground(cs)});
        try stdout.print("    Acrylic tint  : 0x{X:0>6}\n", .{root.getAcrylicTintColor(cs)});
        try stdout.print("    Acrylic alpha : {d}\n", .{root.getAcrylicOpacity(cs)});
    }

    try stdout.print("\n  DWM composition : {s}\n", .{if (dwm.isEnabled()) "enabled" else "disabled"});
    try stdout.print("  Blur radius     : {d}px\n", .{theme.DwmDefaults.blur_radius});
    try stdout.print("  Blur passes     : {d}\n", .{theme.DwmDefaults.blur_passes});
    try stdout.print("  Noise opacity   : {d}\n", .{theme.DwmDefaults.noise_opacity});
    try stdout.print("  Shadow layers   : {d}\n", .{theme.DwmDefaults.shadow_layers});
    try stdout.print("  Reveal enabled  : {s}\n\n", .{if (theme.DwmDefaults.reveal_enabled) "yes" else "no"});

    // ═══ Phase 4: DirectComposition Visual Tree ═══
    try stdout.print("── Phase 4: Visual Tree Compositor ──\n", .{});
    compositor.init();
    _ = compositor.createRootVisual(1920, 1080);
    try stdout.print("  Visual tree     : initialized\n", .{});
    try stdout.print("  Root visual     : 1920x1080\n", .{});
    try stdout.print("  Backend         : {s}\n", .{root.compositor_backend});

    // ═══ Phase 5: Shell Startup (explorer.exe equivalent) ═══
    try stdout.print("\n── Phase 5: Shell Startup (explorer.exe) ──\n", .{});
    cursor.init();
    shell.initShellWithScheme(.dark);
    try stdout.print("  Shell state     : {s}\n", .{@tagName(shell.getState())});
    try stdout.print("  Color scheme    : {s}\n", .{@tagName(shell.getColorScheme())});
    try stdout.print("  Virtual desktops: {d}\n", .{shell.getVirtualDesktopCount()});

    // Desktop icons
    try stdout.print("  Desktop icons   : {d}\n", .{desktop.getIconCount()});
    for (desktop.getIcons()) |icon| {
        if (icon.visible) {
            try stdout.print("    [{d},{d}] {s}\n", .{ icon.grid_x, icon.grid_y, icon.name[0..icon.name_len] });
        }
    }

    // Taskbar items
    try stdout.print("  Taskbar buttons : {d}\n", .{taskbar.getButtons().len});
    for (taskbar.getButtons()) |btn| {
        if (btn.visible) {
            try stdout.print("    {s} (pinned={s}, active={s})\n", .{
                btn.name[0..btn.name_len],
                if (btn.pinned) "yes" else "no",
                if (btn.active) "yes" else "no",
            });
        }
    }

    // ═══ OS Interface: Minimized Core/CMD/PowerShell ═══
    try stdout.print("\n── OS Interfaces (ZirconOS/src) ──\n", .{});
    try stdout.print("  ZirconOS Core   : minimized (kernel services)\n", .{});
    try stdout.print("  CMD Shell       : minimized (Win32 console)\n", .{});
    try stdout.print("  PowerShell      : minimized (cmdlet engine)\n", .{});

    // Layout report
    try stdout.print("\n── Layout ──\n", .{});
    try stdout.print("  Taskbar height  : {d}px\n", .{root.getTaskbarHeight()});
    try stdout.print("  Titlebar height : {d}px\n", .{root.getTitlebarHeight()});
    try stdout.print("  Start menu      : {d}x{d}\n", .{ theme.Layout.startmenu_width, theme.Layout.startmenu_height });
    try stdout.print("  Action center   : {d}px wide\n", .{theme.Layout.action_center_width});
    try stdout.print("  Search bar      : {d}px\n", .{theme.Layout.search_bar_height});

    // Rendering pipeline summary (win10Desktop.md §7)
    try stdout.print("\n── DWM Rendering Pipeline (win10Desktop.md §7) ──\n", .{});
    try stdout.print("  ┌─────────────────────────────────────────────────────┐\n", .{});
    try stdout.print("  │ Win32 App (GDI → Redirected Surface)               │\n", .{});
    try stdout.print("  │ UWP App  (XAML → SwapChain Surface → DComp Node)   │\n", .{});
    try stdout.print("  ├─────────────────────────────────────────────────────┤\n", .{});
    try stdout.print("  │ Windows.UI.Composition Compositor                  │\n", .{});
    try stdout.print("  │   ContainerVisual → SpriteVisual → LayerVisual     │\n", .{});
    try stdout.print("  │   CompositionBrush: Color | Surface | Effect       │\n", .{});
    try stdout.print("  │   CompositionAnimation: KeyFrame | Expression      │\n", .{});
    try stdout.print("  ├─────────────────────────────────────────────────────┤\n", .{});
    try stdout.print("  │ DWM + DirectComposition (dwm.exe)                  │\n", .{});
    try stdout.print("  │   Visual Tree → Z-order sort                       │\n", .{});
    try stdout.print("  │     per-node: Transform → Clip → Effect → Blend    │\n", .{});
    try stdout.print("  │   Acrylic: blur → noise → tint → luminosity        │\n", .{});
    try stdout.print("  │   Reveal: radial gradient at pointer position      │\n", .{});
    try stdout.print("  │   Shadow: multi-layer depth shadow per window       │\n", .{});
    try stdout.print("  │   Cursor: smooth subpixel interpolation            │\n", .{});
    try stdout.print("  ├─────────────────────────────────────────────────────┤\n", .{});
    try stdout.print("  │ WDDM 2.x → MPO → VRR → Present → VSync           │\n", .{});
    try stdout.print("  └─────────────────────────────────────────────────────┘\n", .{});

    // Resource summary
    try stdout.print("\n── Resources ──\n", .{});
    try stdout.print("  Fluent logo     : {s}/logo.svg\n", .{resource_loader.FLUENT_RES});
    try stdout.print("  Start button    : {s}/start_button.svg\n", .{resource_loader.FLUENT_RES});
    try stdout.print("  Default cursor  : {s}/cursors/zircon_arrow.svg\n", .{resource_loader.FLUENT_RES});
    try stdout.print("  Aero fallback   : {s}/\n", .{resource_loader.AERO_RES});
    try stdout.print("  Font path       : {s}\n", .{font_loader.getFontSearchPath()});

    for (resource_loader.getWallpapers()) |wp| {
        if (wp.loaded) {
            const source_tag = if (wp.source == .fluent) "[Fluent]" else "[Aero]";
            try stdout.print("  Wallpaper {s}  : {s}\n", .{ source_tag, wp.path[0..wp.path_len] });
        }
    }

    try stdout.print("\n═══ ZirconOS Fluent Desktop Ready ═══\n", .{});
    try stdout.print("UEFI boot → DirectComposition visual tree compositor active.\n", .{});
    try stdout.print("Acrylic={s}, Reveal={s}, Smooth cursor=true\n", .{
        if (dwm.isEnabled()) "enabled" else "disabled",
        if (theme.DwmDefaults.reveal_enabled) "enabled" else "disabled",
    });
    try stdout.print("Fonts={d} (from ZirconOSFonts), Resources={d} (Fluent+Aero)\n", .{
        font_loader.getFontCount(),
        resource_loader.getTotalResourceCount(),
    });
    try stdout.print("OS Interfaces: Core(min), CMD(min), PowerShell(min)\n", .{});
}
