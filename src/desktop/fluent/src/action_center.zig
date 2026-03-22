//! Fluent Action Center
//! Notification panel with quick settings toggles (WiFi, Bluetooth,
//! Night Light, Focus Assist, etc.), brightness/volume sliders, and
//! notification cards. Slides in from the right edge.

const theme = @import("theme.zig");

pub const QuickToggle = struct {
    name: [24]u8 = [_]u8{0} ** 24,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    active: bool = false,
};

pub const Notification = struct {
    app_name: [32]u8 = [_]u8{0} ** 32,
    app_name_len: u8 = 0,
    title: [64]u8 = [_]u8{0} ** 64,
    title_len: u8 = 0,
    body: [128]u8 = [_]u8{0} ** 128,
    body_len: u8 = 0,
    timestamp_ms: u64 = 0,
    read: bool = false,
    icon_id: u16 = 0,
};

const MAX_TOGGLES: usize = 12;
const MAX_NOTIFICATIONS: usize = 32;

var toggles: [MAX_TOGGLES]QuickToggle = [_]QuickToggle{.{}} ** MAX_TOGGLES;
var toggle_count: usize = 0;

var notifications: [MAX_NOTIFICATIONS]Notification = [_]Notification{.{}} ** MAX_NOTIFICATIONS;
var notif_count: usize = 0;

var visible: bool = false;
var brightness: u8 = 80;
var volume: u8 = 50;
var color_scheme: theme.ColorScheme = .dark;

pub fn init(scheme: theme.ColorScheme) void {
    color_scheme = scheme;
    visible = false;
    toggle_count = 0;
    notif_count = 0;
    brightness = 80;
    volume = 50;

    addDefaultToggles();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addToggle(name: []const u8, icon_id: u16, active: bool) void {
    if (toggle_count >= MAX_TOGGLES) return;
    var t = &toggles[toggle_count];
    t.name_len = setStr(&t.name, name);
    t.icon_id = icon_id;
    t.active = active;
    toggle_count += 1;
}

fn addDefaultToggles() void {
    addToggle("Network", 20, true);
    addToggle("Bluetooth", 21, false);
    addToggle("Night Light", 22, false);
    addToggle("Focus Assist", 23, false);
    addToggle("Location", 24, true);
    addToggle("Airplane", 25, false);
}

pub fn toggle_visibility() void {
    visible = !visible;
}

pub fn show() void {
    visible = true;
}

pub fn hide() void {
    visible = false;
}

pub fn isVisible() bool {
    return visible;
}

pub fn toggleQuickSetting(index: usize) void {
    if (index < toggle_count) {
        toggles[index].active = !toggles[index].active;
    }
}

pub fn getToggles() []const QuickToggle {
    return toggles[0..toggle_count];
}

pub fn getNotifications() []const Notification {
    return notifications[0..notif_count];
}

pub fn pushNotification(app: []const u8, title: []const u8, body: []const u8, icon_id: u16) void {
    if (notif_count >= MAX_NOTIFICATIONS) {
        // Shift out oldest
        for (0..MAX_NOTIFICATIONS - 1) |i| {
            notifications[i] = notifications[i + 1];
        }
        notif_count = MAX_NOTIFICATIONS - 1;
    }
    var n = &notifications[notif_count];
    n.app_name_len = setStr(&n.app_name, app);
    n.title_len = setStr(&n.title, title);
    n.body_len = setStr(&n.body, body);
    n.icon_id = icon_id;
    n.read = false;
    notif_count += 1;
}

pub fn clearNotifications() void {
    notif_count = 0;
}

pub fn setBrightness(val: u8) void {
    brightness = val;
}

pub fn getBrightness() u8 {
    return brightness;
}

pub fn setVolume(val: u8) void {
    volume = val;
}

pub fn getVolume() u8 {
    return volume;
}

pub fn getBackgroundColor() u32 {
    return switch (color_scheme) {
        .dark => theme.action_dark_bg,
        .light => theme.action_light_bg,
    };
}

pub fn getTileColor(active: bool) u32 {
    return switch (color_scheme) {
        .dark => if (active) theme.action_dark_tile_active else theme.action_dark_tile,
        .light => if (active) theme.action_light_tile_active else theme.action_light_tile,
    };
}
