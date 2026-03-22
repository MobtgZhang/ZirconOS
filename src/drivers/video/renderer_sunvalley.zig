//! Sun Valley (Windows 11 / NT 6.4) Desktop Renderer
//!
//! WinUI 3 Composition → Mica material → SDF rounded corners →
//! Snap Layout → centered taskbar → Dynamic Refresh Rate

const fb = @import("framebuffer.zig");
const theme = @import("theme.zig");
const dwm = @import("dwm.zig");
const icons = @import("icons.zig");
const startmenu = @import("startmenu.zig");
const dwm_comp = @import("dwm_compositor.zig");
const mat = @import("material.zig");
const vtree = @import("visual_tree.zig");
const display = @import("display.zig");
const rgb = theme.rgb;

var widget_panel_visible: bool = false;
var quick_settings_visible: bool = false;

pub fn toggleWidgetPanel() void {
    widget_panel_visible = !widget_panel_visible;
}

pub fn toggleQuickSettings() void {
    quick_settings_visible = !quick_settings_visible;
}

pub fn initDwm() void {
    if (dwm.isInitialized()) return;
    dwm.init(.{
        .glass_enabled = true,
        .glass_opacity = 210,
        .glass_blur_radius = 3,
        .glass_saturation = 180,
        .glass_tint_color = rgb(0x1C, 0x1C, 0x1C),
        .glass_tint_opacity = 70,
        .animation_enabled = true,
        .peek_enabled = true,
        .shadow_enabled = true,
        .vsync_compositor = true,
        .smooth_cursor = true,
        .cursor_lerp_factor = 230,
    });

    dwm_comp.initSunValley(.{
        .mica_enabled = true,
        .mica_blur_radius = 3,
        .mica_opacity = 200,
        .mica_luminosity = 160,
        .mica_tint_color = rgb(0x20, 0x20, 0x20),
        .acrylic2_enabled = true,
        .acrylic2_luminosity_blend = 160,
        .corner_radius = 8,
        .snap_layout_enabled = true,
        .snap_zones = 6,
        .taskbar_centered = true,
        .widget_panel_enabled = true,
        .quick_settings_enabled = true,
        .drr_enabled = true,
        .drr_min_hz = 60,
        .drr_max_hz = 120,
        .auto_hdr = false,
        .shell_process_split = true,
        .animation_implicit = true,
        .sdf_antialias = true,
    });

    vtree.init();
    vtree.createTree();
}

pub fn render() void {
    theme.setTheme(.sunvalley);
    if (!dwm.isInitialized()) initDwm();
    renderFrame();
}

pub fn renderFrame() void {
    if (!fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = theme.getActiveTheme();
    const tb_h: i32 = 48;

    const ds = display.getDragState();
    const any_drag = ds.explorer_active or ds.taskmgr_active;

    if (any_drag) {
        patchDragBackground(w, h);
        display.renderDesktopIcons(w, h, t);
        renderWindowFast(w, h, t);
        renderTaskbar(w, h, t, tb_h);
        display.renderCursorAt();
        display.incFrameCount();

        if (ds.explorer_active) {
            const wr = display.getWindowRect(w, h);
            const cur = display.ShellRect{ .x = wr.x, .y = wr.y, .w = wr.w, .h = wr.h };
            var u = display.rectUnion(ds.explorer_prev, cur);
            u = display.rectInflate(u, 16);
            u = display.rectClampToScreen(u, w, h);
            fb.markDirtyRegion(u.x, u.y, u.w, u.h);
        }
    } else {
        fb.drawGradientV(0, 0, w, h, rgb(0x08, 0x12, 0x22), rgb(0x0A, 0x1E, 0x3A));
        display.renderDesktopIcons(w, h, t);
        renderWindow(w, h, t);
        renderOsInterfaceWindows(w, h, t, tb_h);
        renderTaskbar(w, h, t, tb_h);

        if (startmenu.isVisible()) {
            startmenu.render(w, h);
        }
        if (widget_panel_visible) {
            renderWidgetPanel(w, h, t);
        }
        if (quick_settings_visible) {
            renderQuickSettings(w, h, t);
        }

        display.renderContextMenu();
        display.renderCursorAt();
        display.incFrameCount();
        fb.markFullScreenDirty();
    }
}

fn renderWindowFast(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    const wr = display.getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const sv_titlebar_h: i32 = 32;

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);
    fb.drawGradientV(win_x, win_y, win_w, sv_titlebar_h, rgb(0x30, 0x30, 0x30), rgb(0x28, 0x28, 0x28));
    fb.drawTextTransparent(win_x + 12, win_y + 8, "Computer", rgb(0xFF, 0xFF, 0xFF));

    const btn_w: i32 = 46;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, sv_titlebar_h, t.btn_close_top);
    display.drawCloseSymbol(close_x, win_y, btn_w);

    fb.drawHLine(win_x, win_y + sv_titlebar_h, win_w, t.tray_border);
    renderWindowContent(win_x + 1, win_y + sv_titlebar_h, win_w - 2, win_h - sv_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
}

fn renderWindow(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    const wr = display.getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const corner_r: i32 = 8;
    const sv_titlebar_h: i32 = 32;

    if (dwm.isShadowEnabled()) {
        mat.renderShadow(win_x, win_y, win_w, win_h, 12, 5);
    }

    fb.fillRoundedRect(win_x, win_y, win_w, win_h, corner_r, t.window_bg);
    fb.fillRect(win_x, win_y, win_w, sv_titlebar_h, rgb(0x2D, 0x2D, 0x2D));
    fb.drawGradientV(win_x, win_y, win_w, sv_titlebar_h, rgb(0x30, 0x30, 0x30), rgb(0x28, 0x28, 0x28));
    fb.drawTextTransparent(win_x + 12, win_y + 8, "Computer", rgb(0xFF, 0xFF, 0xFF));

    const btn_w: i32 = 46;
    const btn_h: i32 = sv_titlebar_h;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, btn_h, t.btn_close_top);
    display.drawCloseSymbol(close_x, win_y, btn_w);
    fb.fillRect(close_x - btn_w, win_y, btn_w, btn_h, t.btn_minmax_top);
    display.drawMaxSymbol(close_x - btn_w, win_y, btn_w);
    fb.fillRect(close_x - btn_w * 2, win_y, btn_w, btn_h, t.btn_minmax_top);
    display.drawMinSymbol(close_x - btn_w * 2, win_y, btn_w);

    fb.drawHLine(win_x, win_y + sv_titlebar_h, win_w, t.tray_border);
    renderWindowContent(win_x + 1, win_y + sv_titlebar_h, win_w - 2, win_h - sv_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
    mat.applyRoundedClip(win_x, win_y, win_w, win_h, @intCast(corner_r));
}

fn renderWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const theme.ThemeColors) void {
    _ = t;

    fb.fillRect(x, y, w, 36, rgb(0x2D, 0x2D, 0x2D));
    const tabs = [_][]const u8{ "Home", "View" };
    var tx: i32 = x + 12;
    for (tabs, 0..) |tab, i| {
        const tw = fb.textWidth(tab) + 16;
        if (i == 0) {
            fb.fillRoundedRect(tx, y + 6, tw, 24, 4, rgb(0x40, 0x40, 0x40));
        }
        fb.drawTextTransparent(tx + 8, y + 10, tab, if (i == 0) rgb(0xFF, 0xFF, 0xFF) else rgb(0xA0, 0xA0, 0xA0));
        tx += tw + 4;
    }

    const addr_y = y + 37;
    fb.fillRect(x, addr_y, w, 28, rgb(0x1E, 0x1E, 0x1E));
    fb.fillRoundedRect(x + 8, addr_y + 3, w - 16, 22, 6, rgb(0x38, 0x38, 0x38));
    fb.drawTextTransparent(x + 18, addr_y + 7, "This PC > Local Disk (C:)", rgb(0xE0, 0xE0, 0xE0));

    const body_y = addr_y + 29;
    const status_h: i32 = 24;
    const body_h = h - 36 - 28 - status_h - 1;
    if (body_h <= 10) return;

    const nav_w: i32 = @min(180, @max(120, @divTrunc(w, 3)));
    fb.fillRect(x, body_y, nav_w, body_h, rgb(0x20, 0x20, 0x20));
    fb.drawVLine(x + nav_w, body_y, body_h, rgb(0x38, 0x38, 0x38));

    const nav_items = [_]struct { label: []const u8, sel: bool }{
        .{ .label = "Home", .sel = false },
        .{ .label = "Gallery", .sel = false },
        .{ .label = "Desktop", .sel = false },
        .{ .label = "Downloads", .sel = false },
        .{ .label = "Documents", .sel = false },
        .{ .label = "This PC", .sel = true },
        .{ .label = "  C:\\", .sel = false },
        .{ .label = "  D:\\", .sel = false },
        .{ .label = "Network", .sel = false },
    };
    var ny: i32 = body_y + 4;
    for (nav_items) |item| {
        if (ny + 22 > body_y + body_h) break;
        if (item.sel) {
            fb.fillRoundedRect(x + 4, ny, nav_w - 8, 22, 4, rgb(0x38, 0x38, 0x38));
        }
        fb.drawTextTransparent(x + 14, ny + 4, item.label, if (item.sel) rgb(0x60, 0xCD, 0xFF) else rgb(0xD0, 0xD0, 0xD0));
        ny += 24;
    }

    const list_x = x + nav_w + 1;
    const list_w = w - nav_w - 1;
    fb.fillRect(list_x, body_y, list_w, body_h, rgb(0x1E, 0x1E, 0x1E));

    fb.fillRect(list_x, body_y, list_w, 22, rgb(0x28, 0x28, 0x28));
    fb.drawHLine(list_x, body_y + 22, list_w, rgb(0x38, 0x38, 0x38));
    fb.drawTextTransparent(list_x + 30, body_y + 4, "Name", rgb(0x99, 0x99, 0x99));
    if (list_w > 280) {
        fb.drawTextTransparent(list_x + list_w - 200, body_y + 4, "Date modified", rgb(0x99, 0x99, 0x99));
        fb.drawTextTransparent(list_x + list_w - 80, body_y + 4, "Size", rgb(0x99, 0x99, 0x99));
    }

    const entries = [_]struct { name: []const u8, date: []const u8, size: []const u8, icon: icons.IconId }{
        .{ .name = "Users", .date = "2026/01/15", .size = "", .icon = .documents },
        .{ .name = "Program Files", .date = "2026/03/20", .size = "", .icon = .documents },
        .{ .name = "Windows", .date = "2026/02/10", .size = "", .icon = .documents },
        .{ .name = "resources", .date = "2026/01/01", .size = "", .icon = .documents },
        .{ .name = "boot.cfg", .date = "2026/01/01", .size = "1 KB", .icon = .computer },
        .{ .name = "zloader.efi", .date = "2026/03/21", .size = "512 KB", .icon = .computer },
    };
    var ey: i32 = body_y + 24;
    for (entries, 0..) |entry, i| {
        if (ey + 24 > body_y + body_h) break;
        if (i % 2 == 1) {
            fb.fillRect(list_x, ey, list_w - 14, 24, rgb(0x24, 0x24, 0x24));
        }
        icons.drawThemedIcon(entry.icon, list_x + 8, ey + 4, 1, .sunvalley);
        fb.drawTextTransparent(list_x + 30, ey + 5, entry.name, rgb(0xF0, 0xF0, 0xF0));
        if (list_w > 280) {
            fb.drawTextTransparent(list_x + list_w - 200, ey + 5, entry.date, rgb(0x88, 0x88, 0x88));
            fb.drawTextTransparent(list_x + list_w - 80, ey + 5, entry.size, rgb(0x88, 0x88, 0x88));
        }
        ey += 24;
    }

    const sb_x = list_x + list_w - 14;
    fb.fillRect(sb_x, body_y + 23, 14, body_h - 23, rgb(0x1E, 0x1E, 0x1E));
    fb.fillRoundedRect(sb_x + 3, body_y + 28, 8, 36, 4, rgb(0x50, 0x50, 0x50));

    fb.fillRect(x, y + h - status_h, w, status_h, rgb(0x1E, 0x1E, 0x1E));
    fb.drawHLine(x, y + h - status_h, w, rgb(0x38, 0x38, 0x38));
    fb.drawTextTransparent(x + 8, y + h - status_h + 4, "6 items | This PC", rgb(0x70, 0x70, 0x70));
}

fn renderOsInterfaceWindows(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;
    const btn_w: i32 = 32;
    const btn_h: i32 = 26;
    const btn_spacing: i32 = 4;
    const btn_y = tb_y + @divTrunc(tb_h - btn_h, 2);
    const center_x = @divTrunc(scr_w, 2);
    const pinned_count: i32 = 6;
    const icon_spacing: i32 = 40;
    const group_w = pinned_count * icon_spacing;
    const os_x: i32 = center_x + @divTrunc(group_w, 2) + 12;
    const os_items = [_]struct { label: []const u8, color: u32, pill: u32 }{
        .{ .label = "C", .color = rgb(0x1E, 0x1E, 0x1E), .pill = rgb(0x4C, 0xB0, 0xE8) },
        .{ .label = "D", .color = rgb(0x0C, 0x0C, 0x0C), .pill = rgb(0x60, 0x60, 0x60) },
        .{ .label = "P", .color = rgb(0x01, 0x24, 0x56), .pill = rgb(0x60, 0x60, 0x60) },
    };
    for (os_items, 0..) |item, idx| {
        const bx = os_x + @as(i32, @intCast(idx)) * (btn_w + btn_spacing);
        fb.fillRoundedRect(bx, btn_y, btn_w, btn_h, 4, item.color);
        fb.drawTextTransparent(bx + 10, btn_y + 5, item.label, t.clock_text);
        const pill_x = bx + @divTrunc(btn_w - 12, 2);
        const pill_y = btn_y + btn_h - 3;
        fb.fillRect(pill_x, pill_y, 12, 2, item.pill);
    }
}

fn renderTaskbar(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;
    if (dwm.isGlassEnabled()) {
        dwm.renderGlassEffect(0, tb_y, scr_w, tb_h, rgb(0x28, 0x28, 0x32), .taskbar);
    } else {
        fb.fillRect(0, tb_y, scr_w, tb_h, rgb(0x20, 0x20, 0x20));
    }
    fb.drawHLine(0, tb_y, scr_w, rgb(0x48, 0x48, 0x48));
    const center_x = @divTrunc(scr_w, 2);
    const pinned_count: i32 = 6;
    const icon_spacing: i32 = 40;
    const group_w = pinned_count * icon_spacing;
    const group_start = center_x - @divTrunc(group_w, 2);
    display.renderZirconLogo(group_start + 12, tb_y + @divTrunc(tb_h - 14, 2));
    const pill_y = tb_y + tb_h - 5;
    fb.fillRoundedRect(group_start + 8, pill_y, 20, 3, 1, t.selection_bg);
    const search_x = group_start + icon_spacing;
    const search_y = tb_y + @divTrunc(tb_h - 28, 2);
    fb.fillRoundedRect(search_x, search_y, 28, 28, 6, rgb(0x2D, 0x2D, 0x2D));
    fb.drawTextTransparent(search_x + 8, search_y + 6, "S", rgb(0x88, 0x88, 0x88));
    const icon_labels = [_][]const u8{ "E", "B", "T", "S", "M" };
    var i: i32 = 2;
    while (i < pinned_count) : (i += 1) {
        const ix = group_start + i * icon_spacing + 16;
        const iy = tb_y + @divTrunc(tb_h - 16, 2);
        const idx: usize = @intCast(i - 2);
        if (idx < icon_labels.len) {
            fb.drawTextTransparent(ix, iy, icon_labels[idx], t.clock_text);
        }
        if (i < 4) {
            const p_x = group_start + i * icon_spacing + 14;
            const p_color: u32 = if (i == 2) t.selection_bg else rgb(0x60, 0x60, 0x60);
            fb.fillRoundedRect(p_x, pill_y, 12, 3, 1, p_color);
        }
    }
    renderTray(scr_w, tb_y, tb_h, t);
}

fn renderTray(scr_w: i32, tb_y: i32, tb_h: i32, t: *const theme.ThemeColors) void {
    const tray_w: i32 = 140;
    const tray_x = scr_w - tray_w - 12;
    const tray_y = tb_y + @divTrunc(tb_h - 32, 2);
    fb.fillRoundedRect(tray_x, tray_y, tray_w, 32, 4, t.tray_bg);
    fb.drawTextTransparent(tray_x + 8, tray_y + 8, "W", rgb(0xAA, 0xAA, 0xAA));
    fb.drawTextTransparent(tray_x + 24, tray_y + 8, "V", rgb(0xAA, 0xAA, 0xAA));
    fb.drawTextTransparent(tray_x + 40, tray_y + 8, "B", rgb(0xAA, 0xAA, 0xAA));
    fb.drawTextTransparent(tray_x + 60, tray_y + 2, "12:00 PM", t.clock_text);
    fb.drawTextTransparent(tray_x + 60, tray_y + 16, "2026/3/21", rgb(0x99, 0x99, 0x99));
    const bell_x = scr_w - 28;
    fb.drawTextTransparent(bell_x, tb_y + @divTrunc(tb_h - 16, 2), "N", rgb(0x88, 0x88, 0x88));
}

fn renderWidgetPanel(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    _ = scr_w;
    const panel_w: i32 = 360;
    const panel_h: i32 = scr_h - 48 - 16;
    const panel_x: i32 = 8;
    const panel_y: i32 = 8;
    if (dwm.isShadowEnabled()) {
        mat.renderShadow(panel_x, panel_y, panel_w, panel_h, 12, 5);
    }
    fb.fillRoundedRect(panel_x, panel_y, panel_w, panel_h, 8, t.window_bg);
    if (dwm.isGlassEnabled()) {
        mat.renderMica(panel_x, panel_y, panel_w, panel_h);
    }
    mat.applyRoundedClip(panel_x, panel_y, panel_w, panel_h, 8);
    fb.drawTextTransparent(panel_x + 16, panel_y + 12, "Widgets", rgb(0xCC, 0xCC, 0xCC));
    fb.drawHLine(panel_x + 16, panel_y + 32, panel_w - 32, t.tray_border);
    const cards = [_]struct { name: []const u8, detail: []const u8 }{
        .{ .name = "Weather", .detail = "22C  Sunny" },
        .{ .name = "News", .detail = "ZirconOS v1.0 Released" },
        .{ .name = "Calendar", .detail = "Saturday, Mar 21" },
        .{ .name = "System", .detail = "CPU: 4% | RAM: 512MB" },
        .{ .name = "Clock", .detail = "12:00 PM UTC+8" },
    };
    var cy: i32 = panel_y + 44;
    for (cards) |card| {
        if (cy + 64 > panel_y + panel_h - 8) break;
        fb.fillRoundedRect(panel_x + 12, cy, panel_w - 24, 56, 6, rgb(0x2A, 0x2A, 0x2A));
        fb.drawRect(panel_x + 12, cy, panel_w - 24, 56, rgb(0x3A, 0x3A, 0x3A));
        fb.drawTextTransparent(panel_x + 24, cy + 8, card.name, rgb(0xDD, 0xDD, 0xDD));
        fb.drawTextTransparent(panel_x + 24, cy + 28, card.detail, rgb(0x88, 0x88, 0x88));
        cy += 64;
    }
}

fn renderQuickSettings(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    const qs_w: i32 = 340;
    const qs_h: i32 = 360;
    const qs_x = scr_w - qs_w - 12;
    const qs_y = scr_h - 48 - qs_h - 12;
    if (dwm.isShadowEnabled()) {
        mat.renderShadow(qs_x, qs_y, qs_w, qs_h, 12, 5);
    }
    fb.fillRoundedRect(qs_x, qs_y, qs_w, qs_h, 8, t.window_bg);
    if (dwm.isGlassEnabled()) {
        mat.renderAcrylic(qs_x, qs_y, qs_w, qs_h);
    }
    mat.applyRoundedClip(qs_x, qs_y, qs_w, qs_h, 8);
    const toggles = [_]struct { label: []const u8, on: bool }{
        .{ .label = "WiFi", .on = true },
        .{ .label = "Bluetooth", .on = true },
        .{ .label = "Airplane", .on = false },
        .{ .label = "Battery", .on = false },
        .{ .label = "Focus", .on = false },
        .{ .label = "Access", .on = false },
    };
    var ty: i32 = qs_y + 16;
    var col: i32 = 0;
    for (toggles) |toggle| {
        const tx = qs_x + 12 + col * 104;
        const bg_color: u32 = if (toggle.on) rgb(0x4C, 0xB0, 0xE8) else rgb(0x38, 0x38, 0x38);
        fb.fillRoundedRect(tx, ty, 96, 40, 6, bg_color);
        fb.drawRect(tx, ty, 96, 40, rgb(0x50, 0x50, 0x50));
        fb.drawTextTransparent(tx + 8, ty + 12, toggle.label, rgb(0xFF, 0xFF, 0xFF));
        col += 1;
        if (col >= 3) {
            col = 0;
            ty += 48;
        }
    }
    ty += if (col > 0) 56 else 8;
    fb.drawTextTransparent(qs_x + 16, ty, "Brightness", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 6, 3, rgb(0x44, 0x44, 0x44));
    const bright_w = @divTrunc((qs_w - 32) * 3, 4);
    fb.fillRoundedRect(qs_x + 16, ty + 18, bright_w, 6, 3, rgb(0x4C, 0xB0, 0xE8));
    fb.fillRoundedRect(qs_x + 16 + bright_w - 8, ty + 14, 16, 14, 7, rgb(0xFF, 0xFF, 0xFF));
    ty += 38;
    fb.drawTextTransparent(qs_x + 16, ty, "Volume", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 6, 3, rgb(0x44, 0x44, 0x44));
    const vol_w = @divTrunc((qs_w - 32) * 2, 3);
    fb.fillRoundedRect(qs_x + 16, ty + 18, vol_w, 6, 3, rgb(0x4C, 0xB0, 0xE8));
    fb.fillRoundedRect(qs_x + 16 + vol_w - 8, ty + 14, 16, 14, 7, rgb(0xFF, 0xFF, 0xFF));
    ty += 38;
    fb.drawTextTransparent(qs_x + 16, ty, "Battery: 85%", rgb(0x88, 0x88, 0x88));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 4, 2, rgb(0x44, 0x44, 0x44));
    fb.fillRoundedRect(qs_x + 16, ty + 18, @divTrunc((qs_w - 32) * 85, 100), 4, 2, rgb(0x0F, 0x7B, 0x0F));
}

fn patchDragBackground(scr_w: i32, scr_h: i32) void {
    const pad: i32 = 10;
    const topc = rgb(0x08, 0x12, 0x22);
    const botc = rgb(0x0A, 0x1E, 0x3A);
    const drag_state = display.getDragState();
    if (drag_state.explorer_active) {
        const wr = display.getWindowRect(scr_w, scr_h);
        const cur = display.ShellRect{ .x = wr.x, .y = wr.y, .w = wr.w, .h = wr.h };
        var u = display.rectUnion(drag_state.explorer_prev, cur);
        u = display.rectInflate(u, pad);
        u = display.rectClampToScreen(u, scr_w, scr_h);
        if (u.w > 0 and u.h > 0) {
            display.patchVerticalGradientRegion(scr_w, scr_h, u.x, u.y, u.w, u.h, topc, botc);
        }
        display.setExplorerDragPrev(cur);
    }
    if (drag_state.taskmgr_active) {
        const tm_pos = display.getTaskMgrPos();
        const cur = display.ShellRect{ .x = tm_pos.x, .y = tm_pos.y, .w = 320, .h = 260 };
        var u = display.rectUnion(drag_state.taskmgr_prev, cur);
        u = display.rectInflate(u, pad);
        u = display.rectClampToScreen(u, scr_w, scr_h);
        if (u.w > 0 and u.h > 0) {
            display.patchVerticalGradientRegion(scr_w, scr_h, u.x, u.y, u.w, u.h, topc, botc);
        }
        display.setTaskMgrDragPrev(cur);
    }
}
