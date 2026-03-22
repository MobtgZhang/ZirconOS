//! Modern Taskbar
//! Renders the system taskbar with flat dark background:
//! Start button (accent-colored square with Windows logo), running window
//! buttons, system tray / notification area, and clock.
//! Height: 30px. No glass, no gradients — pure flat Metro design.

const theme = @import("theme.zig");

pub const TaskbarConfig = struct {
    height: i32 = theme.Layout.taskbar_height,
};

pub const TaskButton = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    active: bool = false,
    flashing: bool = false,
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
}

pub fn getHeight() i32 {
    return cfg.height;
}

pub fn addTask(name: []const u8, icon_id: u16) void {
    if (button_count >= MAX_TASK_BUTTONS) return;
    var btn = &buttons[button_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        btn.name[i] = name[i];
    }
    btn.name_len = @intCast(len);
    btn.icon_id = icon_id;
    button_count += 1;
}

pub fn setActive(icon_id: u16) void {
    for (buttons[0..button_count]) |*btn| {
        btn.active = (btn.icon_id == icon_id);
    }
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

pub fn getBackgroundColor() u32 {
    return theme.taskbar_bg;
}

pub fn getStartButtonColor() u32 {
    return theme.start_btn_bg;
}

pub fn getStartButtonHoverColor() u32 {
    return theme.start_btn_hover;
}
