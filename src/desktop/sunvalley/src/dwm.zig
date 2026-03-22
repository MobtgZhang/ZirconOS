//! Desktop Window Manager — Mica / Acrylic Compositor
//! Implements the ZirconOS Sun Valley visual composition pipeline:
//!   - Mica material: wallpaper-sampled tint behind window chrome
//!   - Acrylic material: multi-pass blur + noise + luminosity blend
//!   - Rounded corner clipping with configurable radius
//!   - Layered depth shadow system with spread and softness
//!   - Snap layout overlay rendering

const theme = @import("theme.zig");

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

pub const DwmConfig = struct {
    mica_enabled: bool = theme.DwmDefaults.mica_enabled,
    mica_opacity: u8 = theme.DwmDefaults.mica_opacity,
    mica_blur_radius: u8 = theme.DwmDefaults.mica_blur_radius,
    mica_blur_passes: u8 = theme.DwmDefaults.mica_blur_passes,
    mica_luminosity: u8 = theme.DwmDefaults.mica_luminosity,
    mica_tint_color: u32 = theme.DwmDefaults.mica_tint_color,
    mica_tint_opacity: u8 = theme.DwmDefaults.mica_tint_opacity,
    acrylic_enabled: bool = theme.DwmDefaults.acrylic_enabled,
    acrylic_blur_radius: u8 = theme.DwmDefaults.acrylic_blur_radius,
    acrylic_blur_passes: u8 = theme.DwmDefaults.acrylic_blur_passes,
    acrylic_noise_opacity: u8 = theme.DwmDefaults.acrylic_noise_opacity,
    round_corners: bool = theme.DwmDefaults.round_corners,
    corner_radius: u8 = theme.DwmDefaults.corner_radius,
    shadow_enabled: bool = theme.DwmDefaults.shadow_enabled,
    shadow_size: u8 = theme.DwmDefaults.shadow_size,
    shadow_layers: u8 = theme.DwmDefaults.shadow_layers,
    shadow_spread: u8 = theme.DwmDefaults.shadow_spread,
    snap_assist: bool = theme.DwmDefaults.snap_assist,
    color_scheme: theme.ColorScheme = .dark,
};

var config: DwmConfig = .{};
var initialized: bool = false;

pub fn init(cfg: DwmConfig) void {
    config = cfg;
    initialized = true;
}

pub fn isEnabled() bool {
    return initialized and config.mica_enabled;
}

pub fn getConfig() *const DwmConfig {
    return &config;
}

pub fn setMicaEnabled(enabled: bool) void {
    config.mica_enabled = enabled;
}

pub fn setColorScheme(scheme: theme.ColorScheme) void {
    config.color_scheme = scheme;
}

pub fn getColorScheme() theme.ColorScheme {
    return config.color_scheme;
}

// ── Pixel helpers ──

const PixelReader = struct {
    base: usize,
    pitch: u32,
    width: u32,
    height: u32,
    bpp: u8,

    inline fn readPixel(self: *const PixelReader, x: u32, y: u32) u32 {
        if (x >= self.width or y >= self.height) return 0;
        const bytes_pp = @as(u32, self.bpp) / 8;
        const ptr: [*]volatile u8 = @ptrFromInt(self.base);
        const off = y * self.pitch + x * bytes_pp;
        if (bytes_pp >= 3) {
            return @as(u32, ptr[off]) |
                (@as(u32, ptr[off + 1]) << 8) |
                (@as(u32, ptr[off + 2]) << 16);
        }
        return 0;
    }

    inline fn writePixel(self: *const PixelReader, x: u32, y: u32, color: u32) void {
        if (x >= self.width or y >= self.height) return;
        const bytes_pp = @as(u32, self.bpp) / 8;
        const ptr: [*]volatile u8 = @ptrFromInt(self.base);
        const off = y * self.pitch + x * bytes_pp;
        ptr[off] = @truncate(color);
        ptr[off + 1] = @truncate(color >> 8);
        ptr[off + 2] = @truncate(color >> 16);
        if (bytes_pp >= 4) {
            ptr[off + 3] = @truncate(color >> 24);
        }
    }
};

// ── Separable Box Blur ──

fn hblurReadRow(reader: *const PixelReader, y: u32, out_r: []u32, out_g: []u32, out_b: []u32) void {
    for (0..reader.width) |xi| {
        const x: u32 = @intCast(xi);
        const c = reader.readPixel(x, y);
        out_r[xi] = c & 0xFF;
        out_g[xi] = (c >> 8) & 0xFF;
        out_b[xi] = (c >> 16) & 0xFF;
    }
}

fn hblurWriteRow(reader: *const PixelReader, y: u32, in_r: []const u32, in_g: []const u32, in_b: []const u32) void {
    for (0..reader.width) |xi| {
        const x: u32 = @intCast(xi);
        reader.writePixel(x, y, rgb(in_r[xi], in_g[xi], in_b[xi]));
    }
}

fn vblurReadCol(reader: *const PixelReader, x: u32, out_r: []u32, out_g: []u32, out_b: []u32) void {
    for (0..reader.height) |yi| {
        const y: u32 = @intCast(yi);
        const c = reader.readPixel(x, y);
        out_r[yi] = c & 0xFF;
        out_g[yi] = (c >> 8) & 0xFF;
        out_b[yi] = (c >> 16) & 0xFF;
    }
}

fn vblurWriteCol(reader: *const PixelReader, x: u32, in_r: []const u32, in_g: []const u32, in_b: []const u32) void {
    for (0..reader.height) |yi| {
        const y: u32 = @intCast(yi);
        reader.writePixel(x, y, rgb(in_r[yi], in_g[yi], in_b[yi]));
    }
}

fn blurLine(src: []const u32, dst: []u32, len: usize, radius: u8) void {
    const r: usize = @intCast(radius);
    const diam = 2 * r + 1;
    var acc: u32 = 0;
    for (0..@min(r + 1, len)) |i| {
        acc += src[i];
    }
    for (0..len) |i| {
        if (i + r + 1 < len) acc += src[i + r + 1];
        if (i > r) acc -= src[i - r - 1];
        const count: u32 = @intCast(@min(i + r + 1, len) - (if (i > r) i - r else 0));
        dst[i] = acc / @max(count, 1);
        _ = diam;
    }
}

pub fn blurRect(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rx: i32,
    ry: i32,
    rw: i32,
    rh: i32,
) void {
    const reader = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };
    const radius = config.mica_blur_radius;
    const passes = config.mica_blur_passes;
    const max_dim = @max(fb_width, fb_height);
    var buf_r: [4096]u32 = undefined;
    var buf_g: [4096]u32 = undefined;
    var buf_b: [4096]u32 = undefined;
    var tmp_r: [4096]u32 = undefined;
    var tmp_g: [4096]u32 = undefined;
    var tmp_b: [4096]u32 = undefined;
    if (max_dim > 4096) return;

    const sx: u32 = @intCast(@max(rx, 0));
    const sy: u32 = @intCast(@max(ry, 0));
    const ex: u32 = @intCast(@min(rx + rw, @as(i32, @intCast(fb_width))));
    const ey: u32 = @intCast(@min(ry + rh, @as(i32, @intCast(fb_height))));

    for (0..passes) |_| {
        var y = sy;
        while (y < ey) : (y += 1) {
            hblurReadRow(&reader, y, buf_r[0..fb_width], buf_g[0..fb_width], buf_b[0..fb_width]);
            blurLine(buf_r[sx..ex], tmp_r[sx..ex], ex - sx, radius);
            blurLine(buf_g[sx..ex], tmp_g[sx..ex], ex - sx, radius);
            blurLine(buf_b[sx..ex], tmp_b[sx..ex], ex - sx, radius);
            @memcpy(buf_r[sx..ex], tmp_r[sx..ex]);
            @memcpy(buf_g[sx..ex], tmp_g[sx..ex]);
            @memcpy(buf_b[sx..ex], tmp_b[sx..ex]);
            hblurWriteRow(&reader, y, buf_r[0..fb_width], buf_g[0..fb_width], buf_b[0..fb_width]);
        }
        var x = sx;
        while (x < ex) : (x += 1) {
            vblurReadCol(&reader, x, buf_r[0..fb_height], buf_g[0..fb_height], buf_b[0..fb_height]);
            blurLine(buf_r[sy..ey], tmp_r[sy..ey], ey - sy, radius);
            blurLine(buf_g[sy..ey], tmp_g[sy..ey], ey - sy, radius);
            blurLine(buf_b[sy..ey], tmp_b[sy..ey], ey - sy, radius);
            @memcpy(buf_r[sy..ey], tmp_r[sy..ey]);
            @memcpy(buf_g[sy..ey], tmp_g[sy..ey]);
            @memcpy(buf_b[sy..ey], tmp_b[sy..ey]);
            vblurWriteCol(&reader, x, buf_r[0..fb_height], buf_g[0..fb_height], buf_b[0..fb_height]);
        }
    }
}

// ── Mica Material ──

pub fn applyMicaTint(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rx: i32,
    ry: i32,
    rw: i32,
    rh: i32,
    tint_color: u32,
    tint_opacity: u8,
) void {
    const reader = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };
    const tr = tint_color & 0xFF;
    const tg = (tint_color >> 8) & 0xFF;
    const tb = (tint_color >> 16) & 0xFF;
    const ta: u32 = tint_opacity;
    const inv = 255 - ta;

    const sx: u32 = @intCast(@max(rx, 0));
    const sy: u32 = @intCast(@max(ry, 0));
    const ex: u32 = @intCast(@min(rx + rw, @as(i32, @intCast(fb_width))));
    const ey: u32 = @intCast(@min(ry + rh, @as(i32, @intCast(fb_height))));

    var y = sy;
    while (y < ey) : (y += 1) {
        var x = sx;
        while (x < ex) : (x += 1) {
            const c = reader.readPixel(x, y);
            const cr = c & 0xFF;
            const cg = (c >> 8) & 0xFF;
            const cb = (c >> 16) & 0xFF;
            const nr = (cr * inv + tr * ta) / 255;
            const ng = (cg * inv + tg * ta) / 255;
            const nb = (cb * inv + tb * ta) / 255;
            reader.writePixel(x, y, rgb(nr, ng, nb));
        }
    }
}

// ── Acrylic Material (blur + noise + luminosity) ──

pub fn applyNoiseOverlay(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rx: i32,
    ry: i32,
    rw: i32,
    rh: i32,
    opacity: u8,
) void {
    const reader = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };
    const sx: u32 = @intCast(@max(rx, 0));
    const sy: u32 = @intCast(@max(ry, 0));
    const ex: u32 = @intCast(@min(rx + rw, @as(i32, @intCast(fb_width))));
    const ey: u32 = @intCast(@min(ry + rh, @as(i32, @intCast(fb_height))));
    const opa: u32 = opacity;
    const inv = 255 - opa;

    var seed: u32 = 0x5A1C0E7F;
    var y = sy;
    while (y < ey) : (y += 1) {
        var x = sx;
        while (x < ex) : (x += 1) {
            seed ^= seed << 13;
            seed ^= seed >> 17;
            seed ^= seed << 5;
            const noise: u32 = (seed >> 24) & 0xFF;
            const c = reader.readPixel(x, y);
            const cr = c & 0xFF;
            const cg = (c >> 8) & 0xFF;
            const cb = (c >> 16) & 0xFF;
            const nr = (cr * inv + noise * opa) / 255;
            const ng = (cg * inv + noise * opa) / 255;
            const nb = (cb * inv + noise * opa) / 255;
            reader.writePixel(x, y, rgb(nr, ng, nb));
        }
    }
}

// ── Layered Depth Shadow ──

pub fn renderDepthShadow(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    wx: i32,
    wy: i32,
    ww: i32,
    wh: i32,
) void {
    if (!config.shadow_enabled) return;
    const reader = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };
    const layers = config.shadow_layers;
    const base_size: i32 = config.shadow_size;
    const spread: i32 = config.shadow_spread;

    for (0..layers) |li| {
        const layer: i32 = @intCast(li);
        const offset = base_size + layer * spread;
        const alpha_max: u32 = 60 - @as(u32, @intCast(li)) * 10;
        if (alpha_max == 0) continue;

        const sx: i32 = wx - offset;
        const sy: i32 = wy - offset + 2;
        const ex: i32 = wx + ww + offset;
        const ey: i32 = wy + wh + offset + 2;

        var y: i32 = @max(sy, 0);
        while (y < @min(ey, @as(i32, @intCast(fb_height)))) : (y += 1) {
            var x: i32 = @max(sx, 0);
            while (x < @min(ex, @as(i32, @intCast(fb_width)))) : (x += 1) {
                if (x >= wx and x < wx + ww and y >= wy and y < wy + wh) {
                    x = wx + ww;
                    continue;
                }
                const ux: u32 = @intCast(x);
                const uy: u32 = @intCast(y);
                const c = reader.readPixel(ux, uy);
                const cr = c & 0xFF;
                const cg = (c >> 8) & 0xFF;
                const cb = (c >> 16) & 0xFF;
                const inv = 255 - alpha_max;
                const nr = (cr * inv) / 255;
                const ng = (cg * inv) / 255;
                const nb = (cb * inv) / 255;
                reader.writePixel(ux, uy, rgb(nr, ng, nb));
            }
        }
    }
}

// ── Rounded Corner Clipping ──

pub fn clipRoundedCorners(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    wx: i32,
    wy: i32,
    ww: i32,
    wh: i32,
    radius: i32,
    bg_color: u32,
) void {
    const reader = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };
    const corners = [4][2]i32{
        .{ wx, wy },
        .{ wx + ww - radius, wy },
        .{ wx, wy + wh - radius },
        .{ wx + ww - radius, wy + wh - radius },
    };
    for (corners) |corner| {
        const cx = corner[0] + radius;
        const cy = corner[1] + radius;
        var dy: i32 = -radius;
        while (dy <= 0) : (dy += 1) {
            var dx: i32 = -radius;
            while (dx <= 0) : (dx += 1) {
                if (dx * dx + dy * dy > radius * radius) {
                    const px = cx + (if (corner[0] == wx) dx - radius else -dx);
                    const py = cy + (if (corner[1] == wy) dy - radius else -dy);
                    if (px >= 0 and px < @as(i32, @intCast(fb_width)) and
                        py >= 0 and py < @as(i32, @intCast(fb_height)))
                    {
                        reader.writePixel(@intCast(px), @intCast(py), bg_color);
                    }
                }
                dx += 1;
            }
        }
    }
}

// ── Mica Region (full pipeline) ──

pub fn renderMicaRegion(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rx: i32,
    ry: i32,
    rw: i32,
    rh: i32,
    tint_color: u32,
    tint_opacity: u8,
) void {
    blurRect(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, rx, ry, rw, rh);
    applyMicaTint(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, rx, ry, rw, rh, tint_color, tint_opacity);
}

// ── Acrylic Region (full pipeline) ──

pub fn renderAcrylicRegion(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rx: i32,
    ry: i32,
    rw: i32,
    rh: i32,
    tint_color: u32,
    tint_opacity: u8,
) void {
    blurRect(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, rx, ry, rw, rh);
    applyNoiseOverlay(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, rx, ry, rw, rh, config.acrylic_noise_opacity);
    applyMicaTint(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, rx, ry, rw, rh, tint_color, tint_opacity);
}

// ── Snap Layout Assist ──

pub const SnapZone = enum {
    left_half,
    right_half,
    top_left,
    top_right,
    bottom_left,
    bottom_right,
    maximize,
};

pub fn getSnapRect(zone: SnapZone, screen_w: i32, screen_h: i32) struct { x: i32, y: i32, w: i32, h: i32 } {
    const gap = theme.Layout.snap_zone_gap;
    const tb = theme.Layout.taskbar_height;
    const usable_h = screen_h - tb;
    const half_w = @divTrunc(screen_w, 2);
    const half_h = @divTrunc(usable_h, 2);

    return switch (zone) {
        .left_half => .{ .x = gap, .y = gap, .w = half_w - gap * 2, .h = usable_h - gap * 2 },
        .right_half => .{ .x = half_w + gap, .y = gap, .w = half_w - gap * 2, .h = usable_h - gap * 2 },
        .top_left => .{ .x = gap, .y = gap, .w = half_w - gap * 2, .h = half_h - gap * 2 },
        .top_right => .{ .x = half_w + gap, .y = gap, .w = half_w - gap * 2, .h = half_h - gap * 2 },
        .bottom_left => .{ .x = gap, .y = half_h + gap, .w = half_w - gap * 2, .h = half_h - gap * 2 },
        .bottom_right => .{ .x = half_w + gap, .y = half_h + gap, .w = half_w - gap * 2, .h = half_h - gap * 2 },
        .maximize => .{ .x = 0, .y = 0, .w = screen_w, .h = usable_h },
    };
}
