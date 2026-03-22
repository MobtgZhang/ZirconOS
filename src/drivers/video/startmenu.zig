//! Start Menu Renderer
//! Renders theme-specific start menus for the ZirconOS desktop.
//! Each theme (Classic, Luna, Aero, Modern, Fluent, SunValley) has
//! a distinct visual style with original ZirconOS design.

const std = @import("std");
const fb = @import("framebuffer.zig");
const icons = @import("icons.zig");
const klog = @import("../../rtl/klog.zig");

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
    return b | (g << 8) | (r << 16);
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

// ── Luna XP：两列 + 搜索 + 底栏（原误放在 Aero 的「蓝顶」布局）──
const luna_two_col_left = [_]MenuItem{
    .{ .label = "Internet Explorer", .icon_id = .browser, .bold = true },
    .{ .label = "Windows Media Player", .icon_id = .documents, .separator_after = true },
    .{ .label = "Terminal", .icon_id = .computer },
    .{ .label = "Notepad", .icon_id = .documents },
    .{ .label = "Calculator", .icon_id = .computer },
    .{ .label = "Paint", .icon_id = .documents },
    .{ .label = "Registry Editor", .icon_id = .computer, .separator_after = true },
};
const luna_two_col_right = [_]MenuItem{
    .{ .label = "Documents", .icon_id = .documents, .bold = true },
    .{ .label = "Pictures", .icon_id = .documents, .bold = true },
    .{ .label = "Music", .icon_id = .documents, .bold = true },
    .{ .label = "Games", .icon_id = .computer, .separator_after = true },
    .{ .label = "Computer", .icon_id = .computer, .bold = true },
    .{ .label = "Network", .icon_id = .network },
    .{ .label = "Control Panel", .icon_id = .computer },
    .{ .label = "Devices and Printers", .icon_id = .computer },
    .{ .label = "Default Programs", .icon_id = .computer },
    .{ .label = "Help and Support", .icon_id = .documents, .separator_after = true },
    .{ .label = "Run...", .icon_id = .computer },
};

const LUNA_HEADER_H: i32 = 62;
const LUNA_LEFT_W: i32 = 212;
const LUNA_ROW_H: i32 = 26;
const LUNA_SEARCH_H: i32 = 50;
const LUNA_FOOTER_H: i32 = 46;
const LUNA_IDX_ALL_PROGRAMS: i32 = 50;

// ── Aero (Win7) 毛玻璃：独立列项与布局常数 ──
const aero7_left = [_]MenuItem{
    .{ .label = "Internet Explorer", .icon_id = .browser, .bold = true },
    .{ .label = "Windows Media Player", .icon_id = .documents, .separator_after = true },
    .{ .label = "Terminal", .icon_id = .computer },
    .{ .label = "Notepad", .icon_id = .documents },
    .{ .label = "Calculator", .icon_id = .computer },
    .{ .label = "Paint", .icon_id = .documents },
};
const aero7_right = [_]MenuItem{
    .{ .label = "Documents", .icon_id = .documents, .bold = true },
    .{ .label = "Pictures", .icon_id = .documents, .bold = true },
    .{ .label = "Music", .icon_id = .documents, .bold = true },
    .{ .label = "Games", .icon_id = .computer, .separator_after = true },
    .{ .label = "Computer", .icon_id = .computer, .bold = true },
    .{ .label = "Network", .icon_id = .network },
    .{ .label = "Control Panel", .icon_id = .computer },
    .{ .label = "Devices and Printers", .icon_id = .computer },
    .{ .label = "Help and Support", .icon_id = .documents, .separator_after = true },
    .{ .label = "Run...", .icon_id = .computer },
};

const AERO7_HEADER_H: i32 = 52;
const AERO7_LEFT_W: i32 = 200;
const AERO7_ROW_H: i32 = 24;
const AERO7_SEARCH_H: i32 = 46;
const AERO7_FOOTER_H: i32 = 44;
const AERO7_RAIL_W: i32 = 52;
const AERO7_IDX_ALL: i32 = 48;

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

/// Windows 2000–style 左列（程序与系统）
const w2k_left_items = [_]MenuItem{
    .{ .label = "Programs", .icon_id = .computer, .separator_after = false },
    .{ .label = "Documents", .icon_id = .documents, .separator_after = false },
    .{ .label = "Settings", .icon_id = .computer, .separator_after = false },
    .{ .label = "Find", .icon_id = .documents, .separator_after = false },
    .{ .label = "Help", .icon_id = .documents, .separator_after = false },
    .{ .label = "Run...", .icon_id = .computer, .separator_after = false },
};

/// 右列（位置与硬件）
const w2k_right_items = [_]MenuItem{
    .{ .label = "My Computer", .icon_id = .computer, .bold = true },
    .{ .label = "My Documents", .icon_id = .documents, .bold = true },
    .{ .label = "My Network Places", .icon_id = .network, .separator_after = true },
    .{ .label = "Control Panel", .icon_id = .computer },
    .{ .label = "Printers and Faxes", .icon_id = .documents },
};

/// 点击「开始」菜单项后的动作（由 display 处理关机 / 注销）
pub const MenuAction = enum {
    none,
    shutdown,
    standby,
    logoff,
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

/// 鼠标在开始菜单内移动时更新高亮（Classic / Luna / Aero 完整命中）。
/// 若高亮行变化则返回 true，供 shell 决定是否需要整屏重绘。
pub fn updatePointerHover(px: i32, py: i32, scr_w: i32, scr_h: i32) bool {
    if (!menu_visible) return false;
    if (menu_style == .luna) {
        const prev = hover_index;
        hover_index = lunaTwoColHoverIndex(px, py, scr_w, scr_h);
        return prev != hover_index;
    }
    if (menu_style == .aero) {
        const prev = hover_index;
        hover_index = aero7HoverIndex(px, py, scr_w, scr_h);
        return prev != hover_index;
    }
    if (menu_style != .classic) {
        const prev = hover_index;
        hover_index = -1;
        return prev != -1;
    }
    const r = classicRect(scr_h);
    const prev = hover_index;
    if (!r.contains(px, py)) {
        hover_index = -1;
        return prev != -1;
    }
    hover_index = classicHoverIndex(px, py, r);
    return prev != hover_index;
}

fn classicHoverIndex(px: i32, py: i32, r: MenuRect) i32 {
    const foot_y = r.y + r.h - W2K_FOOTER_H;
    if (px >= r.x + 8 and px < r.x + 96 and py >= foot_y + 6 and py < foot_y + 30) return 200;
    if (px >= r.x + r.w - 108 and px < r.x + r.w - 12 and py >= foot_y + 6 and py < foot_y + 30) return 201;

    const content_top = r.y + W2K_HEADER_H + 4;
    const split_x = r.x + W2K_LEFT_W;
    if (py < content_top + 2 or py >= foot_y) return -1;

    if (px >= r.x + 8 and px < split_x) {
        const row = @divTrunc(py - (content_top + 2), W2K_ROW_H);
        if (row >= 0 and row < w2k_left_items.len) return row;
        return -1;
    }

    if (px >= split_x + 8 and px < r.x + r.w - 8) {
        var iy: i32 = content_top + 2;
        var ridx: i32 = 100;
        for (w2k_right_items) |item| {
            if (py >= iy and py < iy + W2K_ROW_H) return ridx;
            iy += W2K_ROW_H;
            if (item.separator_after) iy += 4;
            ridx += 1;
        }
    }
    return -1;
}

/// 处理菜单内点击（相对当前 `menu_style`）。返回 `.shutdown` / `.logoff` 时由 shell 执行关机或注销。
pub fn handleMenuClick(px: i32, py: i32, scr_w: i32, scr_h: i32) MenuAction {
    if (!menu_visible) return .none;
    const r = getMenuRect(scr_w, scr_h);
    if (!r.contains(px, py)) return .none;
    return switch (menu_style) {
        .classic => handleClassicMenuClick(px, py, r),
        .luna => handleLunaTwoColMenuClick(px, py, scr_w, scr_h),
        .aero => handleAero7MenuClick(px, py, scr_w, scr_h),
        else => .none,
    };
}

fn handleClassicMenuClick(px: i32, py: i32, r: MenuRect) MenuAction {
    const foot_y = r.y + r.h - W2K_FOOTER_H;
    if (px >= r.x + r.w - 108 and px < r.x + r.w - 12 and py >= foot_y + 6 and py < foot_y + 30)
        return .shutdown;
    if (px >= r.x + 8 and px < r.x + 96 and py >= foot_y + 6 and py < foot_y + 30)
        return .logoff;

    const content_top = r.y + W2K_HEADER_H + 4;
    const split_x = r.x + W2K_LEFT_W;
    if (py < content_top + 2 or py >= foot_y) return .none;

    if (px >= r.x + 8 and px < split_x) {
        const row = @divTrunc(py - (content_top + 2), W2K_ROW_H);
        if (row >= 0 and row < w2k_left_items.len) {
            klog.info("Start menu: %s", .{w2k_left_items[@intCast(row)].label});
        }
        return .none;
    }

    if (px >= split_x + 8 and px < r.x + r.w - 8) {
        var iy: i32 = content_top + 2;
        for (w2k_right_items) |item| {
            if (py >= iy and py < iy + W2K_ROW_H) {
                klog.info("Start menu: %s", .{item.label});
                return .none;
            }
            iy += W2K_ROW_H;
            if (item.separator_after) iy += 4;
        }
    }
    return .none;
}

fn handleLunaTwoColMenuClick(px: i32, py: i32, scr_w: i32, scr_h: i32) MenuAction {
    const h = lunaTwoColHoverIndex(px, py, scr_w, scr_h);
    if (h == 201) return .shutdown;
    if (h == 200) return .logoff;
    if (h >= 0 and h < luna_two_col_left.len) {
        klog.info("Start menu (Luna): %s", .{luna_two_col_left[@intCast(h)].label});
        return .none;
    }
    if (h == LUNA_IDX_ALL_PROGRAMS) {
        klog.info("Start menu (Luna): All Programs", .{});
        return .none;
    }
    if (h >= 100) {
        const idx: usize = @intCast(h - 100);
        if (idx < luna_two_col_right.len) {
            klog.info("Start menu (Luna): %s", .{luna_two_col_right[idx].label});
        }
    }
    return .none;
}

fn handleAero7MenuClick(px: i32, py: i32, scr_w: i32, scr_h: i32) MenuAction {
    const h = aero7HoverIndex(px, py, scr_w, scr_h);
    if (h == 201) return .shutdown;
    if (h == 202) return .standby;
    if (h == 200) return .logoff;
    if (h >= 0 and h < aero7_left.len) {
        klog.info("Start menu (Aero): %s", .{aero7_left[@intCast(h)].label});
        return .none;
    }
    if (h == AERO7_IDX_ALL) {
        klog.info("Start menu (Aero): All Programs", .{});
        return .none;
    }
    if (h >= 100) {
        const idx: usize = @intCast(h - 100);
        if (idx < aero7_right.len) {
            klog.info("Start menu (Aero): %s", .{aero7_right[idx].label});
        }
    }
    return .none;
}

fn lunaTwoColHoverIndex(px: i32, py: i32, scr_w: i32, scr_h: i32) i32 {
    _ = scr_w;
    const r = lunaRect(scr_h);
    if (!r.contains(px, py)) return -1;

    const content_y = r.y + LUNA_HEADER_H + 2;
    const mid_h = r.h - LUNA_HEADER_H - LUNA_SEARCH_H - LUNA_FOOTER_H - 4;
    const search_y = r.y + r.h - LUNA_SEARCH_H - LUNA_FOOTER_H;
    const foot_y = r.y + r.h - LUNA_FOOTER_H;
    const split_x = r.x + 2 + LUNA_LEFT_W;
    const all_prog_y = content_y + mid_h - LUNA_ROW_H - 6;

    if (py >= foot_y and py < r.y + r.h) {
        if (py >= foot_y + 6 and py < foot_y + 36) {
            if (px >= r.x + 8 and px < r.x + 100) return 200;
            if (px >= r.x + r.w - 120 and px < r.x + r.w - 8) return 201;
        }
        return -1;
    }
    if (py >= search_y) return -1;

    if (py >= all_prog_y and py < all_prog_y + LUNA_ROW_H and px >= r.x + 8 and px < split_x)
        return LUNA_IDX_ALL_PROGRAMS;

    if (px >= r.x + 8 and px < split_x and py >= content_y + 6 and py < all_prog_y) {
        const row = @divTrunc(py - (content_y + 6), LUNA_ROW_H);
        if (row >= 0 and row < luna_two_col_left.len) return row;
    }

    if (px >= split_x + 8 and px < r.x + r.w - 8 and py >= content_y + 6 and py < search_y - 4) {
        var iy: i32 = content_y + 6;
        var ridx: i32 = 100;
        for (luna_two_col_right) |item| {
            if (py >= iy and py < iy + LUNA_ROW_H) return ridx;
            iy += LUNA_ROW_H;
            if (item.separator_after) iy += 4;
            ridx += 1;
        }
    }
    return -1;
}

fn aero7HoverIndex(px: i32, py: i32, scr_w: i32, scr_h: i32) i32 {
    _ = scr_w;
    const r = aeroRect(scr_h);
    if (!r.contains(px, py)) return -1;

    const inner_x = r.x + 4;
    const inner_y = r.y + 4;
    const inner_w = r.w - 8;
    const inner_h = r.h - 8;
    const rail = AERO7_RAIL_W;
    const main_x = inner_x + rail;
    const main_w = inner_w - rail;

    const content_y = inner_y + AERO7_HEADER_H + 2;
    const mid_h = inner_h - AERO7_HEADER_H - AERO7_SEARCH_H - AERO7_FOOTER_H - 6;
    const search_y = inner_y + inner_h - AERO7_SEARCH_H - AERO7_FOOTER_H;
    const foot_y = inner_y + inner_h - AERO7_FOOTER_H;
    const split_x = main_x + AERO7_LEFT_W;
    const all_prog_y = content_y + mid_h - AERO7_ROW_H - 6;

    if (py >= foot_y and py < inner_y + inner_h) {
        if (py >= foot_y + 6 and py < foot_y + 34) {
            const sd_x = main_x + main_w - 116;
            if (px >= main_x + 8 and px < main_x + 96) return 200;
            if (px >= main_x + 100 and px < sd_x - 8) return 202;
            if (px >= sd_x and px < main_x + main_w - 8) return 201;
        }
        return -1;
    }
    if (py >= search_y) return -1;

    if (py >= all_prog_y and py < all_prog_y + AERO7_ROW_H and px >= main_x + 8 and px < split_x)
        return AERO7_IDX_ALL;

    if (px >= main_x + 8 and px < split_x and py >= content_y + 6 and py < all_prog_y) {
        const row = @divTrunc(py - (content_y + 6), AERO7_ROW_H);
        if (row >= 0 and row < aero7_left.len) return row;
    }

    if (px >= split_x + 6 and px < main_x + main_w - 8 and py >= content_y + 6 and py < search_y - 4) {
        var iy: i32 = content_y + 6;
        var ridx: i32 = 100;
        for (aero7_right) |item| {
            if (py >= iy and py < iy + AERO7_ROW_H) return ridx;
            iy += AERO7_ROW_H;
            if (item.separator_after) iy += 4;
            ridx += 1;
        }
    }
    return -1;
}

fn classicRect(scr_h: i32) MenuRect {
    const h: i32 = 420;
    const w: i32 = 380;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = w, .h = h };
}

// 与 renderClassic / 命中测试共用的 Windows 2000 经典布局常数
const W2K_HEADER_H: i32 = 52;
const W2K_LEFT_W: i32 = 196;
const W2K_ROW_H: i32 = 22;
const W2K_FOOTER_H: i32 = 40;

fn lunaRect(scr_h: i32) MenuRect {
    const h: i32 = LUNA_HEADER_H + 320 + LUNA_SEARCH_H + LUNA_FOOTER_H;
    const w: i32 = 400;
    return .{ .x = 0, .y = scr_h - 30 - h, .w = w, .h = h };
}

fn aeroRect(scr_h: i32) MenuRect {
    const h: i32 = AERO7_HEADER_H + 310 + AERO7_SEARCH_H + AERO7_FOOTER_H + AERO7_RAIL_W + 12;
    const w: i32 = 428;
    return .{ .x = 0, .y = scr_h - 40 - h, .w = w, .h = h };
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
    const bg = rgb(0xD4, 0xD0, 0xC8);
    const border = rgb(0x80, 0x80, 0x80);
    const text_color = rgb(0x00, 0x00, 0x00);
    const banner_top = rgb(0x00, 0x00, 0xA8);
    const banner_bot = rgb(0x10, 0x24, 0x82);
    const hi = rgb(0xFF, 0xFF, 0xFF);
    const sep = rgb(0xA0, 0x9C, 0x94);
    const taskbar_gray = rgb(0xC0, 0xC0, 0xC0);

    // 与桌面衔接：轻阴影 + 整块面板（避免「贴图」感）
    fb.blendTintRect(r.x + 3, r.y + 3, r.w, r.h, rgb(0x00, 0x00, 0x00), 40, 255);

    fb.fillRect(r.x, r.y, r.w, r.h, bg);
    fb.draw3DRect(r.x, r.y, r.w, r.h, hi, border);
    fb.drawRect(r.x, r.y, r.w, r.h, border);

    // 内凹 1px，与任务栏同系灰阶
    fb.drawHLine(r.x + 1, r.y + 1, r.w - 2, rgb(0xE8, 0xE8, 0xE8));
    fb.drawVLine(r.x + 1, r.y + 1, r.h - 2, rgb(0xE8, 0xE8, 0xE8));

    // 顶部：ZirconOS 资源图标（经典主题浏览器/地球标志）+ 标题
    const hdr_inset: i32 = 3;
    fb.drawGradientH(r.x + hdr_inset, r.y + hdr_inset, r.w - 2 * hdr_inset, W2K_HEADER_H - 2 * hdr_inset, banner_top, banner_bot);
    const logo_scale: u32 = 2;
    const icon_px = icons.getIconTotalSize(logo_scale);
    drawMenuIcon(.browser, r.x + 10, r.y + 10, logo_scale);
    const title_x = r.x + 14 + icon_px;
    fb.drawTextTransparent(title_x, r.y + 12, "ZirconOS", hi);
    fb.drawTextTransparent(title_x, r.y + 30, "Built on NT Technology", rgb(0xC0, 0xD8, 0xFF));

    const foot_y = r.y + r.h - W2K_FOOTER_H;
    const content_top = r.y + W2K_HEADER_H + 4;
    const split_x = r.x + W2K_LEFT_W;
    fb.drawVLine(split_x, content_top, foot_y - content_top, sep);

    var iy: i32 = content_top + 2;
    const lx: i32 = r.x + 8;
    var idx: i32 = 0;
    for (w2k_left_items) |item| {
        if (hover_index == idx) {
            fb.fillRect(lx - 2, iy - 1, W2K_LEFT_W - 12, W2K_ROW_H, rgb(0x0A, 0x24, 0x6E));
            fb.drawTextTransparent(lx + 20, iy + 3, item.label, hi);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, lx, iy + 2, 1);
            }
            fb.drawTextTransparent(lx + 20, iy + 3, item.label, text_color);
        }
        if (std.mem.eql(u8, item.label, "Programs")) {
            fb.drawTextTransparent(r.x + W2K_LEFT_W - 28, iy + 3, ">", if (hover_index == idx) hi else text_color);
        }
        iy += W2K_ROW_H;
        idx += 1;
    }

    iy = content_top + 2;
    const rx: i32 = split_x + 8;
    var ridx: i32 = 100;
    for (w2k_right_items) |item| {
        if (hover_index == ridx) {
            fb.fillRect(rx - 2, iy - 1, r.w - W2K_LEFT_W - 14, W2K_ROW_H, rgb(0x0A, 0x24, 0x6E));
            fb.drawTextTransparent(rx + 20, iy + 3, item.label, hi);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, rx, iy + 2, 1);
            }
            if (item.bold) {
                fb.drawTextTransparent(rx + 20, iy + 3, item.label, rgb(0x00, 0x00, 0x80));
            } else {
                fb.drawTextTransparent(rx + 20, iy + 3, item.label, text_color);
            }
        }
        iy += W2K_ROW_H;
        if (item.separator_after) {
            iy += 4;
            fb.drawHLine(rx, iy - 2, r.w - W2K_LEFT_W - 16, sep);
        }
        ridx += 1;
    }

    fb.drawHLine(r.x + 4, foot_y, r.w - 8, sep);
    // 底边与任务栏顶线同色，视觉上连成一体
    fb.drawHLine(r.x + 1, r.y + r.h - 1, r.w - 2, taskbar_gray);

    fb.fillRect(r.x + 8, foot_y + 6, 88, 24, if (hover_index == 200) rgb(0x0A, 0x24, 0x6E) else rgb(0xC8, 0xC4, 0xBC));
    fb.drawTextTransparent(r.x + 18, foot_y + 12, "Log Off", if (hover_index == 200) hi else text_color);
    fb.fillRect(r.x + r.w - 108, foot_y + 6, 96, 24, if (hover_index == 201) rgb(0x0A, 0x24, 0x6E) else rgb(0xC8, 0xC4, 0xBC));
    fb.drawTextTransparent(r.x + r.w - 92, foot_y + 12, "Shut Down", if (hover_index == 201) hi else text_color);
}

/// Luna（XP）：亮蓝顶栏 + 两列 + 搜索 + 底栏 —— 与 Aero 毛玻璃区分。
fn renderLuna(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = lunaRect(scr_h);
    const content_bg = rgb(0xF8, 0xF8, 0xF8);
    const right_bg = rgb(0xD3, 0xE5, 0xFA);
    const text_color = rgb(0x1A, 0x1A, 0x1A);
    const text_white = rgb(0xFF, 0xFF, 0xFF);
    const sep_color = rgb(0xBF, 0xD7, 0xF4);
    const outer_hi = rgb(0xE8, 0xF0, 0xFF);
    const outer_lo = rgb(0x00, 0x3C, 0xA0);

    fb.blendTintRect(r.x + 4, r.y + 4, r.w, r.h, rgb(0x00, 0x00, 0x00), 28, 255);
    fb.fillRect(r.x + 2, r.y + 2, r.w - 4, r.h - 4, content_bg);
    fb.draw3DRect(r.x, r.y, r.w, r.h, outer_hi, outer_lo);
    fb.draw3DRect(r.x + 1, r.y + 1, r.w - 2, r.h - 2, rgb(0x80, 0xB8, 0xF0), rgb(0x00, 0x48, 0xA8));

    const header_h = LUNA_HEADER_H;
    fb.drawGradientH(r.x + 2, r.y + 2, r.w - 4, header_h, rgb(0x00, 0x58, 0xE6), rgb(0x3A, 0x81, 0xE5));
    fb.addSpecularBand(r.x + 2, r.y + 2, r.w - 4, @divTrunc(header_h, 3), 28);

    fb.fillRoundedRect(r.x + 10, r.y + 10, 44, 44, 4, rgb(0xE8, 0xE8, 0xE8));
    fb.drawRect(r.x + 10, r.y + 10, 44, 44, rgb(0xFF, 0xFF, 0xFF));
    drawMenuIcon(.computer, r.x + 16, r.y + 16, 2);
    fb.drawTextTransparent(r.x + 60, r.y + 16, "ZirconOS User", text_white);
    fb.drawTextTransparent(r.x + 60, r.y + 34, "Administrator", rgb(0xC0, 0xE0, 0xFF));

    const content_y = r.y + header_h + 2;
    const mid_h = r.h - LUNA_HEADER_H - LUNA_SEARCH_H - LUNA_FOOTER_H - 4;
    const search_y = r.y + r.h - LUNA_SEARCH_H - LUNA_FOOTER_H;
    const foot_y = r.y + r.h - LUNA_FOOTER_H;
    const split_x = r.x + 2 + LUNA_LEFT_W;
    const all_prog_y = content_y + mid_h - LUNA_ROW_H - 6;

    fb.fillRect(r.x + 2, content_y, LUNA_LEFT_W, mid_h, content_bg);
    fb.fillRect(split_x, content_y, r.w - 4 - LUNA_LEFT_W, mid_h, right_bg);
    fb.drawVLine(split_x, content_y, mid_h, sep_color);

    var iy: i32 = content_y + 6;
    for (luna_two_col_left, 0..) |item, li| {
        if (iy + LUNA_ROW_H > all_prog_y - 2) break;
        const row_r = hover_index == @as(i32, @intCast(li));
        if (row_r) {
            fb.fillRect(r.x + 6, iy - 1, LUNA_LEFT_W - 10, LUNA_ROW_H, rgb(0x31, 0x6A, 0xC5));
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, r.x + 10, iy + 3, 1);
            }
            fb.drawTextTransparent(r.x + 38, iy + 5, item.label, text_white);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, r.x + 10, iy + 3, 1);
            }
            const tc = if (item.bold) rgb(0x00, 0x00, 0x00) else text_color;
            fb.drawTextTransparent(r.x + 38, iy + 5, item.label, tc);
        }
        iy += LUNA_ROW_H;
        if (item.separator_after) {
            fb.drawHLine(r.x + 8, iy, LUNA_LEFT_W - 12, sep_color);
            iy += 4;
        }
    }

    fb.drawHLine(r.x + 8, all_prog_y - 2, LUNA_LEFT_W - 12, sep_color);
    const ap_hov = hover_index == LUNA_IDX_ALL_PROGRAMS;
    if (ap_hov) {
        fb.fillRect(r.x + 6, all_prog_y - 1, LUNA_LEFT_W - 10, LUNA_ROW_H, rgb(0x31, 0x6A, 0xC5));
        fb.drawTextTransparent(r.x + 38, all_prog_y + 5, "All Programs", text_white);
        fb.drawTextTransparent(r.x + LUNA_LEFT_W - 22, all_prog_y + 5, ">", text_white);
    } else {
        fb.drawTextTransparent(r.x + 38, all_prog_y + 5, "All Programs", rgb(0x00, 0x51, 0x9E));
        fb.drawTextTransparent(r.x + LUNA_LEFT_W - 22, all_prog_y + 5, ">", rgb(0x60, 0x60, 0x60));
    }

    iy = content_y + 6;
    var ridx: i32 = 100;
    for (luna_two_col_right) |item| {
        if (iy + LUNA_ROW_H > search_y - 6) break;
        const row_r = hover_index == ridx;
        if (row_r) {
            fb.fillRect(split_x + 4, iy - 1, r.w - LUNA_LEFT_W - 14, LUNA_ROW_H, rgb(0x31, 0x6A, 0xC5));
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, split_x + 8, iy + 3, 1);
            }
            fb.drawTextTransparent(split_x + 34, iy + 5, item.label, text_white);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, split_x + 8, iy + 3, 1);
            }
            const tc = if (item.bold) rgb(0x00, 0x00, 0x80) else text_color;
            fb.drawTextTransparent(split_x + 34, iy + 5, item.label, tc);
        }
        iy += LUNA_ROW_H;
        if (item.separator_after) {
            fb.drawHLine(split_x + 6, iy, r.w - LUNA_LEFT_W - 16, sep_color);
            iy += 4;
        }
        ridx += 1;
    }

    fb.fillRect(r.x + 2, search_y, r.w - 4, LUNA_SEARCH_H, rgb(0xE4, 0xEA, 0xF8));
    fb.drawHLine(r.x + 2, search_y, r.w - 4, sep_color);
    fb.drawRect(r.x + 10, search_y + 10, r.w - 24, 28, rgb(0xA8, 0xB8, 0xD8));
    fb.fillRect(r.x + 11, search_y + 11, r.w - 26, 26, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(r.x + 18, search_y + 17, "Search programs and files", rgb(0x90, 0x90, 0x90));

    fb.fillRect(r.x + 2, foot_y, r.w - 4, LUNA_FOOTER_H, rgb(0xD4, 0xE7, 0xFF));
    fb.drawHLine(r.x + 2, foot_y, r.w - 4, sep_color);

    const log_h = hover_index == 200;
    fb.drawTextTransparent(r.x + 14, foot_y + 14, "Log off", if (log_h) rgb(0x00, 0x51, 0x9E) else text_color);

    const sd_x = r.x + r.w - 118;
    const sd_hov = hover_index == 201;
    fb.fillRoundedRect(sd_x, foot_y + 8, 108, 30, 3, if (sd_hov) rgb(0xF0, 0x50, 0x40) else rgb(0xE0, 0x40, 0x30));
    fb.drawTextTransparent(sd_x + 10, foot_y + 15, "Shut down", text_white);
    fb.drawTextTransparent(sd_x + 94, foot_y + 15, ">", rgb(0xFF, 0xE8, 0xE0));
}

/// Aero（Win7）：左侧深色轨 + 银灰玻璃顶栏 + 磨砂白/雾蓝列 + 柔和高光（与 Luna 亮蓝区分）。
fn renderAero(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const r = aeroRect(scr_h);
    const text_dark = rgb(0x18, 0x1C, 0x22);
    const text_dim = rgb(0x50, 0x58, 0x62);
    const text_white = rgb(0xFF, 0xFF, 0xFF);
    const sep = rgb(0xB8, 0xC4, 0xD4);
    const rail_bg = rgb(0x10, 0x1C, 0x30);

    fb.blendTintRect(r.x + 5, r.y + 5, r.w, r.h, rgb(0x00, 0x00, 0x00), 35, 255);
    fb.fillRoundedRect(r.x + 2, r.y + 2, r.w - 4, r.h - 4, 6, rgb(0xE8, 0xEE, 0xF6));
    fb.blendTintRect(r.x + 2, r.y + 2, r.w - 4, r.h - 4, rgb(0x88, 0xA8, 0xC8), 22, 200);
    fb.draw3DRect(r.x, r.y, r.w, r.h, rgb(0xF5, 0xFA, 0xFF), rgb(0x40, 0x58, 0x70));
    fb.draw3DRect(r.x + 1, r.y + 1, r.w - 2, r.h - 2, rgb(0xC8, 0xD8, 0xE8), rgb(0x30, 0x40, 0x55));

    const inner_x = r.x + 4;
    const inner_y = r.y + 4;
    const inner_w = r.w - 8;
    const inner_h = r.h - 8;
    const rail = AERO7_RAIL_W;
    const main_x = inner_x + rail;
    const main_w = inner_w - rail;

    fb.fillRect(inner_x, inner_y, rail, inner_h, rail_bg);
    fb.drawGradientV(inner_x, inner_y, rail, @divTrunc(inner_h, 2), rgb(0x18, 0x28, 0x40), rail_bg);
    fb.drawVLine(main_x - 1, inner_y, inner_h, rgb(0x30, 0x44, 0x5C));
    const orb_y = inner_y + inner_h - rail - 6;
    fb.fillRoundedRect(inner_x + 8, orb_y, 36, 36, 18, rgb(0x28, 0x48, 0x78));
    fb.drawGradientV(inner_x + 9, orb_y + 1, 34, 17, rgb(0x50, 0x78, 0xA8), rgb(0x28, 0x48, 0x78));
    fb.drawTextTransparent(inner_x + 18, orb_y + 11, "Z", rgb(0xE8, 0xF0, 0xFF));

    const hdr_h = AERO7_HEADER_H;
    fb.drawGradientH(main_x, inner_y, main_w, hdr_h, rgb(0x68, 0x78, 0x88), rgb(0x90, 0xA0, 0xB0));
    fb.blendTintRect(main_x, inner_y, main_w, hdr_h, rgb(0xE8, 0xF0, 0xF8), 45, 220);
    fb.addSpecularBand(main_x, inner_y, main_w, @divTrunc(hdr_h, 3), 22);
    fb.drawHLine(main_x + 2, inner_y + 2, main_w - 4, rgb(0xF8, 0xFC, 0xFF));

    fb.fillRoundedRect(main_x + 8, inner_y + 8, 40, 40, 5, rgb(0xA8, 0xB8, 0xC8));
    fb.blendTintRect(main_x + 8, inner_y + 8, 40, 40, rgb(0xFF, 0xFF, 0xFF), 35, 255);
    fb.drawRect(main_x + 8, inner_y + 8, 40, 40, rgb(0xD8, 0xE4, 0xF0));
    drawMenuIcon(.computer, main_x + 12, inner_y + 12, 2);
    fb.drawTextTransparent(main_x + 54, inner_y + 12, "ZirconOS User", text_white);
    fb.drawTextTransparent(main_x + 54, inner_y + 30, "Windows 7 · Aero Glass", rgb(0xE8, 0xF0, 0xF8));

    const content_y = inner_y + hdr_h + 2;
    const mid_h = inner_h - AERO7_HEADER_H - AERO7_SEARCH_H - AERO7_FOOTER_H - 6;
    const search_y = inner_y + inner_h - AERO7_SEARCH_H - AERO7_FOOTER_H;
    const foot_y = inner_y + inner_h - AERO7_FOOTER_H;
    const split_x = main_x + AERO7_LEFT_W;
    const all_prog_y = content_y + mid_h - AERO7_ROW_H - 6;

    fb.fillRect(main_x, content_y, AERO7_LEFT_W, mid_h, rgb(0xFA, 0xFC, 0xFE));
    fb.blendTintRect(main_x, content_y, AERO7_LEFT_W, mid_h, rgb(0xF0, 0xF6, 0xFC), 30, 255);
    fb.fillRect(split_x, content_y, main_w - AERO7_LEFT_W, mid_h, rgb(0xE4, 0xEC, 0xF4));
    fb.blendTintRect(split_x, content_y, main_w - AERO7_LEFT_W, mid_h, rgb(0xC8, 0xD8, 0xE8), 18, 200);
    fb.drawVLine(split_x, content_y, mid_h, sep);

    var iy: i32 = content_y + 6;
    for (aero7_left, 0..) |item, li| {
        if (iy + AERO7_ROW_H > all_prog_y - 2) break;
        const row_r = hover_index == @as(i32, @intCast(li));
        if (row_r) {
            fb.blendTintRect(main_x + 6, iy - 1, AERO7_LEFT_W - 12, AERO7_ROW_H, rgb(0x70, 0x98, 0xC8), 55, 255);
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, main_x + 10, iy + 3, 1);
            }
            fb.drawTextTransparent(main_x + 36, iy + 5, item.label, text_white);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, main_x + 10, iy + 3, 1);
            }
            const tc = if (item.bold) text_dark else text_dim;
            fb.drawTextTransparent(main_x + 36, iy + 5, item.label, tc);
        }
        iy += AERO7_ROW_H;
        if (item.separator_after) {
            fb.drawHLine(main_x + 8, iy, AERO7_LEFT_W - 14, sep);
            iy += 4;
        }
    }

    fb.drawHLine(main_x + 8, all_prog_y - 2, AERO7_LEFT_W - 14, sep);
    const ap_hov = hover_index == AERO7_IDX_ALL;
    if (ap_hov) {
        fb.blendTintRect(main_x + 6, all_prog_y - 1, AERO7_LEFT_W - 12, AERO7_ROW_H, rgb(0x70, 0x98, 0xC8), 50, 255);
        fb.drawTextTransparent(main_x + 36, all_prog_y + 5, "All Programs", text_white);
        fb.drawTextTransparent(main_x + AERO7_LEFT_W - 22, all_prog_y + 5, ">", rgb(0xE8, 0xF4, 0xFF));
    } else {
        fb.drawTextTransparent(main_x + 36, all_prog_y + 5, "All Programs", rgb(0x20, 0x50, 0x88));
        fb.drawTextTransparent(main_x + AERO7_LEFT_W - 22, all_prog_y + 5, ">", text_dim);
    }

    iy = content_y + 6;
    var ridx: i32 = 100;
    for (aero7_right) |item| {
        if (iy + AERO7_ROW_H > search_y - 6) break;
        const row_r = hover_index == ridx;
        if (row_r) {
            fb.blendTintRect(split_x + 4, iy - 1, main_w - AERO7_LEFT_W - 12, AERO7_ROW_H, rgb(0x70, 0x98, 0xC8), 50, 255);
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, split_x + 8, iy + 3, 1);
            }
            fb.drawTextTransparent(split_x + 34, iy + 5, item.label, text_white);
        } else {
            if (item.icon_id) |iid| {
                drawMenuIcon(iid, split_x + 8, iy + 3, 1);
            }
            const tc = if (item.bold) rgb(0x10, 0x38, 0x68) else text_dim;
            fb.drawTextTransparent(split_x + 34, iy + 5, item.label, tc);
        }
        iy += AERO7_ROW_H;
        if (item.separator_after) {
            fb.drawHLine(split_x + 6, iy, main_w - AERO7_LEFT_W - 14, sep);
            iy += 4;
        }
        ridx += 1;
    }

    fb.fillRect(main_x, search_y, main_w, AERO7_SEARCH_H, rgb(0xDC, 0xE4, 0xEE));
    fb.blendTintRect(main_x, search_y, main_w, AERO7_SEARCH_H, rgb(0xF8, 0xFC, 0xFF), 25, 255);
    fb.drawHLine(main_x, search_y, main_w, sep);
    fb.drawRect(main_x + 8, search_y + 9, main_w - 16, 26, rgb(0x98, 0xA8, 0xB8));
    fb.fillRect(main_x + 9, search_y + 10, main_w - 18, 24, rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(main_x + 16, search_y + 15, "Search programs and files", rgb(0x98, 0xA0, 0xA8));

    fb.fillRect(main_x, foot_y, main_w, AERO7_FOOTER_H, rgb(0xD0, 0xDC, 0xE8));
    fb.blendTintRect(main_x, foot_y, main_w, AERO7_FOOTER_H, rgb(0xF0, 0xF6, 0xFC), 20, 255);
    fb.drawHLine(main_x, foot_y, main_w, sep);

    const log_h = hover_index == 200;
    fb.drawTextTransparent(main_x + 10, foot_y + 14, "Log off", if (log_h) rgb(0x30, 0x60, 0x98) else text_dim);

    const sleep_h = hover_index == 202;
    fb.drawTextTransparent(main_x + 100, foot_y + 14, "Sleep", if (sleep_h) rgb(0x30, 0x60, 0x98) else text_dim);

    const sd_x = main_x + main_w - 116;
    const sd_hov = hover_index == 201;
    fb.fillRoundedRect(sd_x, foot_y + 8, 106, 28, 4, if (sd_hov) rgb(0xD8, 0x50, 0x40) else rgb(0xB8, 0x48, 0x38));
    fb.blendTintRect(sd_x, foot_y + 8, 106, 28, rgb(0xFF, 0xC8, 0xB8), if (sd_hov) 35 else 18, 255);
    fb.drawTextTransparent(sd_x + 10, foot_y + 14, "Shut down", text_white);
    fb.drawTextTransparent(sd_x + 90, foot_y + 14, ">", rgb(0xFF, 0xE8, 0xE0));
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
