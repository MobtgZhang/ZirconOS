//! Modern Start Screen
//! Full-screen tile grid (Windows 8 Metro style) instead of a traditional
//! start menu. Tiles are colored rectangles with icon and label, arranged
//! in a grid. Each tile has an accent color from the Metro palette.

const theme = @import("theme.zig");

pub const TileSize = enum(u8) {
    small = 0,
    medium = 1,
    wide = 2,
    large = 3,
};

pub const Tile = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    color: u32 = theme.tile_blue,
    size: TileSize = .medium,
    grid_col: i32 = 0,
    grid_row: i32 = 0,
};

const MAX_TILES: usize = 32;

var tiles: [MAX_TILES]Tile = [_]Tile{.{}} ** MAX_TILES;
var tile_count: usize = 0;

var visible: bool = false;
var search_text: [128]u8 = [_]u8{0} ** 128;
var search_len: usize = 0;

pub fn init() void {
    tile_count = 0;
    visible = false;
    search_len = 0;

    addDefaultTiles();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addTile(name: []const u8, icon_id: u16, color: u32, size: TileSize, col: i32, row: i32) void {
    if (tile_count >= MAX_TILES) return;
    var t = &tiles[tile_count];
    t.name_len = setStr(&t.name, name);
    t.icon_id = icon_id;
    t.color = color;
    t.size = size;
    t.grid_col = col;
    t.grid_row = row;
    tile_count += 1;
}

pub const identity = struct {
    pub const title = "Windows 8 Style - Modern";
    pub const search_placeholder = "Search";
    pub const header_sub = "ZirconOS - Metro Flat Design";
    pub const shutdown_label = "Power";
    pub const logoff_label = "Sign out";
    pub const user_name = "ZirconOS User";
    pub const version_tag = "Modern Metro v1.0";
};

fn addDefaultTiles() void {
    addTile("Desktop", 1, theme.tile_blue, .medium, 0, 0);
    addTile("Browser", 6, theme.tile_teal, .wide, 1, 0);
    addTile("Mail", 8, theme.tile_purple, .medium, 0, 1);
    addTile("Terminal", 4, theme.tile_dark, .medium, 1, 1);
    addTile("Settings", 7, theme.tile_dark, .medium, 2, 1);
    addTile("Documents", 2, theme.tile_orange, .medium, 0, 2);
    addTile("Photos", 10, theme.tile_green, .wide, 1, 2);
    addTile("Music", 11, theme.tile_red, .medium, 0, 3);
    addTile("Store", 9, theme.tile_green, .medium, 1, 3);
    addTile("Maps", 5, theme.tile_blue, .medium, 2, 3);
    addTile("Calendar", 12, theme.tile_purple, .medium, 3, 0);
    addTile("Weather", 13, theme.tile_teal, .medium, 3, 1);
}

pub fn toggle() void {
    visible = !visible;
    if (!visible) {
        search_len = 0;
    }
}

pub fn show() void {
    visible = true;
}

pub fn hide() void {
    visible = false;
    search_len = 0;
}

pub fn isVisible() bool {
    return visible;
}

pub fn contains(_: i32, _: i32, _: i32) bool {
    if (!visible) return false;
    return true;
}

pub fn getTiles() []const Tile {
    return tiles[0..tile_count];
}

pub fn getTileCount() usize {
    return tile_count;
}

pub fn getBackgroundColor() u32 {
    return theme.getActiveAccent();
}

pub fn getSearchBoxColor() u32 {
    return theme.search_box_bg;
}
