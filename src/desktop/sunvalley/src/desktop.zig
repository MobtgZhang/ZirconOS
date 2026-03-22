//! Sun Valley Desktop Manager
//! Manages wallpaper rendering, desktop icon grid with rounded selection,
//! right-click context menu with rounded flyout, and drag support.
//! Supports live wallpaper tinting for Mica material sampling.

const theme = @import("theme.zig");

pub const DesktopIcon = struct {
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: u8 = 0,
    grid_x: i32 = 0,
    grid_y: i32 = 0,
    icon_id: u16 = 0,
    selected: bool = false,
    visible: bool = false,
};

const MAX_ICONS: usize = 128;
var icons: [MAX_ICONS]DesktopIcon = [_]DesktopIcon{.{}} ** MAX_ICONS;
var icon_count: usize = 0;

var context_menu_visible: bool = false;
var context_menu_x: i32 = 0;
var context_menu_y: i32 = 0;

pub fn init() void {
    icon_count = 0;
    context_menu_visible = false;
    addDefaultIcons();
}

fn addDefaultIcons() void {
    addIcon("This PC", 0, 0, 1);
    addIcon("Documents", 0, 1, 2);
    addIcon("Recycle Bin", 0, 2, 3);
    addIcon("Terminal", 0, 3, 4);
    addIcon("Network", 0, 4, 5);
}

fn addIcon(name: []const u8, gx: i32, gy: i32, id: u16) void {
    if (icon_count >= MAX_ICONS) return;
    var ic = &icons[icon_count];
    const len = @min(name.len, 64);
    for (0..len) |i| {
        ic.name[i] = name[i];
    }
    ic.name_len = @intCast(len);
    ic.grid_x = gx;
    ic.grid_y = gy;
    ic.icon_id = id;
    ic.visible = true;
    icon_count += 1;
}

pub fn getIcons() []const DesktopIcon {
    return icons[0..icon_count];
}

pub fn selectIcon(index: usize) void {
    deselectAll();
    if (index < icon_count) {
        icons[index].selected = true;
    }
}

pub fn deselectAll() void {
    for (&icons) |*ic| {
        ic.selected = false;
    }
}

pub fn showContextMenu(x: i32, y: i32) void {
    context_menu_visible = true;
    context_menu_x = x;
    context_menu_y = y;
}

pub fn hideContextMenu() void {
    context_menu_visible = false;
}

pub fn isContextMenuVisible() bool {
    return context_menu_visible;
}

pub fn getContextMenuPos() struct { x: i32, y: i32 } {
    return .{ .x = context_menu_x, .y = context_menu_y };
}

pub fn getDesktopBackground(scheme: theme.ColorScheme) u32 {
    return theme.getScheme(scheme).desktop_bg;
}

pub fn iconHitTest(click_x: i32, click_y: i32) ?usize {
    const grid_x_step = theme.Layout.icon_grid_x;
    const grid_y_step = theme.Layout.icon_grid_y;
    const icon_sz = theme.Layout.icon_size;
    const margin_x: i32 = 16;
    const margin_y: i32 = 16;

    for (icons[0..icon_count], 0..) |ic, i| {
        if (!ic.visible) continue;
        const ix = margin_x + ic.grid_x * grid_x_step;
        const iy = margin_y + ic.grid_y * grid_y_step;
        if (click_x >= ix and click_x < ix + icon_sz and
            click_y >= iy and click_y < iy + icon_sz + 20)
        {
            return i;
        }
    }
    return null;
}

pub fn getContextMenuItems() [6][]const u8 {
    return .{
        "View",
        "Sort by",
        "Refresh",
        "Paste",
        "Display settings",
        "Personalize",
    };
}
