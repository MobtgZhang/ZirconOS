//! Resource Loader — ZirconOS Modern Desktop
//! Scans and catalogues graphical assets from the resources/ directory tree:
//!   resources/wallpapers/    — SVG wallpaper backgrounds per theme
//!   resources/icons/         — Monochrome flat system icons (SVG)
//!   resources/cursors/       — Flat cursor sprites (SVG)
//!
//! At init time, the loader registers known built-in resource entries
//! so the compositor and shell can reference them by path or ID.

pub const MAX_WALLPAPERS: usize = 16;
pub const MAX_ICONS: usize = 64;
pub const MAX_CURSORS: usize = 16;
pub const MAX_THEME_FILES: usize = 16;
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
    addWallpaper("resources/wallpapers/modern_default.svg", 1);
    addWallpaper("resources/wallpapers/modern_purple.svg", 2);
    addWallpaper("resources/wallpapers/modern_green.svg", 3);
    addWallpaper("resources/wallpapers/modern_orange.svg", 4);
    addWallpaper("resources/wallpapers/modern_red.svg", 5);
    addWallpaper("resources/wallpapers/modern_dark.svg", 6);
}

fn registerBuiltinIcons() void {
    addIcon("resources/icons/this_pc.svg", 1);
    addIcon("resources/icons/documents.svg", 2);
    addIcon("resources/icons/recycle_bin.svg", 3);
    addIcon("resources/icons/terminal.svg", 4);
    addIcon("resources/icons/network.svg", 5);
    addIcon("resources/icons/browser.svg", 6);
    addIcon("resources/icons/settings.svg", 7);
    addIcon("resources/icons/mail.svg", 8);
    addIcon("resources/icons/store.svg", 9);
    addIcon("resources/icons/photos.svg", 10);
    addIcon("resources/icons/music.svg", 11);
    addIcon("resources/icons/calendar.svg", 12);
    addIcon("resources/icons/weather.svg", 13);
}

fn registerBuiltinCursors() void {
    addCursor("resources/cursors/modern_arrow.svg", 1);
    addCursor("resources/cursors/modern_hand.svg", 2);
    addCursor("resources/cursors/modern_ibeam.svg", 3);
    addCursor("resources/cursors/modern_wait.svg", 4);
    addCursor("resources/cursors/modern_crosshair.svg", 5);
    addCursor("resources/cursors/modern_size_ns.svg", 6);
    addCursor("resources/cursors/modern_size_ew.svg", 7);
    addCursor("resources/cursors/modern_move.svg", 8);
}

fn registerBuiltinThemeFiles() void {
    addThemeFile("resources/themes/modern_blue.theme", 1);
    addThemeFile("resources/themes/modern_purple.theme", 2);
    addThemeFile("resources/themes/modern_green.theme", 3);
    addThemeFile("resources/themes/modern_orange.theme", 4);
    addThemeFile("resources/themes/modern_red.theme", 5);
    addThemeFile("resources/themes/modern_dark.theme", 6);
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

// ── Monochrome flat embedded 16x16 bitmap icons ──
// Metro style: single-color silhouettes on colored tile backgrounds.

pub const EmbeddedIcon = struct {
    id: u16,
    name: []const u8,
    svg_path: []const u8,
    palette: [4]u32,
    pixels: [16][16]u2,
};

pub const modern_icons = [_]EmbeddedIcon{
    .{
        .id = 1,
        .name = "this_pc",
        .svg_path = "resources/icons/this_pc.svg",
        .palette = .{ 0x000000, 0xFFFFFF, 0x0078D7, 0x666666 },
        .pixels = .{
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0 },
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
    .{
        .id = 3,
        .name = "recycle_bin",
        .svg_path = "resources/icons/recycle_bin.svg",
        .palette = .{ 0x000000, 0xFFFFFF, 0x0078D7, 0x666666 },
        .pixels = .{
            .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0 },
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0 },
            .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
};

pub fn getEmbeddedIcons() []const EmbeddedIcon {
    return &modern_icons;
}

pub fn findEmbeddedIconById(id: u16) ?*const EmbeddedIcon {
    for (&modern_icons) |*icon| {
        if (icon.id == id) return icon;
    }
    return null;
}

pub fn isInitialized() bool {
    return initialized;
}
