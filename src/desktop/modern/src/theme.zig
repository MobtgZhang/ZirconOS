//! ZirconOS Modern Theme Definition
//! Windows 8 Metro flat visual style: no gradients, no transparency,
//! bold accent colors, clean typography, and sharp rectangular geometry.

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
// Segoe UI mapped to NotoSans from ZirconOSFonts

pub const FONT_SYSTEM = "Noto Sans";
pub const FONT_SYSTEM_SIZE: i32 = 11;
pub const FONT_MONO = "Source Code Pro";
pub const FONT_MONO_SIZE: i32 = 10;
pub const FONT_CJK = "Noto Sans CJK SC";
pub const FONT_CJK_SIZE: i32 = 11;
pub const FONT_TITLE_SIZE: i32 = 11;

// ── Visual Geometry Constants ──
// Metro: no shadows, no rounded corners — everything is sharp rectangles

pub const WINDOW_SHADOW_SIZE: i32 = 0;
pub const TITLEBAR_CORNER_RADIUS: i32 = 0;

// ── Color Schemes ──

pub const ColorScheme = enum {
    modern_blue,
    modern_purple,
    modern_green,
    modern_orange,
    modern_red,
    modern_dark,
    highcontrast,
};

pub const SchemeColors = struct {
    accent: u32,
    accent_light: u32,
    accent_dark: u32,
    titlebar_text: u32,
    desktop_bg: u32,
};

pub const scheme_blue = SchemeColors{
    .accent = rgb(0x00, 0x78, 0xD7),
    .accent_light = rgb(0x42, 0x9C, 0xE3),
    .accent_dark = rgb(0x00, 0x63, 0xB1),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0x00, 0x78, 0xD7),
};

pub const scheme_purple = SchemeColors{
    .accent = rgb(0x88, 0x17, 0x98),
    .accent_light = rgb(0xB1, 0x46, 0xC2),
    .accent_dark = rgb(0x6B, 0x0F, 0x78),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0x88, 0x17, 0x98),
};

pub const scheme_green = SchemeColors{
    .accent = rgb(0x10, 0x7C, 0x10),
    .accent_light = rgb(0x33, 0x9C, 0x33),
    .accent_dark = rgb(0x0B, 0x60, 0x0B),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0x10, 0x7C, 0x10),
};

pub const scheme_orange = SchemeColors{
    .accent = rgb(0xDA, 0x3B, 0x01),
    .accent_light = rgb(0xEF, 0x69, 0x50),
    .accent_dark = rgb(0xAA, 0x2E, 0x00),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0xDA, 0x3B, 0x01),
};

pub const scheme_red = SchemeColors{
    .accent = rgb(0xE8, 0x11, 0x23),
    .accent_light = rgb(0xF0, 0x63, 0x6E),
    .accent_dark = rgb(0xC5, 0x0F, 0x1F),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0xE8, 0x11, 0x23),
};

pub const scheme_dark = SchemeColors{
    .accent = rgb(0x76, 0x76, 0x76),
    .accent_light = rgb(0x99, 0x99, 0x99),
    .accent_dark = rgb(0x4C, 0x4C, 0x4C),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .desktop_bg = rgb(0x2D, 0x2D, 0x2D),
};

pub fn getScheme(cs: ColorScheme) SchemeColors {
    return switch (cs) {
        .modern_blue => scheme_blue,
        .modern_purple => scheme_purple,
        .modern_green => scheme_green,
        .modern_orange => scheme_orange,
        .modern_red => scheme_red,
        .modern_dark => scheme_dark,
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
        .modern_blue => "resources/wallpapers/modern_default.svg",
        .modern_purple => "resources/wallpapers/modern_purple.svg",
        .modern_green => "resources/wallpapers/modern_green.svg",
        .modern_orange => "resources/wallpapers/modern_orange.svg",
        .modern_red => "resources/wallpapers/modern_red.svg",
        .modern_dark => "resources/wallpapers/modern_dark.svg",
        .highcontrast => "resources/wallpapers/modern_default.svg",
    };
    const len = @min(src.len, 128);
    for (0..len) |i| {
        wp.path[i] = src[i];
    }
    wp.len = @intCast(len);
    return wp;
}

// ── Active Theme State ──

var active_scheme: ColorScheme = .modern_blue;

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

pub fn getActiveAccent() u32 {
    return getScheme(active_scheme).accent;
}

// ── Core Modern Palette (Default Blue) ──
// Windows 8 Metro: flat, solid, no gradients

pub const desktop_bg = rgb(0x00, 0x78, 0xD7);

pub const taskbar_bg = rgb(0x1F, 0x1F, 0x1F);
pub const taskbar_top_edge = rgb(0x1F, 0x1F, 0x1F);
pub const taskbar_bottom = rgb(0x1F, 0x1F, 0x1F);

pub const start_btn_bg = rgb(0x00, 0x78, 0xD7);
pub const start_btn_hover = rgb(0x42, 0x9C, 0xE3);
pub const start_btn_text = rgb(0xFF, 0xFF, 0xFF);
pub const start_label = "Start";

pub const titlebar_active = rgb(0x00, 0x78, 0xD7);
pub const titlebar_inactive = rgb(0xFF, 0xFF, 0xFF);
pub const titlebar_text = rgb(0xFF, 0xFF, 0xFF);
pub const titlebar_inactive_text = rgb(0xA0, 0xA0, 0xA0);

pub const window_bg = rgb(0xFF, 0xFF, 0xFF);
pub const window_border = rgb(0x00, 0x78, 0xD7);
pub const window_border_inactive = rgb(0xAA, 0xAA, 0xAA);

pub const btn_close_bg = rgb(0xE8, 0x11, 0x23);
pub const btn_close_hover = rgb(0xF1, 0x70, 0x7A);
pub const btn_minmax_bg = rgb(0x00, 0x78, 0xD7);
pub const btn_minmax_hover = rgb(0x42, 0x9C, 0xE3);

pub const tray_bg = rgb(0x1F, 0x1F, 0x1F);
pub const tray_border = rgb(0x33, 0x33, 0x33);
pub const clock_text = rgb(0xFF, 0xFF, 0xFF);

pub const icon_text = rgb(0xFF, 0xFF, 0xFF);
pub const icon_text_shadow = rgb(0x00, 0x00, 0x00);
pub const icon_selection = rgb(0x00, 0x78, 0xD7);

pub const menu_bg = rgb(0x1F, 0x1F, 0x1F);
pub const menu_text = rgb(0xFF, 0xFF, 0xFF);
pub const menu_hover_bg = rgb(0x33, 0x33, 0x33);
pub const menu_separator = rgb(0x44, 0x44, 0x44);

pub const search_box_bg = rgb(0xFF, 0xFF, 0xFF);
pub const search_box_border = rgb(0x00, 0x78, 0xD7);
pub const search_placeholder = rgb(0x99, 0x99, 0x99);

pub const shutdown_btn_bg = rgb(0xE8, 0x11, 0x23);
pub const shutdown_btn_text = rgb(0xFF, 0xFF, 0xFF);

pub const login_bg = rgb(0x00, 0x78, 0xD7);
pub const login_panel_bg = rgb(0x00, 0x63, 0xB1);

pub const button_face = rgb(0xCC, 0xCC, 0xCC);
pub const button_highlight = rgb(0xE0, 0xE0, 0xE0);
pub const button_shadow = rgb(0x99, 0x99, 0x99);
pub const selection_bg = rgb(0x00, 0x78, 0xD7);

// ── Metro Tile Colors ──

pub const tile_blue = rgb(0x00, 0x78, 0xD7);
pub const tile_green = rgb(0x10, 0x7C, 0x10);
pub const tile_orange = rgb(0xDA, 0x3B, 0x01);
pub const tile_purple = rgb(0x88, 0x17, 0x98);
pub const tile_red = rgb(0xE8, 0x11, 0x23);
pub const tile_teal = rgb(0x00, 0x99, 0xBC);
pub const tile_dark = rgb(0x2D, 0x2D, 0x2D);

// ── Compositor Defaults (Metro: no glass, no blur) ──

pub const CompositorDefaults = struct {
    pub const glass_enabled: bool = false;
    pub const glass_opacity: u8 = 255;
    pub const blur_radius: u8 = 0;
    pub const blur_passes: u8 = 0;
    pub const animation_enabled: bool = true;
    pub const shadow_enabled: bool = false;
    pub const shadow_size: u8 = 0;
    pub const shadow_layers: u8 = 0;
    pub const vsync: bool = true;
};

// ── Layout Constants ──

pub const Layout = struct {
    pub const taskbar_height: i32 = 30;
    pub const titlebar_height: i32 = 24;
    pub const start_btn_width: i32 = 48;
    pub const start_btn_height: i32 = 30;
    pub const icon_size: i32 = 48;
    pub const icon_grid_x: i32 = 80;
    pub const icon_grid_y: i32 = 90;
    pub const window_border_width: i32 = 1;
    pub const corner_radius: i32 = 0;
    pub const btn_size: i32 = 24;
    pub const tray_height: i32 = 22;
    pub const tray_clock_width: i32 = 72;
    pub const startscreen_tile_size: i32 = 120;
    pub const startscreen_tile_gap: i32 = 4;
    pub const startscreen_columns: i32 = 6;
};

// ── Compositor Helper Functions ──

pub fn isGlassEnabled() bool {
    return CompositorDefaults.glass_enabled;
}

pub fn getGlassAlpha() u8 {
    return 255;
}

pub fn getBlurRadius() i32 {
    return 0;
}

pub const ThemeColors = struct {
    desktop_background: u32,
    window_border_active: u32,
    window_border_inactive: u32,
    button_highlight: u32,
    button_shadow: u32,
    titlebar_active: u32,
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
        .titlebar_active = sc.accent,
        .titlebar_text = sc.titlebar_text,
    };
}
