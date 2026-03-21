//! Desktop Icon Rendering — Theme-Aware Icon System
//! Each theme (Classic, Luna, Aero, Modern, Fluent, SunValley) has its own
//! distinct icon set with unique palette and pixel design.
//!
//! Icon resources are provided by 3rdparty theme packages:
//!   ZirconOSAero/resources/icons/       — 48×48 SVG crystal/glass style
//!   ZirconOSFluent/resources/icons/     — 32×32 SVG outlined/filled style
//!   ZirconOSSunValley/resources/icons/  — 32×32 SVG thin outline/rounded
//!   ZirconOSClassic/resources/icons/    — 32×32 SVG 16-color retro style
//!   ZirconOSLuna/resources/icons/       — 48×48 SVG colorful 3D style
//!   ZirconOSModern/resources/icons/     — 32×32 SVG flat Metro style
//!
//! When the framebuffer cannot render SVG, this module provides per-theme
//! embedded 16×16 bitmap fallback icons. Each theme has a DIFFERENT pixel
//! design and palette to match its visual identity.

const fb = @import("framebuffer.zig");

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

// ── Public Types ──

pub const IconId = enum(u8) {
    computer = 0,
    documents = 1,
    network = 2,
    recycle_bin = 3,
    browser = 4,
    settings = 5,
    terminal = 6,
    folder = 7,
};

pub const ThemeStyle = enum(u8) {
    classic = 0,
    luna = 1,
    aero = 2,
    modern = 3,
    fluent = 4,
    sunvalley = 5,
};

pub const ICON_PX_SIZE: u32 = 16;

// ── SVG Resource Paths (from 3rdparty theme packages) ──

pub const SvgIconPaths = struct {
    computer: []const u8,
    documents: []const u8,
    network: []const u8,
    recycle_bin: []const u8,
    browser: []const u8,
    settings: []const u8,
    terminal: []const u8,
    folder: []const u8,
};

pub fn getSvgPaths(style: ThemeStyle) SvgIconPaths {
    return switch (style) {
        .classic => .{
            .computer = "3rdparty/ZirconOSClassic/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSClassic/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSClassic/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSClassic/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSClassic/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSClassic/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSClassic/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSClassic/resources/icons/folder.svg",
        },
        .luna => .{
            .computer = "3rdparty/ZirconOSLuna/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSLuna/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSLuna/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSLuna/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSLuna/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSLuna/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSLuna/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSLuna/resources/icons/folder.svg",
        },
        .aero => .{
            .computer = "3rdparty/ZirconOSAero/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSAero/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSAero/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSAero/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSAero/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSAero/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSAero/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSAero/resources/icons/folder.svg",
        },
        .modern => .{
            .computer = "3rdparty/ZirconOSModern/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSModern/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSModern/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSModern/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSModern/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSModern/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSModern/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSModern/resources/icons/folder.svg",
        },
        .fluent => .{
            .computer = "3rdparty/ZirconOSFluent/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSFluent/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSFluent/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSFluent/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSFluent/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSFluent/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSFluent/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSFluent/resources/icons/file_manager.svg",
        },
        .sunvalley => .{
            .computer = "3rdparty/ZirconOSSunValley/resources/icons/computer.svg",
            .documents = "3rdparty/ZirconOSSunValley/resources/icons/documents.svg",
            .network = "3rdparty/ZirconOSSunValley/resources/icons/network.svg",
            .recycle_bin = "3rdparty/ZirconOSSunValley/resources/icons/recycle_bin.svg",
            .browser = "3rdparty/ZirconOSSunValley/resources/icons/browser.svg",
            .settings = "3rdparty/ZirconOSSunValley/resources/icons/settings.svg",
            .terminal = "3rdparty/ZirconOSSunValley/resources/icons/terminal.svg",
            .folder = "3rdparty/ZirconOSSunValley/resources/icons/file_manager.svg",
        },
    };
}

// ── Public Drawing API ──

pub fn drawIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32) void {
    drawThemedIcon(id, screen_x, screen_y, scale, .classic);
}

pub fn drawThemedIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32, style: ThemeStyle) void {
    switch (style) {
        .classic => drawPixelIcon(id, screen_x, screen_y, scale, &classic_palettes, &classic_pixels),
        .luna => drawPixelIcon(id, screen_x, screen_y, scale, &luna_palettes, &luna_pixels),
        .aero => drawAeroIcon(id, screen_x, screen_y, scale),
        .modern => drawPixelIcon(id, screen_x, screen_y, scale, &modern_palettes, &modern_pixels),
        .fluent => drawFluentIcon(id, screen_x, screen_y, scale),
        .sunvalley => drawSunValleyIcon(id, screen_x, screen_y, scale),
    }
}

pub fn getIconTotalSize(scale: u32) i32 {
    return @intCast(ICON_PX_SIZE * (if (scale < 1) 1 else scale));
}

// ═══════════════════════════════════════════════════════════
//  Per-Theme Embedded Bitmap Fallback Icons (16×16 @ 4bpp)
//  Each theme has DISTINCT pixel designs and palettes.
// ═══════════════════════════════════════════════════════════

const IconPixels = [16][16]u4;
const IconPalette = [9]u32;

// ── Helper: draw any 16×16 indexed-color icon ──

fn drawPixelIcon(
    id: IconId,
    screen_x: i32,
    screen_y: i32,
    scale: u32,
    palettes: *const [8]IconPalette,
    pixels: *const [8]IconPixels,
) void {
    const idx = @intFromEnum(id);
    if (idx >= 8) return;
    const data = &pixels[idx];
    const palette = &palettes[idx];
    const s: i32 = if (scale < 1) 1 else @intCast(scale);

    for (data, 0..) |row, dy| {
        for (row, 0..) |cidx, dx| {
            if (cidx == 0) continue;
            const color = palette[@intCast(cidx)];
            const px = screen_x + @as(i32, @intCast(dx)) * s;
            const py = screen_y + @as(i32, @intCast(dy)) * s;
            if (s == 1) {
                if (px >= 0 and py >= 0) fb.putPixel32(@intCast(px), @intCast(py), color);
            } else {
                fb.fillRect(px, py, s, s, color);
            }
        }
    }
}

// ════════════════════════════════════════════════════════════
//  CLASSIC theme — Windows 2000: 16-color, sharp beveled edges
// ════════════════════════════════════════════════════════════

const classic_palettes = [8]IconPalette{
    // computer: beige tower + blue CRT
    .{ 0, rgb(0xD4, 0xD0, 0xC8), rgb(0x80, 0x80, 0x80), rgb(0x00, 0x00, 0x80), rgb(0x00, 0x50, 0xD0), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x40, 0x40), rgb(0xA0, 0xA0, 0xA0), rgb(0x00, 0x80, 0x00) },
    // documents: yellow folder + white page
    .{ 0, rgb(0xFF, 0xE0, 0x80), rgb(0xE0, 0xB0, 0x30), rgb(0xFF, 0xF0, 0xA0), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x00, 0x80), rgb(0xC0, 0x90, 0x20), rgb(0x80, 0x80, 0x80), rgb(0xD4, 0xD0, 0xC8) },
    // network: blue monitors + yellow cable
    .{ 0, rgb(0x40, 0x60, 0xA0), rgb(0x20, 0x40, 0x80), rgb(0x00, 0xA0, 0xD0), rgb(0xD4, 0xD0, 0xC8), rgb(0xFF, 0xFF, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xFF, 0xFF, 0xFF), rgb(0x60, 0x60, 0x60) },
    // recycle_bin: grey bin + green arrows
    .{ 0, rgb(0x80, 0x80, 0x80), rgb(0xA0, 0xA0, 0xA0), rgb(0x60, 0x60, 0x60), rgb(0xC0, 0xC0, 0xC0), rgb(0x40, 0x40, 0x40), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x80, 0x40), rgb(0xD4, 0xD0, 0xC8) },
    // browser: teal globe
    .{ 0, rgb(0x2A, 0xBF, 0xBF), rgb(0x0D, 0x5C, 0x5C), rgb(0xA8, 0xF0, 0xF0), rgb(0xFF, 0xFF, 0xFF), rgb(0x1A, 0x8A, 0x8A), rgb(0x3F, 0xA3, 0xD8), rgb(0xE8, 0xF8, 0xF8), rgb(0x00, 0x60, 0x60) },
    // settings: grey gear
    .{ 0, rgb(0xC0, 0xC0, 0xC0), rgb(0x80, 0x80, 0x80), rgb(0xA0, 0xA0, 0xA0), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x40, 0x40), rgb(0x60, 0x60, 0x60), rgb(0xD4, 0xD0, 0xC8), rgb(0x00, 0x00, 0x80) },
    // terminal: black window + green text
    .{ 0, rgb(0x00, 0x00, 0x00), rgb(0x40, 0x40, 0x40), rgb(0x00, 0xC0, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xC0, 0xC0, 0xC0), rgb(0x00, 0x80, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0xD4, 0xD0, 0xC8) },
    // folder: yellow folder
    .{ 0, rgb(0xFF, 0xE0, 0x80), rgb(0xE0, 0xB0, 0x30), rgb(0xFF, 0xF0, 0xA0), rgb(0xC0, 0x90, 0x20), rgb(0x80, 0x80, 0x80), rgb(0xFF, 0xFF, 0xFF), rgb(0xD4, 0xD0, 0xC8), rgb(0x60, 0x60, 0x60) },
};

const classic_pixels = [8]IconPixels{
    // computer
    .{
        .{ 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 4, 4, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 4, 3, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 1, 1, 1, 8, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 6, 7, 7, 7, 6, 0, 0, 0, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 2, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 2, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // documents
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 5, 5, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 5, 5, 5, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 5, 4, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // network
    .{
        .{ 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0 },
        .{ 0, 2, 4, 4, 4, 2, 0, 0, 0, 0, 2, 4, 4, 4, 2, 0 },
        .{ 0, 2, 3, 3, 3, 2, 0, 0, 0, 0, 2, 3, 3, 3, 2, 0 },
        .{ 0, 2, 3, 7, 3, 2, 0, 0, 0, 0, 2, 3, 7, 3, 2, 0 },
        .{ 0, 2, 3, 3, 3, 2, 0, 0, 0, 0, 2, 3, 3, 3, 2, 0 },
        .{ 0, 2, 4, 4, 4, 2, 0, 0, 0, 0, 2, 4, 4, 4, 2, 0 },
        .{ 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0 },
        .{ 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0 },
        .{ 0, 0, 0, 6, 5, 5, 5, 5, 5, 5, 5, 5, 6, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0 },
        .{ 0, 6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 0 },
        .{ 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // recycle_bin
    .{
        .{ 0, 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 5, 5, 3, 3, 3, 3, 3, 3, 5, 5, 0, 0, 0 },
        .{ 0, 0, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 0, 0 },
        .{ 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0 },
        .{ 0, 0, 0, 5, 2, 2, 2, 2, 2, 2, 2, 2, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 7, 5, 7, 5, 7, 5, 7, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 2, 2, 2, 2, 2, 2, 2, 2, 5, 0, 0, 0 },
        .{ 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // browser
    .{
        .{ 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 2, 2, 1, 5, 1, 5, 1, 2, 2, 0, 0, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 1, 3, 1, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 2, 1, 3, 7, 3, 5, 3, 5, 3, 7, 3, 1, 2, 0, 0 },
        .{ 0, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 0, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 2, 5, 1, 1, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 2, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 6, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 2, 5, 1, 1, 5, 1, 5, 1, 5, 1, 5, 1, 1, 5, 2, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 0, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 0, 0 },
        .{ 0, 2, 1, 3, 7, 3, 5, 3, 5, 3, 7, 3, 1, 2, 0, 0 },
        .{ 0, 0, 2, 1, 3, 3, 1, 3, 1, 3, 3, 1, 2, 0, 0, 0 },
        .{ 0, 0, 0, 2, 2, 1, 5, 1, 5, 1, 2, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // settings
    .{
        .{ 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 5, 0, 0, 2, 1, 2, 0, 0, 5, 0, 0, 0, 0 },
        .{ 0, 0, 5, 2, 2, 0, 0, 1, 0, 0, 2, 2, 5, 0, 0, 0 },
        .{ 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 3, 5, 5, 5, 3, 3, 1, 0, 0, 0, 0 },
        .{ 2, 2, 0, 1, 3, 5, 0, 0, 0, 5, 3, 1, 0, 2, 2, 0 },
        .{ 2, 1, 1, 1, 3, 5, 0, 0, 0, 5, 3, 1, 1, 1, 2, 0 },
        .{ 2, 2, 0, 1, 3, 5, 0, 0, 0, 5, 3, 1, 0, 2, 2, 0 },
        .{ 0, 0, 0, 1, 3, 3, 5, 5, 5, 3, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0 },
        .{ 0, 0, 5, 2, 2, 0, 0, 1, 0, 0, 2, 2, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 0, 0, 2, 1, 2, 0, 0, 5, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // terminal
    .{
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 2, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 3, 1, 1, 3, 3, 3, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // folder
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
};

// ════════════════════════════════════════════════════════════
//  LUNA theme — Windows XP: vivid colors, 3D rounded look, orange/blue
// ════════════════════════════════════════════════════════════

const luna_palettes = [8]IconPalette{
    // computer: vivid blue monitor + grey tower
    .{ 0, rgb(0x00, 0x58, 0xE6), rgb(0x3A, 0x81, 0xE5), rgb(0x80, 0xB0, 0xF0), rgb(0xEC, 0xE9, 0xD8), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x3C, 0xA0), rgb(0xAC, 0xA8, 0x99), rgb(0x40, 0xC0, 0x40) },
    // documents: bright orange folder + white sheet
    .{ 0, rgb(0xFF, 0xA0, 0x00), rgb(0xE0, 0x80, 0x00), rgb(0xFF, 0xC8, 0x60), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x00, 0xA0), rgb(0xC0, 0x60, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xEC, 0xE9, 0xD8) },
    // network: XP blue + green connected
    .{ 0, rgb(0x00, 0x58, 0xE6), rgb(0x3A, 0x81, 0xE5), rgb(0x80, 0xC0, 0xFF), rgb(0xEC, 0xE9, 0xD8), rgb(0x00, 0xC0, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x40, 0x40) },
    // recycle_bin: XP green bin
    .{ 0, rgb(0x3C, 0x8D, 0x2E), rgb(0x5C, 0xBB, 0x4C), rgb(0x2A, 0x6A, 0x1E), rgb(0xC0, 0xE0, 0xC0), rgb(0x1A, 0x4A, 0x10), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x80, 0x30), rgb(0xEC, 0xE9, 0xD8) },
    // browser: XP blue globe + orange ring
    .{ 0, rgb(0x00, 0x58, 0xE6), rgb(0x00, 0x3C, 0xA0), rgb(0x80, 0xC0, 0xFF), rgb(0xFF, 0xFF, 0xFF), rgb(0xFF, 0xA0, 0x00), rgb(0xFF, 0xC8, 0x60), rgb(0x3A, 0x81, 0xE5), rgb(0x00, 0x80, 0x40) },
    // settings: XP blue/grey gear
    .{ 0, rgb(0x00, 0x58, 0xE6), rgb(0xAC, 0xA8, 0x99), rgb(0xEC, 0xE9, 0xD8), rgb(0xFF, 0xFF, 0xFF), rgb(0x80, 0x80, 0x80), rgb(0x3A, 0x81, 0xE5), rgb(0x00, 0x3C, 0xA0), rgb(0xD4, 0xD0, 0xC8) },
    // terminal: XP black/green console
    .{ 0, rgb(0x00, 0x00, 0x00), rgb(0x00, 0x58, 0xE6), rgb(0x40, 0xFF, 0x40), rgb(0xAC, 0xA8, 0x99), rgb(0xEC, 0xE9, 0xD8), rgb(0x00, 0xA0, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0x3A, 0x81, 0xE5) },
    // folder: XP orange folder
    .{ 0, rgb(0xFF, 0xA0, 0x00), rgb(0xE0, 0x80, 0x00), rgb(0xFF, 0xC8, 0x60), rgb(0xC0, 0x60, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xFF, 0xFF, 0xFF), rgb(0xEC, 0xE9, 0xD8), rgb(0x40, 0x40, 0x40) },
};

const luna_pixels = [8]IconPixels{
    // computer — XP style: wider monitor, vivid blue, rounded stand
    .{
        .{ 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0 },
        .{ 0, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 3, 3, 3, 3, 3, 3, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 3, 5, 3, 3, 3, 3, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 3, 3, 3, 3, 3, 3, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 3, 3, 3, 3, 3, 3, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 6, 0, 0, 0 },
        .{ 0, 6, 1, 1, 1, 1, 8, 1, 1, 1, 1, 1, 6, 0, 0, 0 },
        .{ 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 7, 4, 4, 4, 7, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 7, 4, 4, 4, 4, 4, 7, 0, 0, 0, 0, 0 },
        .{ 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0 },
        .{ 0, 6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 0, 0 },
        .{ 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // documents — XP orange folder
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 3, 3, 1, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0 },
        .{ 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 5, 4, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 5, 5, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 4, 5, 5, 5, 4, 4, 4, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // network — XP: screens + green activity
    .{
        .{ 0, 6, 6, 6, 6, 6, 0, 0, 0, 0, 6, 6, 6, 6, 6, 0 },
        .{ 0, 6, 4, 4, 4, 6, 0, 0, 0, 0, 6, 4, 4, 4, 6, 0 },
        .{ 0, 6, 1, 3, 1, 6, 0, 0, 0, 0, 6, 1, 3, 1, 6, 0 },
        .{ 0, 6, 1, 7, 1, 6, 0, 0, 0, 0, 6, 1, 7, 1, 6, 0 },
        .{ 0, 6, 1, 1, 1, 6, 0, 0, 0, 0, 6, 1, 1, 1, 6, 0 },
        .{ 0, 6, 4, 4, 4, 6, 0, 0, 0, 0, 6, 4, 4, 4, 6, 0 },
        .{ 0, 6, 6, 6, 6, 6, 0, 0, 0, 0, 6, 6, 6, 6, 6, 0 },
        .{ 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0 },
        .{ 0, 0, 0, 6, 5, 5, 5, 5, 5, 5, 5, 5, 6, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0 },
        .{ 0, 6, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 6, 0 },
        .{ 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // recycle_bin — XP green bin
    .{
        .{ 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 5, 3, 3, 3, 3, 3, 3, 3, 5, 0, 0, 0, 0 },
        .{ 0, 0, 5, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 0, 0, 0 },
        .{ 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 2, 1, 2, 1, 2, 1, 2, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 7, 5, 7, 5, 7, 5, 7, 5, 7, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 1, 5, 1, 5, 1, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 5, 1, 2, 1, 2, 1, 2, 1, 2, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // browser — XP: blue globe + orange ring
    .{
        .{ 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 2, 5, 1, 7, 1, 7, 1, 5, 2, 0, 0, 0, 0 },
        .{ 0, 0, 5, 1, 3, 3, 1, 3, 1, 3, 3, 1, 5, 0, 0, 0 },
        .{ 0, 2, 1, 3, 4, 3, 7, 3, 7, 3, 4, 3, 1, 2, 0, 0 },
        .{ 0, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 0, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 6, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 2, 7, 1, 1, 7, 1, 7, 1, 7, 1, 7, 1, 1, 7, 2, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 6, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 2, 7, 1, 1, 7, 1, 7, 1, 7, 1, 7, 1, 1, 7, 2, 0 },
        .{ 2, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 2, 0 },
        .{ 0, 5, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 5, 0, 0 },
        .{ 0, 2, 1, 3, 4, 3, 7, 3, 7, 3, 4, 3, 1, 2, 0, 0 },
        .{ 0, 0, 5, 1, 3, 3, 1, 3, 1, 3, 3, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 2, 5, 1, 7, 1, 7, 1, 5, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // settings — shared with Classic
    .{
        .{ 0, 0, 0, 0, 0, 0, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 5, 0, 0, 5, 1, 5, 0, 0, 5, 0, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 0, 0, 1, 0, 0, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 1, 1, 1, 1, 1, 1, 5, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 2, 2, 5, 5, 5, 2, 2, 1, 0, 0, 0, 0 },
        .{ 5, 5, 0, 1, 2, 5, 0, 0, 0, 5, 2, 1, 0, 5, 5, 0 },
        .{ 5, 1, 1, 1, 2, 5, 0, 0, 0, 5, 2, 1, 1, 1, 5, 0 },
        .{ 5, 5, 0, 1, 2, 5, 0, 0, 0, 5, 2, 1, 0, 5, 5, 0 },
        .{ 0, 0, 0, 1, 2, 2, 5, 5, 5, 2, 2, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 5, 1, 1, 1, 1, 1, 1, 1, 5, 0, 0, 0, 0 },
        .{ 0, 0, 5, 1, 5, 0, 0, 1, 0, 0, 5, 1, 5, 0, 0, 0 },
        .{ 0, 0, 0, 5, 0, 0, 5, 1, 5, 0, 0, 5, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // terminal — shared with Classic
    .{
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 2, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 3, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 3, 1, 1, 3, 3, 3, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // folder — XP orange
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 3, 3, 1, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0 },
        .{ 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
};

// ════════════════════════════════════════════════════════════
//  MODERN theme — Windows 8 Metro: flat single-color tiles
// ════════════════════════════════════════════════════════════

const modern_palettes = [8]IconPalette{
    .{ 0, rgb(0x00, 0x78, 0xD7), rgb(0x00, 0x5A, 0x9E), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0xCA, 0x8B, 0x02), rgb(0xA0, 0x6A, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0x00, 0x78, 0xD7), rgb(0x00, 0x5A, 0x9E), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0x44, 0x44, 0x44), rgb(0x33, 0x33, 0x33), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0x00, 0x78, 0xD7), rgb(0x00, 0x5A, 0x9E), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0x44, 0x44, 0x44), rgb(0x33, 0x33, 0x33), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0x1E, 0x1E, 0x1E), rgb(0x00, 0x00, 0x00), rgb(0x40, 0xFF, 0x40), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
    .{ 0, rgb(0xCA, 0x8B, 0x02), rgb(0xA0, 0x6A, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0xCC, 0xCC, 0xCC), 0, 0, 0, 0 },
};

const modern_pixels = [8]IconPixels{
    // computer — flat monitor + base
    .{
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // documents — flat folder
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // network — flat
    .{
        .{ 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0 },
        .{ 0, 1, 3, 3, 3, 1, 0, 0, 0, 0, 1, 3, 3, 3, 1, 0 },
        .{ 0, 1, 3, 3, 3, 1, 0, 0, 0, 0, 1, 3, 3, 3, 1, 0 },
        .{ 0, 1, 3, 3, 3, 1, 0, 0, 0, 0, 1, 3, 3, 3, 1, 0 },
        .{ 0, 1, 3, 3, 3, 1, 0, 0, 0, 0, 1, 3, 3, 3, 1, 0 },
        .{ 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0 },
        .{ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 0 },
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // recycle_bin — flat
    .{
        .{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // browser — flat circle
    .{
        .{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 1, 1, 3, 3, 1, 3, 1, 3, 3, 1, 1, 0, 0, 0 },
        .{ 0, 1, 1, 3, 3, 3, 2, 3, 2, 3, 3, 3, 1, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 1, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 1, 0 },
        .{ 1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1, 0 },
        .{ 1, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 1, 0 },
        .{ 1, 2, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 2, 1, 0 },
        .{ 1, 1, 3, 3, 1, 3, 1, 3, 1, 3, 1, 3, 3, 1, 1, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 1, 3, 3, 3, 2, 3, 2, 3, 3, 3, 1, 1, 0, 0 },
        .{ 0, 0, 1, 1, 3, 3, 1, 3, 1, 3, 3, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // settings — flat gear
    .{
        .{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0 },
        .{ 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 3, 3, 3, 1, 1, 1, 0, 0, 0, 0 },
        .{ 1, 1, 0, 1, 1, 3, 0, 0, 0, 3, 1, 1, 0, 1, 1, 0 },
        .{ 1, 1, 1, 1, 1, 3, 0, 0, 0, 3, 1, 1, 1, 1, 1, 0 },
        .{ 1, 1, 0, 1, 1, 3, 0, 0, 0, 3, 1, 1, 0, 1, 1, 0 },
        .{ 0, 0, 0, 1, 1, 1, 3, 3, 3, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0 },
        .{ 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // terminal — flat
    .{
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 3, 2, 2, 3, 3, 3, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0 },
        .{ 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
    // folder — flat
    .{
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    },
};

// ════════════════════════════════════════════════════════════
//  AERO theme — Glass/crystal style with reflection overlay
//  Uses Aero palette from 3rdparty/ZirconOSAero
// ════════════════════════════════════════════════════════════

const aero_palettes = [8]IconPalette{
    .{ 0, rgb(0x2B, 0x56, 0x7A), rgb(0x41, 0x80, 0xC8), rgb(0x6B, 0xA0, 0xD8), rgb(0xA0, 0xC0, 0xE8), rgb(0xFF, 0xFF, 0xFF), rgb(0xC0, 0xC0, 0xC0), rgb(0x80, 0x80, 0x80), rgb(0x40, 0x40, 0x40) },
    .{ 0, rgb(0xC0, 0x90, 0x20), rgb(0xE0, 0xB8, 0x40), rgb(0xFF, 0xD8, 0x70), rgb(0xFF, 0xFF, 0xFF), rgb(0x1A, 0x1A, 0x1A), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0xA0, 0x70, 0x10) },
    .{ 0, rgb(0x41, 0x80, 0xC8), rgb(0x2B, 0x56, 0x7A), rgb(0x80, 0xC0, 0xFF), rgb(0xF0, 0xF0, 0xF0), rgb(0x33, 0x99, 0xFF), rgb(0x80, 0x80, 0x80), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x40, 0x40) },
    .{ 0, rgb(0x80, 0x80, 0x80), rgb(0xA0, 0xA0, 0xA0), rgb(0x60, 0x60, 0x60), rgb(0xD0, 0xD0, 0xD0), rgb(0x40, 0x40, 0x40), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x80, 0x40), rgb(0xC0, 0xC0, 0xC0) },
    .{ 0, rgb(0x20, 0x80, 0xC0), rgb(0x10, 0x60, 0x90), rgb(0x60, 0xC0, 0xF0), rgb(0xFF, 0xFF, 0xFF), rgb(0x1A, 0x8A, 0x8A), rgb(0x3F, 0xA3, 0xD8), rgb(0xE8, 0xF8, 0xF8), rgb(0x0A, 0x4A, 0x6A) },
    .{ 0, rgb(0x80, 0x90, 0xA0), rgb(0x60, 0x70, 0x80), rgb(0xA0, 0xB0, 0xC0), rgb(0xFF, 0xFF, 0xFF), rgb(0x40, 0x50, 0x60), rgb(0xC0, 0xC8, 0xD0), rgb(0xD0, 0xD8, 0xE0), rgb(0x41, 0x80, 0xC8) },
    .{ 0, rgb(0x10, 0x10, 0x10), rgb(0x2B, 0x56, 0x7A), rgb(0x00, 0xC0, 0x00), rgb(0x60, 0x70, 0x80), rgb(0xD0, 0xD0, 0xD0), rgb(0x00, 0x80, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0x41, 0x80, 0xC8) },
    .{ 0, rgb(0xC0, 0x90, 0x20), rgb(0xA0, 0x70, 0x10), rgb(0xE0, 0xB8, 0x40), rgb(0x80, 0x60, 0x00), rgb(0x60, 0x60, 0x60), rgb(0xFF, 0xFF, 0xFF), rgb(0xF0, 0xF0, 0xF0), rgb(0x40, 0x40, 0x40) },
};

fn drawAeroIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32) void {
    const s: i32 = if (scale < 1) 1 else @intCast(scale);
    const sz: i32 = 16 * s;

    fb.fillRoundedRect(screen_x + 1, screen_y + 1, sz, sz, 2, rgb(0x00, 0x00, 0x00));

    drawPixelIcon(id, screen_x, screen_y, scale, &aero_palettes, &classic_pixels);

    const hi_h = @divTrunc(sz, 3);
    if (hi_h > 1) {
        fb.addSpecularBand(screen_x, screen_y, sz, hi_h, 20);
    }
}

// ════════════════════════════════════════════════════════════
//  FLUENT theme — Outlined icons with accent-colored container
//  Uses palette from 3rdparty/ZirconOSFluent
// ════════════════════════════════════════════════════════════

const fluent_palettes = [8]IconPalette{
    .{ 0, rgb(0x00, 0x67, 0xC0), rgb(0x00, 0x4E, 0x98), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xE0, 0xE0), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x1A, 0x1A, 0x1A) },
    .{ 0, rgb(0xCA, 0x8B, 0x02), rgb(0xA0, 0x6E, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0xF0, 0xE0, 0xC0), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x1A, 0x1A, 0x1A) },
    .{ 0, rgb(0x00, 0x78, 0xD4), rgb(0x00, 0x5A, 0x9E), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xF0, 0xFF), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x00, 0xC0, 0x00) },
    .{ 0, rgb(0x44, 0x44, 0x44), rgb(0x33, 0x33, 0x33), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xE0, 0xE0), rgb(0x60, 0x60, 0x60), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x1A, 0x1A, 0x1A) },
    .{ 0, rgb(0x00, 0x9E, 0xDA), rgb(0x00, 0x78, 0xA8), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xF8, 0xFF), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x1A, 0x1A, 0x1A) },
    .{ 0, rgb(0x44, 0x44, 0x44), rgb(0x33, 0x33, 0x33), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xE0, 0xE0), rgb(0x60, 0x60, 0x60), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x00, 0x67, 0xC0) },
    .{ 0, rgb(0x1E, 0x1E, 0x1E), rgb(0x12, 0x12, 0x12), rgb(0x00, 0xC8, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xE0, 0xE0, 0xE0), rgb(0x00, 0x90, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0x00, 0x67, 0xC0) },
    .{ 0, rgb(0xCA, 0x8B, 0x02), rgb(0xA0, 0x6E, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0xF0, 0xE0, 0xC0), rgb(0x60, 0x60, 0x60), rgb(0x80, 0x80, 0x80), rgb(0xF3, 0xF3, 0xF3), rgb(0x1A, 0x1A, 0x1A) },
};

fn getFluentContainerColor(id: IconId) u32 {
    return switch (id) {
        .computer => rgb(0x00, 0x67, 0xC0),
        .documents => rgb(0xCA, 0x8B, 0x02),
        .network => rgb(0x00, 0x78, 0xD4),
        .recycle_bin => rgb(0x44, 0x44, 0x44),
        .browser => rgb(0x00, 0x9E, 0xDA),
        .settings => rgb(0x44, 0x44, 0x44),
        .terminal => rgb(0x1E, 0x1E, 0x1E),
        .folder => rgb(0xCA, 0x8B, 0x02),
    };
}

fn drawFluentIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32) void {
    const s: i32 = if (scale < 1) 1 else @intCast(scale);
    const sz: i32 = 16 * s;
    const pad: i32 = 2 * s;

    fb.fillRoundedRect(screen_x - pad, screen_y - pad, sz + pad * 2, sz + pad * 2, 4, getFluentContainerColor(id));

    drawPixelIcon(id, screen_x, screen_y, scale, &fluent_palettes, &modern_pixels);
}

// ════════════════════════════════════════════════════════════
//  SUNVALLEY theme — Thin outline, rounded circle container
//  Uses palette from 3rdparty/ZirconOSSunValley
// ════════════════════════════════════════════════════════════

const sunvalley_palettes = [8]IconPalette{
    .{ 0, rgb(0x1A, 0x3A, 0x5C), rgb(0x4C, 0xB0, 0xE8), rgb(0xFF, 0xFF, 0xFF), rgb(0xD0, 0xE8, 0xF8), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
    .{ 0, rgb(0x5C, 0x3A, 0x00), rgb(0xCA, 0x8B, 0x02), rgb(0xFF, 0xFF, 0xFF), rgb(0xF8, 0xE8, 0xC0), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
    .{ 0, rgb(0x1A, 0x3A, 0x5C), rgb(0x4C, 0xB0, 0xE8), rgb(0xFF, 0xFF, 0xFF), rgb(0xD0, 0xE8, 0xF8), rgb(0x00, 0xC0, 0x00), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
    .{ 0, rgb(0x2C, 0x2C, 0x2C), rgb(0x88, 0x88, 0x88), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xE0, 0xE0), rgb(0x50, 0x50, 0x50), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
    .{ 0, rgb(0x0A, 0x4A, 0x5A), rgb(0x4C, 0xB0, 0xE8), rgb(0xFF, 0xFF, 0xFF), rgb(0xC0, 0xF0, 0xFF), rgb(0x40, 0x40, 0x40), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
    .{ 0, rgb(0x2C, 0x2C, 0x2C), rgb(0x88, 0x88, 0x88), rgb(0xFF, 0xFF, 0xFF), rgb(0xE0, 0xE0, 0xE0), rgb(0x50, 0x50, 0x50), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x4C, 0xB0, 0xE8) },
    .{ 0, rgb(0x1C, 0x1C, 0x1C), rgb(0x2C, 0x2C, 0x2C), rgb(0x00, 0xC8, 0x00), rgb(0x60, 0x60, 0x60), rgb(0xDD, 0xDD, 0xDD), rgb(0x00, 0x90, 0x00), rgb(0xFF, 0xFF, 0xFF), rgb(0x4C, 0xB0, 0xE8) },
    .{ 0, rgb(0x5C, 0x3A, 0x00), rgb(0xCA, 0x8B, 0x02), rgb(0xFF, 0xFF, 0xFF), rgb(0xF8, 0xE8, 0xC0), rgb(0x50, 0x50, 0x50), rgb(0x80, 0x80, 0x80), rgb(0xF0, 0xF0, 0xF0), rgb(0x1C, 0x1C, 0x1C) },
};

fn getSunValleyContainerColor(id: IconId) u32 {
    return switch (id) {
        .computer => rgb(0x1A, 0x3A, 0x5C),
        .documents => rgb(0x5C, 0x3A, 0x00),
        .network => rgb(0x1A, 0x3A, 0x5C),
        .recycle_bin => rgb(0x2C, 0x2C, 0x2C),
        .browser => rgb(0x0A, 0x4A, 0x5A),
        .settings => rgb(0x2C, 0x2C, 0x2C),
        .terminal => rgb(0x1C, 0x1C, 0x1C),
        .folder => rgb(0x5C, 0x3A, 0x00),
    };
}

fn drawSunValleyIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32) void {
    const s: i32 = if (scale < 1) 1 else @intCast(scale);
    const sz: i32 = 16 * s;
    const pad: i32 = 3 * s;
    const cx = screen_x + @divTrunc(sz, 2);
    const cy = screen_y + @divTrunc(sz, 2);
    const r = @divTrunc(sz + pad * 2, 2);

    fb.fillRoundedRect(cx - r + 1, cy - r + 1, r * 2, r * 2, r, rgb(0x00, 0x00, 0x00));
    fb.fillRoundedRect(cx - r, cy - r, r * 2, r * 2, r, getSunValleyContainerColor(id));

    drawPixelIcon(id, screen_x, screen_y, scale, &sunvalley_palettes, &modern_pixels);
}
