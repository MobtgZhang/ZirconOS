//! Sun Valley Quick Settings
//! Bottom-right flyout with toggles (WiFi, Bluetooth, Airplane mode,
//! Night light, Focus assist), brightness/volume sliders, and battery info.
//! Features Acrylic backdrop with rounded card layout.

const theme = @import("theme.zig");

pub const QuickToggle = struct {
    name: [24]u8 = [_]u8{0} ** 24,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    on: bool = false,
    available: bool = true,
};

const MAX_TOGGLES: usize = 8;
var toggles: [MAX_TOGGLES]QuickToggle = [_]QuickToggle{.{}} ** MAX_TOGGLES;
var toggle_count: usize = 0;

var brightness: u8 = 80;
var volume: u8 = 50;
var visible: bool = false;
var color_scheme: theme.ColorScheme = .dark;

pub fn init(scheme: theme.ColorScheme) void {
    toggle_count = 0;
    visible = false;
    brightness = 80;
    volume = 50;
    color_scheme = scheme;
    addDefaultToggles();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addToggle(name: []const u8, icon_id: u16, default_on: bool) void {
    if (toggle_count >= MAX_TOGGLES) return;
    var t = &toggles[toggle_count];
    t.name_len = setStr(&t.name, name);
    t.icon_id = icon_id;
    t.on = default_on;
    toggle_count += 1;
}

fn addDefaultToggles() void {
    addToggle("Wi-Fi", 20, true);
    addToggle("Bluetooth", 21, true);
    addToggle("Airplane", 22, false);
    addToggle("Night light", 23, false);
    addToggle("Focus", 24, false);
    addToggle("Accessibility", 25, false);
}

pub fn toggle_visibility() void {
    visible = !visible;
}

pub fn toggle() void {
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

pub fn toggleSetting(index: usize) void {
    if (index < toggle_count) {
        toggles[index].on = !toggles[index].on;
    }
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

pub fn getToggles() []const QuickToggle {
    return toggles[0..toggle_count];
}

pub fn getBackgroundColor() u32 {
    return theme.quick_settings_bg;
}

pub fn getToggleOnColor() u32 {
    return theme.quick_toggle_on;
}

pub fn getToggleOffColor() u32 {
    return theme.quick_toggle_off;
}

pub fn getSliderTrackColor() u32 {
    return theme.quick_slider_track;
}

pub fn getSliderFillColor() u32 {
    return theme.quick_slider_fill;
}
