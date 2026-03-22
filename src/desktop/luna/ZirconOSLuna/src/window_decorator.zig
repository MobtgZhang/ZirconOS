//! Window Decorator - ZirconOS Luna Window Chrome
//! Draws the Luna-style title bar, borders, control buttons
//! (minimize/maximize/close), and system menu.
//! Reference: ReactOS uxtheme/themes (dll/win32/uxtheme/)

const theme = @import("theme.zig");

pub const COLORREF = theme.COLORREF;

// ── Title Bar Button IDs ──

pub const TitleButton = enum(u8) {
    none = 0,
    close = 1,
    maximize = 2,
    minimize = 3,
    restore = 4,
    help = 5,
};

pub const TitleButtonState = enum(u8) {
    normal = 0,
    hover = 1,
    pressed = 2,
    disabled = 3,
};

pub const TitleButtonInfo = struct {
    button: TitleButton = .none,
    state: TitleButtonState = .normal,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = theme.TITLEBAR_BUTTON_SIZE,
    height: i32 = theme.TITLEBAR_BUTTON_SIZE,

    pub fn hitTest(self: *const TitleButtonInfo, mx: i32, my: i32) bool {
        return mx >= self.x and mx < self.x + self.width and
            my >= self.y and my < self.y + self.height;
    }
};

// ── Window State for Decoration ──

pub const MAX_TITLE_LEN: usize = 128;

pub const WindowChrome = struct {
    hwnd: u64 = 0,
    is_active: bool = false,
    is_maximized: bool = false,
    is_minimized: bool = false,
    has_minimize: bool = true,
    has_maximize: bool = true,
    has_close: bool = true,
    has_help: bool = false,
    has_system_menu: bool = true,
    has_icon: bool = true,

    title: [MAX_TITLE_LEN]u8 = [_]u8{0} ** MAX_TITLE_LEN,
    title_len: usize = 0,
    icon_id: u32 = 0,

    window_x: i32 = 0,
    window_y: i32 = 0,
    window_width: i32 = 0,
    window_height: i32 = 0,

    close_btn: TitleButtonInfo = .{ .button = .close },
    maximize_btn: TitleButtonInfo = .{ .button = .maximize },
    minimize_btn: TitleButtonInfo = .{ .button = .minimize },

    system_menu_visible: bool = false,

    pub fn getTitle(self: *const WindowChrome) []const u8 {
        return self.title[0..self.title_len];
    }

    pub fn setTitle(self: *WindowChrome, t: []const u8) void {
        const n = @min(t.len, MAX_TITLE_LEN);
        @memcpy(self.title[0..n], t[0..n]);
        self.title_len = n;
    }
};

// ── Decoration Metrics ──

pub const DecorationMetrics = struct {
    titlebar_height: i32,
    border_width: i32,
    button_size: i32,
    button_margin: i32,
    corner_radius: i32,
    icon_size: i32,
    icon_margin: i32,
    client_offset_x: i32,
    client_offset_y: i32,
};

pub fn getDecorationMetrics() DecorationMetrics {
    return .{
        .titlebar_height = theme.TITLEBAR_HEIGHT,
        .border_width = theme.WINDOW_BORDER_WIDTH,
        .button_size = theme.TITLEBAR_BUTTON_SIZE,
        .button_margin = theme.TITLEBAR_BUTTON_MARGIN,
        .corner_radius = theme.TITLEBAR_CORNER_RADIUS,
        .icon_size = theme.TITLEBAR_ICON_SIZE,
        .icon_margin = theme.TITLEBAR_ICON_MARGIN,
        .client_offset_x = theme.WINDOW_BORDER_WIDTH,
        .client_offset_y = theme.TITLEBAR_HEIGHT + theme.WINDOW_BORDER_WIDTH,
    };
}

// ── Frame Regions ──

pub const HitTestResult = enum(u8) {
    nowhere = 0,
    client = 1,
    caption = 2,
    close_button = 3,
    maximize_button = 4,
    minimize_button = 5,
    sysmenu = 6,
    left = 10,
    right = 11,
    top = 12,
    bottom = 13,
    top_left = 14,
    top_right = 15,
    bottom_left = 16,
    bottom_right = 17,
};

pub fn hitTestFrame(chrome: *const WindowChrome, mx: i32, my: i32) HitTestResult {
    const x = mx - chrome.window_x;
    const y = my - chrome.window_y;
    const w = chrome.window_width;
    const h = chrome.window_height;
    const border = theme.WINDOW_BORDER_WIDTH;
    const resize = theme.WINDOW_RESIZE_BORDER;
    const tb_h = theme.TITLEBAR_HEIGHT;

    if (x < 0 or y < 0 or x >= w or y >= h) return .nowhere;

    if (chrome.close_btn.hitTest(mx, my)) return .close_button;
    if (chrome.has_maximize and chrome.maximize_btn.hitTest(mx, my)) return .maximize_button;
    if (chrome.has_minimize and chrome.minimize_btn.hitTest(mx, my)) return .minimize_button;

    if (chrome.has_icon and x < border + theme.TITLEBAR_ICON_SIZE + theme.TITLEBAR_ICON_MARGIN and y < tb_h) {
        return .sysmenu;
    }

    if (!chrome.is_maximized) {
        if (y < resize and x < resize) return .top_left;
        if (y < resize and x >= w - resize) return .top_right;
        if (y >= h - resize and x < resize) return .bottom_left;
        if (y >= h - resize and x >= w - resize) return .bottom_right;
        if (x < resize) return .left;
        if (x >= w - resize) return .right;
        if (y < resize) return .top;
        if (y >= h - resize) return .bottom;
    }

    if (y < tb_h) return .caption;

    if (x >= border and x < w - border and y >= tb_h and y < h - border) {
        return .client;
    }

    return .nowhere;
}

// ── Title Bar Colors ──

pub fn getTitleBarColors(is_active: bool) struct {
    left: COLORREF,
    right: COLORREF,
    text: COLORREF,
} {
    const colors = theme.getColors();
    if (is_active) {
        return .{
            .left = colors.titlebar_active_left,
            .right = colors.titlebar_active_right,
            .text = colors.titlebar_text_active,
        };
    } else {
        return .{
            .left = colors.titlebar_inactive_left,
            .right = colors.titlebar_inactive_right,
            .text = colors.titlebar_text_inactive,
        };
    }
}

pub fn getCloseButtonColor(state: TitleButtonState) COLORREF {
    return switch (state) {
        .hover => theme.RGB(0xE8, 0x11, 0x23),
        .pressed => theme.RGB(0xF1, 0x70, 0x7A),
        .normal => theme.RGB(0xD1, 0x60, 0x50),
        .disabled => theme.RGB(0xC0, 0xC0, 0xC0),
    };
}

pub fn getMinMaxButtonColor(state: TitleButtonState, is_active: bool) COLORREF {
    const colors = theme.getColors();
    return switch (state) {
        .hover => theme.interpolateColor(
            if (is_active) colors.titlebar_active_right else colors.titlebar_inactive_right,
            theme.RGB(255, 255, 255),
            1,
            3,
        ),
        .pressed => theme.interpolateColor(
            if (is_active) colors.titlebar_active_left else colors.titlebar_inactive_left,
            theme.RGB(0, 0, 0),
            1,
            6,
        ),
        .normal => if (is_active) colors.titlebar_active_right else colors.titlebar_inactive_right,
        .disabled => theme.RGB(0xC0, 0xC0, 0xC0),
    };
}

pub fn getBorderColor(is_active: bool) COLORREF {
    const colors = theme.getColors();
    return if (is_active) colors.window_border else colors.titlebar_inactive_left;
}

// ── Button Layout ──

pub fn layoutButtons(chrome: *WindowChrome) void {
    const btn_size = theme.TITLEBAR_BUTTON_SIZE;
    const margin = theme.TITLEBAR_BUTTON_MARGIN;
    const right_edge = chrome.window_x + chrome.window_width;
    const btn_y = chrome.window_y + 5;

    chrome.close_btn.x = right_edge - btn_size - margin - 4;
    chrome.close_btn.y = btn_y;
    chrome.close_btn.width = btn_size;
    chrome.close_btn.height = btn_size;

    if (chrome.has_maximize) {
        chrome.maximize_btn.x = chrome.close_btn.x - btn_size - 2;
        chrome.maximize_btn.y = btn_y;
        chrome.maximize_btn.width = btn_size;
        chrome.maximize_btn.height = btn_size;
        chrome.maximize_btn.button = if (chrome.is_maximized) .restore else .maximize;
    }

    if (chrome.has_minimize) {
        const ref_x = if (chrome.has_maximize) chrome.maximize_btn.x else chrome.close_btn.x;
        chrome.minimize_btn.x = ref_x - btn_size - 2;
        chrome.minimize_btn.y = btn_y;
        chrome.minimize_btn.width = btn_size;
        chrome.minimize_btn.height = btn_size;
    }
}

// ── System Menu ──

pub const MAX_SYSMENU_ITEMS: usize = 8;

pub const SystemMenuItem = struct {
    label: [24]u8 = [_]u8{0} ** 24,
    label_len: usize = 0,
    command: TitleButton = .none,
    is_separator: bool = false,
    is_disabled: bool = false,
    is_default: bool = false,

    pub fn getLabel(self: *const SystemMenuItem) []const u8 {
        return self.label[0..self.label_len];
    }
};

pub fn getDefaultSystemMenu(chrome: *const WindowChrome) [MAX_SYSMENU_ITEMS]SystemMenuItem {
    var items: [MAX_SYSMENU_ITEMS]SystemMenuItem = [_]SystemMenuItem{.{}} ** MAX_SYSMENU_ITEMS;
    var idx: usize = 0;

    items[idx] = makeSysMenuItem("Restore", .restore, chrome.is_maximized, false);
    idx += 1;
    items[idx] = makeSysMenuItem("Move", .none, !chrome.is_maximized, false);
    idx += 1;
    items[idx] = makeSysMenuItem("Size", .none, !chrome.is_maximized, false);
    idx += 1;
    items[idx] = makeSysMenuItem("Minimize", .minimize, chrome.has_minimize, false);
    idx += 1;
    items[idx] = makeSysMenuItem("Maximize", .maximize, chrome.has_maximize and !chrome.is_maximized, false);
    idx += 1;
    items[idx] = .{ .is_separator = true };
    idx += 1;
    items[idx] = makeSysMenuItem("Close", .close, true, true);

    return items;
}

fn makeSysMenuItem(label: []const u8, cmd: TitleButton, enabled: bool, is_default: bool) SystemMenuItem {
    var item: SystemMenuItem = .{};
    item.command = cmd;
    item.is_disabled = !enabled;
    item.is_default = is_default;
    const n = @min(label.len, item.label.len);
    @memcpy(item.label[0..n], label[0..n]);
    item.label_len = n;
    return item;
}

// ── Initialization ──

pub fn init() void {
    _ = &getDecorationMetrics;
}
