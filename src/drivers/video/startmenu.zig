//! Start Menu Renderer
//! Renders theme-specific start menus for the ZirconOS desktop.
//! Each theme (Classic, Luna, Aero, Modern, Fluent, SunValley) has
//! a distinct visual style with original ZirconOS design.

const fb = @import("framebuffer.zig");
const display = @import("display.zig");
const icons = @import("icons.zig");

fn getIconStyle() icons.ThemeStyle {
    return switch (menu_style) {
        .classic => .classic,
        .luna => .luna,
        .aero => .aero,
        .modern => .modern,
        .fluent => .fluent,
        .sunvalley => .sunvalley,
    };
}

fn drawMenuIcon(id: icons.IconId, x: i32, y: i32, scale: u32) void {
    icons.drawThemedIcon(id, x, y, scale, getIconStyle());
}

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

// ── Aero (Win7) menu items: classic two-column with search box ──
const aero_left_items = [_]MenuItem{
    .{ .label = "Internet Explorer", .icon_id = .browser, .bold = true },
    .{ .label = "Windows Media Player", .icon_id = .documents, .separator_after = true },
    .{ .label = "Terminal", .icon_id = .computer },
    .{ .label = "Notepad", .icon_id = .documents },
    .{ .label = "Calculator", .icon_id = .computer },
    .{ .label = "Paint", .icon_id = .documents },
    .{ .label = "Registry Editor", .icon_id = .computer, .separator_after = true },
};
const aero_right_items = [_]MenuItem{
    .{ .label = "Documents", .icon_id = .documents, .bold = true },
    .{ .label = "Computer", .icon_id = .computer, .bold = true },
    .{ .label = "Control Panel", .icon_id = .computer },
    .{ .label = "Network", .icon_id = .network, .separator_after = true },
    .{ .label = "Search", .icon_id = .documents },
    .{ .label = "Run...", .icon_id = .computer },
};

// ── Fluent (Win10) menu items: tile-centric layout ──
const fluent_left_items = [_]MenuItem{
    .{ .label = "Edge Browser", .icon_id = .browser, .bold = true },
    .{ .label = "Mail", .icon_id = .documents },
    .{ .label = "Calendar", .icon_id = .documents, .separator_after = true },
    .{ .label = "File Explorer", .icon_id = .computer },
    .{ .label = "Settings", .icon_id = .computer },
    .{ .label = "Store", .icon_id = .browser, .separator_after = true },
};

// ── Sun Valley (Win11) items: centered grid, modern apps ──
const sv_pinned_items = [_]MenuItem{
    .{ .label = "Edge", .icon_id = .browser },
    .{ .label = "Files", .icon_id = .computer },
    .{ .label = "Terminal", .icon_id = .computer },
    .{ .label = "Settings", .icon_id = .computer },
    .{ .label = "Store", .icon_id = .browser },
    .{ .label = "Photos", .icon_id = .documents },
    .{ .label = "Mail", .icon_id = .documents },
    .{ .label = "Teams", .icon_id = .browser },
    .{ .label = "Widgets", .icon_id = .documents },
    .{ .label = "Clock", .icon_id = .computer },
};

// ── Legacy (Classic/Luna/Modern) shared items ──
const left_panel_items = [_]MenuItem{
    .{ .label = "ZirconOS Browser", .icon_id = .browser, .bold = true },
    .{ .label = "Terminal", .icon_id = .computer, .separator_after = true },
    .{ .label = "Notepad", .icon_id = .documents },
    .{ .label = "Calculator", .icon_id = .computer },
    .{ .label = "Paint", .icon_id = .documents },
    .{ .label = "Registry Editor", .icon_id = .computer, .separator_after = true },
};

const right_panel_items = [_]MenuItem{
    .{ .label = "Documents", .icon_id = .documents, .bold = true },
    .{ .label = "Computer", .icon_id = .computer, .bold = true },
    .{ .label = "Control Panel", .icon_id = .computer },
    .{ .label = "Network", .icon_id = .network, .separator_after = true },
    .{ .label = "Search", .icon_id = .documents },
    .{ .label = "Run...", .icon_id = .computer },
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

pub fn getMenuRect(scr_w: i32, scr_h: i32) MenuRect {
    return switch (menu_style) {
        .classic => classicRect(scr_h),
        .luna => lunaRect(scr_h),
        .aero => aeroRect(scr_h),
        .modern => modernRect(scr_h),
        .fluent => fluentRect(scr_h),
        .sunvalley => sunvalleyRect(scr_w, scr_h),
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
    return .{ .x = 0, .y = scr_h - 40 - h, .w = 380, .h = h };
}

fn modernRect(scr_h: i32) MenuRect {
    const h: i32 = 440;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = 360, .h = h };
}

fn fluentRect(scr_h: i32) MenuRect {
    const h: i32 = 440;
    return .{ .x = 0, .y = scr_h - 48 - h, .w = 360, .h = h };
}

fn sunvalleyRect(scr_w: i32, scr_h: i32) MenuRect {
    const h: i32 = 460;
    const w: i32 = 400;
    const menu_x = @divTrunc(scr_w - w, 2);
    return .{ .x = menu_x, .y = scr_h - 48 - h, .w = w, .h = h };
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
            drawMenuIcon(iid, ix, iy + 2, 1);
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
            drawMenuIcon(iid, r.x + 10, iy + 2, 1);
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
            drawMenuIcon(iid, r.x + left_w + 10, iy + 2, 1);
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
    const glass_border = rgb(0x40, 0x68, 0xA0);
    const content_bg = rgb(0xF5, 0xF5, 0xF5);
    const right_bg = rgb(0xE8, 0xED, 0xF4);
    const text_color = rgb(0x1A, 0x1A, 0x1A);
    const text_white = rgb(0xFF, 0xFF, 0xFF);
    const sep_color = rgb(0xD8, 0xD8, 0xD8);

    // Soft shadow behind menu
    fb.blendTintRect(r.x + 4, r.y + 4, r.w, r.h, rgb(0x00, 0x00, 0x00), 30, 255);

    // Glass border frame: blur the background behind the menu border region
    fb.boxBlurRect(r.x, r.y, r.w, 4, 8, 2);
    fb.boxBlurRect(r.x, r.y, 4, r.h, 8, 2);
    fb.boxBlurRect(r.x + r.w - 4, r.y, 4, r.h, 8, 2);
    fb.boxBlurRect(r.x, r.y + r.h - 4, r.w, 4, 8, 2);
    fb.blendTintRect(r.x, r.y, r.w, r.h, glass_border, 140, 180);

    fb.fillRect(r.x + 2, r.y + 2, r.w - 4, r.h - 4, content_bg);

    // Header with glass effect
    const header_h: i32 = 56;
    fb.drawGradientH(r.x + 2, r.y + 2, r.w - 4, header_h, rgb(0x40, 0x80, 0xC8), rgb(0x60, 0x98, 0xD8));
    fb.addSpecularBand(r.x + 2, r.y + 2, r.w - 4, @divTrunc(header_h, 3), 25);

    fb.fillRect(r.x + 10, r.y + 10, 38, 38, rgb(0xD0, 0xE0, 0xF0));
    fb.drawRect(r.x + 10, r.y + 10, 38, 38, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 56, r.y + 14, "ZirconOS User", text_white);
    fb.drawTextTransparent(r.x + 56, r.y + 32, "ZirconOS \xc2\xb7 Aero Glass + DWM", rgb(0xE8, 0xF0, 0xFF));

    const content_y = r.y + header_h + 2;
    const search_y = r.y + r.h - 42;
    const content_h = search_y - content_y;
    const left_w: i32 = @divTrunc(r.w * 55, 100);

    fb.fillRect(r.x + 2, content_y, left_w, content_h, content_bg);
    fb.fillRect(r.x + 2 + left_w, content_y, r.w - 4 - left_w, content_h, right_bg);
    fb.drawVLine(r.x + 2 + left_w, content_y, content_h, sep_color);

    var iy: i32 = content_y + 8;
    for (aero_left_items) |item| {
        if (iy + 28 > search_y - 4) break;
        if (item.icon_id) |iid| {
            drawMenuIcon(iid, r.x + 14, iy + 4, 1);
        }
        if (item.bold) {
            fb.drawTextTransparent(r.x + 40, iy + 7, item.label, rgb(0x00, 0x00, 0x00));
        } else {
            fb.drawTextTransparent(r.x + 40, iy + 7, item.label, text_color);
        }
        iy += 28;
        if (item.separator_after) {
            fb.drawHLine(r.x + 10, iy, left_w - 16, sep_color);
            iy += 6;
        }
    }

    iy = content_y + 8;
    for (aero_right_items) |item| {
        if (iy + 28 > search_y - 4) break;
        if (item.icon_id) |iid| {
            drawMenuIcon(iid, r.x + left_w + 12, iy + 4, 1);
        }
        if (item.bold) {
            fb.drawTextTransparent(r.x + left_w + 38, iy + 7, item.label, rgb(0x00, 0x00, 0x00));
        } else {
            fb.drawTextTransparent(r.x + left_w + 38, iy + 7, item.label, text_color);
        }
        iy += 28;
        if (item.separator_after) {
            fb.drawHLine(r.x + left_w + 8, iy, r.w - left_w - 20, sep_color);
            iy += 6;
        }
    }

    fb.fillRect(r.x + 2, search_y, r.w - 4, 40, rgb(0xE0, 0xE8, 0xF0));
    fb.drawHLine(r.x + 2, search_y, r.w - 4, sep_color);

    fb.drawRect(r.x + 10, search_y + 8, r.w - 130, 24, rgb(0xA0, 0xB0, 0xC0));
    fb.fillRect(r.x + 11, search_y + 9, r.w - 132, 22, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 16, search_y + 13, "Search programs and files", rgb(0xA0, 0xA0, 0xA0));

    const btn_x = r.x + r.w - 108;
    fb.fillRoundedRect(btn_x, search_y + 6, 96, 28, 4, rgb(0xE0, 0x40, 0x30));
    fb.drawTextTransparent(btn_x + 12, search_y + 12, "Shut Down", text_white);

    fb.drawRect(r.x, r.y, r.w, r.h, glass_border);
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
    const bg = rgb(0x1E, 0x1E, 0x1E);
    const accent = rgb(0x00, 0x67, 0xC0);
    const text_color = rgb(0xFF, 0xFF, 0xFF);
    const text_dim = rgb(0x99, 0x99, 0x99);

    // Shadow
    fb.fillRect(r.x + 3, r.y + 3, r.w, r.h, rgb(0x0A, 0x0A, 0x0A));

    fb.fillRect(r.x, r.y, r.w, r.h, bg);

    // Accent stripe on left edge
    fb.fillRect(r.x, r.y, 3, r.h, accent);

    fb.drawTextTransparent(r.x + 16, r.y + 6, "Windows 10 - Fluent Design", text_dim);

    // Header with "Pinned" label and "All apps" link
    fb.drawTextTransparent(r.x + 16, r.y + 22, "Pinned", text_color);
    fb.drawTextTransparent(r.x + r.w - 80, r.y + 22, "All apps >", text_dim);

    // Live tiles (Fluent: medium + wide mixed)
    const tile_bg = rgb(0x2D, 0x2D, 0x2D);
    const tile_hover = rgb(0x38, 0x38, 0x38);
    _ = tile_hover;

    // Row 1: wide + medium tiles
    var ty: i32 = r.y + 48;
    fb.fillRoundedRect(r.x + 12, ty, 200, 80, 4, accent);
    fb.drawTextTransparent(r.x + 24, ty + 8, "ZirconOS - Acrylic + Reveal", rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 24, ty + 28, "Microsoft Edge - Fluent", rgb(0xCC, 0xDD, 0xFF));
    fb.drawTextTransparent(r.x + 24, ty + 52, "Latest: v1.0", rgb(0x88, 0xBB, 0xEE));

    fb.fillRoundedRect(r.x + 218, ty, 80, 80, 4, tile_bg);
    fb.drawTextCentered(r.x + 218, ty + 56, 80, 16, "Mail", text_color);

    fb.fillRoundedRect(r.x + 304, ty, 44, 38, 4, tile_bg);
    fb.drawTextCentered(r.x + 304, ty + 20, 44, 16, "Calc", text_dim);
    fb.fillRoundedRect(r.x + 304, ty + 42, 44, 38, 4, tile_bg);
    fb.drawTextCentered(r.x + 304, ty + 60, 44, 16, "Info", text_dim);

    // Row 2: medium tiles
    ty += 86;
    const row2_items = [_]struct { label: []const u8, color: u32 }{
        .{ .label = "Files", .color = rgb(0xCA, 0x8B, 0x02) },
        .{ .label = "Store", .color = rgb(0x00, 0x7A, 0xD1) },
        .{ .label = "Settings", .color = rgb(0x44, 0x44, 0x44) },
        .{ .label = "Terminal", .color = rgb(0x0C, 0x0C, 0x0C) },
    };
    for (row2_items, 0..) |item, i| {
        const tx = r.x + 12 + @as(i32, @intCast(i)) * 86;
        fb.fillRoundedRect(tx, ty, 80, 64, 4, item.color);
        fb.drawTextCentered(tx, ty + 44, 80, 16, item.label, text_color);
    }

    // Row 3: small tiles
    ty += 70;
    const row3_items = [_][]const u8{ "Photos", "Registry", "Network", "Sound" };
    for (row3_items, 0..) |item, i| {
        const tx = r.x + 12 + @as(i32, @intCast(i)) * 86;
        fb.fillRoundedRect(tx, ty, 80, 50, 4, tile_bg);
        fb.drawTextCentered(tx, ty + 30, 80, 16, item, text_dim);
    }

    // "Recommended" section
    ty += 60;
    fb.drawHLine(r.x + 12, ty, r.w - 24, rgb(0x38, 0x38, 0x38));
    ty += 8;
    fb.drawTextTransparent(r.x + 16, ty, "Recommended", text_color);
    ty += 22;

    const rec_items = [_][]const u8{ "Recent Doc.txt", "Setup.exe", "System32" };
    for (rec_items) |item| {
        if (ty + 24 > r.y + r.h - 56) break;
        fb.drawTextTransparent(r.x + 28, ty + 2, item, text_dim);
        ty += 22;
    }

    // Bottom bar (User + Power)
    const bot_y = r.y + r.h - 52;
    fb.drawHLine(r.x + 8, bot_y, r.w - 16, rgb(0x38, 0x38, 0x38));

    fb.fillRoundedRect(r.x + 12, bot_y + 8, 32, 32, 16, accent);
    fb.drawTextTransparent(r.x + 24, bot_y + 16, "U", text_color);
    fb.drawTextTransparent(r.x + 52, bot_y + 16, "ZirconOS User", text_color);

    fb.fillRoundedRect(r.x + r.w - 76, bot_y + 12, 60, 28, 4, rgb(0x38, 0x38, 0x38));
    fb.drawTextTransparent(r.x + r.w - 62, bot_y + 18, "Power", text_color);

    fb.drawRect(r.x, r.y, r.w, r.h, rgb(0x44, 0x44, 0x44));
}

fn renderSunValley(scr_w: i32, scr_h: i32) void {
    const r = sunvalleyRect(scr_w, scr_h);
    const bg = rgb(0x2C, 0x2C, 0x2C);
    const accent = rgb(0x4C, 0xB0, 0xE8);
    const text_color = rgb(0xFF, 0xFF, 0xFF);
    const text_dim = rgb(0x99, 0x99, 0x99);
    const card_bg = rgb(0x38, 0x38, 0x38);

    // Rounded shadow
    fb.fillRoundedRect(r.x + 3, r.y + 3, r.w, r.h, 8, rgb(0x0A, 0x0A, 0x0A));
    fb.fillRoundedRect(r.x, r.y, r.w, r.h, 8, bg);

    // Search bar (centered, rounded pill)
    const search_y = r.y + 14;
    fb.fillRoundedRect(r.x + 20, search_y, r.w - 40, 32, 16, rgb(0x3A, 0x3A, 0x3A));
    fb.drawRect(r.x + 20, search_y, r.w - 40, 32, rgb(0x50, 0x50, 0x50));
    fb.drawTextTransparent(r.x + 40, search_y + 8, "S", rgb(0x88, 0x88, 0x88));
    fb.drawTextTransparent(r.x + 56, search_y + 8, "Type here to search", text_dim);

    // "Pinned" header with "All apps >" link
    fb.drawTextTransparent(r.x + 20, search_y + 40, "Windows 11 - Sun Valley", text_dim);
    fb.drawTextTransparent(r.x + 20, search_y + 56, "Pinned", text_color);
    fb.drawTextTransparent(r.x + r.w - 84, search_y + 56, "All apps >", text_dim);

    // Pinned app grid (5 columns, Win11 style)
    const tile_start_y = search_y + 78;
    const tile_w: i32 = 60;
    const tile_h: i32 = 64;
    const gap: i32 = 10;
    const cols: i32 = 5;

    const pin_items = [_]struct { label: []const u8, color: u32 }{
        .{ .label = "Edge", .color = rgb(0x00, 0x78, 0xD4) },
        .{ .label = "Files", .color = rgb(0xCA, 0x8B, 0x02) },
        .{ .label = "Terminal", .color = rgb(0x0C, 0x0C, 0x0C) },
        .{ .label = "Settings", .color = rgb(0x44, 0x44, 0x44) },
        .{ .label = "Store", .color = rgb(0x00, 0x7A, 0xD1) },
        .{ .label = "Photos", .color = rgb(0x88, 0x44, 0xCC) },
        .{ .label = "Mail", .color = rgb(0x00, 0x67, 0xC0) },
        .{ .label = "Teams", .color = rgb(0x50, 0x50, 0xD0) },
        .{ .label = "Widgets", .color = rgb(0x4C, 0xB0, 0xE8) },
        .{ .label = "Clock", .color = rgb(0x20, 0x60, 0xA0) },
        .{ .label = "Camera", .color = rgb(0x60, 0x20, 0x80) },
        .{ .label = "Calc", .color = rgb(0x00, 0x60, 0x88) },
    };

    for (pin_items, 0..) |item, idx| {
        const row: i32 = @intCast(idx / @as(usize, @intCast(cols)));
        const col: i32 = @intCast(idx % @as(usize, @intCast(cols)));
        const tx = r.x + 20 + col * (tile_w + gap);
        const ty = tile_start_y + row * (tile_h + gap);

        // Icon circle
        const icon_cx = tx + @divTrunc(tile_w, 2);
        const icon_cy = ty + 16;
        fb.fillRoundedRect(icon_cx - 14, icon_cy - 14, 28, 28, 14, item.color);

        // Label centered below
        fb.drawTextCentered(tx, ty + tile_h - 18, tile_w, 16, item.label, text_dim);
    }

    // Separator
    const sep_y = tile_start_y + 2 * (tile_h + gap) + 12;
    fb.drawHLine(r.x + 16, sep_y, r.w - 32, rgb(0x44, 0x44, 0x44));

    // "Recommended" section
    fb.drawTextTransparent(r.x + 20, sep_y + 10, "Recommended", text_color);
    fb.drawTextTransparent(r.x + r.w - 60, sep_y + 10, "More >", text_dim);

    // Recommended items (cards with icons)
    var ry: i32 = sep_y + 30;
    const rec_items = [_]struct { name: []const u8, detail: []const u8 }{
        .{ .name = "Recent Doc.txt", .detail = "Yesterday" },
        .{ .name = "Setup.exe", .detail = "2 days ago" },
        .{ .name = "System32", .detail = "Last week" },
    };
    for (rec_items) |item| {
        if (ry + 36 > r.y + r.h - 56) break;
        fb.fillRoundedRect(r.x + 16, ry, r.w - 32, 32, 6, card_bg);
        fb.drawTextTransparent(r.x + 28, ry + 4, item.name, text_color);
        fb.drawTextTransparent(r.x + r.w - 100, ry + 4, item.detail, text_dim);
        ry += 38;
    }

    // Bottom bar
    const bot_y = r.y + r.h - 52;
    fb.drawHLine(r.x + 12, bot_y, r.w - 24, rgb(0x44, 0x44, 0x44));

    fb.fillRoundedRect(r.x + 16, bot_y + 8, 32, 32, 16, accent);
    fb.drawTextTransparent(r.x + 28, bot_y + 16, "U", rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 56, bot_y + 16, "ZirconOS User", text_color);

    fb.fillRoundedRect(r.x + r.w - 76, bot_y + 12, 60, 28, 6, rgb(0x38, 0x38, 0x38));
    fb.drawTextTransparent(r.x + r.w - 62, bot_y + 18, "Power", text_color);

    // Rounded border
    fb.drawRect(r.x, r.y, r.w, r.h, rgb(0x50, 0x50, 0x50));
}
