//! Renderer - ZirconOS Modern Rendering Abstraction Layer
//! Provides a platform-independent drawing interface with Metro-specific
//! flat design: sharp rectangles, no rounded corners, no gradients,
//! no blur, no shadows — pure solid-color geometry.

const theme = @import("theme.zig");

pub const COLORREF = theme.COLORREF;

pub const Rect = struct {
    x: i32 = 0,
    y: i32 = 0,
    w: i32 = 0,
    h: i32 = 0,

    pub fn contains(self: Rect, px: i32, py: i32) bool {
        return px >= self.x and px < self.x + self.w and
            py >= self.y and py < self.y + self.h;
    }

    pub fn intersects(self: Rect, other: Rect) bool {
        return self.x < other.x + other.w and
            self.x + self.w > other.x and
            self.y < other.y + other.h and
            self.y + self.h > other.y;
    }

    pub fn intersection(self: Rect, other: Rect) Rect {
        const x1 = @max(self.x, other.x);
        const y1 = @max(self.y, other.y);
        const x2 = @min(self.x + self.w, other.x + other.w);
        const y2 = @min(self.y + self.h, other.y + other.h);
        if (x2 <= x1 or y2 <= y1) return .{};
        return .{ .x = x1, .y = y1, .w = x2 - x1, .h = y2 - y1 };
    }

    pub fn union_(self: Rect, other: Rect) Rect {
        if (self.w == 0 or self.h == 0) return other;
        if (other.w == 0 or other.h == 0) return self;
        const x1 = @min(self.x, other.x);
        const y1 = @min(self.y, other.y);
        const x2 = @max(self.x + self.w, other.x + other.w);
        const y2 = @max(self.y + self.h, other.y + other.h);
        return .{ .x = x1, .y = y1, .w = x2 - x1, .h = y2 - y1 };
    }

    pub fn isEmpty(self: Rect) bool {
        return self.w <= 0 or self.h <= 0;
    }

    pub fn offset(self: Rect, dx: i32, dy: i32) Rect {
        return .{ .x = self.x + dx, .y = self.y + dy, .w = self.w, .h = self.h };
    }

    pub fn inset(self: Rect, d: i32) Rect {
        return .{
            .x = self.x + d,
            .y = self.y + d,
            .w = @max(self.w - d * 2, 0),
            .h = @max(self.h - d * 2, 0),
        };
    }
};

pub const Point = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const Size = struct {
    w: i32 = 0,
    h: i32 = 0,
};

pub const TextAlignment = enum(u8) {
    left = 0,
    center = 1,
    right = 2,
};

pub const FontWeight = enum(u8) {
    normal = 0,
    bold = 1,
    light = 2,
    semibold = 3,
};

pub const FontSpec = struct {
    name: []const u8 = theme.FONT_SYSTEM,
    size: i32 = theme.FONT_SYSTEM_SIZE,
    weight: FontWeight = .normal,
};

pub const RenderOps = struct {
    fill_rect: ?*const fn (rect: Rect, color: COLORREF) void = null,
    draw_rect: ?*const fn (rect: Rect, color: COLORREF, width: i32) void = null,
    draw_line: ?*const fn (x1: i32, y1: i32, x2: i32, y2: i32, color: COLORREF) void = null,
    draw_text: ?*const fn (text: []const u8, rect: Rect, color: COLORREF, font: FontSpec, alignment: TextAlignment) void = null,
    draw_icon: ?*const fn (icon_id: u32, x: i32, y: i32, size: i32) void = null,
    draw_bitmap: ?*const fn (bitmap_id: u32, dest: Rect) void = null,
    set_clip: ?*const fn (rect: Rect) void = null,
    clear_clip: ?*const fn () void = null,
    blit_surface: ?*const fn (surface_id: u32, dest: Rect, alpha: u8) void = null,
    flush: ?*const fn () void = null,
    fill_rect_alpha: ?*const fn (rect: Rect, color: COLORREF, alpha: u8) void = null,
};

var render_ops: RenderOps = .{};

pub fn setRenderOps(ops: RenderOps) void {
    render_ops = ops;
}

pub fn getRenderOps() *const RenderOps {
    return &render_ops;
}

pub fn fillRect(rect: Rect, color: COLORREF) void {
    if (render_ops.fill_rect) |f| f(rect, color);
}

pub fn drawRect(rect: Rect, color: COLORREF, width: i32) void {
    if (render_ops.draw_rect) |f| f(rect, color, width);
}

pub fn drawLine(x1: i32, y1: i32, x2: i32, y2: i32, color: COLORREF) void {
    if (render_ops.draw_line) |f| f(x1, y1, x2, y2, color);
}

pub fn drawText(text: []const u8, rect: Rect, color: COLORREF, font: FontSpec, alignment: TextAlignment) void {
    if (render_ops.draw_text) |f| f(text, rect, color, font, alignment);
}

pub fn drawIcon(icon_id: u32, x: i32, y: i32, size: i32) void {
    if (render_ops.draw_icon) |f| f(icon_id, x, y, size);
}

pub fn drawBitmap(bitmap_id: u32, dest: Rect) void {
    if (render_ops.draw_bitmap) |f| f(bitmap_id, dest);
}

pub fn setClip(rect: Rect) void {
    if (render_ops.set_clip) |f| f(rect);
}

pub fn clearClip() void {
    if (render_ops.clear_clip) |f| f();
}

pub fn blitSurface(surface_id: u32, dest: Rect, alpha: u8) void {
    if (render_ops.blit_surface) |f| f(surface_id, dest, alpha);
}

pub fn flushRender() void {
    if (render_ops.flush) |f| f();
}

pub fn fillRectAlpha(rect: Rect, color: COLORREF, alpha: u8) void {
    if (render_ops.fill_rect_alpha) |f| {
        f(rect, color, alpha);
    } else {
        fillRect(rect, theme.alphaBlend(color, theme.RGB(0xFF, 0xFF, 0xFF), alpha));
    }
}

/// Metro flat 1px border frame (no rounded corners, no 3D effect)
pub fn drawFlatFrame(rect: Rect, active: bool) void {
    const border_color = if (active) theme.window_border else theme.window_border_inactive;
    drawRect(rect, border_color, theme.Layout.window_border_width);
}

/// Metro flat titlebar (solid accent color, no gradient)
pub fn renderFlatTitlebar(rect: Rect) void {
    const colors = theme.getColors();
    fillRect(.{
        .x = rect.x,
        .y = rect.y,
        .w = rect.w,
        .h = theme.Layout.titlebar_height,
    }, colors.titlebar_active);
}

/// Render Metro desktop background (solid accent color)
pub fn renderDesktopBackground(rect: Rect) void {
    fillRect(rect, theme.getColors().desktop_background);
}

/// Metro flat taskbar (solid dark background, no glass)
pub fn renderFlatTaskbar(rect: Rect) void {
    fillRect(rect, theme.taskbar_bg);
}

/// Metro tile rendering (solid colored rectangle with text)
pub fn renderTile(rect: Rect, color: COLORREF) void {
    fillRect(rect, color);
}
