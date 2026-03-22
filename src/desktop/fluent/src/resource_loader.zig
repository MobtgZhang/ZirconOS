//! Resource Loader — ZirconOS Fluent Desktop
//! Scans and catalogues graphical assets from both Fluent and Aero resource trees:
//!   ZirconOSFluent/resources/   — Primary Fluent theme assets
//!   ZirconOSAero/resources/     — Fallback/supplementary graphical resources
//!
//! Resource categories:
//!   wallpapers/   — SVG wallpaper backgrounds (dark and light)
//!   icons/        — Application and system icons (SVG)
//!   cursors/      — Cursor sprites (SVG)
//!   themes/       — .theme configuration files
//!   sounds/       — Event sound schemes
//!
//! At init time, the loader registers known built-in resource entries
//! so the DirectComposition visual tree compositor can reference them.

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

pub const ResourceSource = enum(u8) {
    fluent = 0,
    aero = 1,
};

pub const ResourceEntry = struct {
    path: [PATH_MAX]u8 = [_]u8{0} ** PATH_MAX,
    path_len: u8 = 0,
    loaded: bool = false,
    id: u16 = 0,
    kind: ResourceKind = .wallpaper,
    color_scheme: theme.ColorScheme = .dark,
    source: ResourceSource = .fluent,
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

pub const FLUENT_RES = "src/desktop/fluent/resources";
pub const AERO_RES = "src/desktop/aero/resources";

fn setPath(dest: *[PATH_MAX]u8, src: []const u8) u8 {
    const len = @min(src.len, PATH_MAX);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addWallpaper(path: []const u8, id: u16, scheme: theme.ColorScheme, source: ResourceSource) void {
    if (wallpaper_count >= MAX_WALLPAPERS) return;
    var e = &wallpapers[wallpaper_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .wallpaper;
    e.color_scheme = scheme;
    e.source = source;
    e.loaded = true;
    wallpaper_count += 1;
}

fn addIcon(path: []const u8, id: u16, source: ResourceSource) void {
    if (icon_count >= MAX_ICONS) return;
    var e = &icons_arr[icon_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .icon;
    e.source = source;
    e.loaded = true;
    icon_count += 1;
}

fn addCursor(path: []const u8, id: u16, source: ResourceSource) void {
    if (cursor_count >= MAX_CURSORS) return;
    var e = &cursors[cursor_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .cursor;
    e.source = source;
    e.loaded = true;
    cursor_count += 1;
}

fn addThemeFile(path: []const u8, id: u16, source: ResourceSource) void {
    if (theme_file_count >= MAX_THEME_FILES) return;
    var e = &theme_files[theme_file_count];
    e.path_len = setPath(&e.path, path);
    e.id = id;
    e.kind = .theme_file;
    e.source = source;
    e.loaded = true;
    theme_file_count += 1;
}

pub fn init() void {
    if (initialized) return;

    wallpaper_count = 0;
    icon_count = 0;
    cursor_count = 0;
    theme_file_count = 0;

    registerFluentWallpapers();
    registerAeroWallpapers();
    registerFluentIcons();
    registerAeroIcons();
    registerFluentCursors();
    registerAeroCursors();
    registerFluentThemeFiles();
    registerAeroThemeFiles();

    initialized = true;
}

fn registerFluentWallpapers() void {
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_default.svg", 1, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_flow.svg", 2, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_light.svg", 3, .light, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_gradient.svg", 4, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_aurora.svg", 5, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_cityscape.svg", 6, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_abstract.svg", 7, .dark, .fluent);
    addWallpaper(FLUENT_RES ++ "/wallpapers/zircon_spectrum.svg", 8, .dark, .fluent);
}

fn registerAeroWallpapers() void {
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_default.svg", 101, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_aurora.svg", 102, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_crystal.svg", 103, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_nebula.svg", 104, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_ocean.svg", 105, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_landscape.svg", 106, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_nature.svg", 107, .dark, .aero);
    addWallpaper(AERO_RES ++ "/wallpapers/zircon_architecture.svg", 108, .dark, .aero);
}

fn registerFluentIcons() void {
    addIcon(FLUENT_RES ++ "/icons/computer.svg", 1, .fluent);
    addIcon(FLUENT_RES ++ "/icons/documents.svg", 2, .fluent);
    addIcon(FLUENT_RES ++ "/icons/recycle_bin.svg", 3, .fluent);
    addIcon(FLUENT_RES ++ "/icons/terminal.svg", 4, .fluent);
    addIcon(FLUENT_RES ++ "/icons/file_manager.svg", 5, .fluent);
    addIcon(FLUENT_RES ++ "/icons/browser.svg", 6, .fluent);
    addIcon(FLUENT_RES ++ "/icons/settings.svg", 7, .fluent);
    addIcon(FLUENT_RES ++ "/icons/calculator.svg", 8, .fluent);
    addIcon(FLUENT_RES ++ "/icons/network.svg", 9, .fluent);
    addIcon(FLUENT_RES ++ "/icons/store.svg", 10, .fluent);
    addIcon(FLUENT_RES ++ "/icons/mail.svg", 11, .fluent);
    addIcon(FLUENT_RES ++ "/icons/calendar.svg", 12, .fluent);
}

fn registerAeroIcons() void {
    addIcon(AERO_RES ++ "/icons/computer.svg", 101, .aero);
    addIcon(AERO_RES ++ "/icons/documents.svg", 102, .aero);
    addIcon(AERO_RES ++ "/icons/recycle_bin.svg", 103, .aero);
    addIcon(AERO_RES ++ "/icons/terminal.svg", 104, .aero);
    addIcon(AERO_RES ++ "/icons/browser.svg", 105, .aero);
    addIcon(AERO_RES ++ "/icons/settings.svg", 106, .aero);
    addIcon(AERO_RES ++ "/icons/network.svg", 107, .aero);
    addIcon(AERO_RES ++ "/icons/folder.svg", 108, .aero);
    addIcon(AERO_RES ++ "/icons/file.svg", 109, .aero);
    addIcon(AERO_RES ++ "/icons/lock.svg", 110, .aero);
    addIcon(AERO_RES ++ "/icons/shutdown.svg", 111, .aero);
    addIcon(AERO_RES ++ "/icons/user.svg", 112, .aero);
}

fn registerFluentCursors() void {
    addCursor(FLUENT_RES ++ "/cursors/zircon_arrow.svg", 1, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_text.svg", 2, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_busy.svg", 3, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_working.svg", 4, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_link.svg", 5, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_move.svg", 6, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_ns.svg", 7, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_ew.svg", 8, .fluent);
    addCursor(FLUENT_RES ++ "/cursors/zircon_unavail.svg", 9, .fluent);
}

fn registerAeroCursors() void {
    addCursor(AERO_RES ++ "/cursors/zircon_arrow.svg", 101, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_text.svg", 102, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_busy.svg", 103, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_working.svg", 104, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_link.svg", 105, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_move.svg", 106, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_ns.svg", 107, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_ew.svg", 108, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_help.svg", 109, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_nesw.svg", 110, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_nwse.svg", 111, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_pen.svg", 112, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_up.svg", 113, .aero);
    addCursor(AERO_RES ++ "/cursors/zircon_unavail.svg", 114, .aero);
}

fn registerFluentThemeFiles() void {
    addThemeFile(FLUENT_RES ++ "/themes/zircon-fluent-dark.theme", 1, .fluent);
    addThemeFile(FLUENT_RES ++ "/themes/zircon-fluent-light.theme", 2, .fluent);
    addThemeFile(FLUENT_RES ++ "/themes/zircon-fluent-contrast.theme", 3, .fluent);
}

fn registerAeroThemeFiles() void {
    addThemeFile(AERO_RES ++ "/themes/zircon-aero.theme", 101, .aero);
    addThemeFile(AERO_RES ++ "/themes/zircon-aero-blue.theme", 102, .aero);
    addThemeFile(AERO_RES ++ "/themes/zircon-aero-graphite.theme", 103, .aero);
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
        if (e.color_scheme == scheme and e.source == .fluent) return e;
    }
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

pub fn findIconBySource(source: ResourceSource, id: u16) ?*const ResourceEntry {
    for (icons_arr[0..icon_count]) |*e| {
        if (e.source == source and e.id == id) return e;
    }
    return null;
}

pub fn getFluentResourceCount() usize {
    var count: usize = 0;
    for (wallpapers[0..wallpaper_count]) |e| {
        if (e.source == .fluent) count += 1;
    }
    for (icons_arr[0..icon_count]) |e| {
        if (e.source == .fluent) count += 1;
    }
    for (cursors[0..cursor_count]) |e| {
        if (e.source == .fluent) count += 1;
    }
    return count;
}

pub fn getAeroResourceCount() usize {
    var count: usize = 0;
    for (wallpapers[0..wallpaper_count]) |e| {
        if (e.source == .aero) count += 1;
    }
    for (icons_arr[0..icon_count]) |e| {
        if (e.source == .aero) count += 1;
    }
    for (cursors[0..cursor_count]) |e| {
        if (e.source == .aero) count += 1;
    }
    return count;
}

// ── ICO-compatible embedded 16x16 bitmap fallback icons ──
// Fluent Design icons: flat, monochrome outlines on accent backgrounds.

pub const EmbeddedIcon = struct {
    id: u16,
    name: []const u8,
    svg_path: []const u8,
    palette: [16]u32,
    pixels: [16][16]u4,
};

pub const fluent_icons = [_]EmbeddedIcon{
    .{
        .id = 1,
        .name = "computer",
        .svg_path = FLUENT_RES ++ "/icons/computer.svg",
        .palette = .{
            0x000000, 0x1E1E1E, 0x0067C0, 0x0078D4,
            0x60CDFF, 0xFFFFFF, 0xF3F3F3, 0x9E9E9E,
            0x484848, 0x005A9E, 0x106EBE, 0xDEECF9,
            0xFF4343, 0x00CC6A, 0xFFC83D, 0x2D2D2D,
        },
        .pixels = .{
            .{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
            .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 4, 4, 4, 4, 4, 4, 4, 3, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1, 0, 0 },
            .{ 0, 1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 0, 0 },
            .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
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
    return &fluent_icons;
}

pub fn findEmbeddedIconById(id: u16) ?*const EmbeddedIcon {
    for (&fluent_icons) |*icon| {
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
