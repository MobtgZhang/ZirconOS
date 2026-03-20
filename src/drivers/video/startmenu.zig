//! Start Menu Renderer
//! Renders theme-specific start menus for the ZirconOS desktop.
//! Each theme (Classic, Luna, Aero, Modern, Fluent, SunValley) has
//! a distinct visual style matching the corresponding Windows era.

const fb = @import("framebuffer.zig");
const display = @import("display.zig");
const icons = @import("icons.zig");

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

pub const MenuStyle = enum(u8) {
    classic = 0,
    luna = 1,
    aero = 2,
    modern = 3,
    fluent = 4,
    sunvalley = 5,
};

pub const MenuItem = struct {
    label: []const u8,
    icon_id: ?icons.IconId = null,
    separator_after: bool = false,
    bold: bool = false,
};

const left_panel_items = [_]MenuItem{
    .{ .label = "Internet Explorer", .icon_id = .internet, .bold = true },
    .{ .label = "Command Prompt", .icon_id = .my_computer, .separator_after = true },
    .{ .label = "Notepad", .icon_id = .my_documents },
    .{ .label = "Calculator", .icon_id = .my_computer },
    .{ .label = "Paint", .icon_id = .my_documents },
    .{ .label = "Registry Editor", .icon_id = .my_computer, .separator_after = true },
};

const right_panel_items = [_]MenuItem{
    .{ .label = "My Documents", .icon_id = .my_documents, .bold = true },
    .{ .label = "My Computer", .icon_id = .my_computer, .bold = true },
    .{ .label = "Control Panel", .icon_id = .my_computer },
    .{ .label = "Network Places", .icon_id = .network, .separator_after = true },
    .{ .label = "Search", .icon_id = .my_documents },
    .{ .label = "Run...", .icon_id = .my_computer },
};

const bottom_items = [_]MenuItem{
    .{ .label = "Log Off", .icon_id = null },
    .{ .label = "Shut Down", .icon_id = null },
};

var menu_visible: bool = false;
var menu_style: MenuStyle = .classic;
var hover_index: i32 = -1;

pub fn isVisible() bool {
    return menu_visible;
}

pub fn show(style: MenuStyle) void {
    menu_visible = true;
    menu_style = style;
    hover_index = -1;
}

pub fn hide() void {
    menu_visible = false;
    hover_index = -1;
}

pub fn toggle(style: MenuStyle) void {
    if (menu_visible) hide() else show(style);
}

pub fn setHoverIndex(idx: i32) void {
    hover_index = idx;
}

pub fn getMenuRect(scr_h: i32) MenuRect {
    return switch (menu_style) {
        .classic => classicRect(scr_h),
        .luna => lunaRect(scr_h),
        .aero => aeroRect(scr_h),
        .modern => modernRect(scr_h),
        .fluent => fluentRect(scr_h),
        .sunvalley => sunvalleyRect(scr_h),
    };
}

pub const MenuRect = struct {
    x: i32,
    y: i32,
    w: i32,
    h: i32,

    pub fn contains(self: MenuRect, px: i32, py: i32) bool {
        return px >= self.x and px < self.x + self.w and
            py >= self.y and py < self.y + self.h;
    }
};

fn classicRect(scr_h: i32) MenuRect {
    const h: i32 = 320;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 240, .h = h };
}

fn lunaRect(scr_h: i32) MenuRect {
    const h: i32 = 400;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 380, .h = h };
}

fn aeroRect(scr_h: i32) MenuRect {
    const h: i32 = 420;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 380, .h = h };
}

fn modernRect(scr_h: i32) MenuRect {
    const h: i32 = 440;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 360, .h = h };
}

fn fluentRect(scr_h: i32) MenuRect {
    const h: i32 = 440;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 360, .h = h };
}

fn sunvalleyRect(scr_h: i32) MenuRect {
    const h: i32 = 460;
    const w: i32 = 400;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = w, .h = h };
}

pub fn render(scr_w: i32, scr_h: i32) void {
    if (!menu_visible or !fb.isInitialized()) return;

    switch (menu_style) {
        .classic => renderClassic(scr_w, scr_h),
        .luna => renderLuna(scr_w, scr_h),
        .aero => renderAero(scr_w, scr_h),
        .modern => renderModern(scr_w, scr_h),
        .fluent => renderFluent(scr_w, scr_h),
        .sunvalley => renderSunValley(scr_w, scr_h),
    }
}

fn renderClassic(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = classicRect(scr_h);
    const bg = rgb(0xC0, 0xC0, 0xC0);
    const border = rgb(0x80, 0x80, 0x80);
    const header_bg = rgb(0x00, 0x00, 0x80);
    const text_color = rgb(0x00, 0x00, 0x00);
    const header_text = rgb(0xFF, 0xFF, 0xFF);

    fb.fillRect(r.x, r.y, r.w, r.h, bg);
    fb.drawRect(r.x, r.y, r.w, r.h, border);

    fb.draw3DRect(r.x, r.y, r.w, r.h, rgb(0xFF, 0xFF, 0xFF), border);

    const sidebar_w: i32 = 22;
    fb.drawGradientV(r.x + 2, r.y + 2, sidebar_w, r.h - 4, rgb(0x00, 0x00, 0x80), rgb(0x00, 0x00, 0x40));

    fb.drawTextTransparent(r.x + 5, r.y + r.h - 80, "Z", header_text);
    fb.drawTextTransparent(r.x + 5, r.y + r.h - 64, "i", header_text);
    fb.drawTextTransparent(r.x + 5, r.y + r.h - 48, "r", header_text);
    fb.drawTextTransparent(r.x + 5, r.y + r.h - 32, "c", header_text);
    _ = header_bg;

    var iy: i32 = r.y + 6;
    const ix: i32 = r.x + sidebar_w + 6;
    for (left_panel_items) |item| {
        if (iy + 22 > r.y + r.h - 26) break;
        if (item.icon_id) |iid| {
            icons.drawIcon(iid, ix, iy + 2, 1);
        }
        fb.drawTextTransparent(ix + 22, iy + 3, item.label, text_color);
        iy += 22;
        if (item.separator_after) {
            fb.drawHLine(ix, iy, r.w - sidebar_w - 12, border);
            iy += 4;
        }
    }

    const bot_y = r.y + r.h - 24;
    fb.drawHLine(r.x + 2, bot_y, r.w - 4, border);
    fb.drawTextTransparent(r.x + sidebar_w + 8, bot_y + 5, "Shut Down...", text_color);
}

fn renderLuna(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = lunaRect(scr_h);
    const left_bg = rgb(0xFF, 0xFF, 0xFF);
    const right_bg = rgb(0xD3, 0xE5, 0xFA);
    const header_left = rgb(0x00, 0x58, 0xE6);
    const header_right = rgb(0x3A, 0x81, 0xE5);
    const bottom_bg = rgb(0xD4, 0xE7, 0xFF);
    const border = rgb(0x00, 0x3C, 0xA0);
    const text_dark = rgb(0x00, 0x00, 0x00);
    const text_white = rgb(0xFF, 0xFF, 0xFF);
    const sep_color = rgb(0xBF, 0xD7, 0xF4);

    fb.fillRect(r.x + 4, r.y + 4, r.w, r.h, rgb(0x40, 0x40, 0x40));

    fb.fillRect(r.x, r.y, r.w, r.h, left_bg);

    const header_h: i32 = 54;
    fb.drawGradientH(r.x, r.y, r.w, header_h, header_left, header_right);

    fb.fillRect(r.x + 8, r.y + 10, 34, 34, rgb(0xE8, 0xE8, 0xE8));
    fb.drawRect(r.x + 8, r.y + 10, 34, 34, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 50, r.y + 14, "ZirconOS User", text_white);
    fb.drawTextTransparent(r.x + 50, r.y + 32, "Administrator", rgb(0xC0, 0xE0, 0xFF));

    const content_y = r.y + header_h;
    const content_h = r.h - header_h - 36;
    const left_w: i32 = @divTrunc(r.w, 2);

    fb.fillRect(r.x, content_y, left_w, content_h, left_bg);
    fb.fillRect(r.x + left_w, content_y, r.w - left_w, content_h, right_bg);
    fb.drawVLine(r.x + left_w, content_y, content_h, sep_color);

    var iy: i32 = content_y + 8;
    for (left_panel_items) |item| {
        if (iy + 26 > content_y + content_h) break;
        if (item.icon_id) |iid| {
            icons.drawIcon(iid, r.x + 10, iy + 2, 1);
        }
        fb.drawTextTransparent(r.x + 34, iy + 5, item.label, text_dark);
        iy += 26;
        if (item.separator_after) {
            fb.drawHLine(r.x + 8, iy, left_w - 16, sep_color);
            iy += 4;
        }
    }

    iy = content_y + 8;
    for (right_panel_items) |item| {
        if (iy + 26 > content_y + content_h) break;
        if (item.icon_id) |iid| {
            icons.drawIcon(iid, r.x + left_w + 10, iy + 2, 1);
        }
        fb.drawTextTransparent(r.x + left_w + 34, iy + 5, item.label, text_dark);
        iy += 26;
        if (item.separator_after) {
            fb.drawHLine(r.x + left_w + 8, iy, r.w - left_w - 16, sep_color);
            iy += 4;
        }
    }

    const bot_h: i32 = 36;
    const bot_y = r.y + r.h - bot_h;
    fb.fillRect(r.x, bot_y, r.w, bot_h, bottom_bg);
    fb.drawHLine(r.x, bot_y, r.w, sep_color);

    const logoff_x = r.x + r.w - 170;
    fb.drawTextTransparent(logoff_x, bot_y + 10, "Log Off", text_dark);

    const shutdown_x = r.x + r.w - 80;
    fb.fillRoundedRect(shutdown_x - 4, bot_y + 4, 76, 26, 4, rgb(0xE0, 0x40, 0x30));
    fb.drawTextTransparent(shutdown_x + 4, bot_y + 10, "Shut Down", text_white);

    fb.drawRect(r.x, r.y, r.w, r.h, border);
}

fn renderAero(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = aeroRect(scr_h);
    const glass_bg = rgb(0x20, 0x30, 0x50);
    const content_bg = rgb(0xF0, 0xF0, 0xF0);
    const text_color = rgb(0x00, 0x00, 0x00);
    const text_white = rgb(0xFF, 0xFF, 0xFF);

    fb.fillRect(r.x + 3, r.y + 3, r.w, r.h, rgb(0x10, 0x10, 0x10));

    fb.fillRect(r.x, r.y, r.w, r.h, glass_bg);
    fb.fillRect(r.x + 2, r.y + 2, r.w - 4, r.h - 4, content_bg);

    const search_y = r.y + r.h - 40;
    fb.fillRect(r.x + 2, search_y, r.w - 4, 38, rgb(0xE8, 0xE8, 0xE8));
    fb.drawRect(r.x + 10, search_y + 8, r.w - 130, 22, rgb(0xA0, 0xA0, 0xA0));
    fb.fillRect(r.x + 11, search_y + 9, r.w - 132, 20, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 16, search_y + 12, "Search programs and files", rgb(0xA0, 0xA0, 0xA0));

    const btn_x = r.x + r.w - 108;
    fb.fillRoundedRect(btn_x, search_y + 4, 96, 28, 4, rgb(0xE0, 0x40, 0x30));
    fb.drawTextTransparent(btn_x + 12, search_y + 10, "Shut Down", text_white);

    var iy: i32 = r.y + 12;
    for (left_panel_items) |item| {
        if (iy + 26 > search_y - 4) break;
        if (item.icon_id) |iid| {
            icons.drawIcon(iid, r.x + 14, iy + 2, 1);
        }
        fb.drawTextTransparent(r.x + 38, iy + 5, item.label, text_color);
        iy += 26;
        if (item.separator_after) {
            fb.drawHLine(r.x + 8, iy, r.w - 16, rgb(0xD0, 0xD0, 0xD0));
            iy += 4;
        }
    }

    fb.drawRect(r.x, r.y, r.w, r.h, rgb(0x50, 0x78, 0xA8));
}

fn renderModern(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = modernRect(scr_h);
    const bg = rgb(0x00, 0x78, 0xD7);
    const tile_bg = rgb(0x00, 0x90, 0xF0);
    const text_color = rgb(0xFF, 0xFF, 0xFF);

    fb.fillRect(r.x, r.y, r.w, r.h, bg);

    const tile_w: i32 = 100;
    const tile_h: i32 = 80;
    const gap: i32 = 8;
    const cols: i32 = 3;

    var ty: i32 = r.y + 50;
    var row: i32 = 0;
    while (row < 4) : (row += 1) {
        var col: i32 = 0;
        while (col < cols) : (col += 1) {
            const tx = r.x + 16 + col * (tile_w + gap);
            fb.fillRect(tx, ty, tile_w, tile_h, tile_bg);

            const tile_items = [_][]const u8{
                "Desktop",      "Mail",         "IE",
                "Files",        "Settings",     "Calculator",
                "Notepad",      "CMD",          "Registry",
                "Network",      "Audio",        "Info",
            };
            const idx: usize = @intCast(row * cols + col);
            if (idx < tile_items.len) {
                fb.drawTextCentered(tx, ty + tile_h - 20, tile_w, 16, tile_items[idx], text_color);
            }
        }
        ty += tile_h + gap;
    }

    fb.drawTextTransparent(r.x + 16, r.y + 16, "Start", text_color);

    const user_y = r.y + r.h - 50;
    fb.drawTextTransparent(r.x + 16, user_y, "ZirconOS User", text_color);
    fb.fillRoundedRect(r.x + r.w - 90, user_y - 4, 76, 24, 4, rgb(0x00, 0x60, 0xB0));
    fb.drawTextTransparent(r.x + r.w - 80, user_y + 2, "Power", text_color);
}

fn renderFluent(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = fluentRect(scr_h);
    const bg = rgb(0x20, 0x20, 0x20);
    const accent = rgb(0x00, 0x67, 0xC0);
    const text_color = rgb(0xFF, 0xFF, 0xFF);
    const text_dim = rgb(0xA0, 0xA0, 0xA0);

    fb.fillRect(r.x, r.y, r.w, r.h, bg);

    const tile_w: i32 = 96;
    const tile_h: i32 = 72;
    const gap: i32 = 6;
    const cols: i32 = 3;
    const tile_bg = rgb(0x30, 0x30, 0x30);

    var ty: i32 = r.y + 50;
    var row: i32 = 0;
    while (row < 4) : (row += 1) {
        var col: i32 = 0;
        while (col < cols) : (col += 1) {
            const tx = r.x + 16 + col * (tile_w + gap);
            fb.fillRoundedRect(tx, ty, tile_w, tile_h, 4, tile_bg);

            const items_f = [_][]const u8{
                "Edge",    "Mail",       "Files",
                "Store",   "Settings",   "Calc",
                "Photos",  "Terminal",   "Registry",
                "Network", "Sound",      "Info",
            };
            const idx: usize = @intCast(row * cols + col);
            if (idx < items_f.len) {
                fb.drawTextCentered(tx, ty + tile_h - 20, tile_w, 16, items_f[idx], text_color);
            }
        }
        ty += tile_h + gap;
    }

    fb.drawTextTransparent(r.x + 16, r.y + 16, "Pinned", text_dim);

    const bot_y = r.y + r.h - 50;
    fb.drawHLine(r.x + 8, bot_y, r.w - 16, rgb(0x40, 0x40, 0x40));

    fb.fillRoundedRect(r.x + 12, bot_y + 8, 36, 36, 18, accent);
    fb.drawTextTransparent(r.x + 24, bot_y + 18, "U", text_color);
    fb.drawTextTransparent(r.x + 56, bot_y + 16, "ZirconOS User", text_color);

    fb.fillRoundedRect(r.x + r.w - 80, bot_y + 12, 64, 28, 4, rgb(0x40, 0x40, 0x40));
    fb.drawTextTransparent(r.x + r.w - 68, bot_y + 18, "Power", text_color);

    fb.drawRect(r.x, r.y, r.w, r.h, rgb(0x40, 0x40, 0x40));
}

fn renderSunValley(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = sunvalleyRect(scr_h);
    const bg = rgb(0xF3, 0xF3, 0xF3);
    const accent = rgb(0x00, 0x67, 0xC0);
    const text_color = rgb(0x00, 0x00, 0x00);
    const text_dim = rgb(0x60, 0x60, 0x60);

    fb.fillRect(r.x + 4, r.y + 4, r.w, r.h, rgb(0xC0, 0xC0, 0xC0));
    fb.fillRoundedRect(r.x, r.y, r.w, r.h, 8, bg);

    const search_y = r.y + 12;
    fb.fillRoundedRect(r.x + 16, search_y, r.w - 32, 30, 8, rgb(0xFB, 0xFB, 0xFB));
    fb.drawTextTransparent(r.x + 28, search_y + 7, "Type here to search", text_dim);

    fb.drawTextTransparent(r.x + 16, search_y + 44, "Pinned", text_color);

    const tile_start_y = search_y + 64;
    const tile_w: i32 = 70;
    const tile_h: i32 = 64;
    const gap: i32 = 8;
    const cols: i32 = 4;
    const tile_bg = rgb(0xE8, 0xE8, 0xE8);

    var row: i32 = 0;
    while (row < 3) : (row += 1) {
        var col: i32 = 0;
        while (col < cols) : (col += 1) {
            const tx = r.x + 24 + col * (tile_w + gap);
            const ty = tile_start_y + row * (tile_h + gap);
            fb.fillRoundedRect(tx, ty, tile_w, tile_h, 6, tile_bg);

            const items_sv = [_][]const u8{
                "Edge",    "Mail",     "Files",   "Store",
                "Photos",  "Settings", "Calc",    "Terminal",
                "Network", "Sound",    "Registry","Info",
            };
            const idx: usize = @intCast(row * cols + col);
            if (idx < items_sv.len) {
                fb.drawTextCentered(tx, ty + tile_h - 18, tile_w, 16, items_sv[idx], text_color);
            }
        }
    }

    fb.drawTextTransparent(r.x + 16, tile_start_y + 3 * (tile_h + gap) + 8, "Recommended", text_color);

    const rec_y = tile_start_y + 3 * (tile_h + gap) + 28;
    const rec_items = [_][]const u8{ "Recent Document.txt", "Setup.exe", "System32 folder" };
    for (rec_items, 0..) |item, idx| {
        const ry = rec_y + @as(i32, @intCast(idx)) * 24;
        if (ry + 24 > r.y + r.h - 50) break;
        fb.drawTextTransparent(r.x + 30, ry + 4, item, text_dim);
    }

    const bot_y = r.y + r.h - 50;
    fb.drawHLine(r.x + 12, bot_y, r.w - 24, rgb(0xE0, 0xE0, 0xE0));

    fb.fillRoundedRect(r.x + 16, bot_y + 8, 32, 32, 16, accent);
    fb.drawTextTransparent(r.x + 28, bot_y + 16, "U", rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 56, bot_y + 16, "ZirconOS User", text_color);

    fb.fillRoundedRect(r.x + r.w - 80, bot_y + 12, 64, 28, 6, rgb(0xE0, 0xE0, 0xE0));
    fb.drawTextTransparent(r.x + r.w - 68, bot_y + 18, "Power", text_color);

    fb.drawRect(r.x, r.y, r.w, r.h, rgb(0xD0, 0xD0, 0xD0));
}
