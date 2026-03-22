//! Sun Valley Input Manager
//! Dispatches pointer and keyboard events to the appropriate desktop
//! component: centered taskbar, start menu, widget panel, quick settings,
//! window chrome, or desktop icon grid.
//! Implements hit testing following the Z-order priority:
//!   overlays (start menu / widgets / quick settings) → windows → desktop
//!
//! Shell components are independent processes per Win11 architecture (§3.1),
//! so input routing respects process boundaries.

const theme = @import("theme.zig");
const desktop_mod = @import("desktop.zig");
const taskbar_mod = @import("taskbar.zig");
const startmenu_mod = @import("startmenu.zig");
const widget_mod = @import("widget_panel.zig");
const quick_mod = @import("quick_settings.zig");
const cursor_mod = @import("cursor.zig");

pub const InputEvent = enum(u8) {
    mouse_move = 0,
    mouse_left_down = 1,
    mouse_left_up = 2,
    mouse_right_down = 3,
    mouse_right_up = 4,
    mouse_scroll = 5,
    key_down = 6,
    key_up = 7,
    touch_start = 8,
    touch_move = 9,
    touch_end = 10,
};

pub const HitTarget = enum(u8) {
    none = 0,
    desktop = 1,
    desktop_icon = 2,
    taskbar = 3,
    start_button = 4,
    start_menu = 5,
    widget_panel = 6,
    quick_settings = 7,
    window_titlebar = 8,
    window_chrome = 9,
    window_content = 10,
    context_menu = 11,
    search_bar = 12,
    tray_area = 13,
    snap_overlay = 14,
};

var screen_width: i32 = 0;
var screen_height: i32 = 0;
var initialized: bool = false;

pub fn init(w: i32, h: i32) void {
    screen_width = w;
    screen_height = h;
    initialized = true;
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn hitTest(x: i32, y: i32) HitTarget {
    if (!initialized) return .none;

    if (startmenu_mod.isVisible()) {
        if (startmenu_mod.contains(screen_width, screen_height, x, y)) return .start_menu;
    }

    if (widget_mod.isVisible()) {
        return .widget_panel;
    }

    if (quick_mod.isVisible()) {
        return .quick_settings;
    }

    if (desktop_mod.isContextMenuVisible()) {
        return .context_menu;
    }

    const tb_y = screen_height - taskbar_mod.getHeight();
    if (y >= tb_y) {
        if (taskbar_mod.isClickOnStartButton(x, y, screen_width, screen_height)) return .start_button;
        return .taskbar;
    }

    if (desktop_mod.iconHitTest(x, y)) |_| {
        return .desktop_icon;
    }

    return .desktop;
}

pub fn handleMouseClick(x: i32, y: i32) void {
    if (!initialized) return;

    cursor_mod.setPosition(x, y);
    const target = hitTest(x, y);

    switch (target) {
        .start_button => {
            if (widget_mod.isVisible()) widget_mod.hide();
            if (quick_mod.isVisible()) quick_mod.hide();
            startmenu_mod.toggle();
        },
        .start_menu => {},
        .widget_panel => {},
        .quick_settings => {},
        .taskbar => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
            if (widget_mod.isVisible()) widget_mod.hide();
            if (quick_mod.isVisible()) quick_mod.hide();
        },
        .desktop_icon => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
            if (widget_mod.isVisible()) widget_mod.hide();
            if (quick_mod.isVisible()) quick_mod.hide();
            if (desktop_mod.iconHitTest(x, y)) |idx| {
                desktop_mod.selectIcon(idx);
            }
        },
        .desktop => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
            if (widget_mod.isVisible()) widget_mod.hide();
            if (quick_mod.isVisible()) quick_mod.hide();
            desktop_mod.deselectAll();
            desktop_mod.hideContextMenu();
        },
        .context_menu => {},
        else => {},
    }
}

pub fn handleRightClick(x: i32, y: i32) void {
    if (!initialized) return;

    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        return;
    }
    if (widget_mod.isVisible()) {
        widget_mod.hide();
        return;
    }
    if (quick_mod.isVisible()) {
        quick_mod.hide();
        return;
    }

    const tb_y = screen_height - taskbar_mod.getHeight();
    if (y < tb_y) {
        desktop_mod.showContextMenu(x, y);
    }
}

pub fn handleMouseMove(x: i32, y: i32) void {
    cursor_mod.setPosition(x, y);
}
