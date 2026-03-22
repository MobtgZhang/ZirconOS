//! Fluent Input Manager
//! Dispatches pointer and keyboard events to the appropriate desktop
//! component: taskbar, start menu, action center, window chrome, or
//! desktop icon grid. Implements hit testing following the Z-order
//! priority: overlays → windows → desktop.

const theme = @import("theme.zig");
const desktop_mod = @import("desktop.zig");
const taskbar_mod = @import("taskbar.zig");
const startmenu_mod = @import("startmenu.zig");
const action_center_mod = @import("action_center.zig");
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
};

pub const HitTarget = enum(u8) {
    none = 0,
    desktop = 1,
    desktop_icon = 2,
    taskbar = 3,
    start_button = 4,
    start_menu = 5,
    action_center = 6,
    window_titlebar = 7,
    window_chrome = 8,
    window_content = 9,
    context_menu = 10,
    search_bar = 11,
    tray_area = 12,
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

/// Determine which desktop element is at the given screen coordinate.
pub fn hitTest(x: i32, y: i32) HitTarget {
    if (!initialized) return .none;

    if (startmenu_mod.isVisible()) {
        if (startmenu_mod.contains(screen_height, x, y)) return .start_menu;
    }

    if (action_center_mod.isVisible()) {
        return .action_center;
    }

    if (desktop_mod.isContextMenuVisible()) {
        return .context_menu;
    }

    const tb_y = screen_height - taskbar_mod.getHeight();
    if (y >= tb_y) {
        if (taskbar_mod.isClickOnStartButton(x, y, screen_height)) return .start_button;
        return .taskbar;
    }

    if (desktop_mod.iconHitTest(x, y)) |_| {
        return .desktop_icon;
    }

    return .desktop;
}

/// Process a mouse click event at the given position.
pub fn handleMouseClick(x: i32, y: i32) void {
    if (!initialized) return;

    cursor_mod.setPosition(x, y);
    const target = hitTest(x, y);

    switch (target) {
        .start_button => {
            if (action_center_mod.isVisible()) action_center_mod.hide();
            startmenu_mod.toggle();
        },
        .start_menu => {},
        .action_center => {},
        .taskbar => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
        },
        .desktop_icon => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
            if (action_center_mod.isVisible()) action_center_mod.hide();
            if (desktop_mod.iconHitTest(x, y)) |idx| {
                desktop_mod.selectIcon(idx);
            }
        },
        .desktop => {
            if (startmenu_mod.isVisible()) startmenu_mod.hide();
            if (action_center_mod.isVisible()) action_center_mod.hide();
            desktop_mod.deselectAll();
            desktop_mod.hideContextMenu();
        },
        .context_menu => {},
        else => {},
    }
}

/// Process a right-click event.
pub fn handleRightClick(x: i32, y: i32) void {
    if (!initialized) return;

    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        return;
    }
    if (action_center_mod.isVisible()) {
        action_center_mod.hide();
        return;
    }

    const tb_y = screen_height - taskbar_mod.getHeight();
    if (y < tb_y) {
        desktop_mod.showContextMenu(x, y);
    }
}

/// Process mouse movement.
pub fn handleMouseMove(x: i32, y: i32) void {
    cursor_mod.setPosition(x, y);
}
