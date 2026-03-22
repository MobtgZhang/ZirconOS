//! Renderer - ZirconOS Luna Rendering Abstraction Layer
//! Provides a platform-independent drawing interface with Luna-specific
//! enhancements: gradient fills, rounded corners (8px), soft shadow (4px),
//! and the classic Windows XP 3D button look.
//! No glass blur — Luna uses opaque GDI-style gradient rendering.

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
};

pub const FontStyle = enum(u8) {
    normal = 0,
    italic = 1,
};

pub const FontSpec = struct {
    name: []const u8 = theme.FONT_SYSTEM,
    size: i32 = theme.FONT_SYSTEM_SIZE,
    weight: FontWeight = .normal,
    style: FontStyle = .normal,
};

pub const GradientDirection = enum(u8) {
    horizontal = 0,
    vertical = 1,
};

pub const RenderOps = struct {
    fill_rect: ?*const fn (rect: Rect, color: COLORREF) void = null,
    draw_rect: ?*const fn (rect: Rect, color: COLORREF, width: i32) void = null,
    draw_line: ?*const fn (x1: i32, y1: i32, x2: i32, y2: i32, color: COLORREF) void = null,
    draw_gradient: ?*const fn (rect: Rect, start: COLORREF, end: COLORREF, dir: GradientDirection) void = null,
    draw_round_rect: ?*const fn (rect: Rect, color: COLORREF, radius: i32) void = null,
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

pub fn drawGradient(rect: Rect, start: COLORREF, end: COLORREF, dir: GradientDirection) void {
    if (render_ops.draw_gradient) |f| f(rect, start, end, dir);
}

pub fn drawRoundRect(rect: Rect, color: COLORREF, radius: i32) void {
    if (render_ops.draw_round_rect) |f| f(rect, color, radius);
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

pub fn drawHGradient(rect: Rect, start_color: COLORREF, end_color: COLORREF) void {
    drawGradient(rect, start_color, end_color, .horizontal);
}

pub fn drawVGradient(rect: Rect, start_color: COLORREF, end_color: COLORREF) void {
    drawGradient(rect, start_color, end_color, .vertical);
}

pub fn fillRectAlpha(rect: Rect, color: COLORREF, alpha: u8) void {
    if (render_ops.fill_rect_alpha) |f| {
        f(rect, color, alpha);
    } else {
        fillRect(rect, theme.alphaBlend(color, theme.RGB(0xFF, 0xFF, 0xFF), alpha));
    }
}

/// Luna-style 4px soft shadow with graduated opacity
pub fn drawShadow(rect: Rect, shadow_size: i32) void {
    const shadow_color = theme.RGB(0, 0, 0);
    var i: i32 = 0;
    while (i < shadow_size) : (i += 1) {
        const base_alpha: i32 = 24;
        const alpha_step: u8 = @intCast(@max(0, base_alpha - @divTrunc(base_alpha * i, shadow_size)));
        const shadow_right = Rect{
            .x = rect.x + rect.w + i,
            .y = rect.y + shadow_size,
            .w = 1,
            .h = rect.h,
        };
        fillRect(shadow_right, theme.alphaBlend(shadow_color, theme.RGB(0xFF, 0xFF, 0xFF), alpha_step));
        const shadow_bottom = Rect{
            .x = rect.x + shadow_size,
            .y = rect.y + rect.h + i,
            .w = rect.w,
            .h = 1,
        };
        fillRect(shadow_bottom, theme.alphaBlend(shadow_color, theme.RGB(0xFF, 0xFF, 0xFF), alpha_step));
    }
}

/// Luna-style 3D frame with raised/sunken appearance
pub fn draw3DFrame(rect: Rect, raised: bool) void {
    const colors = theme.getColors();
    if (theme.LunaDefaults.rounded_corners) {
        const border_color = if (raised) colors.window_border_active else colors.button_shadow;
        drawRoundRect(rect, border_color, theme.TITLEBAR_CORNER_RADIUS);
    } else {
        const light = if (raised) colors.button_highlight else colors.button_shadow;
        const dark = if (raised) colors.button_shadow else colors.button_highlight;
        drawLine(rect.x, rect.y, rect.x + rect.w - 1, rect.y, light);
        drawLine(rect.x, rect.y, rect.x, rect.y + rect.h - 1, light);
        drawLine(rect.x + rect.w - 1, rect.y, rect.x + rect.w - 1, rect.y + rect.h - 1, dark);
        drawLine(rect.x, rect.y + rect.h - 1, rect.x + rect.w - 1, rect.y + rect.h - 1, dark);
    }
}

/// Luna-style gradient titlebar (left-to-right horizontal gradient)
pub fn drawLunaTitlebar(rect: Rect) void {
    const gp = theme.getTitlebarGradient();
    drawHGradient(rect, gp.start_color, gp.end_color);
}

/// Full Luna window frame:
///   1. Soft shadow → 2. Gradient titlebar → 3. Rounded corners → 4. Border
pub fn renderLunaWindowFrame(frame_rect: Rect, titlebar_h: i32) void {
    drawShadow(frame_rect, theme.WINDOW_SHADOW_SIZE);

    const titlebar_rect = Rect{
        .x = frame_rect.x,
        .y = frame_rect.y,
        .w = frame_rect.w,
        .h = titlebar_h,
    };
    drawLunaTitlebar(titlebar_rect);

    draw3DFrame(frame_rect, true);
}

/// Render Luna desktop wallpaper background (solid color fallback)
pub fn renderDesktopBackground(rect: Rect) void {
    fillRect(rect, theme.getColors().desktop_background);
}

/// Luna gradient taskbar (top-to-bottom vertical gradient)
pub fn renderGradientTaskbar(rect: Rect) void {
    const gp = theme.getTaskbarGradient();
    drawVGradient(rect, gp.start_color, gp.end_color);
    const edge = Rect{ .x = rect.x, .y = rect.y, .w = rect.w, .h = 1 };
    fillRect(edge, theme.taskbar_top_edge);
}

/// Luna Start button with green gradient and "start" text
pub fn renderStartButton(rect: Rect) void {
    drawVGradient(rect, theme.start_btn_top, theme.start_btn_bottom);
    drawRoundRect(rect, theme.getActiveColors().start_btn_dark, 4);
    drawText(
        theme.start_label,
        rect,
        theme.start_btn_text,
        .{ .weight = .bold, .style = .italic },
        .center,
    );
}
