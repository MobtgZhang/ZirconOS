//! ZirconOS Fluent Theme Definition
//! Original design: acrylic translucency, depth layering, reveal highlights,
//! and motion-driven UI. Dual light/dark mode support.

pub fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

pub fn argb(a: u32, r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16) | (a << 24);
}

// ── Color Schemes ──

pub const ColorScheme = enum {
    light,
    dark,
};

pub const SchemeColors = struct {
    acrylic_tint: u32,
    acrylic_opacity: u8,
    acrylic_luminosity: u8,
    titlebar_bg: u32,
    titlebar_text: u32,
    titlebar_inactive_bg: u32,
    titlebar_inactive_text: u32,
    desktop_bg: u32,
    accent: u32,
    accent_light: u32,
    accent_dark: u32,
    text_primary: u32,
    text_secondary: u32,
    surface: u32,
    surface_variant: u32,
    divider: u32,
};

pub const scheme_dark = SchemeColors{
    .acrylic_tint = rgb(0x20, 0x20, 0x20),
    .acrylic_opacity = 200,
    .acrylic_luminosity = 60,
    .titlebar_bg = rgb(0x20, 0x20, 0x20),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_inactive_bg = rgb(0x2B, 0x2B, 0x2B),
    .titlebar_inactive_text = rgb(0x99, 0x99, 0x99),
    .desktop_bg = rgb(0x0A, 0x16, 0x28),
    .accent = rgb(0x00, 0x78, 0xD4),
    .accent_light = rgb(0x60, 0xCD, 0xFF),
    .accent_dark = rgb(0x00, 0x45, 0x78),
    .text_primary = rgb(0xFF, 0xFF, 0xFF),
    .text_secondary = rgb(0xAA, 0xAA, 0xAA),
    .surface = rgb(0x2D, 0x2D, 0x2D),
    .surface_variant = rgb(0x38, 0x38, 0x38),
    .divider = rgb(0x44, 0x44, 0x44),
};

pub const scheme_light = SchemeColors{
    .acrylic_tint = rgb(0xFC, 0xFC, 0xFC),
    .acrylic_opacity = 180,
    .acrylic_luminosity = 80,
    .titlebar_bg = rgb(0xF3, 0xF3, 0xF3),
    .titlebar_text = rgb(0x1A, 0x1A, 0x1A),
    .titlebar_inactive_bg = rgb(0xF0, 0xF0, 0xF0),
    .titlebar_inactive_text = rgb(0x80, 0x80, 0x80),
    .desktop_bg = rgb(0xE8, 0xF4, 0xFD),
    .accent = rgb(0x00, 0x78, 0xD4),
    .accent_light = rgb(0x42, 0x9C, 0xE3),
    .accent_dark = rgb(0x00, 0x5A, 0x9E),
    .text_primary = rgb(0x1A, 0x1A, 0x1A),
    .text_secondary = rgb(0x60, 0x60, 0x60),
    .surface = rgb(0xFF, 0xFF, 0xFF),
    .surface_variant = rgb(0xF5, 0xF5, 0xF5),
    .divider = rgb(0xE0, 0xE0, 0xE0),
};

pub fn getScheme(cs: ColorScheme) SchemeColors {
    return switch (cs) {
        .dark => scheme_dark,
        .light => scheme_light,
    };
}

// ── Taskbar Colors ──

pub const taskbar_dark_bg = rgb(0x1C, 0x1C, 0x1C);
pub const taskbar_dark_text = rgb(0xFF, 0xFF, 0xFF);
pub const taskbar_dark_hover = rgb(0x38, 0x38, 0x38);
pub const taskbar_dark_active = rgb(0x44, 0x44, 0x44);
pub const taskbar_dark_accent_strip = rgb(0x00, 0x78, 0xD4);

pub const taskbar_light_bg = rgb(0xF3, 0xF3, 0xF3);
pub const taskbar_light_text = rgb(0x1A, 0x1A, 0x1A);
pub const taskbar_light_hover = rgb(0xE0, 0xE0, 0xE0);
pub const taskbar_light_active = rgb(0xD0, 0xD0, 0xD0);
pub const taskbar_light_accent_strip = rgb(0x00, 0x78, 0xD4);

// ── Start Menu Colors ──

pub const start_dark_bg = rgb(0x20, 0x20, 0x20);
pub const start_dark_tile = rgb(0x30, 0x30, 0x30);
pub const start_dark_tile_hover = rgb(0x3E, 0x3E, 0x3E);
pub const start_dark_search_bg = rgb(0x2D, 0x2D, 0x2D);
pub const start_dark_search_border = rgb(0x44, 0x44, 0x44);
pub const start_dark_text = rgb(0xFF, 0xFF, 0xFF);

pub const start_light_bg = rgb(0xF2, 0xF2, 0xF2);
pub const start_light_tile = rgb(0xFF, 0xFF, 0xFF);
pub const start_light_tile_hover = rgb(0xE8, 0xE8, 0xE8);
pub const start_light_search_bg = rgb(0xFF, 0xFF, 0xFF);
pub const start_light_search_border = rgb(0xD0, 0xD0, 0xD0);
pub const start_light_text = rgb(0x1A, 0x1A, 0x1A);

// ── Window Controls ──

pub const btn_close_bg = rgb(0xC4, 0x2B, 0x1C);
pub const btn_close_hover = rgb(0xE8, 0x11, 0x23);
pub const btn_close_icon = rgb(0xFF, 0xFF, 0xFF);
pub const btn_chrome_hover_dark = rgb(0x3E, 0x3E, 0x3E);
pub const btn_chrome_hover_light = rgb(0xE5, 0xE5, 0xE5);

// ── Reveal Highlight ──

pub const reveal_border_opacity: u8 = 40;
pub const reveal_radius: u32 = 80;
pub const reveal_color_dark = rgb(0xFF, 0xFF, 0xFF);
pub const reveal_color_light = rgb(0x00, 0x00, 0x00);

// ── Action Center Colors ──

pub const action_dark_bg = rgb(0x24, 0x24, 0x24);
pub const action_dark_tile = rgb(0x30, 0x30, 0x30);
pub const action_dark_tile_active = rgb(0x00, 0x78, 0xD4);
pub const action_light_bg = rgb(0xF0, 0xF0, 0xF0);
pub const action_light_tile = rgb(0xFF, 0xFF, 0xFF);
pub const action_light_tile_active = rgb(0x00, 0x78, 0xD4);

// ── DWM / Composition Defaults ──

pub const DwmDefaults = struct {
    pub const composition_enabled: bool = true;
    pub const acrylic_enabled: bool = true;
    pub const acrylic_opacity: u8 = 200;
    pub const blur_radius: u8 = 20;
    pub const blur_passes: u8 = 4;
    pub const noise_opacity: u8 = 8;
    pub const luminosity_blend: u8 = 60;
    pub const shadow_enabled: bool = true;
    pub const shadow_size: u8 = 12;
    pub const shadow_layers: u8 = 5;
    pub const shadow_opacity: u8 = 30;
    pub const animation_enabled: bool = true;
    pub const animation_duration_ms: u16 = 200;
    pub const reveal_enabled: bool = true;
    pub const vsync: bool = true;
};

// ── Layout Constants ──

pub const Layout = struct {
    pub const taskbar_height: i32 = 48;
    pub const titlebar_height: i32 = 32;
    pub const start_btn_width: i32 = 48;
    pub const icon_size: i32 = 48;
    pub const icon_grid_x: i32 = 80;
    pub const icon_grid_y: i32 = 90;
    pub const window_border_width: i32 = 1;
    pub const corner_radius: i32 = 0;
    pub const btn_chrome_width: i32 = 46;
    pub const btn_chrome_height: i32 = 32;
    pub const tray_height: i32 = 28;
    pub const tray_clock_width: i32 = 80;
    pub const startmenu_width: i32 = 640;
    pub const startmenu_height: i32 = 560;
    pub const tile_small: i32 = 56;
    pub const tile_medium: i32 = 120;
    pub const tile_wide: i32 = 248;
    pub const tile_large: i32 = 248;
    pub const tile_gap: i32 = 4;
    pub const action_center_width: i32 = 360;
    pub const notification_width: i32 = 360;
    pub const search_bar_height: i32 = 36;
};
