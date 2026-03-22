//! ZirconOS Luna — Windows XP-style GDI Desktop Theme
//! Library root: re-exports all public modules for use by the kernel
//! display compositor and the standalone desktop shell executable.
//!
//! Architecture follows Windows XP desktop model:
//!   winlogon → shell (explorer) → GDI compositor → desktop/taskbar/startmenu
//! Luna uses gradient-based rendering without DWM glass composition.

pub const theme = @import("theme.zig");
pub const desktop = @import("desktop.zig");
pub const taskbar = @import("taskbar.zig");
pub const startmenu = @import("startmenu.zig");
pub const window_decorator = @import("window_decorator.zig");
pub const shell = @import("shell.zig");
pub const controls = @import("controls.zig");
pub const winlogon = @import("winlogon.zig");
pub const theme_loader = @import("theme_loader.zig");
pub const resource_loader = @import("resource_loader.zig");
pub const font_loader = @import("font_loader.zig");

// ── Theme identity ──

pub const theme_name = "Luna";
pub const theme_version = "1.0.0";
pub const theme_description = "ZirconOS Luna — Windows XP-style vivid gradients, colorful icons, and green Start button";

// ── Available theme variants ──

pub const available_themes = [_][]const u8{
    "luna_blue",
    "luna_olive",
    "luna_silver",
};

// ── Quick accessors for the kernel display compositor ──

pub fn getTaskbarGradientTop() u32 {
    return theme.getActiveColors().taskbar_top;
}

pub fn getStartButtonColor() u32 {
    return theme.getActiveColors().start_btn;
}

pub fn getDesktopBackground() u32 {
    return theme.getActiveDesktopBg();
}

pub fn getTaskbarHeight() i32 {
    return theme.Layout.taskbar_height;
}

pub fn getTitlebarHeight() i32 {
    return theme.Layout.titlebar_height;
}

pub fn isGradientEnabled() bool {
    return theme.isGradientEnabled();
}

pub fn initLunaShell() void {
    shell.initShell();
}

pub fn switchTheme(cs: theme.ColorScheme) void {
    shell.switchTheme(cs);
}

pub fn switchThemeByName(name: []const u8) bool {
    return shell.switchThemeByName(name);
}

pub fn getActiveScheme() theme.ColorScheme {
    return theme.getActiveScheme();
}

pub fn getWallpaperPath() []const u8 {
    return desktop.getWallpaperPath();
}

pub fn getAvailableThemeCount() usize {
    return theme_loader.getThemeCount();
}
