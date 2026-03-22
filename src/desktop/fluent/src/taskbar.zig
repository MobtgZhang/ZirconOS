//! Fluent Taskbar
//! Renders the system taskbar with: start button, search area (optional),
//! task view button, pinned/running app buttons, system tray, and clock.
//! Supports acrylic backdrop and accent underline for active windows.

const theme = @import("theme.zig");

pub const TaskbarConfig = struct {
    acrylic_enabled: bool = true,
    height: i32 = theme.Layout.taskbar_height,
    show_search: bool = true,
    show_task_view: bool = true,
    show_clock: bool = true,
    show_tray: bool = true,
    color_scheme: theme.ColorScheme = .dark,
};

pub const TaskButtonKind = enum(u8) {
    pinned = 0,
    running = 1,
    os_interface = 2,
};

pub const TaskButton = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    active: bool = false,
    pinned: bool = false,
    has_window: bool = false,
    flashing: bool = false,
    visible: bool = true,
    minimized: bool = false,
    kind: TaskButtonKind = .pinned,
};

const MAX_TASK_BUTTONS: usize = 32;
var buttons: [MAX_TASK_BUTTONS]TaskButton = [_]TaskButton{.{}} ** MAX_TASK_BUTTONS;
var button_count: usize = 0;
var cfg: TaskbarConfig = .{};
var initialized_flag: bool = false;

pub fn init(config: TaskbarConfig) void {
    cfg = config;
    button_count = 0;
    initialized_flag = true;

    addPinnedDefault();
}

fn addPinnedDefault() void {
    addPinned("File Manager", 5);
    addPinned("Terminal", 4);
    addPinned("Browser", 6);
    addPinned("Settings", 7);

    addOsInterfaceWindows();
}

fn addOsInterfaceWindows() void {
    addOsInterface("ZirconOS Core", 20);
    addOsInterface("CMD", 21);
    addOsInterface("PowerShell", 22);
}

fn addOsInterface(name: []const u8, icon_id: u16) void {
    if (button_count >= MAX_TASK_BUTTONS) return;
    var btn = &buttons[button_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        btn.name[i] = name[i];
    }
    btn.name_len = @intCast(len);
    btn.icon_id = icon_id;
    btn.has_window = true;
    btn.minimized = true;
    btn.kind = .os_interface;
    btn.visible = true;
    button_count += 1;
}

fn addPinned(name: []const u8, icon_id: u16) void {
    if (button_count >= MAX_TASK_BUTTONS) return;
    var btn = &buttons[button_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        btn.name[i] = name[i];
    }
    btn.name_len = @intCast(len);
    btn.icon_id = icon_id;
    btn.pinned = true;
    button_count += 1;
}

pub fn getHeight() i32 {
    return cfg.height;
}

pub fn getButtons() []const TaskButton {
    return buttons[0..button_count];
}

pub fn isClickOnStartButton(x: i32, y: i32, screen_h: i32) bool {
    const tb_y = screen_h - cfg.height;
    if (y < tb_y or y >= screen_h) return false;
    return x >= 0 and x < theme.Layout.start_btn_width;
}

pub fn isClickOnTaskbar(x: i32, y: i32, screen_h: i32) bool {
    _ = x;
    const tb_y = screen_h - cfg.height;
    return y >= tb_y and y < screen_h;
}

pub fn addTaskWindow(name: []const u8, icon_id: u16) void {
    for (buttons[0..button_count]) |*btn| {
        if (btn.icon_id == icon_id and btn.pinned) {
            btn.has_window = true;
            return;
        }
    }

    if (button_count >= MAX_TASK_BUTTONS) return;
    var btn = &buttons[button_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        btn.name[i] = name[i];
    }
    btn.name_len = @intCast(len);
    btn.icon_id = icon_id;
    btn.has_window = true;
    button_count += 1;
}

pub fn setActive(icon_id: u16) void {
    for (buttons[0..button_count]) |*btn| {
        btn.active = (btn.icon_id == icon_id);
    }
}

pub fn getBackgroundColor() u32 {
    return switch (cfg.color_scheme) {
        .dark => theme.taskbar_dark_bg,
        .light => theme.taskbar_light_bg,
    };
}

pub fn getTextColor() u32 {
    return switch (cfg.color_scheme) {
        .dark => theme.taskbar_dark_text,
        .light => theme.taskbar_light_text,
    };
}

pub fn getHoverColor() u32 {
    return switch (cfg.color_scheme) {
        .dark => theme.taskbar_dark_hover,
        .light => theme.taskbar_light_hover,
    };
}

pub fn getAccentStripColor() u32 {
    return switch (cfg.color_scheme) {
        .dark => theme.taskbar_dark_accent_strip,
        .light => theme.taskbar_light_accent_strip,
    };
}
