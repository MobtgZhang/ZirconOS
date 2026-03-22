//! Theme definitions and selection for ZirconOS desktop environments.
//!
//! Each theme defines a consistent color set used across taskbar, titlebar,
//! window chrome, icons, tray, and start button. The active theme is a
//! global singleton switched at runtime via `setTheme`.

const builtin = @import("builtin");

const is_x86 = (builtin.target.cpu.arch == .x86_64);

pub fn rgb(r: u32, g: u32, b: u32) u32 {
    return b | (g << 8) | (r << 16);
}

pub const ThemeColors = struct {
    desktop_bg: u32,
    taskbar_top: u32,
    taskbar_bottom: u32,
    start_btn_top: u32,
    start_btn_bottom: u32,
    start_btn_text: u32,
    titlebar_active_left: u32,
    titlebar_active_right: u32,
    titlebar_text: u32,
    window_bg: u32,
    window_border: u32,
    tray_bg: u32,
    clock_text: u32,
    icon_text: u32,
    icon_text_shadow: u32,
    btn_close_top: u32,
    btn_close_bottom: u32,
    btn_minmax_top: u32,
    btn_minmax_bottom: u32,
    selection_bg: u32,
    button_face: u32,
    button_highlight: u32,
    button_shadow: u32,
    tray_border: u32,
    start_label: []const u8,
};

pub const ThemeId = enum(u8) {
    classic = 0,
    luna = 1,
    aero = 2,
    modern = 3,
    fluent = 4,
    sunvalley = 5,
};

pub const THEME_CLASSIC = ThemeColors{
    .desktop_bg = rgb(0x00, 0x80, 0x80),
    .taskbar_top = rgb(0xC0, 0xC0, 0xC0),
    .taskbar_bottom = rgb(0xC0, 0xC0, 0xC0),
    .start_btn_top = rgb(0xC0, 0xC0, 0xC0),
    .start_btn_bottom = rgb(0xA0, 0xA0, 0xA0),
    .start_btn_text = rgb(0x00, 0x00, 0x00),
    .titlebar_active_left = rgb(0x00, 0x00, 0x80),
    .titlebar_active_right = rgb(0x10, 0x84, 0xD0),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x80, 0x80, 0x80),
    .tray_bg = rgb(0xC0, 0xC0, 0xC0),
    .clock_text = rgb(0x00, 0x00, 0x00),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC0, 0xC0, 0xC0),
    .btn_close_bottom = rgb(0x80, 0x80, 0x80),
    .btn_minmax_top = rgb(0xC0, 0xC0, 0xC0),
    .btn_minmax_bottom = rgb(0x80, 0x80, 0x80),
    .selection_bg = rgb(0x00, 0x00, 0x80),
    .button_face = rgb(0xC0, 0xC0, 0xC0),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x80, 0x80, 0x80),
    .tray_border = rgb(0x80, 0x80, 0x80),
    .start_label = "Start",
};

pub const THEME_LUNA = ThemeColors{
    .desktop_bg = rgb(0x00, 0x4E, 0x98),
    .taskbar_top = rgb(0x00, 0x54, 0xE3),
    .taskbar_bottom = rgb(0x01, 0x50, 0xD0),
    .start_btn_top = rgb(0x3C, 0x8D, 0x2E),
    .start_btn_bottom = rgb(0x3F, 0xAA, 0x3B),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x58, 0xE6),
    .titlebar_active_right = rgb(0x3A, 0x81, 0xE5),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x00, 0x55, 0xE5),
    .tray_bg = rgb(0x0E, 0x8A, 0xEB),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xD4, 0x4A, 0x3C),
    .btn_close_bottom = rgb(0xB0, 0x2C, 0x20),
    .btn_minmax_top = rgb(0x2C, 0x5C, 0xD0),
    .btn_minmax_bottom = rgb(0x1C, 0x48, 0xB0),
    .selection_bg = rgb(0x31, 0x6A, 0xC5),
    .button_face = rgb(0xEC, 0xE9, 0xD8),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0xAC, 0xA8, 0x99),
    .tray_border = rgb(0x00, 0x3C, 0xA0),
    .start_label = "start",
};

pub const THEME_AERO = ThemeColors{
    .desktop_bg = rgb(0x12, 0x38, 0x62),
    .taskbar_top = rgb(0x22, 0x34, 0x4E),
    .taskbar_bottom = rgb(0x18, 0x26, 0x3A),
    .start_btn_top = rgb(0x3D, 0x79, 0xCB),
    .start_btn_bottom = rgb(0x24, 0x56, 0x9D),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x41, 0x80, 0xC8),
    .titlebar_active_right = rgb(0x6B, 0xA0, 0xD8),
    .titlebar_text = rgb(0x00, 0x00, 0x00),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x50, 0x78, 0xA8),
    .tray_bg = rgb(0x1C, 0x2A, 0x3E),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xE0, 0x4B, 0x3A),
    .btn_close_bottom = rgb(0xC0, 0x30, 0x20),
    .btn_minmax_top = rgb(0x40, 0x60, 0x90),
    .btn_minmax_bottom = rgb(0x30, 0x50, 0x80),
    .selection_bg = rgb(0x33, 0x99, 0xFF),
    .button_face = rgb(0xF0, 0xF0, 0xF0),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0xA0, 0xA0, 0xA0),
    .tray_border = rgb(0x40, 0x58, 0x78),
    .start_label = "Start",
};

pub const THEME_MODERN = ThemeColors{
    .desktop_bg = rgb(0x00, 0x78, 0xD7),
    .taskbar_top = rgb(0x1F, 0x1F, 0x1F),
    .taskbar_bottom = rgb(0x1F, 0x1F, 0x1F),
    .start_btn_top = rgb(0x00, 0x78, 0xD7),
    .start_btn_bottom = rgb(0x00, 0x60, 0xB0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x78, 0xD7),
    .titlebar_active_right = rgb(0x00, 0x78, 0xD7),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x00, 0x78, 0xD7),
    .tray_bg = rgb(0x1F, 0x1F, 0x1F),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xE8, 0x11, 0x23),
    .btn_close_bottom = rgb(0xC0, 0x00, 0x10),
    .btn_minmax_top = rgb(0x2D, 0x2D, 0x2D),
    .btn_minmax_bottom = rgb(0x1F, 0x1F, 0x1F),
    .selection_bg = rgb(0x00, 0x78, 0xD7),
    .button_face = rgb(0xCC, 0xCC, 0xCC),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x80, 0x80, 0x80),
    .tray_border = rgb(0x33, 0x33, 0x33),
    .start_label = "Start",
};

pub const THEME_FLUENT = ThemeColors{
    .desktop_bg = rgb(0x00, 0x47, 0x8A),
    .taskbar_top = rgb(0x20, 0x20, 0x20),
    .taskbar_bottom = rgb(0x20, 0x20, 0x20),
    .start_btn_top = rgb(0x00, 0x67, 0xC0),
    .start_btn_bottom = rgb(0x00, 0x55, 0xA0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x5A, 0x9E),
    .titlebar_active_right = rgb(0x00, 0x5A, 0x9E),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xF3, 0xF3, 0xF3),
    .window_border = rgb(0x00, 0x5A, 0x9E),
    .tray_bg = rgb(0x20, 0x20, 0x20),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC4, 0x2B, 0x1C),
    .btn_close_bottom = rgb(0xA0, 0x20, 0x10),
    .btn_minmax_top = rgb(0x2D, 0x2D, 0x2D),
    .btn_minmax_bottom = rgb(0x20, 0x20, 0x20),
    .selection_bg = rgb(0x00, 0x67, 0xC0),
    .button_face = rgb(0xE1, 0xE1, 0xE1),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x8A, 0x8A, 0x8A),
    .tray_border = rgb(0x38, 0x38, 0x38),
    .start_label = "Start",
};

pub const THEME_SUNVALLEY = ThemeColors{
    .desktop_bg = rgb(0x08, 0x12, 0x22),
    .taskbar_top = rgb(0x1C, 0x1C, 0x1C),
    .taskbar_bottom = rgb(0x1C, 0x1C, 0x1C),
    .start_btn_top = rgb(0x4C, 0xB0, 0xE8),
    .start_btn_bottom = rgb(0x28, 0x80, 0xC0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x1F, 0x1F, 0x1F),
    .titlebar_active_right = rgb(0x1F, 0x1F, 0x1F),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x44, 0x44, 0x44),
    .tray_bg = rgb(0x1C, 0x1C, 0x1C),
    .clock_text = rgb(0xDD, 0xDD, 0xDD),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC4, 0x2B, 0x1C),
    .btn_close_bottom = rgb(0xA0, 0x20, 0x15),
    .btn_minmax_top = rgb(0x3A, 0x3A, 0x3A),
    .btn_minmax_bottom = rgb(0x30, 0x30, 0x30),
    .selection_bg = rgb(0x4C, 0xB0, 0xE8),
    .button_face = rgb(0x2D, 0x2D, 0x2D),
    .button_highlight = rgb(0x38, 0x38, 0x38),
    .button_shadow = rgb(0x44, 0x44, 0x44),
    .tray_border = rgb(0x40, 0x40, 0x40),
    .start_label = "",
};

var active_theme: *const ThemeColors = &THEME_LUNA;
var active_theme_id: ThemeId = .luna;

pub fn setTheme(id: ThemeId) void {
    active_theme_id = id;
    active_theme = switch (id) {
        .classic => &THEME_CLASSIC,
        .luna => &THEME_LUNA,
        .aero => &THEME_AERO,
        .modern => &THEME_MODERN,
        .fluent => &THEME_FLUENT,
        .sunvalley => &THEME_SUNVALLEY,
    };
    if (is_x86) {
        const mouse = @import("../input/mouse.zig");
        switch (id) {
            .classic => {
                mouse.setInterpolation(false, 1);
                mouse.setSmoothing(false);
                mouse.setSensitivity(11);
            },
            else => {
                mouse.setInterpolation(true, 6);
                mouse.setSmoothing(true);
                mouse.setSensitivity(10);
            },
        }
    }
}

pub fn getActiveTheme() *const ThemeColors {
    return active_theme;
}

pub fn getActiveThemeId() ThemeId {
    return active_theme_id;
}

pub fn getThemeName() []const u8 {
    return switch (active_theme_id) {
        .classic => "Classic",
        .luna => "Luna",
        .aero => "Aero",
        .modern => "Modern",
        .fluent => "Fluent",
        .sunvalley => "Sun Valley",
    };
}

pub fn getTaskbarHeight() i32 {
    return switch (active_theme_id) {
        .aero => 40,
        .fluent, .sunvalley => 48,
        else => 30,
    };
}
