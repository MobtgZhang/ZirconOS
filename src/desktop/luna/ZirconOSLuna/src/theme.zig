//! ZirconOS Luna Theme - Windows XP Visual Style Definitions
//! Defines colors, dimensions, gradients and style constants for the
//! Luna Blue, Olive Green, and Silver color schemes.

pub const COLORREF = u32;

pub fn RGB(r: u8, g: u8, b: u8) COLORREF {
    return @as(u32, r) | (@as(u32, g) << 8) | (@as(u32, b) << 16);
}

pub fn getRValue(color: COLORREF) u8 {
    return @intCast(color & 0xFF);
}

pub fn getGValue(color: COLORREF) u8 {
    return @intCast((color >> 8) & 0xFF);
}

pub fn getBValue(color: COLORREF) u8 {
    return @intCast((color >> 16) & 0xFF);
}

pub const ColorScheme = enum(u8) {
    blue = 0,
    olive_green = 1,
    silver = 2,
};

pub const ThemeColors = struct {
    taskbar_top: COLORREF,
    taskbar_bottom: COLORREF,
    start_btn_top: COLORREF,
    start_btn_bottom: COLORREF,
    start_btn_text: COLORREF,
    titlebar_active_left: COLORREF,
    titlebar_active_right: COLORREF,
    titlebar_inactive_left: COLORREF,
    titlebar_inactive_right: COLORREF,
    titlebar_text_active: COLORREF,
    titlebar_text_inactive: COLORREF,
    window_border: COLORREF,
    window_background: COLORREF,
    desktop_background: COLORREF,
    menu_background: COLORREF,
    menu_highlight: COLORREF,
    menu_highlight_text: COLORREF,
    menu_text: COLORREF,
    menu_separator: COLORREF,
    button_face: COLORREF,
    button_highlight: COLORREF,
    button_shadow: COLORREF,
    button_text: COLORREF,
    scrollbar_track: COLORREF,
    scrollbar_thumb: COLORREF,
    selection_bg: COLORREF,
    selection_text: COLORREF,
    tooltip_bg: COLORREF,
    tooltip_text: COLORREF,
    login_bg_top: COLORREF,
    login_bg_bottom: COLORREF,
    login_panel: COLORREF,
    login_text: COLORREF,
    tray_bg: COLORREF,
    clock_text: COLORREF,
};

pub const LUNA_BLUE = ThemeColors{
    .taskbar_top = RGB(0x00, 0x54, 0xE3),
    .taskbar_bottom = RGB(0x01, 0x50, 0xD0),
    .start_btn_top = RGB(0x3C, 0x8D, 0x2E),
    .start_btn_bottom = RGB(0x3F, 0xAA, 0x3B),
    .start_btn_text = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = RGB(0x00, 0x58, 0xE6),
    .titlebar_active_right = RGB(0x3A, 0x81, 0xE5),
    .titlebar_inactive_left = RGB(0x7A, 0x96, 0xDF),
    .titlebar_inactive_right = RGB(0xA6, 0xBC, 0xE3),
    .titlebar_text_active = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_text_inactive = RGB(0xD8, 0xE4, 0xF8),
    .window_border = RGB(0x00, 0x55, 0xE5),
    .window_background = RGB(0xFF, 0xFF, 0xFF),
    .desktop_background = RGB(0x00, 0x4E, 0x98),
    .menu_background = RGB(0xFF, 0xFF, 0xFF),
    .menu_highlight = RGB(0x31, 0x6A, 0xC5),
    .menu_highlight_text = RGB(0xFF, 0xFF, 0xFF),
    .menu_text = RGB(0x00, 0x00, 0x00),
    .menu_separator = RGB(0xC5, 0xC5, 0xC5),
    .button_face = RGB(0xEC, 0xE9, 0xD8),
    .button_highlight = RGB(0xFF, 0xFF, 0xFF),
    .button_shadow = RGB(0xAC, 0xA8, 0x99),
    .button_text = RGB(0x00, 0x00, 0x00),
    .scrollbar_track = RGB(0xE8, 0xE8, 0xEB),
    .scrollbar_thumb = RGB(0xC1, 0xC1, 0xC6),
    .selection_bg = RGB(0x31, 0x6A, 0xC5),
    .selection_text = RGB(0xFF, 0xFF, 0xFF),
    .tooltip_bg = RGB(0xFF, 0xFF, 0xE1),
    .tooltip_text = RGB(0x00, 0x00, 0x00),
    .login_bg_top = RGB(0x00, 0x58, 0xB0),
    .login_bg_bottom = RGB(0x00, 0x3B, 0x7A),
    .login_panel = RGB(0xE3, 0xEF, 0xF8),
    .login_text = RGB(0x00, 0x00, 0x00),
    .tray_bg = RGB(0x0E, 0x8A, 0xEB),
    .clock_text = RGB(0xFF, 0xFF, 0xFF),
};

pub const LUNA_OLIVE = ThemeColors{
    .taskbar_top = RGB(0x8D, 0xB0, 0x80),
    .taskbar_bottom = RGB(0x6B, 0x8E, 0x5B),
    .start_btn_top = RGB(0x7E, 0x9D, 0x6D),
    .start_btn_bottom = RGB(0x6B, 0x8E, 0x5B),
    .start_btn_text = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = RGB(0x7C, 0x9C, 0x6A),
    .titlebar_active_right = RGB(0x9A, 0xB8, 0x89),
    .titlebar_inactive_left = RGB(0xA4, 0xB9, 0x97),
    .titlebar_inactive_right = RGB(0xC4, 0xD2, 0xBA),
    .titlebar_text_active = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_text_inactive = RGB(0xD8, 0xE4, 0xD0),
    .window_border = RGB(0x6B, 0x8E, 0x5B),
    .window_background = RGB(0xFF, 0xFF, 0xFF),
    .desktop_background = RGB(0x4A, 0x6E, 0x3A),
    .menu_background = RGB(0xFF, 0xFF, 0xFF),
    .menu_highlight = RGB(0x7C, 0x9C, 0x6A),
    .menu_highlight_text = RGB(0xFF, 0xFF, 0xFF),
    .menu_text = RGB(0x00, 0x00, 0x00),
    .menu_separator = RGB(0xC5, 0xC5, 0xC5),
    .button_face = RGB(0xEC, 0xE9, 0xD8),
    .button_highlight = RGB(0xFF, 0xFF, 0xFF),
    .button_shadow = RGB(0xAC, 0xA8, 0x99),
    .button_text = RGB(0x00, 0x00, 0x00),
    .scrollbar_track = RGB(0xE8, 0xE8, 0xEB),
    .scrollbar_thumb = RGB(0xC1, 0xC1, 0xC6),
    .selection_bg = RGB(0x7C, 0x9C, 0x6A),
    .selection_text = RGB(0xFF, 0xFF, 0xFF),
    .tooltip_bg = RGB(0xFF, 0xFF, 0xE1),
    .tooltip_text = RGB(0x00, 0x00, 0x00),
    .login_bg_top = RGB(0x6B, 0x8E, 0x5B),
    .login_bg_bottom = RGB(0x4A, 0x6E, 0x3A),
    .login_panel = RGB(0xE8, 0xF0, 0xE3),
    .login_text = RGB(0x00, 0x00, 0x00),
    .tray_bg = RGB(0x8D, 0xB0, 0x80),
    .clock_text = RGB(0xFF, 0xFF, 0xFF),
};

pub const LUNA_SILVER = ThemeColors{
    .taskbar_top = RGB(0xB5, 0xB9, 0xC6),
    .taskbar_bottom = RGB(0x8B, 0x8F, 0xA4),
    .start_btn_top = RGB(0x9A, 0x9E, 0xAF),
    .start_btn_bottom = RGB(0x8B, 0x8F, 0xA4),
    .start_btn_text = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = RGB(0x98, 0x9C, 0xAE),
    .titlebar_active_right = RGB(0xB5, 0xB9, 0xC8),
    .titlebar_inactive_left = RGB(0xB5, 0xB9, 0xC6),
    .titlebar_inactive_right = RGB(0xCF, 0xD2, 0xDB),
    .titlebar_text_active = RGB(0xFF, 0xFF, 0xFF),
    .titlebar_text_inactive = RGB(0xE0, 0xE1, 0xE6),
    .window_border = RGB(0x8B, 0x8F, 0xA4),
    .window_background = RGB(0xFF, 0xFF, 0xFF),
    .desktop_background = RGB(0x5C, 0x60, 0x78),
    .menu_background = RGB(0xFF, 0xFF, 0xFF),
    .menu_highlight = RGB(0x98, 0x9C, 0xAE),
    .menu_highlight_text = RGB(0xFF, 0xFF, 0xFF),
    .menu_text = RGB(0x00, 0x00, 0x00),
    .menu_separator = RGB(0xC5, 0xC5, 0xC5),
    .button_face = RGB(0xEC, 0xE9, 0xD8),
    .button_highlight = RGB(0xFF, 0xFF, 0xFF),
    .button_shadow = RGB(0xAC, 0xA8, 0x99),
    .button_text = RGB(0x00, 0x00, 0x00),
    .scrollbar_track = RGB(0xE8, 0xE8, 0xEB),
    .scrollbar_thumb = RGB(0xC1, 0xC1, 0xC6),
    .selection_bg = RGB(0x98, 0x9C, 0xAE),
    .selection_text = RGB(0xFF, 0xFF, 0xFF),
    .tooltip_bg = RGB(0xFF, 0xFF, 0xE1),
    .tooltip_text = RGB(0x00, 0x00, 0x00),
    .login_bg_top = RGB(0x8B, 0x8F, 0xA4),
    .login_bg_bottom = RGB(0x5C, 0x60, 0x78),
    .login_panel = RGB(0xE8, 0xE8, 0xF0),
    .login_text = RGB(0x00, 0x00, 0x00),
    .tray_bg = RGB(0xB5, 0xB9, 0xC6),
    .clock_text = RGB(0xFF, 0xFF, 0xFF),
};

// ── Dimension Constants ──

pub const TITLEBAR_HEIGHT: i32 = 30;
pub const TITLEBAR_BUTTON_SIZE: i32 = 21;
pub const TITLEBAR_BUTTON_MARGIN: i32 = 2;
pub const TITLEBAR_ICON_SIZE: i32 = 16;
pub const TITLEBAR_ICON_MARGIN: i32 = 4;
pub const TITLEBAR_TEXT_OFFSET_X: i32 = 24;
pub const TITLEBAR_TEXT_OFFSET_Y: i32 = 7;
pub const TITLEBAR_CORNER_RADIUS: i32 = 8;

pub const WINDOW_BORDER_WIDTH: i32 = 3;
pub const WINDOW_RESIZE_BORDER: i32 = 4;
pub const WINDOW_SHADOW_SIZE: i32 = 4;
pub const WINDOW_MIN_WIDTH: i32 = 130;
pub const WINDOW_MIN_HEIGHT: i32 = 50;

pub const TASKBAR_HEIGHT: i32 = 30;
pub const TASKBAR_BUTTON_HEIGHT: i32 = 24;
pub const TASKBAR_CLOCK_WIDTH: i32 = 80;

pub const START_BTN_WIDTH: i32 = 108;
pub const START_BTN_HEIGHT: i32 = 30;

pub const STARTMENU_WIDTH: i32 = 380;
pub const STARTMENU_HEIGHT: i32 = 460;
pub const STARTMENU_LEFT_WIDTH: i32 = 190;
pub const STARTMENU_RIGHT_WIDTH: i32 = 190;
pub const STARTMENU_ITEM_HEIGHT: i32 = 30;
pub const STARTMENU_ICON_SIZE: i32 = 24;
pub const STARTMENU_HEADER_HEIGHT: i32 = 54;
pub const STARTMENU_FOOTER_HEIGHT: i32 = 36;
pub const STARTMENU_SEPARATOR_HEIGHT: i32 = 8;

pub const DESKTOP_ICON_SIZE: i32 = 32;
pub const DESKTOP_ICON_SPACING_X: i32 = 75;
pub const DESKTOP_ICON_SPACING_Y: i32 = 75;
pub const DESKTOP_ICON_TEXT_WIDTH: i32 = 70;
pub const DESKTOP_ICON_MARGIN: i32 = 10;

pub const LOGIN_PANEL_WIDTH: i32 = 400;
pub const LOGIN_PANEL_HEIGHT: i32 = 300;
pub const LOGIN_AVATAR_SIZE: i32 = 48;
pub const LOGIN_INPUT_WIDTH: i32 = 200;
pub const LOGIN_INPUT_HEIGHT: i32 = 24;
pub const LOGIN_BUTTON_WIDTH: i32 = 72;
pub const LOGIN_BUTTON_HEIGHT: i32 = 23;

pub const BUTTON_HEIGHT: i32 = 23;
pub const BUTTON_MIN_WIDTH: i32 = 75;
pub const BUTTON_CORNER_RADIUS: i32 = 3;
pub const CHECKBOX_SIZE: i32 = 13;
pub const RADIO_SIZE: i32 = 13;
pub const TEXTBOX_HEIGHT: i32 = 21;

pub const TOOLTIP_PADDING: i32 = 4;
pub const MENU_ITEM_HEIGHT: i32 = 22;
pub const MENU_ICON_WIDTH: i32 = 24;
pub const SCROLLBAR_WIDTH: i32 = 17;

// ── Font Definitions ──

pub const FONT_SYSTEM = "Tahoma";
pub const FONT_SYSTEM_SIZE: i32 = 8;
pub const FONT_TITLEBAR = "Trebuchet MS";
pub const FONT_TITLEBAR_SIZE: i32 = 10;
pub const FONT_MENU = "Tahoma";
pub const FONT_MENU_SIZE: i32 = 8;
pub const FONT_ICON = "Tahoma";
pub const FONT_ICON_SIZE: i32 = 8;
pub const FONT_STARTMENU_USER = "Franklin Gothic Medium";
pub const FONT_STARTMENU_USER_SIZE: i32 = 14;
pub const FONT_TOOLTIP = "Tahoma";
pub const FONT_TOOLTIP_SIZE: i32 = 8;
pub const FONT_CLOCK = "Tahoma";
pub const FONT_CLOCK_SIZE: i32 = 8;

// ── Theme State ──

var current_scheme: ColorScheme = .blue;
var current_colors: *const ThemeColors = &LUNA_BLUE;

pub fn setColorScheme(scheme: ColorScheme) void {
    current_scheme = scheme;
    current_colors = switch (scheme) {
        .blue => &LUNA_BLUE,
        .olive_green => &LUNA_OLIVE,
        .silver => &LUNA_SILVER,
    };
}

pub fn getColorScheme() ColorScheme {
    return current_scheme;
}

pub fn getColors() *const ThemeColors {
    return current_colors;
}

pub fn getThemeName() []const u8 {
    return switch (current_scheme) {
        .blue => "Luna Blue",
        .olive_green => "Luna Olive Green",
        .silver => "Luna Silver",
    };
}

pub fn interpolateColor(c1: COLORREF, c2: COLORREF, t_num: u32, t_den: u32) COLORREF {
    if (t_den == 0) return c1;
    const r1: u32 = c1 & 0xFF;
    const g1: u32 = (c1 >> 8) & 0xFF;
    const b1: u32 = (c1 >> 16) & 0xFF;
    const r2: u32 = c2 & 0xFF;
    const g2: u32 = (c2 >> 8) & 0xFF;
    const b2: u32 = (c2 >> 16) & 0xFF;

    const r: u32 = r1 + (r2 -| r1) * t_num / t_den;
    const g: u32 = g1 + (g2 -| g1) * t_num / t_den;
    const b: u32 = b1 + (b2 -| b1) * t_num / t_den;

    return (r & 0xFF) | ((g & 0xFF) << 8) | ((b & 0xFF) << 16);
}

pub fn init() void {
    current_scheme = .blue;
    current_colors = &LUNA_BLUE;
}
