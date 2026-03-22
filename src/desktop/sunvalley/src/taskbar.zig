//! Sun Valley Taskbar
//! Centered icon layout with pill-shaped active indicators,
//! system tray with quick-settings flyout, and date/time display.
//! Supports auto-hide and dynamic overflow.

const theme = @import("theme.zig");

pub const TaskbarConfig = struct {
    centered: bool = theme.Layout.taskbar_centered,
    height: i32 = theme.Layout.taskbar_height,
    auto_hide: bool = false,
    show_search: bool = true,
    show_task_view: bool = true,
    show_widgets: bool = true,
    color_scheme: theme.ColorScheme = .dark,
};

pub const PinnedApp = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    running: bool = false,
    active: bool = false,
    notification_count: u8 = 0,
};

const MAX_PINNED: usize = 16;
const MAX_RUNNING: usize = 32;
var pinned: [MAX_PINNED]PinnedApp = [_]PinnedApp{.{}} ** MAX_PINNED;
var pinned_count: usize = 0;
var running: [MAX_RUNNING]PinnedApp = [_]PinnedApp{.{}} ** MAX_RUNNING;
var running_count: usize = 0;
var cfg: TaskbarConfig = .{};
var initialized_flag: bool = false;

pub fn init(config: TaskbarConfig) void {
    cfg = config;
    pinned_count = 0;
    running_count = 0;
    initialized_flag = true;
    addDefaultPinned();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addDefaultPinned() void {
    addPinned("File Manager", 5);
    addPinned("Browser", 6);
    addPinned("Terminal", 4);
    addPinned("Settings", 7);
}

fn addPinned(name: []const u8, icon_id: u16) void {
    if (pinned_count >= MAX_PINNED) return;
    var app = &pinned[pinned_count];
    app.name_len = setStr(&app.name, name);
    app.icon_id = icon_id;
    pinned_count += 1;
}

pub fn getHeight() i32 {
    return cfg.height;
}

pub fn isCentered() bool {
    return cfg.centered;
}

pub fn getPinnedApps() []const PinnedApp {
    return pinned[0..pinned_count];
}

pub fn getRunningApps() []const PinnedApp {
    return running[0..running_count];
}

pub fn setActive(icon_id: u16) void {
    for (pinned[0..pinned_count]) |*app| {
        app.active = (app.icon_id == icon_id);
    }
    for (running[0..running_count]) |*app| {
        app.active = (app.icon_id == icon_id);
    }
}

pub fn launchApp(name: []const u8, icon_id: u16) void {
    for (pinned[0..pinned_count]) |*app| {
        if (app.icon_id == icon_id) {
            app.running = true;
            return;
        }
    }
    if (running_count >= MAX_RUNNING) return;
    var app = &running[running_count];
    app.name_len = setStr(&app.name, name);
    app.icon_id = icon_id;
    app.running = true;
    running_count += 1;
}

pub fn isClickOnStartButton(x: i32, y: i32, screen_w: i32, screen_h: i32) bool {
    const tb_y = screen_h - cfg.height;
    if (y < tb_y or y >= screen_h) return false;
    if (cfg.centered) {
        const center_x = @divTrunc(screen_w, 2);
        const total_icons: i32 = @intCast(pinned_count + 3);
        const group_w = total_icons * (theme.Layout.taskbar_icon_size + theme.Layout.taskbar_icon_spacing);
        const start_x = center_x - @divTrunc(group_w, 2);
        return x >= start_x and x < start_x + theme.Layout.start_btn_width;
    }
    return x >= 0 and x < theme.Layout.start_btn_width;
}

pub fn isClickOnTaskbar(x: i32, y: i32, screen_h: i32) bool {
    _ = x;
    const tb_y = screen_h - cfg.height;
    return y >= tb_y and y < screen_h;
}

pub fn getBackgroundColor() u32 {
    return switch (cfg.color_scheme) {
        .dark => theme.taskbar_dark_bg,
        .light => theme.taskbar_light_bg,
    };
}

pub fn getPillColor(active: bool) u32 {
    return if (active) theme.taskbar_pill_active else theme.taskbar_pill_inactive;
}
