//! Embedded pixel-art desktop icons (16x16 indexed color)
//! Each icon is a 16x16 grid; values map to a per-icon palette.
//! 0 = transparent. The renderer skips transparent pixels so the
//! desktop background shows through.

const fb = @import("framebuffer.zig");

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

// ── My Computer ──
// A beige PC tower with a blue monitor screen

const my_computer_palette = [_]u32{
    0, // 0: transparent
    rgb(0xD4, 0xD0, 0xC8), // 1: beige case
    rgb(0x80, 0x80, 0x80), // 2: dark border
    rgb(0x00, 0x00, 0x80), // 3: blue screen
    rgb(0x00, 0x50, 0xD0), // 4: screen highlight
    rgb(0xFF, 0xFF, 0xFF), // 5: white highlight
    rgb(0x40, 0x40, 0x40), // 6: dark grey
    rgb(0xA0, 0xA0, 0xA0), // 7: medium grey
    rgb(0x00, 0x80, 0x00), // 8: power LED green
};

const my_computer_data = [16][16]u4{
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
};

// ── My Documents ──
// A yellow folder with a blue document inside

const my_documents_palette = [_]u32{
    0, // 0: transparent
    rgb(0xFF, 0xE0, 0x80), // 1: folder yellow
    rgb(0xE0, 0xB0, 0x30), // 2: folder dark
    rgb(0xFF, 0xF0, 0xA0), // 3: folder highlight
    rgb(0xFF, 0xFF, 0xFF), // 4: document white
    rgb(0x00, 0x00, 0x80), // 5: text lines
    rgb(0xC0, 0x90, 0x20), // 6: folder edge
    rgb(0x80, 0x80, 0x80), // 7: shadow
};

const my_documents_data = [16][16]u4{
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
};

// ── Network Places ──
// Two connected computers

const network_palette = [_]u32{
    0, // 0: transparent
    rgb(0x40, 0x60, 0xA0), // 1: blue body
    rgb(0x20, 0x40, 0x80), // 2: dark blue
    rgb(0x00, 0xA0, 0xD0), // 3: screen blue
    rgb(0xD4, 0xD0, 0xC8), // 4: beige
    rgb(0xFF, 0xFF, 0x00), // 5: cable yellow
    rgb(0x80, 0x80, 0x80), // 6: grey
    rgb(0xFF, 0xFF, 0xFF), // 7: white
};

const network_data = [16][16]u4{
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
};

// ── Recycle Bin ──
// A trash can with lid

const recycle_palette = [_]u32{
    0, // 0: transparent
    rgb(0x80, 0x80, 0x80), // 1: grey body
    rgb(0xA0, 0xA0, 0xA0), // 2: light grey
    rgb(0x60, 0x60, 0x60), // 3: dark grey
    rgb(0xC0, 0xC0, 0xC0), // 4: highlight
    rgb(0x40, 0x40, 0x40), // 5: shadow
    rgb(0xFF, 0xFF, 0xFF), // 6: white
    rgb(0x00, 0x80, 0x40), // 7: green recycle
};

const recycle_data = [16][16]u4{
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
};

// ── Internet Explorer ──
// Blue 'e' icon

const internet_palette = [_]u32{
    0, // 0: transparent
    rgb(0x00, 0x60, 0xE0), // 1: blue
    rgb(0x00, 0x40, 0xA0), // 2: dark blue
    rgb(0x00, 0x80, 0xFF), // 3: light blue
    rgb(0xFF, 0xFF, 0xFF), // 4: white
    rgb(0xFF, 0xC0, 0x00), // 5: gold ring
    rgb(0xE0, 0xA0, 0x00), // 6: dark gold
    rgb(0x00, 0x50, 0xC0), // 7: mid blue
};

const internet_data = [16][16]u4{
    .{ 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0 },
    .{ 0, 0, 0, 5, 6, 0, 0, 0, 0, 0, 6, 5, 0, 0, 0, 0 },
    .{ 0, 0, 5, 0, 0, 2, 2, 2, 2, 2, 0, 0, 5, 0, 0, 0 },
    .{ 0, 5, 0, 0, 2, 1, 1, 1, 1, 1, 2, 0, 0, 5, 0, 0 },
    .{ 0, 5, 0, 2, 1, 3, 3, 3, 1, 1, 1, 2, 0, 5, 0, 0 },
    .{ 5, 0, 0, 2, 1, 3, 1, 1, 1, 1, 1, 2, 0, 0, 5, 0 },
    .{ 5, 0, 0, 2, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 5, 0 },
    .{ 5, 0, 0, 2, 1, 1, 3, 3, 3, 2, 0, 0, 0, 0, 5, 0 },
    .{ 5, 0, 0, 2, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0, 5, 0 },
    .{ 5, 0, 0, 2, 1, 1, 1, 1, 1, 1, 1, 2, 0, 0, 5, 0 },
    .{ 0, 5, 0, 2, 1, 3, 3, 3, 3, 1, 1, 2, 0, 5, 0, 0 },
    .{ 0, 5, 0, 0, 2, 1, 1, 1, 1, 1, 2, 0, 0, 5, 0, 0 },
    .{ 0, 0, 5, 0, 0, 2, 2, 2, 2, 2, 0, 0, 5, 0, 0, 0 },
    .{ 0, 0, 0, 5, 6, 0, 0, 0, 0, 0, 6, 5, 0, 0, 0, 0 },
    .{ 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0 },
    .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
};

// ── Public Icon Types ──

pub const IconId = enum(u8) {
    my_computer = 0,
    my_documents = 1,
    network = 2,
    recycle_bin = 3,
    internet = 4,
};

pub const ICON_PX_SIZE: u32 = 16;

pub fn drawIcon(id: IconId, screen_x: i32, screen_y: i32, scale: u32) void {
    const data = switch (id) {
        .my_computer => &my_computer_data,
        .my_documents => &my_documents_data,
        .network => &network_data,
        .recycle_bin => &recycle_data,
        .internet => &internet_data,
    };
    const palette: []const u32 = switch (id) {
        .my_computer => &my_computer_palette,
        .my_documents => &my_documents_palette,
        .network => &network_palette,
        .recycle_bin => &recycle_palette,
        .internet => &internet_palette,
    };

    const s: i32 = if (scale < 1) 1 else @intCast(scale);

    for (data, 0..) |row, dy| {
        for (row, 0..) |idx, dx| {
            if (idx == 0) continue;
            const color = palette[@intCast(idx)];
            const px = screen_x + @as(i32, @intCast(dx)) * s;
            const py = screen_y + @as(i32, @intCast(dy)) * s;
            if (s == 1) {
                if (px >= 0 and py >= 0) {
                    fb.putPixel32(@intCast(px), @intCast(py), color);
                }
            } else {
                fb.fillRect(px, py, s, s, color);
            }
        }
    }
}

pub fn getIconTotalSize(scale: u32) i32 {
    return @intCast(ICON_PX_SIZE * (if (scale < 1) 1 else scale));
}
