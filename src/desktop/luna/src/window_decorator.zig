//! Luna Window Decorator
//! Draws window chrome with gradient titlebar, rounded top corners,
//! and caption buttons (minimize, maximize/restore, close).
//! Active windows get vivid blue gradient; inactive windows use muted blue/grey.
//! Close button uses warm orange-red; minimize/maximize use blue gradient.

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

    pub fn getTitlebarLeftColor(self: *const WindowChrome) u32 {
        const sc = theme.getActiveColors();
        return if (self.active) sc.titlebar_left else sc.titlebar_inactive_left;
    }

    pub fn getTitlebarRightColor(self: *const WindowChrome) u32 {
        const sc = theme.getActiveColors();
        return if (self.active) sc.titlebar_right else sc.titlebar_inactive_right;
    }

    pub fn getTitlebarText(self: *const WindowChrome) u32 {
        return if (self.active) theme.titlebar_text else theme.titlebar_inactive_text;
    }

    pub fn getBorderColor(self: *const WindowChrome) u32 {
        return if (self.active) theme.window_border else theme.window_border_inactive;
    }
};

pub fn hitTestCaption(chrome: *const WindowChrome, click_x: i32, click_y: i32) CaptionButton {
    const tb_h = theme.Layout.titlebar_height;
    const btn_sz = theme.Layout.btn_size;

    if (click_y < chrome.y or click_y >= chrome.y + tb_h) return .none;

    const close_x = chrome.x + chrome.width - btn_sz - 4;
    const max_x = close_x - btn_sz - 2;
    const min_x = max_x - btn_sz - 2;

    if (click_x >= close_x and click_x < close_x + btn_sz and
        click_y >= chrome.y + 2 and click_y < chrome.y + 2 + btn_sz)
    {
        return .close;
    }
    if (click_x >= max_x and click_x < max_x + btn_sz and
        click_y >= chrome.y + 2 and click_y < chrome.y + 2 + btn_sz)
    {
        return .maximize;
    }
    if (click_x >= min_x and click_x < min_x + btn_sz and
        click_y >= chrome.y + 2 and click_y < chrome.y + 2 + btn_sz)
    {
        return .minimize;
    }
    return .none;
}

pub fn getCloseButtonTopColor() u32 {
    return theme.btn_close_top;
}

pub fn getCloseButtonBottomColor() u32 {
    return theme.btn_close_bottom;
}

pub fn getMinMaxButtonTopColor() u32 {
    return theme.btn_minmax_top;
}

pub fn getMinMaxButtonBottomColor() u32 {
    return theme.btn_minmax_bottom;
}
