//! Shell - ZirconOS Luna Desktop Shell (explorer.exe equivalent)
//! Main entry point for the desktop environment. Coordinates
//! login, desktop, taskbar, start menu, and window management.
//! Reference: ReactOS explorer (base/shell/explorer/)

const theme = @import("theme.zig");
const winlogon = @import("winlogon.zig");
const desktop = @import("desktop.zig");
const taskbar = @import("taskbar.zig");
const startmenu = @import("startmenu.zig");
const window_decorator = @import("window_decorator.zig");
const controls = @import("controls.zig");

// ── Shell State ──

pub const ShellState = enum(u8) {
    not_started = 0,
    initializing = 1,
    login_screen = 2,
    loading_desktop = 3,
    desktop_active = 4,
    locking = 5,
    locked = 6,
    logging_off = 7,
    shutting_down = 8,
};

pub const ShellEvent = enum(u8) {
    none = 0,
    mouse_move = 1,
    mouse_left_down = 2,
    mouse_left_up = 3,
    mouse_right_down = 4,
    mouse_right_up = 5,
    mouse_double_click = 6,
    key_down = 7,
    key_up = 8,
    timer_tick = 9,
    window_created = 10,
    window_destroyed = 11,
    window_activated = 12,
    user_logon = 13,
    user_logoff = 14,
    start_menu_toggle = 15,
    shutdown_requested = 16,
};

pub const ShellConfig = struct {
    screen_width: i32 = 800,
    screen_height: i32 = 600,
    color_depth: u32 = 32,
    color_scheme: theme.ColorScheme = .blue,
    auto_logon: bool = false,
    auto_logon_user: [64]u8 = [_]u8{0} ** 64,
    auto_logon_user_len: usize = 0,
};

// ── Open Window Tracking ──

pub const MAX_SHELL_WINDOWS: usize = 32;

pub const ShellWindow = struct {
    hwnd: u64 = 0,
    chrome: window_decorator.WindowChrome = .{},
    is_active: bool = false,
    z_order: u32 = 0,

    pub fn getTitle(self: *const ShellWindow) []const u8 {
        return self.chrome.getTitle();
    }
};

// ── Global State ──

var shell_state: ShellState = .not_started;
var config: ShellConfig = .{};

var shell_windows: [MAX_SHELL_WINDOWS]ShellWindow = [_]ShellWindow{.{}} ** MAX_SHELL_WINDOWS;
var window_count: usize = 0;
var active_window_index: i32 = -1;
var next_z_order: u32 = 1;

var mouse_x: i32 = 0;
var mouse_y: i32 = 0;
var shell_tick_count: u64 = 0;
var shell_initialized: bool = false;

// ── Shell Lifecycle ──

pub fn start(cfg: ShellConfig) void {
    config = cfg;
    shell_state = .initializing;

    theme.init();
    theme.setColorScheme(cfg.color_scheme);

    winlogon.init();
    desktop.init();
    taskbar.init();
    startmenu.init();
    window_decorator.init();
    controls.init();

    desktop.setDesktopSize(cfg.screen_width, cfg.screen_height);
    taskbar.setScreenSize(cfg.screen_width, cfg.screen_height);

    if (cfg.auto_logon and cfg.auto_logon_user_len > 0) {
        performAutoLogon();
    } else {
        shell_state = .login_screen;
    }

    shell_initialized = true;
}

fn performAutoLogon() void {
    const name = config.auto_logon_user[0..config.auto_logon_user_len];
    const result = winlogon.authenticate(name, "");
    if (result == .success) {
        transitionToDesktop();
    } else {
        shell_state = .login_screen;
    }
}

fn transitionToDesktop() void {
    shell_state = .loading_desktop;

    startmenu.setUserInfo(winlogon.getCurrentUsername(), 0);

    shell_state = .desktop_active;
}

// ── Event Handling ──

pub fn handleEvent(event: ShellEvent, param1: i32, param2: i32) void {
    shell_tick_count += 1;

    switch (shell_state) {
        .login_screen => handleLoginEvent(event, param1, param2),
        .desktop_active => handleDesktopEvent(event, param1, param2),
        .locked => handleLockedEvent(event, param1, param2),
        else => {},
    }
}

fn handleLoginEvent(event: ShellEvent, param1: i32, param2: i32) void {
    switch (event) {
        .mouse_left_down => {
            _ = param2;
        },
        .key_down => {
            const key: u8 = @intCast(param1 & 0xFF);
            if (key == 0x0D) {
                const result = winlogon.submitPassword("");
                if (result == .success) {
                    transitionToDesktop();
                }
            }
        },
        .user_logon => transitionToDesktop(),
        else => {},
    }
}

fn handleDesktopEvent(event: ShellEvent, param1: i32, param2: i32) void {
    switch (event) {
        .mouse_move => {
            mouse_x = param1;
            mouse_y = param2;
        },
        .mouse_left_down => {
            const mx = param1;
            const my = param2;

            if (startmenu.isOpen()) {
                const rect = startmenu.getMenuRect();
                if (mx < rect.x or mx >= rect.x + rect.w or
                    my < rect.y or my >= rect.y + rect.h)
                {
                    startmenu.closeMenu();
                    taskbar.setStartButtonState(.normal);
                }
            }

            const sb = taskbar.getStartButton();
            if (sb.hitTest(mx, my)) {
                taskbar.toggleStartMenu();
                if (taskbar.isStartMenuOpen()) {
                    startmenu.openMenu(0, taskbar.getTaskbarY());
                } else {
                    startmenu.closeMenu();
                }
                return;
            }

            if (desktop.hitTestIcon(mx, my)) |idx| {
                desktop.selectIcon(idx);
                return;
            }

            desktop.deselectAll();
        },
        .mouse_right_down => {
            if (!startmenu.isOpen()) {
                desktop.showContextMenu(param1, param2);
            }
        },
        .mouse_double_click => {
            if (desktop.hitTestIcon(param1, param2)) |_| {
                // launch icon
            }
        },
        .key_down => {
            const key: u8 = @intCast(param1 & 0xFF);
            if (key == 0x5B or key == 0x5C) {
                taskbar.toggleStartMenu();
                if (taskbar.isStartMenuOpen()) {
                    startmenu.openMenu(0, taskbar.getTaskbarY());
                } else {
                    startmenu.closeMenu();
                }
            }
        },
        .timer_tick => {
            const tick = @as(u32, @intCast(shell_tick_count & 0xFFFFFFFF));
            const seconds = tick % 60;
            const minutes = (tick / 60) % 60;
            const hours = (tick / 3600) % 24;
            taskbar.updateClock(@intCast(hours), @intCast(minutes), @intCast(seconds));
        },
        .window_created => {
            const hwnd: u64 = @intCast(@as(u32, @bitCast(param1)));
            _ = taskbar.addTaskButton(hwnd, "New Window", 0);
        },
        .window_destroyed => {
            const hwnd: u64 = @intCast(@as(u32, @bitCast(param1)));
            _ = taskbar.removeTaskButton(hwnd);
            removeWindow(hwnd);
        },
        .window_activated => {
            const hwnd: u64 = @intCast(@as(u32, @bitCast(param1)));
            taskbar.setActiveTask(hwnd);
            activateWindow(hwnd);
        },
        .start_menu_toggle => {
            taskbar.toggleStartMenu();
            if (taskbar.isStartMenuOpen()) {
                startmenu.openMenu(0, taskbar.getTaskbarY());
            } else {
                startmenu.closeMenu();
            }
        },
        .user_logoff => logoff(),
        .shutdown_requested => beginShutdown(),
        else => {},
    }
}

fn handleLockedEvent(event: ShellEvent, param1: i32, _: i32) void {
    switch (event) {
        .key_down => {
            const key: u8 = @intCast(param1 & 0xFF);
            if (key == 0x0D) {
                const result = winlogon.unlockWorkstation("");
                if (result == .success) {
                    shell_state = .desktop_active;
                }
            }
        },
        else => {},
    }
}

// ── Window Management ──

pub fn registerWindow(hwnd: u64, title: []const u8) ?*ShellWindow {
    if (window_count >= MAX_SHELL_WINDOWS) return null;

    var win = &shell_windows[window_count];
    win.* = .{};
    win.hwnd = hwnd;
    win.chrome.hwnd = hwnd;
    win.chrome.setTitle(title);
    win.z_order = next_z_order;
    next_z_order += 1;

    window_decorator.layoutButtons(&win.chrome);

    window_count += 1;
    return win;
}

pub fn removeWindow(hwnd: u64) void {
    for (shell_windows[0..window_count]) |*win| {
        if (win.hwnd == hwnd) {
            win.hwnd = 0;
            return;
        }
    }
}

pub fn activateWindow(hwnd: u64) void {
    for (shell_windows[0..window_count], 0..) |*win, i| {
        if (win.hwnd == hwnd) {
            win.is_active = true;
            win.chrome.is_active = true;
            win.z_order = next_z_order;
            next_z_order += 1;
            active_window_index = @intCast(i);
        } else {
            win.is_active = false;
            win.chrome.is_active = false;
        }
    }
}

pub fn getActiveWindow() ?*const ShellWindow {
    if (active_window_index >= 0 and @as(usize, @intCast(active_window_index)) < window_count) {
        return &shell_windows[@intCast(active_window_index)];
    }
    return null;
}

pub fn getWindowCount() usize {
    var count: usize = 0;
    for (shell_windows[0..window_count]) |*win| {
        if (win.hwnd != 0) count += 1;
    }
    return count;
}

// ── Session Control ──

pub fn logoff() void {
    shell_state = .logging_off;
    startmenu.closeMenu();
    taskbar.setStartButtonState(.normal);
    winlogon.logoff();
    window_count = 0;
    active_window_index = -1;
    shell_state = .login_screen;
}

pub fn lockWorkstation() void {
    shell_state = .locking;
    startmenu.closeMenu();
    winlogon.lockWorkstation();
    shell_state = .locked;
}

pub fn beginShutdown() void {
    shell_state = .shutting_down;
    startmenu.closeMenu();
    winlogon.shutdown(.shutdown);
}

// ── State Query ──

pub fn getShellState() ShellState {
    return shell_state;
}

pub fn isDesktopActive() bool {
    return shell_state == .desktop_active;
}

pub fn isLoginScreen() bool {
    return shell_state == .login_screen;
}

pub fn getMousePosition() struct { x: i32, y: i32 } {
    return .{ .x = mouse_x, .y = mouse_y };
}

pub fn getConfig() *const ShellConfig {
    return &config;
}

pub fn getTickCount() u64 {
    return shell_tick_count;
}

// ── Login Helpers ──

pub fn selectLoginUser(index: u32) winlogon.AuthResult {
    return winlogon.beginLogon(index);
}

pub fn submitLoginPassword(password: []const u8) winlogon.AuthResult {
    const result = winlogon.submitPassword(password);
    if (result == .success) {
        transitionToDesktop();
    }
    return result;
}

// ── Initialization ──

pub fn init() void {
    shell_state = .not_started;
    window_count = 0;
    active_window_index = -1;
    next_z_order = 1;
    mouse_x = 0;
    mouse_y = 0;
    shell_tick_count = 0;
    shell_initialized = false;
}
