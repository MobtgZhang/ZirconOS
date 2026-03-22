//! ZirconOS Fluent — Acrylic Desktop Theme
//! Library root: re-exports all public modules for use by the kernel
//! display compositor and the standalone desktop shell executable.
//!
//! Boot: Default UEFI (both ZBM and GRUB) → Fluent Desktop
//!
//! Architecture: DirectComposition Visual Tree (NT 6.3 / win10Desktop.md)
//!   - Acrylic translucency (blur + noise + tint + luminosity)
//!   - Reveal highlight (radial gradient at pointer)
//!   - Multi-layer depth shadows
//!   - Dual light/dark mode with runtime switching
//!   - Virtual desktop support (up to 16)
//!   - Action center with quick toggles
//!
//! Resource integration:
//!   ZirconOSFluent/resources/  — Primary Fluent UI assets
//!   ZirconOSAero/resources/    — Fallback graphical window chrome
//!   ZirconOSFonts/fonts/       — NotoSans, SourceCodePro, NotoSansCJK, etc.
//!
//! OS interfaces provided by ZirconOS/src:
//!   Minimized Core, CMD, PowerShell windows in taskbar
//!
//! Rendering pipeline per frame (win10Desktop.md §7):
//!   Background → Visual Tree Compose (Z-order → Transform → Clip → Effect → Blend)
//!   → Windows (Acrylic titlebar) → Taskbar (Acrylic backdrop)
//!   → Overlays (Start menu / Action center) → Reveal highlight → Cursor
//!   → DirectComposition Present → VSync

pub const theme = @import("theme.zig");
pub const dwm = @import("dwm.zig");
pub const desktop = @import("desktop.zig");
pub const taskbar = @import("taskbar.zig");
pub const startmenu = @import("startmenu.zig");
pub const window_decorator = @import("window_decorator.zig");
pub const shell = @import("shell.zig");
pub const controls = @import("controls.zig");
pub const winlogon = @import("winlogon.zig");
pub const action_center = @import("action_center.zig");
pub const resource_loader = @import("resource_loader.zig");
pub const compositor = @import("compositor.zig");
pub const renderer = @import("renderer.zig");
pub const font_loader = @import("font_loader.zig");
pub const theme_loader = @import("theme_loader.zig");
pub const cursor = @import("cursor.zig");
pub const input = @import("input.zig");

// ── Theme identity ──

pub const theme_name = "Fluent";
pub const theme_version = "1.1.0";
pub const theme_description =
    "ZirconOS Fluent — UEFI boot (ZBM/GRUB), DirectComposition visual tree compositor, " ++
    "Acrylic translucency, Reveal highlights, depth shadows, dual light/dark mode. " ++
    "Renders with ZirconOSAero/resources graphical chrome and ZirconOSFonts typefaces.";
pub const compatible_kernel = "NT6.3";
pub const compositor_backend = "DirectComposition_VisualTree";
pub const boot_method = "UEFI (ZBM + GRUB)";

// ── Quick accessors for the kernel display compositor ──

pub fn getAcrylicTintColor(scheme: theme.ColorScheme) u32 {
    return theme.getScheme(scheme).acrylic_tint;
}

pub fn getAcrylicOpacity(scheme: theme.ColorScheme) u8 {
    return theme.getScheme(scheme).acrylic_opacity;
}

pub fn getDesktopBackground(scheme: theme.ColorScheme) u32 {
    return theme.getScheme(scheme).desktop_bg;
}

pub fn getTaskbarHeight() i32 {
    return theme.Layout.taskbar_height;
}

pub fn getTitlebarHeight() i32 {
    return theme.Layout.titlebar_height;
}

pub fn isDwmEnabled() bool {
    return dwm.isEnabled();
}

pub fn isCompositorReady() bool {
    return compositor.isInitialized() and dwm.isEnabled();
}

pub fn getResourceCount() usize {
    if (resource_loader.isInitialized()) {
        return resource_loader.getTotalResourceCount();
    }
    return 0;
}

pub fn getFluentResourceCount() usize {
    if (resource_loader.isInitialized()) {
        return resource_loader.getFluentResourceCount();
    }
    return 0;
}

pub fn getAeroResourceCount() usize {
    if (resource_loader.isInitialized()) {
        return resource_loader.getAeroResourceCount();
    }
    return 0;
}

pub fn getFontCount() usize {
    if (font_loader.isInitialized()) {
        return font_loader.getFontCount();
    }
    return 0;
}

pub fn getDefaultFontName() []const u8 {
    if (font_loader.isInitialized()) {
        const f = font_loader.getDefaultFont();
        return f.name[0..f.name_len];
    }
    return "ZirconOS Sans";
}

pub fn getMonospaceFontName() []const u8 {
    if (font_loader.isInitialized()) {
        const f = font_loader.getMonospaceFont();
        return f.name[0..f.name_len];
    }
    return "ZirconOS Mono";
}

/// Full Fluent DWM initialization: loads resources (Fluent + Aero fallback),
/// fonts (ZirconOSFonts), theme, initializes compositor and shell.
/// ReactOS-compatible startup: smss.exe → csrss.exe → winlogon.exe → explorer.exe (shell)
pub fn initFluentDwm() void {
    resource_loader.init();
    font_loader.init();
    theme_loader.init();
    theme_loader.loadBuiltinTheme(.dark);
    compositor.init();
    cursor.init();
    shell.initShell();
}

/// Initialize with explicit color scheme selection.
pub fn initFluentDwmWithScheme(scheme: theme.ColorScheme) void {
    resource_loader.init();
    font_loader.init();
    theme_loader.init();
    _ = theme_loader.loadBuiltinTheme(scheme);
    compositor.init();
    cursor.init();
    shell.initShellWithScheme(scheme);
}
