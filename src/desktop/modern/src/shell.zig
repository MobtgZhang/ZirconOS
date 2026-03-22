//! Modern Desktop Shell
//! Orchestrates the desktop session: initializes basic compositor,
//! coordinates desktop, taskbar, start screen, and manages window
//! focus, z-order, session lifecycle, and theme switching.
//!
//! Startup sequence mirrors ReactOS explorer.exe NT6.2 mode:
//! 1. WinLogon authenticates user and creates desktop
//! 2. Shell initializes resource and font loaders
//! 3. Shell initializes basic compositor with default theme
//! 4. Desktop, taskbar, and start screen components are created
//! 5. Theme loader registers built-in themes and applies active theme
//! 6. OS interface windows (Core, CMD, PowerShell) are minimized to taskbar
//! 7. Shell enters the desktop message loop

const theme = @import("theme.zig");
const desktop_mod = @import("desktop.zig");
const taskbar_mod = @import("taskbar.zig");
const startmenu_mod = @import("startmenu.zig");
const winlogon_mod = @import("winlogon.zig");
const theme_loader = @import("theme_loader.zig");
const resource_loader = @import("resource_loader.zig");
const font_loader = @import("font_loader.zig");

pub const ShellState = enum {
    initializing,
    login,
    desktop,
    start_screen,
    lock_screen,
    shutting_down,
};

pub const OsWindowState = struct {
    title: [32]u8 = [_]u8{0} ** 32,
    title_len: u8 = 0,
    icon_id: u16 = 0,
    minimized: bool = true,
};

const MAX_OS_WINDOWS: usize = 8;
var os_windows: [MAX_OS_WINDOWS]OsWindowState = [_]OsWindowState{.{}} ** MAX_OS_WINDOWS;
var os_window_count: usize = 0;

var state: ShellState = .initializing;

pub fn getState() ShellState {
    return state;
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addOsWindow(title: []const u8, icon_id: u16) void {
    if (os_window_count >= MAX_OS_WINDOWS) return;
    var w = &os_windows[os_window_count];
    w.title_len = setStr(&w.title, title);
    w.icon_id = icon_id;
    w.minimized = true;
    os_window_count += 1;
}

pub fn initShell() void {
    resource_loader.init();
    font_loader.init();

    theme_loader.registerBuiltinThemes();

    desktop_mod.init();

    taskbar_mod.init(.{
        .height = theme.Layout.taskbar_height,
    });

    startmenu_mod.init();
    winlogon_mod.init();

    registerOsWindows();

    state = .desktop;
}

fn registerOsWindows() void {
    os_window_count = 0;
    addOsWindow("ZirconOS Core", 1);
    addOsWindow("Command Prompt", 4);
    addOsWindow("PowerShell", 4);

    for (os_windows[0..os_window_count]) |w| {
        taskbar_mod.addTask(w.title[0..w.title_len], w.icon_id);
    }
}

pub fn getOsWindows() []const OsWindowState {
    return os_windows[0..os_window_count];
}

pub fn getOsWindowCount() usize {
    return os_window_count;
}

pub fn handleStartButton() void {
    startmenu_mod.toggle();
    if (startmenu_mod.isVisible()) {
        state = .start_screen;
    } else {
        state = .desktop;
    }
}

pub fn handleDesktopClick(x: i32, y: i32, screen_h: i32) void {
    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        state = .desktop;
        return;
    }

    if (taskbar_mod.isClickOnStartButton(x, y, screen_h)) {
        handleStartButton();
        return;
    }

    if (taskbar_mod.isClickOnTaskbar(x, y, screen_h)) {
        return;
    }

    if (desktop_mod.iconHitTest(x, y)) |idx| {
        desktop_mod.selectIcon(idx);
        return;
    }

    desktop_mod.deselectAll();
}

pub fn handleDesktopRightClick(x: i32, y: i32, screen_h: i32) void {
    _ = screen_h;
    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        state = .desktop;
        return;
    }
    desktop_mod.showContextMenu(x, y);
}

pub fn switchTheme(cs: theme.ColorScheme) void {
    desktop_mod.applyTheme(cs);
}

pub fn switchThemeByName(name: []const u8) bool {
    if (theme_loader.findThemeById(name)) |tc| {
        theme_loader.applyThemeConfig(tc);
        switchTheme(tc.color_scheme);
        return true;
    }
    return false;
}

pub fn getAvailableThemeCount() usize {
    return theme_loader.getThemeCount();
}

pub fn lockDesktop() void {
    state = .lock_screen;
    winlogon_mod.lockSession();
}

pub fn shutdown() void {
    state = .shutting_down;
}
