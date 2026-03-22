//! Fluent Start Menu
//! Split-panel layout: left sidebar with user/power/all-apps,
//! pinned tile grid, and integrated search bar at the bottom.
//! Supports acrylic backdrop and live tile concept.

const theme = @import("theme.zig");

pub const TileSize = enum {
    small,
    medium,
    wide,
    large,
};

pub const StartTile = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    tile_size: TileSize = .medium,
    accent_color: u32 = 0,
    grid_col: u8 = 0,
    grid_row: u8 = 0,
    live_content: bool = false,
};

pub const MenuItem = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    is_separator: bool = false,
};

const MAX_TILES: usize = 64;
const MAX_MENU_ITEMS: usize = 32;

var tiles: [MAX_TILES]StartTile = [_]StartTile{.{}} ** MAX_TILES;
var tile_count: usize = 0;

var app_list: [MAX_MENU_ITEMS]MenuItem = [_]MenuItem{.{}} ** MAX_MENU_ITEMS;
var app_list_count: usize = 0;

var visible: bool = false;
var search_active: bool = false;
var search_text: [128]u8 = [_]u8{0} ** 128;
var search_len: usize = 0;
var color_scheme: theme.ColorScheme = .dark;

pub fn init(scheme: theme.ColorScheme) void {
    color_scheme = scheme;
    tile_count = 0;
    app_list_count = 0;
    visible = false;
    search_active = false;
    search_len = 0;

    addDefaultTiles();
    addDefaultAppList();
}

pub const identity = struct {
    pub const title = "Windows 10 - Fluent Design";
    pub const pinned_header = "Pinned";
    pub const all_apps = "All apps >";
    pub const live_tile_caption = "Microsoft Edge - Fluent";
    pub const header_sub = "ZirconOS - Acrylic + Reveal";
    pub const user_name = "ZirconOS User";
    pub const version_tag = "Fluent Design System v2.0";
};

fn addDefaultTiles() void {
    addTile("Edge", 6, .wide, theme.scheme_dark.accent, 0, 0);
    addTile("Mail", 11, .medium, theme.rgb(0x00, 0x67, 0xC0), 0, 1);
    addTile("Calendar", 12, .medium, theme.rgb(0x00, 0x78, 0xD4), 1, 1);
    addTile("Store", 10, .medium, theme.rgb(0x00, 0x7A, 0xD1), 0, 2);
    addTile("Files", 5, .medium, theme.rgb(0xCA, 0x8B, 0x02), 1, 0);
    addTile("Settings", 7, .medium, theme.rgb(0x44, 0x44, 0x44), 0, 3);
    addTile("Terminal", 4, .small, theme.rgb(0x0C, 0x0C, 0x0C), 1, 2);
    addTile("Photos", 10, .small, theme.rgb(0x88, 0x44, 0xCC), 1, 3);
}

fn addDefaultAppList() void {
    addAppItem("Calculator", 8);
    addAppItem("Edge Browser", 6);
    addAppItem("File Explorer", 5);
    addAppItem("Mail", 11);
    addAppItem("Network", 9);
    addAppItem("Settings", 7);
    addAppItem("Store", 10);
    addAppItem("Terminal", 4);
}

fn addTile(name: []const u8, icon_id: u16, size: TileSize, accent: u32, col: u8, row: u8) void {
    if (tile_count >= MAX_TILES) return;
    var t = &tiles[tile_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        t.name[i] = name[i];
    }
    t.name_len = @intCast(len);
    t.icon_id = icon_id;
    t.tile_size = size;
    t.accent_color = accent;
    t.grid_col = col;
    t.grid_row = row;
    tile_count += 1;
}

fn addAppItem(name: []const u8, icon_id: u16) void {
    if (app_list_count >= MAX_MENU_ITEMS) return;
    var item = &app_list[app_list_count];
    const len = @min(name.len, 32);
    for (0..len) |i| {
        item.name[i] = name[i];
    }
    item.name_len = @intCast(len);
    item.icon_id = icon_id;
    app_list_count += 1;
}

pub fn toggle() void {
    visible = !visible;
    if (!visible) {
        search_active = false;
        search_len = 0;
    }
}

pub fn show() void {
    visible = true;
}

pub fn hide() void {
    visible = false;
    search_active = false;
    search_len = 0;
}

pub fn isVisible() bool {
    return visible;
}

pub fn contains(screen_h: i32, x: i32, y: i32) bool {
    const menu_h = theme.Layout.startmenu_height;
    const menu_w = theme.Layout.startmenu_width;
    const taskbar_h = theme.Layout.taskbar_height;
    const menu_y = screen_h - taskbar_h - menu_h;

    return x >= 0 and x < menu_w and y >= menu_y and y < menu_y + menu_h;
}

pub fn getTiles() []const StartTile {
    return tiles[0..tile_count];
}

pub fn getAppList() []const MenuItem {
    return app_list[0..app_list_count];
}

pub fn getBackgroundColor() u32 {
    return switch (color_scheme) {
        .dark => theme.start_dark_bg,
        .light => theme.start_light_bg,
    };
}

pub fn getTileColor() u32 {
    return switch (color_scheme) {
        .dark => theme.start_dark_tile,
        .light => theme.start_light_tile,
    };
}

pub fn getTextColor() u32 {
    return switch (color_scheme) {
        .dark => theme.start_dark_text,
        .light => theme.start_light_text,
    };
}
