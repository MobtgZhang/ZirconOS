//! ZirconOS Sun Valley Theme Definition
//! Original design: Mica translucency, rounded geometry, centered layout,
//! snap regions, and layered depth system. Dual light/dark mode with
//! ZirconOS crystal-blue accent palette.

pub fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

pub fn argb(a: u32, r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16) | (a << 24);
}

pub const ColorScheme = enum {
    light,
    dark,
};

pub const SchemeColors = struct {
    mica_tint: u32,
    mica_opacity: u8,
    mica_luminosity: u8,
    acrylic_tint: u32,
    acrylic_opacity: u8,
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
    text_disabled: u32,
    surface: u32,
    surface_variant: u32,
    surface_stroke: u32,
    card_bg: u32,
    card_stroke: u32,
    divider: u32,
    layer_bg: u32,
    layer_on_mica: u32,
    smoke_bg: u32,
    flyout_bg: u32,
    flyout_stroke: u32,
};

pub const scheme_dark = SchemeColors{
    .mica_tint = rgb(0x1C, 0x1C, 0x1C),
    .mica_opacity = 210,
    .mica_luminosity = 50,
    .acrylic_tint = rgb(0x2C, 0x2C, 0x2C),
    .acrylic_opacity = 190,
    .titlebar_bg = rgb(0x1F, 0x1F, 0x1F),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_inactive_bg = rgb(0x2B, 0x2B, 0x2B),
    .titlebar_inactive_text = rgb(0x78, 0x78, 0x78),
    .desktop_bg = rgb(0x08, 0x12, 0x22),
    .accent = rgb(0x4C, 0xB0, 0xE8),
    .accent_light = rgb(0x78, 0xCC, 0xF0),
    .accent_dark = rgb(0x28, 0x80, 0xC0),
    .text_primary = rgb(0xFF, 0xFF, 0xFF),
    .text_secondary = rgb(0xBB, 0xBB, 0xBB),
    .text_disabled = rgb(0x5C, 0x5C, 0x5C),
    .surface = rgb(0x2D, 0x2D, 0x2D),
    .surface_variant = rgb(0x38, 0x38, 0x38),
    .surface_stroke = rgb(0x44, 0x44, 0x44),
    .card_bg = rgb(0x30, 0x30, 0x30),
    .card_stroke = rgb(0x48, 0x48, 0x48),
    .divider = rgb(0x40, 0x40, 0x40),
    .layer_bg = rgb(0x26, 0x26, 0x26),
    .layer_on_mica = rgb(0x3A, 0x3A, 0x3A),
    .smoke_bg = rgb(0x0A, 0x0A, 0x0A),
    .flyout_bg = rgb(0x2C, 0x2C, 0x2C),
    .flyout_stroke = rgb(0x4A, 0x4A, 0x4A),
};

pub const scheme_light = SchemeColors{
    .mica_tint = rgb(0xF3, 0xF3, 0xF3),
    .mica_opacity = 180,
    .mica_luminosity = 85,
    .acrylic_tint = rgb(0xFC, 0xFC, 0xFC),
    .acrylic_opacity = 160,
    .titlebar_bg = rgb(0xF8, 0xF8, 0xF8),
    .titlebar_text = rgb(0x1A, 0x1A, 0x1A),
    .titlebar_inactive_bg = rgb(0xF0, 0xF0, 0xF0),
    .titlebar_inactive_text = rgb(0x90, 0x90, 0x90),
    .desktop_bg = rgb(0xD4, 0xEA, 0xF8),
    .accent = rgb(0x3A, 0x96, 0xD0),
    .accent_light = rgb(0x5C, 0xB4, 0xE8),
    .accent_dark = rgb(0x1E, 0x6C, 0xA8),
    .text_primary = rgb(0x1A, 0x1A, 0x1A),
    .text_secondary = rgb(0x60, 0x60, 0x60),
    .text_disabled = rgb(0xA0, 0xA0, 0xA0),
    .surface = rgb(0xFF, 0xFF, 0xFF),
    .surface_variant = rgb(0xF5, 0xF5, 0xF5),
    .surface_stroke = rgb(0xE5, 0xE5, 0xE5),
    .card_bg = rgb(0xFF, 0xFF, 0xFF),
    .card_stroke = rgb(0xE8, 0xE8, 0xE8),
    .divider = rgb(0xE0, 0xE0, 0xE0),
    .layer_bg = rgb(0xF9, 0xF9, 0xF9),
    .layer_on_mica = rgb(0xFF, 0xFF, 0xFF),
    .smoke_bg = rgb(0xF0, 0xF0, 0xF0),
    .flyout_bg = rgb(0xFC, 0xFC, 0xFC),
    .flyout_stroke = rgb(0xE4, 0xE4, 0xE4),
};

pub fn getScheme(cs: ColorScheme) SchemeColors {
    return switch (cs) {
        .dark => scheme_dark,
        .light => scheme_light,
    };
}

// ── Taskbar ──

pub const taskbar_dark_bg = rgb(0x1C, 0x1C, 0x1C);
pub const taskbar_light_bg = rgb(0xF0, 0xF0, 0xF0);
pub const taskbar_pill_active = rgb(0x4C, 0xB0, 0xE8);
pub const taskbar_pill_inactive = rgb(0x60, 0x60, 0x60);
pub const taskbar_icon_color = rgb(0xFF, 0xFF, 0xFF);
pub const taskbar_search_bg = rgb(0x38, 0x38, 0x38);
pub const taskbar_search_text = rgb(0xAA, 0xAA, 0xAA);
pub const taskbar_separator = rgb(0x44, 0x44, 0x44);
pub const taskbar_tray_text = rgb(0xDD, 0xDD, 0xDD);

// ── Start Menu ──

pub const start_dark_bg = rgb(0x2C, 0x2C, 0x2C);
pub const start_light_bg = rgb(0xF8, 0xF8, 0xF8);
pub const start_search_bg_dark = rgb(0x38, 0x38, 0x38);
pub const start_search_bg_light = rgb(0xF0, 0xF0, 0xF0);
pub const start_pin_hover_dark = rgb(0x3E, 0x3E, 0x3E);
pub const start_pin_hover_light = rgb(0xEA, 0xEA, 0xEA);
pub const start_recommended_label = rgb(0x99, 0x99, 0x99);
pub const start_separator = rgb(0x44, 0x44, 0x44);

// ── Window Controls ──

pub const btn_close_rest = rgb(0xC4, 0x2B, 0x1C);
pub const btn_close_hover = rgb(0xE0, 0x40, 0x30);
pub const btn_close_pressed = rgb(0xA0, 0x20, 0x15);
pub const btn_close_text = rgb(0xFF, 0xFF, 0xFF);
pub const btn_chrome_hover_dark = rgb(0x3A, 0x3A, 0x3A);
pub const btn_chrome_hover_light = rgb(0xE8, 0xE8, 0xE8);
pub const btn_chrome_pressed_dark = rgb(0x30, 0x30, 0x30);
pub const btn_chrome_pressed_light = rgb(0xDA, 0xDA, 0xDA);

// ── Snap Layout Overlay ──

pub const snap_overlay_bg = rgb(0xF0, 0xF0, 0xF0);
pub const snap_overlay_border = rgb(0xD0, 0xD0, 0xD0);
pub const snap_zone_hover = rgb(0x4C, 0xB0, 0xE8);
pub const snap_zone_rest = rgb(0xE5, 0xE5, 0xE5);

// ── Widget Panel ──

pub const widget_bg_dark = rgb(0x24, 0x24, 0x24);
pub const widget_bg_light = rgb(0xFB, 0xFB, 0xFB);
pub const widget_card_dark = rgb(0x32, 0x32, 0x32);
pub const widget_card_light = rgb(0xFF, 0xFF, 0xFF);
pub const widget_card_stroke_dark = rgb(0x48, 0x48, 0x48);
pub const widget_card_stroke_light = rgb(0xE5, 0xE5, 0xE5);

// ── Quick Settings ──

pub const quick_settings_bg = rgb(0x2C, 0x2C, 0x2C);
pub const quick_toggle_on = rgb(0x4C, 0xB0, 0xE8);
pub const quick_toggle_off = rgb(0x44, 0x44, 0x44);
pub const quick_slider_track = rgb(0x50, 0x50, 0x50);
pub const quick_slider_fill = rgb(0x4C, 0xB0, 0xE8);

// ── Login Screen ──

pub const login_bg = rgb(0x08, 0x12, 0x22);
pub const login_panel_bg = rgb(0x20, 0x20, 0x20);
pub const login_panel_stroke = rgb(0x40, 0x40, 0x40);
pub const login_input_bg = rgb(0x2C, 0x2C, 0x2C);
pub const login_input_stroke = rgb(0x50, 0x50, 0x50);
pub const login_input_focus = rgb(0x4C, 0xB0, 0xE8);
pub const login_btn_bg = rgb(0x4C, 0xB0, 0xE8);
pub const login_btn_text = rgb(0xFF, 0xFF, 0xFF);

// ── DWM / Mica Compositor Defaults ──

pub const DwmDefaults = struct {
    pub const mica_enabled: bool = true;
    pub const mica_opacity: u8 = 210;
    pub const mica_blur_radius: u8 = 20;
    pub const mica_blur_passes: u8 = 4;
    pub const mica_luminosity: u8 = 50;
    pub const mica_tint_color: u32 = rgb(0x1C, 0x1C, 0x1C);
    pub const mica_tint_opacity: u8 = 70;
    pub const acrylic_enabled: bool = true;
    pub const acrylic_blur_radius: u8 = 16;
    pub const acrylic_blur_passes: u8 = 3;
    pub const acrylic_noise_opacity: u8 = 4;
    pub const animation_enabled: bool = true;
    pub const round_corners: bool = true;
    pub const corner_radius: u8 = 8;
    pub const shadow_enabled: bool = true;
    pub const shadow_size: u8 = 12;
    pub const shadow_layers: u8 = 5;
    pub const shadow_spread: u8 = 4;
    pub const vsync: bool = true;
    pub const snap_assist: bool = true;
};

// ── Layout Constants ──

pub const Layout = struct {
    pub const taskbar_height: i32 = 48;
    pub const taskbar_centered: bool = true;
    pub const taskbar_icon_size: i32 = 24;
    pub const taskbar_icon_spacing: i32 = 12;
    pub const taskbar_pill_height: i32 = 3;
    pub const titlebar_height: i32 = 32;
    pub const start_btn_width: i32 = 48;
    pub const icon_size: i32 = 48;
    pub const icon_grid_x: i32 = 80;
    pub const icon_grid_y: i32 = 90;
    pub const window_border_width: i32 = 1;
    pub const corner_radius: i32 = 8;
    pub const snap_zone_gap: i32 = 8;
    pub const btn_size: i32 = 46;
    pub const btn_height: i32 = 32;
    pub const tray_height: i32 = 32;
    pub const tray_clock_width: i32 = 88;
    pub const startmenu_width: i32 = 640;
    pub const startmenu_height: i32 = 720;
    pub const startmenu_corner_radius: i32 = 8;
    pub const search_height: i32 = 36;
    pub const widget_panel_width: i32 = 360;
    pub const quick_settings_width: i32 = 340;
    pub const quick_settings_height: i32 = 360;
};
