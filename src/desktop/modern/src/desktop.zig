//! Modern Desktop Manager
//! Manages wallpaper (solid accent color), desktop icon grid, and context menus.
//! Windows 8 Metro style: flat icons on a bold solid-color background.

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

var wallpaper_path: theme.WallpaperPath = .{};
var wallpaper_dirty: bool = true;

pub fn init() void {
    icon_count = 0;
    context_menu_visible = false;
    wallpaper_dirty = true;
    updateWallpaperPath();
    addDefaultIcons();
}

fn addDefaultIcons() void {
    addIcon("This PC", 0, 0, 1);
    addIcon("Documents", 0, 1, 2);
    addIcon("Network", 0, 2, 5);
    addIcon("Recycle Bin", 0, 3, 3);
    addIcon("Browser", 0, 4, 6);
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

pub fn getIconCount() usize {
    return icon_count;
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

pub fn getDesktopBackground() u32 {
    return theme.getActiveDesktopBg();
}

pub fn getDesktopBackgroundDefault() u32 {
    return theme.desktop_bg;
}

fn updateWallpaperPath() void {
    wallpaper_path = theme.getWallpaperForScheme(theme.getActiveScheme());
    wallpaper_dirty = true;
}

pub fn getWallpaperPath() []const u8 {
    return wallpaper_path.path[0..wallpaper_path.len];
}

pub fn isWallpaperDirty() bool {
    return wallpaper_dirty;
}

pub fn clearWallpaperDirty() void {
    wallpaper_dirty = false;
}

pub fn applyTheme(cs: theme.ColorScheme) void {
    theme.setActiveScheme(cs);
    updateWallpaperPath();
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
            click_y >= iy and click_y < iy + icon_sz + 16)
        {
            return i;
        }
    }
    return null;
}

pub fn removeIcon(index: usize) void {
    if (index >= icon_count) return;
    var i = index;
    while (i + 1 < icon_count) : (i += 1) {
        icons[i] = icons[i + 1];
    }
    icons[icon_count - 1] = .{};
    icon_count -= 1;
}

pub fn moveIcon(index: usize, new_gx: i32, new_gy: i32) void {
    if (index >= icon_count) return;
    icons[index].grid_x = new_gx;
    icons[index].grid_y = new_gy;
}
