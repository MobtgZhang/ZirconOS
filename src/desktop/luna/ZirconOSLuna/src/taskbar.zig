//! Taskbar - ZirconOS Luna Taskbar Implementation
//! Implements the Windows XP-style taskbar with Start button,
//! Quick Launch area, task buttons, system tray, and clock.
//! Reference: ReactOS explorer taskbar (base/shell/explorer/taskbar/)

const theme = @import("theme.zig");

pub const COLORREF = theme.COLORREF;

// ── Taskbar Position ──

pub const TaskbarPosition = enum(u8) {
    bottom = 0,
    top = 1,
    left = 2,
    right = 3,
};

// ── Task Button (represents an open window) ──

pub const MAX_TASK_BUTTONS: usize = 32;
pub const MAX_TASK_NAME_LEN: usize = 64;

pub const TaskButtonState = enum(u8) {
    normal = 0,
    active = 1,
    flashing = 2,
    minimized = 3,
};

pub const TaskButton = struct {
    hwnd: u64 = 0,
    name: [MAX_TASK_NAME_LEN]u8 = [_]u8{0} ** MAX_TASK_NAME_LEN,
    name_len: usize = 0,
    icon_id: u32 = 0,
    state: TaskButtonState = .normal,
    is_visible: bool = false,
    x: i32 = 0,
    width: i32 = 0,
    flash_count: u32 = 0,

    pub fn getName(self: *const TaskButton) []const u8 {
        return self.name[0..self.name_len];
    }
};

// ── Quick Launch Item ──

pub const MAX_QUICK_LAUNCH: usize = 8;

pub const QuickLaunchItem = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: usize = 0,
    target_path: [128]u8 = [_]u8{0} ** 128,
    target_path_len: usize = 0,
    icon_id: u32 = 0,
    is_visible: bool = false,
    x: i32 = 0,

    pub fn getName(self: *const QuickLaunchItem) []const u8 {
        return self.name[0..self.name_len];
    }
};

// ── System Tray Icon ──

pub const MAX_TRAY_ICONS: usize = 16;

pub const TrayIconFlags = struct {
    show_tooltip: bool = false,
    has_balloon: bool = false,
    hidden: bool = false,
};

pub const TrayIcon = struct {
    id: u32 = 0,
    owner_hwnd: u64 = 0,
    icon_id: u32 = 0,
    tooltip: [64]u8 = [_]u8{0} ** 64,
    tooltip_len: usize = 0,
    flags: TrayIconFlags = .{},
    is_visible: bool = false,
    x: i32 = 0,

    pub fn getTooltip(self: *const TrayIcon) []const u8 {
        return self.tooltip[0..self.tooltip_len];
    }
};

// ── Clock ──

pub const TaskbarClock = struct {
    hour: u8 = 0,
    minute: u8 = 0,
    second: u8 = 0,
    show_seconds: bool = false,
    is_24h: bool = false,
    x: i32 = 0,
    width: i32 = theme.TASKBAR_CLOCK_WIDTH,

    pub fn getTimeString(self: *const TaskbarClock, buffer: []u8) usize {
        if (buffer.len < 8) return 0;
        var h = self.hour;
        const suffix: u8 = if (!self.is_24h and h >= 12) 'P' else 'A';
        if (!self.is_24h) {
            if (h == 0) h = 12 else if (h > 12) h -= 12;
        }

        var pos: usize = 0;
        if (h >= 10) {
            buffer[pos] = '0' + h / 10;
            pos += 1;
        }
        buffer[pos] = '0' + h % 10;
        pos += 1;
        buffer[pos] = ':';
        pos += 1;
        buffer[pos] = '0' + self.minute / 10;
        pos += 1;
        buffer[pos] = '0' + self.minute % 10;
        pos += 1;

        if (self.show_seconds) {
            buffer[pos] = ':';
            pos += 1;
            buffer[pos] = '0' + self.second / 10;
            pos += 1;
            buffer[pos] = '0' + self.second % 10;
            pos += 1;
        }

        if (!self.is_24h and pos + 3 <= buffer.len) {
            buffer[pos] = ' ';
            pos += 1;
            buffer[pos] = suffix;
            pos += 1;
            buffer[pos] = 'M';
            pos += 1;
        }

        return pos;
    }
};

// ── Start Button ──

pub const StartButtonState = enum(u8) {
    normal = 0,
    hover = 1,
    pressed = 2,
    menu_open = 3,
};

pub const StartButton = struct {
    state: StartButtonState = .normal,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = theme.START_BTN_WIDTH,
    height: i32 = theme.START_BTN_HEIGHT,

    pub fn hitTest(self: *const StartButton, mx: i32, my: i32) bool {
        return mx >= self.x and mx < self.x + self.width and
            my >= self.y and my < self.y + self.height;
    }

    pub fn getColors(self: *const StartButton) struct {
        top: COLORREF,
        bottom: COLORREF,
        text: COLORREF,
    } {
        const colors = theme.getColors();
        return switch (self.state) {
            .pressed, .menu_open => .{
                .top = theme.interpolateColor(colors.start_btn_top, theme.RGB(0, 0, 0), 1, 4),
                .bottom = theme.interpolateColor(colors.start_btn_bottom, theme.RGB(0, 0, 0), 1, 4),
                .text = colors.start_btn_text,
            },
            .hover => .{
                .top = theme.interpolateColor(colors.start_btn_top, theme.RGB(255, 255, 255), 1, 4),
                .bottom = theme.interpolateColor(colors.start_btn_bottom, theme.RGB(255, 255, 255), 1, 4),
                .text = colors.start_btn_text,
            },
            .normal => .{
                .top = colors.start_btn_top,
                .bottom = colors.start_btn_bottom,
                .text = colors.start_btn_text,
            },
        };
    }
};

// ── Taskbar Settings ──

pub const TaskbarSettings = struct {
    position: TaskbarPosition = .bottom,
    auto_hide: bool = false,
    always_on_top: bool = true,
    group_similar: bool = true,
    show_quick_launch: bool = true,
    show_clock: bool = true,
    lock_taskbar: bool = true,
    height: i32 = theme.TASKBAR_HEIGHT,
};

// ── Global State ──

var task_buttons: [MAX_TASK_BUTTONS]TaskButton = [_]TaskButton{.{}} ** MAX_TASK_BUTTONS;
var task_count: usize = 0;

var quick_launch: [MAX_QUICK_LAUNCH]QuickLaunchItem = [_]QuickLaunchItem{.{}} ** MAX_QUICK_LAUNCH;
var quick_launch_count: usize = 0;

var tray_icons: [MAX_TRAY_ICONS]TrayIcon = [_]TrayIcon{.{}} ** MAX_TRAY_ICONS;
var tray_icon_count: usize = 0;

var clock: TaskbarClock = .{};
var start_button: StartButton = .{};
var taskbar_settings: TaskbarSettings = .{};

var screen_width: i32 = 800;
var screen_height: i32 = 600;
var taskbar_initialized: bool = false;

// ── Task Button Management ──

pub fn addTaskButton(hwnd: u64, name: []const u8, icon_id: u32) ?*TaskButton {
    if (task_count >= MAX_TASK_BUTTONS) return null;

    var btn = &task_buttons[task_count];
    btn.* = .{};
    btn.hwnd = hwnd;
    btn.icon_id = icon_id;
    btn.is_visible = true;
    btn.state = .normal;

    const n = @min(name.len, MAX_TASK_NAME_LEN);
    @memcpy(btn.name[0..n], name[0..n]);
    btn.name_len = n;

    task_count += 1;
    recalculateTaskLayout();
    return btn;
}

pub fn removeTaskButton(hwnd: u64) bool {
    for (task_buttons[0..task_count]) |*btn| {
        if (btn.hwnd == hwnd) {
            btn.is_visible = false;
            recalculateTaskLayout();
            return true;
        }
    }
    return false;
}

pub fn setActiveTask(hwnd: u64) void {
    for (task_buttons[0..task_count]) |*btn| {
        if (!btn.is_visible) continue;
        btn.state = if (btn.hwnd == hwnd) .active else .normal;
    }
}

pub fn flashTask(hwnd: u64) void {
    for (task_buttons[0..task_count]) |*btn| {
        if (btn.hwnd == hwnd and btn.state != .active) {
            btn.state = .flashing;
            btn.flash_count = 0;
        }
    }
}

pub fn getTaskButton(index: usize) ?*const TaskButton {
    if (index < task_count and task_buttons[index].is_visible) {
        return &task_buttons[index];
    }
    return null;
}

pub fn getTaskCount() usize {
    var count: usize = 0;
    for (task_buttons[0..task_count]) |*btn| {
        if (btn.is_visible) count += 1;
    }
    return count;
}

pub fn hitTestTask(x: i32, y: i32) ?usize {
    const tb_y = getTaskbarY();
    if (y < tb_y or y >= tb_y + taskbar_settings.height) return null;

    for (task_buttons[0..task_count], 0..) |*btn, i| {
        if (!btn.is_visible) continue;
        if (x >= btn.x and x < btn.x + btn.width) return i;
    }
    return null;
}

// ── Quick Launch ──

pub fn addQuickLaunchItem(name: []const u8, target: []const u8, icon_id: u32) void {
    if (quick_launch_count >= MAX_QUICK_LAUNCH) return;
    var item = &quick_launch[quick_launch_count];
    item.* = .{};
    item.icon_id = icon_id;
    item.is_visible = true;

    const nn = @min(name.len, item.name.len);
    @memcpy(item.name[0..nn], name[0..nn]);
    item.name_len = nn;

    const tp = @min(target.len, item.target_path.len);
    @memcpy(item.target_path[0..tp], target[0..tp]);
    item.target_path_len = tp;

    quick_launch_count += 1;
}

// ── System Tray ──

pub fn addTrayIcon(id: u32, owner: u64, icon_id: u32, tooltip: []const u8) bool {
    if (tray_icon_count >= MAX_TRAY_ICONS) return false;
    var icon = &tray_icons[tray_icon_count];
    icon.* = .{};
    icon.id = id;
    icon.owner_hwnd = owner;
    icon.icon_id = icon_id;
    icon.is_visible = true;
    icon.flags.show_tooltip = tooltip.len > 0;

    const n = @min(tooltip.len, icon.tooltip.len);
    @memcpy(icon.tooltip[0..n], tooltip[0..n]);
    icon.tooltip_len = n;

    tray_icon_count += 1;
    return true;
}

pub fn removeTrayIcon(id: u32) bool {
    for (tray_icons[0..tray_icon_count]) |*icon| {
        if (icon.id == id) {
            icon.is_visible = false;
            return true;
        }
    }
    return false;
}

pub fn getTrayIconCount() usize {
    var count: usize = 0;
    for (tray_icons[0..tray_icon_count]) |*icon| {
        if (icon.is_visible) count += 1;
    }
    return count;
}

// ── Clock ──

pub fn updateClock(hour: u8, minute: u8, second: u8) void {
    clock.hour = hour;
    clock.minute = minute;
    clock.second = second;
}

pub fn getClock() *const TaskbarClock {
    return &clock;
}

// ── Start Button ──

pub fn getStartButton() *const StartButton {
    return &start_button;
}

pub fn setStartButtonState(state: StartButtonState) void {
    start_button.state = state;
}

pub fn isStartMenuOpen() bool {
    return start_button.state == .menu_open;
}

pub fn toggleStartMenu() void {
    if (start_button.state == .menu_open) {
        start_button.state = .normal;
    } else {
        start_button.state = .menu_open;
    }
}

// ── Layout ──

pub fn getTaskbarY() i32 {
    return switch (taskbar_settings.position) {
        .bottom => screen_height - taskbar_settings.height,
        .top => 0,
        else => 0,
    };
}

pub fn getTaskbarRect() struct { x: i32, y: i32, w: i32, h: i32 } {
    return switch (taskbar_settings.position) {
        .bottom => .{
            .x = 0,
            .y = screen_height - taskbar_settings.height,
            .w = screen_width,
            .h = taskbar_settings.height,
        },
        .top => .{
            .x = 0,
            .y = 0,
            .w = screen_width,
            .h = taskbar_settings.height,
        },
        else => .{
            .x = 0,
            .y = screen_height - taskbar_settings.height,
            .w = screen_width,
            .h = taskbar_settings.height,
        },
    };
}

pub fn getTaskbarColors() struct {
    bg_top: COLORREF,
    bg_bottom: COLORREF,
    tray_bg: COLORREF,
    clock_text: COLORREF,
} {
    const colors = theme.getColors();
    return .{
        .bg_top = colors.taskbar_top,
        .bg_bottom = colors.taskbar_bottom,
        .tray_bg = colors.tray_bg,
        .clock_text = colors.clock_text,
    };
}

fn recalculateTaskLayout() void {
    const start_end = theme.START_BTN_WIDTH + 6;
    var ql_width: i32 = 0;
    if (taskbar_settings.show_quick_launch) {
        var ql_visible: i32 = 0;
        for (quick_launch[0..quick_launch_count]) |*item| {
            if (item.is_visible) ql_visible += 1;
        }
        ql_width = ql_visible * 22 + 8;
    }

    const tray_width = computeTrayWidth();
    const clock_width: i32 = if (taskbar_settings.show_clock) theme.TASKBAR_CLOCK_WIDTH else 0;
    const task_area_start = start_end + ql_width;
    const task_area_end = screen_width - tray_width - clock_width - 4;
    const task_area_width = @max(task_area_end - task_area_start, 0);

    var visible_count: i32 = 0;
    for (task_buttons[0..task_count]) |*btn| {
        if (btn.is_visible) visible_count += 1;
    }

    const btn_width: i32 = if (visible_count > 0)
        @min(160, @divTrunc(task_area_width, visible_count))
    else
        160;

    var pos: i32 = task_area_start;
    for (task_buttons[0..task_count]) |*btn| {
        if (!btn.is_visible) continue;
        btn.x = pos;
        btn.width = btn_width;
        pos += btn_width + 2;
    }
}

fn computeTrayWidth() i32 {
    var count: i32 = 0;
    for (tray_icons[0..tray_icon_count]) |*icon| {
        if (icon.is_visible) count += 1;
    }
    return count * 20 + 8;
}

// ── Settings ──

pub fn getSettings() *const TaskbarSettings {
    return &taskbar_settings;
}

pub fn setScreenSize(w: i32, h: i32) void {
    screen_width = w;
    screen_height = h;
    start_button.y = getTaskbarY();
    recalculateTaskLayout();
}

// ── Initialization ──

pub fn init() void {
    task_count = 0;
    quick_launch_count = 0;
    tray_icon_count = 0;
    taskbar_settings = .{};
    clock = .{};
    start_button = .{
        .x = 0,
        .y = screen_height - theme.TASKBAR_HEIGHT,
        .width = theme.START_BTN_WIDTH,
        .height = theme.START_BTN_HEIGHT,
    };

    addQuickLaunchItem("Show Desktop", "shell:desktop", 1);
    addQuickLaunchItem("Internet Explorer", "C:\\Program Files\\Internet Explorer\\iexplore.exe", 2);
    addQuickLaunchItem("Windows Media Player", "C:\\Program Files\\Windows Media Player\\wmplayer.exe", 3);

    _ = addTrayIcon(1, 0, 10, "Volume");
    _ = addTrayIcon(2, 0, 11, "Network");
    _ = addTrayIcon(3, 0, 12, "ZirconOS Security");

    updateClock(12, 0, 0);
    recalculateTaskLayout();
    taskbar_initialized = true;
}
