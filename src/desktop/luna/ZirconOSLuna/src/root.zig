//! ZirconOSLuna - Windows XP Luna Desktop Theme Library
//! Root module exporting all Luna desktop components for use by
//! the ZirconOS Win32 subsystem and shell.

pub const theme = @import("theme.zig");
pub const winlogon = @import("winlogon.zig");
pub const desktop = @import("desktop.zig");
pub const taskbar = @import("taskbar.zig");
pub const startmenu = @import("startmenu.zig");
pub const window_decorator = @import("window_decorator.zig");
pub const shell = @import("shell.zig");
pub const controls = @import("controls.zig");

pub const ColorScheme = theme.ColorScheme;
pub const ThemeColors = theme.ThemeColors;
pub const COLORREF = theme.COLORREF;
pub const RGB = theme.RGB;

pub const ShellState = shell.ShellState;
pub const ShellEvent = shell.ShellEvent;
pub const ShellConfig = shell.ShellConfig;
pub const SessionState = winlogon.SessionState;
pub const AuthResult = winlogon.AuthResult;
pub const UserRole = winlogon.UserRole;

pub fn initLunaDesktop(config: ShellConfig) void {
    shell.start(config);
}

pub fn handleShellEvent(event: ShellEvent, param1: i32, param2: i32) void {
    shell.handleEvent(event, param1, param2);
}

pub fn getShellState() ShellState {
    return shell.getShellState();
}

pub fn isDesktopActive() bool {
    return shell.isDesktopActive();
}

pub fn isLoginScreen() bool {
    return shell.isLoginScreen();
}

pub fn getCurrentUsername() []const u8 {
    return winlogon.getCurrentUsername();
}

pub fn getThemeName() []const u8 {
    return theme.getThemeName();
}

pub fn setColorScheme(scheme: ColorScheme) void {
    theme.setColorScheme(scheme);
}

pub fn logoff() void {
    shell.logoff();
}

pub fn lockWorkstation() void {
    shell.lockWorkstation();
}

pub fn shutdown() void {
    shell.beginShutdown();
}

pub fn selectLoginUser(index: u32) AuthResult {
    return shell.selectLoginUser(index);
}

pub fn submitLoginPassword(password: []const u8) AuthResult {
    return shell.submitLoginPassword(password);
}

pub fn getVersion() []const u8 {
    return "ZirconOS Luna Desktop v0.1.0";
}
