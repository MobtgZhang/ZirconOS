//! Resource Loader — ZirconOS Luna Desktop
//! Scans and catalogues graphical assets from the resources/ directory tree:
//!   resources/wallpapers/    — SVG wallpaper backgrounds per theme
//!   resources/icons/         — Application and system icons (SVG)
//!   resources/cursors/       — Cursor sprites (SVG)
//!
//! At init time, the loader registers known built-in resource entries
//! so the compositor and shell can reference them by path or ID.

pub const MAX_WALLPAPERS: usize = 16;
pub const MAX_ICONS: usize = 64;
pub const MAX_CURSORS: usize = 16;
pub const MAX_THEME_FILES: usize = 8;
pub const PATH_MAX: usize = 128;

pub const ResourceEntry = struct {
    path: [PATH_MAX]u8 = [_]u8{0} ** PATH_MAX,
    path_len: u8 = 0,
    loaded: bool = false,
    id: u16 = 0,
};

var wallpapers: [MAX_WALLPAPERS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_WALLPAPERS;
var wallpaper_count: usize = 0;

var icons: [MAX_ICONS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_ICONS;
var icon_count: usize = 0;

var cursors: [MAX_CURSORS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_CURSORS;
var cursor_count: usize = 0;

var theme_files: [MAX_THEME_FILES]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_THEME_FILES;
var theme_file_count: usize = 0;

var initialized: bool = false;

fn setPath(dest: *[PATH_MAX]u8, src: []const u8) u8 {
    const len = @min(src.len, PATH_MAX);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addWallpaper(path: []const u8, id: u16) void {
    if (wallpaper_count >= MAX_WALLPAPERS) return;
    var e = &wallpapers[wallpaper_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.loaded = true;
    wallpaper_count += 1;
}

fn addIcon(path: []const u8, id: u16) void {
    if (icon_count >= MAX_ICONS) return;
    var e = &icons[icon_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.loaded = true;
    icon_count += 1;
}

fn addCursor(path: []const u8, id: u16) void {
    if (cursor_count >= MAX_CURSORS) return;
    var e = &cursors[cursor_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.loaded = true;
    cursor_count += 1;
}

fn addThemeFile(path: []const u8, id: u16) void {
    if (theme_file_count >= MAX_THEME_FILES) return;
    var e = &theme_files[theme_file_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.loaded = true;
    theme_file_count += 1;
}

pub fn init() void {
    if (initialized) return;

    wallpaper_count = 0;
    icon_count = 0;
    cursor_count = 0;
    theme_file_count = 0;

    registerBuiltinWallpapers();
    registerBuiltinIcons();
    registerBuiltinCursors();
    registerBuiltinThemeFiles();

    initialized = true;
}

fn registerBuiltinWallpapers() void {
    addWallpaper("resources/wallpapers/bliss.svg", 1);
    addWallpaper("resources/wallpapers/bliss_olive.svg", 2);
    addWallpaper("resources/wallpapers/bliss_silver.svg", 3);
}

fn registerBuiltinIcons() void {
    addIcon("resources/icons/my_computer.svg", 1);
    addIcon("resources/icons/my_documents.svg", 2);
    addIcon("resources/icons/my_network_places.svg", 3);
    addIcon("resources/icons/recycle_bin.svg", 4);
    addIcon("resources/icons/internet_explorer.svg", 5);
    addIcon("resources/icons/control_panel.svg", 6);
    addIcon("resources/icons/printers.svg", 7);
    addIcon("resources/icons/terminal.svg", 8);
    addIcon("resources/icons/notepad.svg", 9);
    addIcon("resources/icons/calculator.svg", 10);
    addIcon("resources/icons/outlook_express.svg", 11);
    addIcon("resources/icons/paint.svg", 12);
    addIcon("resources/icons/media_player.svg", 13);
    addIcon("resources/icons/help.svg", 14);
    addIcon("resources/icons/search.svg", 15);
    addIcon("resources/icons/run.svg", 16);
}

fn registerBuiltinCursors() void {
    addCursor("resources/cursors/luna_arrow.svg", 1);
    addCursor("resources/cursors/luna_hand.svg", 2);
    addCursor("resources/cursors/luna_ibeam.svg", 3);
    addCursor("resources/cursors/luna_wait.svg", 4);
    addCursor("resources/cursors/luna_crosshair.svg", 5);
    addCursor("resources/cursors/luna_size_ns.svg", 6);
    addCursor("resources/cursors/luna_size_ew.svg", 7);
    addCursor("resources/cursors/luna_move.svg", 8);
}

fn registerBuiltinThemeFiles() void {
    addThemeFile("resources/themes/luna_blue.theme", 1);
    addThemeFile("resources/themes/luna_olive.theme", 2);
    addThemeFile("resources/themes/luna_silver.theme", 3);
}

// ── Public query API ──

pub fn getWallpaperCount() usize {
    return wallpaper_count;
}

pub fn getIconCount() usize {
    return icon_count;
}

pub fn getCursorCount() usize {
    return cursor_count;
}

pub fn getThemeFileCount() usize {
    return theme_file_count;
}

pub fn getWallpapers() []const ResourceEntry {
    return wallpapers[0..wallpaper_count];
}

pub fn getLoadedIcons() []const ResourceEntry {
    return icons[0..icon_count];
}

pub fn getCursors() []const ResourceEntry {
    return cursors[0..cursor_count];
}

pub fn getThemeFiles() []const ResourceEntry {
    return theme_files[0..theme_file_count];
}

pub fn findWallpaperById(id: u16) ?*const ResourceEntry {
    for (wallpapers[0..wallpaper_count]) |*e| {
        if (e.id == id) return e;
    }
    return null;
}

pub fn findIconById(id: u16) ?*const ResourceEntry {
    for (icons[0..icon_count]) |*e| {
        if (e.id == id) return e;
    }
    return null;
}

pub fn findCursorById(id: u16) ?*const ResourceEntry {
    for (cursors[0..cursor_count]) |*e| {
        if (e.id == id) return e;
    }
    return null;
}

// ── ICO-compatible embedded 16x16 bitmap fallback icons ──

pub const EmbeddedIcon = struct {
    id: u16,
    name: []const u8,
    svg_path: []const u8,
    palette: [16]u32,
    pixels: [16][16]u4,
};

pub const luna_icons = [_]EmbeddedIcon{
    .{
        .id = 1,
        .name = "my_computer",
        .svg_path = "resources/icons/my_computer.svg",
        .palette = .{
            0x000000, 0x004E98, 0x0054E3, 0x3A81E5,
            0x598DED, 0xFFFFFF, 0xC0C0C0, 0x808080,
            0x404040, 0xFF8C00, 0xFFD700, 0x3C8D2E,
            0xFF4040, 0x40C040, 0xECE9D8, 0xF0F0F0,
        },
        .pixels = .{
            .{ 0, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0 },
            .{ 0, 0, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 0, 0, 0 },
            .{ 0, 2, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 2, 0, 0 },
            .{ 0, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 0, 0 },
            .{ 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 6, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0 },
            .{ 0, 0, 14, 7, 7, 7, 7, 7, 7, 7, 7, 7, 14, 0, 0, 0 },
            .{ 0, 0, 0, 14, 14, 14, 14, 14, 14, 14, 14, 14, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    .{
        .id = 4,
        .name = "recycle_bin",
        .svg_path = "resources/icons/recycle_bin.svg",
        .palette = .{
            0x000000, 0x004E98, 0x0054E3, 0x3A81E5,
            0x598DED, 0xFFFFFF, 0xC0C0C0, 0x808080,
            0x404040, 0xFF8C00, 0xFFD700, 0x3C8D2E,
            0xFF4040, 0x40C040, 0xECE9D8, 0xF0F0F0,
        },
        .pixels = .{
            .{ 0, 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 7, 6, 6, 6, 6, 6, 6, 6, 7, 0, 0, 0, 0 },
            .{ 0, 0, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 7, 0, 0, 0 },
            .{ 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0 },
            .{ 0, 0, 7, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 0, 0, 0 },
            .{ 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 8, 8, 8, 8, 8, 8, 8, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
};

pub fn getEmbeddedIcons() []const EmbeddedIcon {
    return &luna_icons;
}

pub fn findEmbeddedIconById(id: u16) ?*const EmbeddedIcon {
    for (&luna_icons) |*icon| {
        if (icon.id == id) return icon;
    }
    return null;
}

pub fn isInitialized() bool {
    return initialized;
}
