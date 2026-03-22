//! Modern Flat Cursor Module
//! Provides cursor state management and the Metro flat arrow bitmap.
//!
//! Metro cursor: clean white arrow with 1px dark outline, no glass
//! effects, no glow — simple and functional flat design.

const theme = @import("theme.zig");

pub const SmoothCursorState = struct {
    target_x: i32 = 0,
    target_y: i32 = 0,
    display_x: i32 = 0,
    display_y: i32 = 0,
    prev_x: i32 = -1,
    prev_y: i32 = -1,
    sub_x: i32 = 0,
    sub_y: i32 = 0,
    velocity_x: i32 = 0,
    velocity_y: i32 = 0,
    base_lerp: i32 = 240,
    is_moving: bool = false,
    jitter_threshold: i32 = 1,

    pub fn update(self: *SmoothCursorState, raw_x: i32, raw_y: i32, scr_w: i32, scr_h: i32) void {
        self.target_x = raw_x;
        self.target_y = raw_y;

        const P: i32 = 256;
        const tx = raw_x * P;
        const ty = raw_y * P;

        const dx = tx - self.sub_x;
        const dy = ty - self.sub_y;
        const dist_sq = @divTrunc(dx, P) * @divTrunc(dx, P) + @divTrunc(dy, P) * @divTrunc(dy, P);

        var lerp = self.base_lerp;
        if (dist_sq > 400) {
            lerp = 254;
        } else if (dist_sq > 100) {
            lerp = self.base_lerp + 10;
        } else if (dist_sq < 4) {
            lerp = self.base_lerp - 20;
            if (lerp < 180) lerp = 180;
        }

        self.sub_x = self.sub_x + @divTrunc(dx * lerp, 256);
        self.sub_y = self.sub_y + @divTrunc(dy * lerp, 256);

        self.prev_x = self.display_x;
        self.prev_y = self.display_y;
        self.display_x = @divTrunc(self.sub_x + P / 2, P);
        self.display_y = @divTrunc(self.sub_y + P / 2, P);

        if (self.display_x < 0) self.display_x = 0;
        if (self.display_y < 0) self.display_y = 0;
        if (self.display_x >= scr_w) self.display_x = scr_w - 1;
        if (self.display_y >= scr_h) self.display_y = scr_h - 1;

        self.velocity_x = self.display_x - self.prev_x;
        self.velocity_y = self.display_y - self.prev_y;
        self.is_moving = (self.display_x != self.prev_x or self.display_y != self.prev_y);
    }

    pub fn positionChanged(self: *const SmoothCursorState) bool {
        return self.display_x != self.prev_x or self.display_y != self.prev_y;
    }

    pub fn snapTo(self: *SmoothCursorState, x: i32, y: i32) void {
        const P: i32 = 256;
        self.target_x = x;
        self.target_y = y;
        self.display_x = x;
        self.display_y = y;
        self.sub_x = x * P;
        self.sub_y = y * P;
        self.prev_x = x;
        self.prev_y = y;
        self.is_moving = false;
    }
};

pub const CURSOR_W: usize = 12;
pub const CURSOR_H: usize = 19;

// 0=transparent, 1=fill(white), 2=outline(black)
pub const modern_cursor_bitmap = [CURSOR_H][CURSOR_W]u2{
    .{ 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0 },
    .{ 2, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
    .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0 },
    .{ 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 0 },
    .{ 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 0 },
    .{ 2, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0 },
    .{ 2, 1, 1, 2, 1, 1, 2, 0, 0, 0, 0, 0 },
    .{ 2, 1, 2, 0, 2, 1, 1, 2, 0, 0, 0, 0 },
    .{ 2, 2, 0, 0, 2, 1, 1, 2, 0, 0, 0, 0 },
    .{ 0, 0, 0, 0, 0, 2, 1, 1, 2, 0, 0, 0 },
    .{ 0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0 },
    .{ 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0 },
};
