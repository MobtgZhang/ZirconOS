//! Desktop Window Manager — Fluent Acrylic Compositor
//! Implements ZirconOS Fluent visual effects:
//!   - Multi-pass box blur (approximates Gaussian for acrylic)
//!   - Noise texture overlay (frosted glass grain)
//!   - Luminosity tint blending
//!   - Reveal highlight (radial gradient at pointer)
//!   - Multi-layer depth shadows
//!
//! All effects are original implementations using standard image
//! processing techniques. The compositor operates on raw framebuffer
//! memory with a separable two-pass blur.

const theme = @import("theme.zig");

pub const DwmConfig = struct {
    composition_enabled: bool = theme.DwmDefaults.composition_enabled,
    acrylic_enabled: bool = theme.DwmDefaults.acrylic_enabled,
    acrylic_opacity: u8 = theme.DwmDefaults.acrylic_opacity,
    blur_radius: u8 = theme.DwmDefaults.blur_radius,
    blur_passes: u8 = theme.DwmDefaults.blur_passes,
    noise_opacity: u8 = theme.DwmDefaults.noise_opacity,
    luminosity_blend: u8 = theme.DwmDefaults.luminosity_blend,
    shadow_enabled: bool = theme.DwmDefaults.shadow_enabled,
    shadow_size: u8 = theme.DwmDefaults.shadow_size,
    shadow_layers: u8 = theme.DwmDefaults.shadow_layers,
    shadow_opacity: u8 = theme.DwmDefaults.shadow_opacity,
    animation_enabled: bool = theme.DwmDefaults.animation_enabled,
    reveal_enabled: bool = theme.DwmDefaults.reveal_enabled,
};

var config: DwmConfig = .{};
var initialized: bool = false;

pub fn init(cfg: DwmConfig) void {
    config = cfg;
    initialized = true;
}

pub fn isEnabled() bool {
    return initialized and config.composition_enabled;
}

pub fn getConfig() *const DwmConfig {
    return &config;
}

pub fn setAcrylicEnabled(enabled: bool) void {
    config.acrylic_enabled = enabled;
}

// ── Pixel I/O ──

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

// ── Separable Box Blur (multi-pass for acrylic) ──

const MAX_LINE: usize = 4096;
var line_buf_r: [MAX_LINE]u32 = undefined;
var line_buf_g: [MAX_LINE]u32 = undefined;
var line_buf_b: [MAX_LINE]u32 = undefined;

fn hblurRead(px: *const PixelReader, row: u32, x0: u32, x1: u32) void {
    var col: u32 = x0;
    while (col < x1) : (col += 1) {
        const c = px.readPixel(col, row);
        const idx = col - x0;
        line_buf_r[idx] = c & 0xFF;
        line_buf_g[idx] = (c >> 8) & 0xFF;
        line_buf_b[idx] = (c >> 16) & 0xFF;
    }
}

fn hblurWrite(px: *const PixelReader, row: u32, x0: u32, x1: u32, w: u32, radius: u32) void {
    var col: u32 = x0;
    while (col < x1) : (col += 1) {
        const idx = col - x0;
        const lo = if (idx >= radius) idx - radius else 0;
        const hi = @min(idx + radius + 1, w);
        const count = hi - lo;
        var sr: u32 = 0;
        var sg: u32 = 0;
        var sb: u32 = 0;
        var k: u32 = lo;
        while (k < hi) : (k += 1) {
            sr += line_buf_r[k];
            sg += line_buf_g[k];
            sb += line_buf_b[k];
        }
        px.writePixel(col, row, (sr / count) | ((sg / count) << 8) | ((sb / count) << 16));
    }
}

fn vblurRead(px: *const PixelReader, col: u32, y0: u32, y1: u32) void {
    var row: u32 = y0;
    while (row < y1) : (row += 1) {
        const c = px.readPixel(col, row);
        const idx = row - y0;
        line_buf_r[idx] = c & 0xFF;
        line_buf_g[idx] = (c >> 8) & 0xFF;
        line_buf_b[idx] = (c >> 16) & 0xFF;
    }
}

fn vblurWrite(px: *const PixelReader, col: u32, y0: u32, y1: u32, h: u32, radius: u32) void {
    var row: u32 = y0;
    while (row < y1) : (row += 1) {
        const idx = row - y0;
        const lo = if (idx >= radius) idx - radius else 0;
        const hi = @min(idx + radius + 1, h);
        const count = hi - lo;
        var sr: u32 = 0;
        var sg: u32 = 0;
        var sb: u32 = 0;
        var k: u32 = lo;
        while (k < hi) : (k += 1) {
            sr += line_buf_r[k];
            sg += line_buf_g[k];
            sb += line_buf_b[k];
        }
        px.writePixel(col, row, (sr / count) | ((sg / count) << 8) | ((sb / count) << 16));
    }
}

pub fn blurRect(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rect_x: i32,
    rect_y: i32,
    rect_w: i32,
    rect_h: i32,
) void {
    if (!config.acrylic_enabled or rect_w <= 0 or rect_h <= 0) return;

    const px = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };

    const x0: u32 = if (rect_x < 0) 0 else @intCast(rect_x);
    const y0: u32 = if (rect_y < 0) 0 else @intCast(rect_y);
    const x1: u32 = @min(x0 + @as(u32, @intCast(rect_w)), fb_width);
    const y1: u32 = @min(y0 + @as(u32, @intCast(rect_h)), fb_height);
    if (x0 >= x1 or y0 >= y1) return;

    const w = x1 - x0;
    const h = y1 - y0;
    if (w > MAX_LINE or h > MAX_LINE) return;

    const passes = config.blur_passes;
    const radius: u32 = @as(u32, config.blur_radius);
    if (radius == 0) return;

    var pass: u8 = 0;
    while (pass < passes) : (pass += 1) {
        var row: u32 = y0;
        while (row < y1) : (row += 1) {
            hblurRead(&px, row, x0, x1);
            hblurWrite(&px, row, x0, x1, w, radius);
        }
        var vcol: u32 = x0;
        while (vcol < x1) : (vcol += 1) {
            vblurRead(&px, vcol, y0, y1);
            vblurWrite(&px, vcol, y0, y1, h, radius);
        }
    }
}

// ── Noise Overlay (deterministic pseudo-noise for frosted grain) ──

fn pseudoNoise(x: u32, y: u32) u8 {
    var seed: u32 = x *% 374761393 +% y *% 668265263;
    seed = (seed ^ (seed >> 13)) *% 1274126177;
    seed = seed ^ (seed >> 16);
    return @truncate(seed & 0xFF);
}

pub fn applyNoiseOverlay(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rect_x: i32,
    rect_y: i32,
    rect_w: i32,
    rect_h: i32,
    opacity: u8,
) void {
    if (rect_w <= 0 or rect_h <= 0 or opacity == 0) return;

    const px = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };

    const x0: u32 = if (rect_x < 0) 0 else @intCast(rect_x);
    const y0: u32 = if (rect_y < 0) 0 else @intCast(rect_y);
    const x1: u32 = @min(x0 + @as(u32, @intCast(rect_w)), fb_width);
    const y1: u32 = @min(y0 + @as(u32, @intCast(rect_h)), fb_height);

    const alpha: u32 = @as(u32, opacity);
    const inv_alpha: u32 = 255 - alpha;

    var row: u32 = y0;
    while (row < y1) : (row += 1) {
        var col: u32 = x0;
        while (col < x1) : (col += 1) {
            const noise_val: u32 = pseudoNoise(col, row);
            const c = px.readPixel(col, row);
            const cr = ((c & 0xFF) * inv_alpha + noise_val * alpha) / 255;
            const cg = (((c >> 8) & 0xFF) * inv_alpha + noise_val * alpha) / 255;
            const cb = (((c >> 16) & 0xFF) * inv_alpha + noise_val * alpha) / 255;
            px.writePixel(col, row, (cr & 0xFF) | ((cg & 0xFF) << 8) | ((cb & 0xFF) << 16));
        }
    }
}

// ── Luminosity Tint Blend ──

pub fn applyLuminosityTint(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rect_x: i32,
    rect_y: i32,
    rect_w: i32,
    rect_h: i32,
    tint_color: u32,
    opacity: u8,
    luminosity: u8,
) void {
    if (rect_w <= 0 or rect_h <= 0) return;

    const px = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };

    const x0: u32 = if (rect_x < 0) 0 else @intCast(rect_x);
    const y0: u32 = if (rect_y < 0) 0 else @intCast(rect_y);
    const x1: u32 = @min(x0 + @as(u32, @intCast(rect_w)), fb_width);
    const y1: u32 = @min(y0 + @as(u32, @intCast(rect_h)), fb_height);

    const tr: u32 = tint_color & 0xFF;
    const tg: u32 = (tint_color >> 8) & 0xFF;
    const tb: u32 = (tint_color >> 16) & 0xFF;
    const alpha: u32 = @as(u32, opacity);
    const inv_alpha: u32 = 255 - alpha;
    const lum_factor: u32 = @as(u32, luminosity);

    var row: u32 = y0;
    while (row < y1) : (row += 1) {
        var col: u32 = x0;
        while (col < x1) : (col += 1) {
            const c = px.readPixel(col, row);
            var cr: u32 = c & 0xFF;
            var cg: u32 = (c >> 8) & 0xFF;
            var cb: u32 = (c >> 16) & 0xFF;

            // Luminosity adjustment: shift toward target luminosity
            const pixel_lum = (cr * 77 + cg * 150 + cb * 29) >> 8;
            cr = (cr * (255 - lum_factor) + pixel_lum * lum_factor) / 255;
            cg = (cg * (255 - lum_factor) + pixel_lum * lum_factor) / 255;
            cb = (cb * (255 - lum_factor) + pixel_lum * lum_factor) / 255;

            // Alpha blend with tint
            const out_r = (tr * alpha + cr * inv_alpha) / 255;
            const out_g = (tg * alpha + cg * inv_alpha) / 255;
            const out_b = (tb * alpha + cb * inv_alpha) / 255;

            px.writePixel(col, row, (out_r & 0xFF) | ((out_g & 0xFF) << 8) | ((out_b & 0xFF) << 16));
        }
    }
}

// ── Reveal Highlight (radial gradient at pointer position) ──

pub fn renderRevealHighlight(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    pointer_x: i32,
    pointer_y: i32,
    radius: u32,
    highlight_color: u32,
    border_opacity: u8,
) void {
    if (radius == 0 or border_opacity == 0) return;

    const px = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };

    const hr: u32 = highlight_color & 0xFF;
    const hg: u32 = (highlight_color >> 8) & 0xFF;
    const hb: u32 = (highlight_color >> 16) & 0xFF;
    const max_alpha: u32 = @as(u32, border_opacity);

    const rad_i32: i32 = @intCast(radius);
    const x0: i32 = pointer_x - rad_i32;
    const y0: i32 = pointer_y - rad_i32;
    const x1: i32 = pointer_x + rad_i32;
    const y1: i32 = pointer_y + rad_i32;

    const sx: u32 = if (x0 < 0) 0 else @intCast(x0);
    const sy: u32 = if (y0 < 0) 0 else @intCast(y0);
    const ex: u32 = @min(if (x1 < 0) 0 else @as(u32, @intCast(x1)), fb_width);
    const ey: u32 = @min(if (y1 < 0) 0 else @as(u32, @intCast(y1)), fb_height);

    const rad_sq = radius * radius;

    var row: u32 = sy;
    while (row < ey) : (row += 1) {
        var col: u32 = sx;
        while (col < ex) : (col += 1) {
            const dx_i: i32 = @as(i32, @intCast(col)) - pointer_x;
            const dy_i: i32 = @as(i32, @intCast(row)) - pointer_y;
            const dx: u32 = @intCast(if (dx_i < 0) -dx_i else dx_i);
            const dy: u32 = @intCast(if (dy_i < 0) -dy_i else dy_i);
            const dist_sq = dx * dx + dy * dy;

            if (dist_sq >= rad_sq) continue;

            const dist_ratio = (dist_sq * 255) / rad_sq;
            const falloff = 255 - dist_ratio;
            const alpha = (max_alpha * falloff) / 255;
            const inv_alpha = 255 - alpha;

            const c = px.readPixel(col, row);
            const out_r = (hr * alpha + (c & 0xFF) * inv_alpha) / 255;
            const out_g = (hg * alpha + ((c >> 8) & 0xFF) * inv_alpha) / 255;
            const out_b = (hb * alpha + ((c >> 16) & 0xFF) * inv_alpha) / 255;
            px.writePixel(col, row, (out_r & 0xFF) | ((out_g & 0xFF) << 8) | ((out_b & 0xFF) << 16));
        }
    }
}

// ── Depth Shadow (Fluent-style elevation shadow) ──

pub fn renderDepthShadow(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    rect_x: i32,
    rect_y: i32,
    rect_w: i32,
    rect_h: i32,
) void {
    if (!config.shadow_enabled or rect_w <= 0 or rect_h <= 0) return;

    const px = PixelReader{
        .base = fb_addr,
        .pitch = fb_pitch,
        .width = fb_width,
        .height = fb_height,
        .bpp = fb_bpp,
    };

    const layers = @as(u32, config.shadow_layers);
    const size = @as(i32, @intCast(config.shadow_size));
    const base_opacity = @as(u32, config.shadow_opacity);

    var layer: u32 = 0;
    while (layer < layers) : (layer += 1) {
        const offset = size - @as(i32, @intCast(layer * 2));
        if (offset <= 0) break;

        const layer_alpha = base_opacity - (layer * (base_opacity / layers));
        const shadow_alpha: u32 = if (layer_alpha > 255) 0 else layer_alpha;

        const sx: i32 = rect_x + offset;
        const sy: i32 = rect_y + offset;

        const x0: u32 = if (sx < 0) 0 else @intCast(sx);
        const y0: u32 = if (sy < 0) 0 else @intCast(sy);
        const x1: u32 = @min(x0 + @as(u32, @intCast(rect_w)), fb_width);
        const y1: u32 = @min(y0 + @as(u32, @intCast(rect_h)), fb_height);

        if (x0 >= x1 or y0 >= y1) continue;

        var row: u32 = y0;
        while (row < y1) : (row += 1) {
            var col: u32 = x0;
            while (col < x1) : (col += 1) {
                const existing = px.readPixel(col, row);
                const er: u32 = existing & 0xFF;
                const eg: u32 = (existing >> 8) & 0xFF;
                const eb: u32 = (existing >> 16) & 0xFF;

                const out_r = er * (255 - shadow_alpha) / 255;
                const out_g = eg * (255 - shadow_alpha) / 255;
                const out_b = eb * (255 - shadow_alpha) / 255;
                px.writePixel(col, row, (out_r & 0xFF) | ((out_g & 0xFF) << 8) | ((out_b & 0xFF) << 16));
            }
        }
    }
}

// ── Full Acrylic Pipeline ──

pub fn renderAcrylicRegion(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    tint: u32,
    opacity: u8,
) void {
    if (!config.composition_enabled) return;

    const eff_tint = if (tint == 0) theme.scheme_dark.acrylic_tint else tint;
    const eff_opacity = if (opacity == 0) config.acrylic_opacity else opacity;

    // Step 1: Gaussian-approximation blur
    blurRect(fb_addr, fb_width, fb_height, fb_pitch, fb_bpp, x, y, w, h);

    // Step 2: Luminosity tint blend
    applyLuminosityTint(
        fb_addr,
        fb_width,
        fb_height,
        fb_pitch,
        fb_bpp,
        x,
        y,
        w,
        h,
        eff_tint,
        eff_opacity,
        config.luminosity_blend,
    );

    // Step 3: Noise grain overlay (frosted texture)
    applyNoiseOverlay(
        fb_addr,
        fb_width,
        fb_height,
        fb_pitch,
        fb_bpp,
        x,
        y,
        w,
        h,
        config.noise_opacity,
    );
}
