//! ZirconOS Luna Theme Definition
//! Windows XP Luna visual style: vivid blue taskbar, green Start button,
//! rounded window edges, gradient titlebars, and colorful 3D icons.
//! No glass blur; uses opaque gradient rendering throughout.

pub const COLORREF = u32;

pub fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

pub const RGB = rgb;

pub fn argb(a: u32, r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16) | (a << 24);
}

pub fn alphaBlend(fg: u32, bg: u32, alpha: u8) u32 {
    const a: u32 = @as(u32, alpha);
    const inv_a: u32 = 255 - a;
    const fr = fg & 0xFF;
    const fg_ = (fg >> 8) & 0xFF;
    const fb = (fg >> 16) & 0xFF;
    const br = bg & 0xFF;
    const bg_ = (bg >> 8) & 0xFF;
    const bb = (bg >> 16) & 0xFF;
    const or_ = (fr * a + br * inv_a) / 255;
    const og = (fg_ * a + bg_ * inv_a) / 255;
    const ob = (fb * a + bb * inv_a) / 255;
    return (or_ & 0xFF) | ((og & 0xFF) << 8) | ((ob & 0xFF) << 16);
}

// ── Font Constants (resolved from ZirconOSFonts) ──
// Tahoma → NotoSans mapping for ZirconOS

pub const FONT_SYSTEM = "Noto Sans";
pub const FONT_SYSTEM_SIZE: i32 = 11;
pub const FONT_MONO = "Source Code Pro";
pub const FONT_MONO_SIZE: i32 = 10;
pub const FONT_CJK = "Noto Sans CJK SC";
pub const FONT_CJK_SIZE: i32 = 11;
pub const FONT_TITLE_SIZE: i32 = 11;

// ── Visual Geometry Constants ──

pub const WINDOW_SHADOW_SIZE: i32 = 4;
pub const TITLEBAR_CORNER_RADIUS: i32 = 8;

// ── Color Schemes ──

pub const ColorScheme = enum {
    luna_blue,
    luna_olive,
    luna_silver,
    highcontrast,
};

pub const SchemeColors = struct {
    desktop_bg: u32,
    taskbar_top: u32,
    taskbar_bottom: u32,
    start_btn: u32,
    start_btn_dark: u32,
    titlebar_left: u32,
    titlebar_right: u32,
    titlebar_text: u32,
    titlebar_inactive_left: u32,
    titlebar_inactive_right: u32,
    window_bg: u32,
    button_face: u32,
    accent: u32,
};

pub const scheme_blue = SchemeColors{
    .desktop_bg = rgb(0x00, 0x4E, 0x98),
    .taskbar_top = rgb(0x00, 0x54, 0xE3),
    .taskbar_bottom = rgb(0x00, 0x2E, 0x8A),
    .start_btn = rgb(0x3C, 0x8D, 0x2E),
    .start_btn_dark = rgb(0x28, 0x6B, 0x1E),
    .titlebar_left = rgb(0x00, 0x58, 0xE6),
    .titlebar_right = rgb(0x3A, 0x81, 0xE5),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_inactive_left = rgb(0x7A, 0x96, 0xDF),
    .titlebar_inactive_right = rgb(0xA6, 0xCA, 0xF0),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .button_face = rgb(0xEC, 0xE9, 0xD8),
    .accent = rgb(0x00, 0x54, 0xE3),
};

pub const scheme_olive = SchemeColors{
    .desktop_bg = rgb(0x5A, 0x6B, 0x4C),
    .taskbar_top = rgb(0x8C, 0xAE, 0x53),
    .taskbar_bottom = rgb(0x5A, 0x7B, 0x34),
    .start_btn = rgb(0x8C, 0xAE, 0x53),
    .start_btn_dark = rgb(0x6B, 0x8A, 0x3C),
    .titlebar_left = rgb(0x8C, 0xAE, 0x53),
    .titlebar_right = rgb(0xB2, 0xCA, 0x7B),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_inactive_left = rgb(0xB8, 0xC0, 0xA0),
    .titlebar_inactive_right = rgb(0xD0, 0xDA, 0xBE),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .button_face = rgb(0xEC, 0xE9, 0xD8),
    .accent = rgb(0x8C, 0xAE, 0x53),
};

pub const scheme_silver = SchemeColors{
    .desktop_bg = rgb(0x54, 0x5C, 0x74),
    .taskbar_top = rgb(0xA0, 0xA8, 0xC0),
    .taskbar_bottom = rgb(0x7A, 0x82, 0x98),
    .start_btn = rgb(0x8C, 0x90, 0xA8),
    .start_btn_dark = rgb(0x6A, 0x70, 0x88),
    .titlebar_left = rgb(0xA0, 0xA8, 0xC0),
    .titlebar_right = rgb(0xC4, 0xCA, 0xDC),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_inactive_left = rgb(0xC0, 0xC4, 0xD0),
    .titlebar_inactive_right = rgb(0xDC, 0xDE, 0xE8),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .button_face = rgb(0xEC, 0xE9, 0xD8),
    .accent = rgb(0xA0, 0xA8, 0xC0),
};

pub fn getScheme(cs: ColorScheme) SchemeColors {
    return switch (cs) {
        .luna_blue => scheme_blue,
        .luna_olive => scheme_olive,
        .luna_silver => scheme_silver,
        .highcontrast => scheme_blue,
    };
}

// ── Wallpaper Paths ──

pub const WallpaperPath = struct {
    path: [128]u8 = [_]u8{0} ** 128,
    len: u8 = 0,
};

pub fn getWallpaperForScheme(cs: ColorScheme) WallpaperPath {
    var wp = WallpaperPath{};
    const src = switch (cs) {
        .luna_blue => "resources/wallpapers/bliss.svg",
        .luna_olive => "resources/wallpapers/bliss_olive.svg",
        .luna_silver => "resources/wallpapers/bliss_silver.svg",
        .highcontrast => "resources/wallpapers/bliss.svg",
    };
    const len = @min(src.len, 128);
    for (0..len) |i| {
        wp.path[i] = src[i];
    }
    wp.len = @intCast(len);
    return wp;
}

// ── Active Theme State ──

var active_scheme: ColorScheme = .luna_blue;

pub fn setActiveScheme(cs: ColorScheme) void {
    active_scheme = cs;
}

pub fn getActiveScheme() ColorScheme {
    return active_scheme;
}

pub fn getActiveColors() SchemeColors {
    return getScheme(active_scheme);
}

pub fn getActiveDesktopBg() u32 {
    return getScheme(active_scheme).desktop_bg;
}

pub fn getActiveTaskbarTop() u32 {
    return getScheme(active_scheme).taskbar_top;
}

// ── Core Luna Palette (Default Blue) ──

pub const desktop_bg = rgb(0x00, 0x4E, 0x98);

pub const taskbar_top = rgb(0x00, 0x54, 0xE3);
pub const taskbar_mid = rgb(0x00, 0x47, 0xC8);
pub const taskbar_bottom = rgb(0x00, 0x2E, 0x8A);
pub const taskbar_top_edge = rgb(0x59, 0x8D, 0xED);

pub const start_btn_top = rgb(0x5A, 0xB8, 0x42);
pub const start_btn_bottom = rgb(0x28, 0x6B, 0x1E);
pub const start_btn_text = rgb(0xFF, 0xFF, 0xFF);
pub const start_label = "start";

pub const titlebar_left = rgb(0x00, 0x58, 0xE6);
pub const titlebar_right = rgb(0x3A, 0x81, 0xE5);
pub const titlebar_text = rgb(0xFF, 0xFF, 0xFF);
pub const titlebar_inactive_left = rgb(0x7A, 0x96, 0xDF);
pub const titlebar_inactive_right = rgb(0xA6, 0xCA, 0xF0);
pub const titlebar_inactive_text = rgb(0xD8, 0xD8, 0xD8);

pub const window_bg = rgb(0xFF, 0xFF, 0xFF);
pub const window_border = rgb(0x00, 0x54, 0xE3);
pub const window_border_inactive = rgb(0x7A, 0x96, 0xDF);

pub const btn_close_top = rgb(0xDA, 0x71, 0x4C);
pub const btn_close_bottom = rgb(0xAE, 0x4A, 0x30);
pub const btn_close_glow = rgb(0xF0, 0x90, 0x70);
pub const btn_minmax_top = rgb(0x00, 0x58, 0xE6);
pub const btn_minmax_bottom = rgb(0x00, 0x3C, 0xAA);

pub const tray_bg = rgb(0x0F, 0x7C, 0xF5);
pub const tray_border = rgb(0x18, 0x62, 0xCC);
pub const clock_text = rgb(0xFF, 0xFF, 0xFF);

pub const icon_text = rgb(0xFF, 0xFF, 0xFF);
pub const icon_text_shadow = rgb(0x00, 0x00, 0x00);
pub const icon_selection = rgb(0x31, 0x6A, 0xC5);

pub const menu_bg = rgb(0xFF, 0xFF, 0xFF);
pub const menu_left_bg = rgb(0xEA, 0xF2, 0xFD);
pub const menu_right_bg = rgb(0xD3, 0xE5, 0xFA);
pub const menu_header_left = rgb(0x00, 0x54, 0xE3);
pub const menu_header_right = rgb(0x3A, 0x81, 0xE5);
pub const menu_separator = rgb(0xC0, 0xC0, 0xC0);
pub const menu_text = rgb(0x00, 0x00, 0x00);
pub const menu_hover_bg = rgb(0x31, 0x6A, 0xC5);
pub const menu_hover_text = rgb(0xFF, 0xFF, 0xFF);

pub const search_box_bg = rgb(0xFF, 0xFF, 0xFF);
pub const search_box_border = rgb(0x7F, 0x9D, 0xB9);

pub const shutdown_btn_bg = rgb(0xE0, 0x50, 0x30);
pub const shutdown_btn_text = rgb(0xFF, 0xFF, 0xFF);

pub const login_bg_top = rgb(0x00, 0x58, 0xE6);
pub const login_bg_bottom = rgb(0x00, 0x2E, 0x8A);
pub const login_panel_bg = rgb(0xEC, 0xE9, 0xD8);

pub const button_face = rgb(0xEC, 0xE9, 0xD8);
pub const button_highlight = rgb(0xFF, 0xFF, 0xFF);
pub const button_shadow = rgb(0xAC, 0xA8, 0x99);
pub const selection_bg = rgb(0x31, 0x6A, 0xC5);

// ── Luna Rendering Configuration ──
// No DWM glass — Luna uses GDI-style gradient rendering

pub const LunaDefaults = struct {
    pub const gradient_enabled: bool = true;
    pub const rounded_corners: bool = true;
    pub const corner_radius: u8 = 8;
    pub const shadow_enabled: bool = true;
    pub const shadow_size: u8 = 4;
    pub const animation_enabled: bool = false;
    pub const vsync: bool = true;
};

// ── Layout Constants ──

pub const Layout = struct {
    pub const taskbar_height: i32 = 30;
    pub const titlebar_height: i32 = 25;
    pub const start_btn_width: i32 = 97;
    pub const start_btn_height: i32 = 30;
    pub const icon_size: i32 = 32;
    pub const icon_grid_x: i32 = 75;
    pub const icon_grid_y: i32 = 75;
    pub const window_border_width: i32 = 3;
    pub const corner_radius: i32 = 8;
    pub const btn_size: i32 = 21;
    pub const tray_height: i32 = 20;
    pub const tray_clock_width: i32 = 60;
    pub const startmenu_width: i32 = 380;
    pub const startmenu_height: i32 = 400;
};

// ── Compositor Helper Functions ──

pub fn isGradientEnabled() bool {
    return LunaDefaults.gradient_enabled;
}

pub fn getShadowSize() i32 {
    return @as(i32, LunaDefaults.shadow_size);
}

pub const ThemeColors = struct {
    desktop_background: u32,
    window_border_active: u32,
    window_border_inactive: u32,
    button_highlight: u32,
    button_shadow: u32,
    titlebar_active_left: u32,
    titlebar_active_right: u32,
    titlebar_text: u32,
};

pub fn getColors() ThemeColors {
    const sc = getActiveColors();
    return .{
        .desktop_background = sc.desktop_bg,
        .window_border_active = window_border,
        .window_border_inactive = window_border_inactive,
        .button_highlight = button_highlight,
        .button_shadow = button_shadow,
        .titlebar_active_left = sc.titlebar_left,
        .titlebar_active_right = sc.titlebar_right,
        .titlebar_text = sc.titlebar_text,
    };
}

pub const GradientParams = struct {
    start_color: u32,
    end_color: u32,
    corner_radius: u8,
};

pub fn getTitlebarGradient() GradientParams {
    const sc = getActiveColors();
    return .{
        .start_color = sc.titlebar_left,
        .end_color = sc.titlebar_right,
        .corner_radius = LunaDefaults.corner_radius,
    };
}

pub fn getTaskbarGradient() GradientParams {
    const sc = getActiveColors();
    return .{
        .start_color = sc.taskbar_top,
        .end_color = sc.taskbar_bottom,
        .corner_radius = 0,
    };
}
