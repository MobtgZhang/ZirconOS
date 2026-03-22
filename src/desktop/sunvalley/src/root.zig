//! ZirconOS Sun Valley — Mica Desktop Theme
//! Library root: re-exports all public modules for use by the kernel
//! display compositor and the standalone desktop shell executable.
//!
//! Architecture: WinUI 3 Composition Layer (NT6.4 compatible)
//! Compositor: Mica + Acrylic 2.0 + SDF Rounded Corners + DRR
//! Shell: Multi-process model (explorer, start menu, widgets, quick settings)

pub const theme = @import("theme.zig");
pub const dwm = @import("dwm.zig");
pub const compositor = @import("compositor.zig");
pub const renderer = @import("renderer.zig");
pub const desktop = @import("desktop.zig");
pub const taskbar = @import("taskbar.zig");
pub const startmenu = @import("startmenu.zig");
pub const window_decorator = @import("window_decorator.zig");
pub const shell = @import("shell.zig");
pub const controls = @import("controls.zig");
pub const winlogon = @import("winlogon.zig");
pub const widget_panel = @import("widget_panel.zig");
pub const quick_settings = @import("quick_settings.zig");
pub const cursor = @import("cursor.zig");
pub const input = @import("input.zig");
pub const resource_loader = @import("resource_loader.zig");
pub const font_loader = @import("font_loader.zig");
pub const theme_loader = @import("theme_loader.zig");

// ── Theme identity ──

pub const theme_name = "Sun Valley";
pub const theme_version = "1.0.0";
pub const theme_description = "ZirconOS Sun Valley — Mica translucency with rounded geometry, centered layout, snap regions, and layered depth system";

// ── Quick accessors for the kernel display compositor ──

pub fn getMicaTintColor(scheme: theme.ColorScheme) u32 {
    return theme.getScheme(scheme).mica_tint;
}

pub fn getMicaOpacity(scheme: theme.ColorScheme) u8 {
    return theme.getScheme(scheme).mica_opacity;
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

pub fn initSunValleyDwm() void {
    shell.initShell();
}

pub fn initSunValleyDwmWithScheme(scheme: theme.ColorScheme) void {
    shell.initShellWithScheme(scheme);
}
