//! Modern Window Decorator
//! Draws window chrome with flat solid-color titlebar, sharp borders,
//! and caption buttons (minimize, maximize/restore, close).
//! Metro style: no glass, no gradients, no rounded corners.
//! Active windows get accent-color titlebar; inactive windows get white.

const theme = @import("theme.zig");

pub const WindowState = enum {
    normal,
    maximized,
    minimized,
};

pub const CaptionButton = enum {
    none,
    minimize,
    maximize,
    close,
};

pub const WindowChrome = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 640,
    height: i32 = 480,
    title: [128]u8 = [_]u8{0} ** 128,
    title_len: u8 = 0,
    active: bool = true,
    state: WindowState = .normal,
    resizable: bool = true,

    pub fn getTitlebarColor(self: *const WindowChrome) u32 {
        return if (self.active) theme.titlebar_active else theme.titlebar_inactive;
    }

    pub fn getTitlebarText(self: *const WindowChrome) u32 {
        return if (self.active) theme.titlebar_text else theme.titlebar_inactive_text;
    }

    pub fn getBorderColor(self: *const WindowChrome) u32 {
        return if (self.active) theme.window_border else theme.window_border_inactive;
    }

    pub fn getCloseButtonColor(self: *const WindowChrome) u32 {
        _ = self;
        return theme.btn_close_bg;
    }

    pub fn getMinMaxButtonColor(self: *const WindowChrome) u32 {
        return if (self.active) theme.btn_minmax_bg else theme.window_border_inactive;
    }
};

pub fn hitTestCaption(chrome: *const WindowChrome, click_x: i32, click_y: i32) CaptionButton {
    const tb_h = theme.Layout.titlebar_height;
    const btn_sz = theme.Layout.btn_size;

    if (click_y < chrome.y or click_y >= chrome.y + tb_h) return .none;

    const close_x = chrome.x + chrome.width - btn_sz;
    const max_x = close_x - btn_sz;
    const min_x = max_x - btn_sz;

    if (click_x >= close_x and click_x < close_x + btn_sz and
        click_y >= chrome.y and click_y < chrome.y + btn_sz)
    {
        return .close;
    }
    if (click_x >= max_x and click_x < max_x + btn_sz and
        click_y >= chrome.y and click_y < chrome.y + btn_sz)
    {
        return .maximize;
    }
    if (click_x >= min_x and click_x < min_x + btn_sz and
        click_y >= chrome.y and click_y < chrome.y + btn_sz)
    {
        return .minimize;
    }
    return .none;
}

pub fn renderTitlebar(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    chrome: *const WindowChrome,
) void {
    _ = fb_addr;
    _ = fb_width;
    _ = fb_height;
    _ = fb_pitch;
    _ = fb_bpp;
    _ = chrome;
}

pub fn renderWindowBorder(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    chrome: *const WindowChrome,
) void {
    _ = fb_addr;
    _ = fb_width;
    _ = fb_height;
    _ = fb_pitch;
    _ = fb_bpp;
    _ = chrome;
}
