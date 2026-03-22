//! Sun Valley Window Decorator
//! Draws window chrome with Mica titlebar, rounded corners,
//! caption buttons in pill-group layout, and snap layout assist.
//! Active windows show accent-colored focus ring; inactive use muted tint.

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");

pub const WindowState = enum {
    normal,
    maximized,
    minimized,
    snapped_left,
    snapped_right,
    snapped_quarter,
};

pub const CaptionButton = enum {
    none,
    minimize,
    maximize,
    close,
    snap_layout,
};

pub const WindowChrome = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 800,
    height: i32 = 600,
    title: [128]u8 = [_]u8{0} ** 128,
    title_len: u8 = 0,
    active: bool = true,
    state: WindowState = .normal,
    resizable: bool = true,
    has_mica: bool = true,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getTitlebarBg(self: *const WindowChrome) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.active) s.titlebar_bg else s.titlebar_inactive_bg;
    }

    pub fn getTitlebarText(self: *const WindowChrome) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.active) s.titlebar_text else s.titlebar_inactive_text;
    }

    pub fn getBorderColor(self: *const WindowChrome) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.active) s.accent else s.surface_stroke;
    }

    pub fn getCornerRadius(self: *const WindowChrome) i32 {
        return if (self.state == .maximized) 0 else theme.Layout.corner_radius;
    }
};

pub fn hitTestCaption(chrome: *const WindowChrome, click_x: i32, click_y: i32) CaptionButton {
    const tb_h = theme.Layout.titlebar_height;
    const btn_w = theme.Layout.btn_size;
    const btn_h = theme.Layout.btn_height;

    if (click_y < chrome.y or click_y >= chrome.y + tb_h) return .none;

    const close_x = chrome.x + chrome.width - btn_w;
    const max_x = close_x - btn_w;
    const min_x = max_x - btn_w;

    if (click_x >= close_x and click_x < close_x + btn_w and
        click_y >= chrome.y and click_y < chrome.y + btn_h)
    {
        return .close;
    }
    if (click_x >= max_x and click_x < max_x + btn_w and
        click_y >= chrome.y and click_y < chrome.y + btn_h)
    {
        return .maximize;
    }
    if (click_x >= min_x and click_x < min_x + btn_w and
        click_y >= chrome.y and click_y < chrome.y + btn_h)
    {
        return .minimize;
    }
    return .none;
}

pub fn renderTitlebarMica(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    chrome: *const WindowChrome,
) void {
    if (chrome.has_mica and chrome.active) {
        const s = theme.getScheme(chrome.color_scheme);
        dwm.renderMicaRegion(
            fb_addr,
            fb_width,
            fb_height,
            fb_pitch,
            fb_bpp,
            chrome.x,
            chrome.y,
            chrome.width,
            theme.Layout.titlebar_height,
            s.mica_tint,
            s.mica_opacity,
        );
    }
}

pub fn renderWindowShadow(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    chrome: *const WindowChrome,
) void {
    if (chrome.active and chrome.state == .normal) {
        dwm.renderDepthShadow(
            fb_addr,
            fb_width,
            fb_height,
            fb_pitch,
            fb_bpp,
            chrome.x,
            chrome.y,
            chrome.width,
            chrome.height,
        );
    }
}

pub fn renderRoundedFrame(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    chrome: *const WindowChrome,
    bg_color: u32,
) void {
    const r = chrome.getCornerRadius();
    if (r > 0) {
        dwm.clipRoundedCorners(
            fb_addr,
            fb_width,
            fb_height,
            fb_pitch,
            fb_bpp,
            chrome.x,
            chrome.y,
            chrome.width,
            chrome.height,
            r,
            bg_color,
        );
    }
}

pub fn getSnapLayoutZones() [6]dwm.SnapZone {
    return .{
        .left_half,
        .right_half,
        .top_left,
        .top_right,
        .bottom_left,
        .bottom_right,
    };
}
