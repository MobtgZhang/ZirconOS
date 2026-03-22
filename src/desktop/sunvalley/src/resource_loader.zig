//! Resource Loader — ZirconOS Sun Valley Desktop
//! Scans and catalogues graphical assets from the Sun Valley resource tree:
//!   ZirconOSSunValley/resources/   — Primary Sun Valley theme assets
//!
//! Resource categories:
//!   wallpapers/   — SVG wallpaper backgrounds (dark, light, bloom, glow, waves, etc.)
//!   icons/        — Application and system icons (SVG, WinUI 3 rounded style)
//!   cursors/      — Cursor sprites (SVG, slightly thicker strokes)
//!   themes/       — .theme configuration files (dark, light, contrast)
//!   sounds/       — Event sound schemes
//!
//! At init time, the loader registers known built-in resource entries
//! so the WinUI 3 Composition visual tree compositor can reference them.

const theme = @import("theme.zig");

pub const MAX_WALLPAPERS: usize = 32;
pub const MAX_ICONS: usize = 64;
pub const MAX_CURSORS: usize = 24;
pub const MAX_THEME_FILES: usize = 16;
pub const PATH_MAX: usize = 128;

pub const ResourceKind = enum {
    wallpaper,
    icon,
    cursor,
    theme_file,
    sound_scheme,
    start_button,
    logo,
};

pub const ResourceEntry = struct {
    path: [PATH_MAX]u8 = [_]u8{0} ** PATH_MAX,
    path_len: u8 = 0,
    loaded: bool = false,
    id: u16 = 0,
    kind: ResourceKind = .wallpaper,
    color_scheme: theme.ColorScheme = .dark,
};

var wallpapers: [MAX_WALLPAPERS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_WALLPAPERS;
var wallpaper_count: usize = 0;

var icons_arr: [MAX_ICONS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_ICONS;
var icon_count: usize = 0;

var cursors: [MAX_CURSORS]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_CURSORS;
var cursor_count: usize = 0;

var theme_files: [MAX_THEME_FILES]ResourceEntry = [_]ResourceEntry{.{}} ** MAX_THEME_FILES;
var theme_file_count: usize = 0;

var initialized: bool = false;

pub const SV_RES = "src/desktop/sunvalley/resources";

fn setPath(dest: *[PATH_MAX]u8, src: []const u8) u8 {
    const len = @min(src.len, PATH_MAX);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addWallpaper(path: []const u8, id: u16, scheme: theme.ColorScheme) void {
    if (wallpaper_count >= MAX_WALLPAPERS) return;
    var e = &wallpapers[wallpaper_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .wallpaper;
    e.color_scheme = scheme;
    e.loaded = true;
    wallpaper_count += 1;
}

fn addIcon(path: []const u8, id: u16) void {
    if (icon_count >= MAX_ICONS) return;
    var e = &icons_arr[icon_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .icon;
    e.loaded = true;
    icon_count += 1;
}

fn addCursor(path: []const u8, id: u16) void {
    if (cursor_count >= MAX_CURSORS) return;
    var e = &cursors[cursor_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .cursor;
    e.loaded = true;
    cursor_count += 1;
}

fn addThemeFile(path: []const u8, id: u16) void {
    if (theme_file_count >= MAX_THEME_FILES) return;
    var e = &theme_files[theme_file_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .theme_file;
    e.loaded = true;
    theme_file_count += 1;
}

pub fn init() void {
    if (initialized) return;

    wallpaper_count = 0;
    icon_count = 0;
    cursor_count = 0;
    theme_file_count = 0;

    registerWallpapers();
    registerIcons();
    registerCursors();
    registerThemeFiles();

    initialized = true;
}

fn registerWallpapers() void {
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_dark.svg", 1, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_light.svg", 2, .light);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_bloom.svg", 3, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_glow.svg", 4, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_waves.svg", 5, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_gradient.svg", 6, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_spectrum.svg", 7, .dark);
    addWallpaper(SV_RES ++ "/wallpapers/zircon_valley_abstract.svg", 8, .dark);
}

fn registerIcons() void {
    addIcon(SV_RES ++ "/icons/computer.svg", 1);
    addIcon(SV_RES ++ "/icons/documents.svg", 2);
    addIcon(SV_RES ++ "/icons/recycle_bin.svg", 3);
    addIcon(SV_RES ++ "/icons/terminal.svg", 4);
    addIcon(SV_RES ++ "/icons/file_manager.svg", 5);
    addIcon(SV_RES ++ "/icons/browser.svg", 6);
    addIcon(SV_RES ++ "/icons/settings.svg", 7);
    addIcon(SV_RES ++ "/icons/store.svg", 8);
    addIcon(SV_RES ++ "/icons/network.svg", 9);
    addIcon(SV_RES ++ "/icons/widgets.svg", 10);
    addIcon(SV_RES ++ "/icons/photos.svg", 11);
    addIcon(SV_RES ++ "/icons/camera.svg", 12);
    addIcon(SV_RES ++ "/icons/clock.svg", 13);
    addIcon(SV_RES ++ "/icons/chat.svg", 14);
}

fn registerCursors() void {
    addCursor(SV_RES ++ "/cursors/zircon_arrow.svg", 1);
    addCursor(SV_RES ++ "/cursors/zircon_text.svg", 2);
    addCursor(SV_RES ++ "/cursors/zircon_busy.svg", 3);
    addCursor(SV_RES ++ "/cursors/zircon_working.svg", 4);
    addCursor(SV_RES ++ "/cursors/zircon_link.svg", 5);
    addCursor(SV_RES ++ "/cursors/zircon_move.svg", 6);
    addCursor(SV_RES ++ "/cursors/zircon_ns.svg", 7);
    addCursor(SV_RES ++ "/cursors/zircon_ew.svg", 8);
    addCursor(SV_RES ++ "/cursors/zircon_nwse.svg", 9);
    addCursor(SV_RES ++ "/cursors/zircon_unavail.svg", 10);
}

fn registerThemeFiles() void {
    addThemeFile(SV_RES ++ "/themes/zircon-sunvalley-dark.theme", 1);
    addThemeFile(SV_RES ++ "/themes/zircon-sunvalley-light.theme", 2);
    addThemeFile(SV_RES ++ "/themes/zircon-sunvalley-contrast.theme", 3);
}

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

pub fn getIcons() []const ResourceEntry {
    return icons_arr[0..icon_count];
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

pub fn findWallpaperByScheme(scheme: theme.ColorScheme) ?*const ResourceEntry {
    for (wallpapers[0..wallpaper_count]) |*e| {
        if (e.color_scheme == scheme) return e;
    }
    return null;
}

pub fn findIconById(id: u16) ?*const ResourceEntry {
    for (icons_arr[0..icon_count]) |*e| {
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
// Sun Valley icons: rounded, filled shapes with WinUI 3 aesthetic.

pub const EmbeddedIcon = struct {
    id: u16,
    name: []const u8,
    svg_path: []const u8,
    palette: [16]u32,
    pixels: [16][16]u4,
};

pub const sv_icons = [_]EmbeddedIcon{
    .{
        .id = 1,
        .name = "computer",
        .svg_path = SV_RES ++ "/icons/computer.svg",
        .palette = .{
            0x000000, 0x1C1C1C, 0x4CB0E8, 0x60CDFF,
            0x0078D4, 0xFFFFFF, 0xF5F5F5, 0x888888,
            0x383838, 0x005FB8, 0x1A1A2E, 0xCCE4FF,
            0xFF6B6B, 0x6BCB77, 0xFFD93D, 0x2C2C2C,
        },
        .pixels = .{
            .{ 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 0 },
            .{ 0, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 5, 5, 5, 5, 5, 5, 5, 3, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 5, 6, 6, 6, 6, 6, 5, 3, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 5, 6, 6, 6, 6, 6, 5, 3, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 5, 6, 6, 6, 6, 6, 5, 3, 2, 8, 0, 0 },
            .{ 0, 8, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 8, 0, 0 },
            .{ 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        },
    },
};

pub fn getEmbeddedIcons() []const EmbeddedIcon {
    return &sv_icons;
}

pub fn findEmbeddedIconById(id: u16) ?*const EmbeddedIcon {
    for (&sv_icons) |*icon| {
        if (icon.id == id) return icon;
    }
    return null;
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn getTotalResourceCount() usize {
    return wallpaper_count + icon_count + cursor_count + theme_file_count;
}
