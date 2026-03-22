//! Fluent Cursor Manager
//! Manages cursor state, smooth interpolation, and cursor sprite
//! selection. Implements the DWM smooth cursor behavior described
//! in the theme configuration (SmoothEnabled, LerpFactor, SubpixelPrecision).
//!
//! The cursor uses a monochrome Fluent-style pointer with a subtle
//! drop shadow for depth, rendered from embedded pixel data.

const theme = @import("theme.zig");

pub const CursorType = enum(u8) {
    arrow = 0,
    text = 1,
    busy = 2,
    working = 3,
    link = 4,
    move_cursor = 5,
    resize_ns = 6,
    resize_ew = 7,
    unavailable = 8,
};

pub const CursorState = struct {
    current_type: CursorType = .arrow,
    target_x: i32 = 0,
    target_y: i32 = 0,
    display_x: i32 = 0,
    display_y: i32 = 0,
    sub_x: i32 = 0,
    sub_y: i32 = 0,
    prev_x: i32 = -1,
    prev_y: i32 = -1,
    lerp_factor: i32 = 220,
    visible: bool = true,
    smooth_enabled: bool = true,
    is_moving: bool = false,
};

var state: CursorState = .{};

pub fn init() void {
    state = .{};
}

pub fn getState() *const CursorState {
    return &state;
}

pub fn setType(cursor_type: CursorType) void {
    state.current_type = cursor_type;
}

pub fn getType() CursorType {
    return state.current_type;
}

pub fn setPosition(x: i32, y: i32) void {
    state.target_x = x;
    state.target_y = y;
}

pub fn setSmoothEnabled(enabled: bool) void {
    state.smooth_enabled = enabled;
}

pub fn setLerpFactor(factor: i32) void {
    state.lerp_factor = if (factor < 64) 64 else if (factor > 255) 255 else factor;
}

pub fn setVisible(vis: bool) void {
    state.visible = vis;
}

/// Advance the smooth cursor interpolation by one step.
/// Uses fixed-point subpixel precision (256 units per pixel)
/// with adaptive lerp: fast catch-up for large sweeps, smooth for fine movements.
pub fn interpolateStep(screen_w: i32, screen_h: i32) void {
    const P: i32 = 256;
    const tx = state.target_x * P;
    const ty = state.target_y * P;
    const dx = tx - state.sub_x;
    const dy = ty - state.sub_y;

    if (!state.smooth_enabled) {
        state.sub_x = tx;
        state.sub_y = ty;
        state.display_x = state.target_x;
        state.display_y = state.target_y;
        return;
    }

    const dist_sq = @divTrunc(dx, P) * @divTrunc(dx, P) + @divTrunc(dy, P) * @divTrunc(dy, P);
    var lerp = state.lerp_factor;
    if (dist_sq > 400) {
        lerp = 252;
    } else if (dist_sq > 100) {
        lerp = state.lerp_factor + 20;
        if (lerp > 255) lerp = 255;
    } else if (dist_sq < 4) {
        lerp = state.lerp_factor - 40;
        if (lerp < 128) lerp = 128;
    }

    state.sub_x = state.sub_x + @divTrunc(dx * lerp, 256);
    state.sub_y = state.sub_y + @divTrunc(dy * lerp, 256);

    state.prev_x = state.display_x;
    state.prev_y = state.display_y;
    state.display_x = @divTrunc(state.sub_x + P / 2, P);
    state.display_y = @divTrunc(state.sub_y + P / 2, P);

    if (state.display_x < 0) state.display_x = 0;
    if (state.display_y < 0) state.display_y = 0;
    if (state.display_x >= screen_w) state.display_x = screen_w - 1;
    if (state.display_y >= screen_h) state.display_y = screen_h - 1;

    state.is_moving = (state.display_x != state.prev_x or state.display_y != state.prev_y);
}

pub fn positionChanged() bool {
    return state.display_x != state.prev_x or state.display_y != state.prev_y;
}

pub fn getDisplayPosition() struct { x: i32, y: i32 } {
    return .{ .x = state.display_x, .y = state.display_y };
}
