//! Fluent (Windows 10 / NT 6.3) Desktop Renderer
//!
//! DirectComposition visual tree → Acrylic material → Reveal highlight
//! → Multi-layer depth shadow → Smooth cursor

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

var action_center_visible: bool = false;

pub fn toggleActionCenter() void {
    action_center_visible = !action_center_visible;
}

pub fn initDwm() void {
    if (dwm.isInitialized()) return;
    dwm.init(.{
        .glass_enabled = true,
        .glass_opacity = 200,
        .glass_blur_radius = 3,
        .glass_saturation = 180,
        .glass_tint_color = rgb(0x20, 0x20, 0x20),
        .glass_tint_opacity = 70,
        .animation_enabled = true,
        .peek_enabled = true,
        .shadow_enabled = true,
        .vsync_compositor = true,
        .smooth_cursor = true,
        .cursor_lerp_factor = 220,
    });

    dwm_comp.initFluent(.{
        .acrylic_enabled = true,
        .acrylic_blur_radius = 3,
        .acrylic_blur_passes = 1,
        .noise_opacity = 8,
        .luminosity_blend = 140,
        .tint_color = rgb(0x20, 0x20, 0x20),
        .tint_opacity = 70,
        .reveal_enabled = true,
        .reveal_radius = 100,
        .reveal_opacity = 60,
        .depth_shadow_layers = 5,
        .depth_shadow_base = 12,
        .virtual_desktops_max = 16,
        .animation_spring_stiffness = 300,
        .animation_damping = 20,
        .mpo_enabled = true,
    });

    vtree.init();
    vtree.createTree();
}

pub fn render() void {
    theme.setTheme(.fluent);
    if (!dwm.isInitialized()) initDwm();
    renderFrame();
}

pub fn renderFrame() void {
    if (!fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = theme.getActiveTheme();
    const tb_h = theme.getTaskbarHeight();

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
        fb.drawGradientV(0, 0, w, h, rgb(0x00, 0x47, 0x8A), rgb(0x00, 0x2A, 0x55));
        display.renderDesktopIcons(w, h, t);
        renderWindow(w, h, t);
        renderOsInterfaceWindows(w, h, t, tb_h);
        renderTaskbar(w, h, t, tb_h);

        if (startmenu.isVisible()) {
            startmenu.render(w, h);
        }

        if (action_center_visible) {
            renderActionCenter(w, h, t);
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
    const fl_titlebar_h: i32 = 32;

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);
    fb.fillRect(win_x, win_y, win_w, fl_titlebar_h, t.titlebar_active_left);

    fb.drawTextTransparent(win_x + 34, win_y + 8, "File Explorer", t.titlebar_text);

    const btn_w: i32 = 46;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, fl_titlebar_h, t.btn_close_top);
    display.drawCloseSymbol(close_x, win_y, btn_w);

    fb.drawHLine(win_x, win_y + fl_titlebar_h, win_w, t.tray_border);
    renderWindowContent(win_x + 1, win_y + fl_titlebar_h, win_w - 2, win_h - fl_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
}

fn renderWindow(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    const wr = display.getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const fl_titlebar_h: i32 = 32;

    if (dwm.isShadowEnabled()) {
        mat.renderShadow(win_x, win_y, win_w, win_h, 12, 5);
    }

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);

    if (dwm.isGlassEnabled()) {
        mat.renderAcrylic(win_x, win_y, win_w, fl_titlebar_h);
    } else {
        fb.fillRect(win_x, win_y, win_w, fl_titlebar_h, t.titlebar_active_left);
    }

    fb.fillRoundedRect(win_x + 8, win_y + 6, 20, 20, 3, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(win_x + 14, win_y + 8, "F", rgb(0xFF, 0xFF, 0xFF));
    fb.drawTextTransparent(win_x + 34, win_y + 8, "File Explorer", t.titlebar_text);

    const btn_w: i32 = 46;
    const btn_h: i32 = fl_titlebar_h;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, btn_h, t.btn_close_top);
    display.drawCloseSymbol(close_x, win_y, btn_w);
    fb.fillRect(close_x - btn_w, win_y, btn_w, btn_h, t.btn_minmax_top);
    display.drawMaxSymbol(close_x - btn_w, win_y, btn_w);
    fb.fillRect(close_x - btn_w * 2, win_y, btn_w, btn_h, t.btn_minmax_top);
    display.drawMinSymbol(close_x - btn_w * 2, win_y, btn_w);

    fb.drawHLine(win_x, win_y + fl_titlebar_h, win_w, t.tray_border);
    renderWindowContent(win_x + 1, win_y + fl_titlebar_h, win_w - 2, win_h - fl_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
}

fn renderWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const theme.ThemeColors) void {
    fb.fillRect(x, y, w, 36, rgb(0xF3, 0xF3, 0xF3));
    fb.drawHLine(x, y + 36, w, t.button_shadow);

    const tabs = [_][]const u8{ "Home", "Share", "View" };
    var tx: i32 = x + 8;
    for (tabs, 0..) |tab, i| {
        const tw = fb.textWidth(tab) + 16;
        if (i == 0) {
            fb.fillRect(tx, y, tw, 36, rgb(0xFF, 0xFF, 0xFF));
            fb.drawHLine(tx, y + 34, tw, rgb(0x00, 0x67, 0xC0));
        }
        fb.drawTextTransparent(tx + 8, y + 10, tab, if (i == 0) rgb(0x00, 0x67, 0xC0) else rgb(0x40, 0x40, 0x40));
        tx += tw + 4;
    }

    const addr_y = y + 37;
    fb.fillRect(x, addr_y, w, 28, rgb(0xF9, 0xF9, 0xF9));
    fb.drawHLine(x, addr_y + 28, w, t.button_shadow);
    fb.fillRoundedRect(x + 8, addr_y + 3, w - 16, 22, 3, rgb(0xFF, 0xFF, 0xFF));
    fb.drawRect(x + 8, addr_y + 3, w - 16, 22, rgb(0x80, 0x80, 0x80));
    fb.fillRect(x + 8, addr_y + 23, w - 16, 2, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(x + 16, addr_y + 7, "> This PC > C:\\", rgb(0x00, 0x00, 0x00));

    const content_y = addr_y + 29;
    const content_h = h - 93;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, rgb(0xF4, 0xF6, 0xFA));
        const nav_w: i32 = 150;
        fb.fillRect(x, content_y, nav_w, content_h, rgb(0xF3, 0xF3, 0xF3));
        fb.drawVLine(x + nav_w, content_y, content_h, rgb(0xE0, 0xE0, 0xE0));

        const nav_items = [_][]const u8{ "Quick access", "Desktop", "Downloads", "Documents", "This PC", "C:\\", "D:\\" };
        var ny: i32 = content_y + 4;
        for (nav_items, 0..) |item, i| {
            if (i == 4) {
                fb.drawHLine(x + 8, ny, nav_w - 16, rgb(0xE0, 0xE0, 0xE0));
                ny += 6;
            }
            if (i == 0) {
                fb.fillRoundedRect(x + 2, ny, nav_w - 4, 20, 3, rgb(0xE5, 0xF1, 0xFB));
            }
            fb.drawTextTransparent(x + 12, ny + 3, item, if (i == 0) rgb(0x00, 0x3C, 0x80) else rgb(0x1A, 0x1A, 0x1A));
            ny += 22;
        }

        const list_x = x + nav_w + 1;
        const list_w = w - nav_w - 1;
        fb.fillRect(list_x, content_y, list_w, 20, rgb(0xF5, 0xF5, 0xF5));
        fb.drawHLine(list_x, content_y + 20, list_w, rgb(0xE0, 0xE0, 0xE0));
        fb.drawTextTransparent(list_x + 28, content_y + 3, "Name", rgb(0x40, 0x40, 0x40));
        if (list_w > 260) {
            fb.drawTextTransparent(list_x + list_w - 200, content_y + 3, "Date modified", rgb(0x40, 0x40, 0x40));
            fb.drawTextTransparent(list_x + list_w - 80, content_y + 3, "Size", rgb(0x40, 0x40, 0x40));
        }

        const items = [_]struct { name: []const u8, date: []const u8, size: []const u8, icon_id: icons.IconId }{
            .{ .name = "Users", .date = "2026/01/15", .size = "", .icon_id = .documents },
            .{ .name = "Programs", .date = "2026/03/20", .size = "", .icon_id = .documents },
            .{ .name = "System", .date = "2026/02/10", .size = "", .icon_id = .documents },
            .{ .name = "resources", .date = "2026/01/01", .size = "", .icon_id = .documents },
            .{ .name = "boot.cfg", .date = "2026/01/01", .size = "1 KB", .icon_id = .computer },
            .{ .name = "zloader", .date = "2026/03/21", .size = "512 KB", .icon_id = .computer },
        };
        var iy: i32 = content_y + 22;
        for (items, 0..) |item, idx| {
            if (iy + 22 > content_y + content_h) break;
            if (idx % 2 == 1) {
                fb.fillRect(list_x, iy, list_w, 22, rgb(0xF8, 0xFA, 0xFD));
            }
            display.drawThemedIconForActiveTheme(item.icon_id, list_x + 6, iy + 3, 1);
            fb.drawTextTransparent(list_x + 28, iy + 4, item.name, rgb(0x00, 0x00, 0x00));
            if (list_w > 260) {
                fb.drawTextTransparent(list_x + list_w - 200, iy + 4, item.date, rgb(0x60, 0x60, 0x60));
                fb.drawTextTransparent(list_x + list_w - 80, iy + 4, item.size, rgb(0x60, 0x60, 0x60));
            }
            iy += 22;
        }

        const sb_x = list_x + list_w - 14;
        fb.fillRect(sb_x, content_y + 21, 14, content_h - 21, rgb(0xF5, 0xF5, 0xF5));
        fb.fillRoundedRect(sb_x + 3, content_y + 24, 8, 36, 4, rgb(0xC0, 0xC0, 0xC8));
    }

    fb.fillRect(x, y + h - 24, w, 24, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(x + 8, y + h - 19, "6 items | This PC | Fluent Design", rgb(0xFF, 0xFF, 0xFF));
}

fn renderOsInterfaceWindows(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors, tb_h: i32) void {
    _ = scr_w;
    const tb_y = scr_h - tb_h;
    const os_x: i32 = 560;
    const btn_w: i32 = 36;
    const btn_spacing: i32 = 4;
    const btn_h: i32 = 28;
    const btn_y = tb_y + @divTrunc(tb_h - btn_h, 2);

    const os_labels = [_][]const u8{ "C", "D", "P" };
    const os_colors = [_]u32{
        rgb(0x00, 0x67, 0xC0),
        rgb(0x1E, 0x1E, 0x1E),
        rgb(0x01, 0x24, 0x56),
    };

    for (os_labels, 0..) |lbl, i| {
        const bx = os_x + @as(i32, @intCast(i)) * (btn_w + btn_spacing);
        fb.fillRect(bx, btn_y, btn_w, btn_h, os_colors[i]);
        fb.drawTextTransparent(bx + 12, btn_y + 6, lbl, t.clock_text);
        fb.drawHLine(bx, btn_y + btn_h - 2, btn_w, rgb(0x44, 0x44, 0x44));
    }
}

fn renderTaskbar(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;
    if (dwm.isGlassEnabled()) {
        dwm.renderGlassEffect(0, tb_y, scr_w, tb_h, rgb(0x28, 0x28, 0x32), .taskbar);
    } else {
        fb.drawGradientV(0, tb_y, scr_w, tb_h, t.taskbar_top, t.taskbar_bottom);
    }
    fb.drawHLine(0, tb_y, scr_w, t.tray_border);

    const start_y = tb_y + @divTrunc(tb_h - 32, 2);
    fb.fillRoundedRect(4, start_y, 36, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    display.renderZirconLogo(15, start_y + 9);
    fb.fillRect(12, tb_y + tb_h - 3, 20, 2, rgb(0x00, 0x67, 0xC0));

    const search_x: i32 = 48;
    const search_w: i32 = 220;
    const search_y = tb_y + @divTrunc(tb_h - 32, 2);
    fb.fillRoundedRect(search_x, search_y, search_w, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    fb.drawRect(search_x, search_y, search_w, 32, rgb(0x44, 0x44, 0x44));
    fb.drawTextTransparent(search_x + 10, search_y + 8, "S", rgb(0x88, 0x88, 0x88));
    fb.drawTextTransparent(search_x + 24, search_y + 8, "Type here to search", rgb(0x66, 0x66, 0x66));

    const tv_x = search_x + search_w + 6;
    fb.fillRoundedRect(tv_x, start_y, 36, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    fb.drawRect(tv_x + 8, start_y + 6, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 18, start_y + 6, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 8, start_y + 16, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 18, start_y + 16, 8, 8, rgb(0xAA, 0xAA, 0xAA));

    const pin_x = tv_x + 42;
    const pin_labels = [_]struct { lbl: []const u8, active: bool }{
        .{ .lbl = "E", .active = true },
        .{ .lbl = "F", .active = true },
        .{ .lbl = "T", .active = false },
        .{ .lbl = "S", .active = false },
    };
    var ix: i32 = pin_x;
    for (pin_labels) |p| {
        const iy = tb_y + @divTrunc(tb_h - 32, 2);
        fb.fillRoundedRect(ix, iy, 36, 32, 4, if (p.active) rgb(0x38, 0x38, 0x38) else rgb(0x20, 0x20, 0x20));
        fb.drawTextTransparent(ix + 12, iy + 8, p.lbl, t.clock_text);
        if (p.active) {
            fb.fillRect(ix + 10, tb_y + tb_h - 3, 16, 2, rgb(0x00, 0x67, 0xC0));
        }
        ix += 40;
    }

    ix += 8;
    const os_labels = [_]struct { label: []const u8, color: u32 }{
        .{ .label = "C", .color = rgb(0x00, 0x67, 0xC0) },
        .{ .label = "D", .color = rgb(0x1E, 0x1E, 0x1E) },
        .{ .label = "P", .color = rgb(0x01, 0x24, 0x56) },
    };
    for (os_labels) |os| {
        const iy = tb_y + @divTrunc(tb_h - 28, 2);
        fb.fillRoundedRect(ix, iy, 32, 28, 3, os.color);
        fb.drawTextTransparent(ix + 10, iy + 6, os.label, t.clock_text);
        fb.fillRect(ix + 8, tb_y + tb_h - 3, 16, 2, rgb(0x44, 0x44, 0x44));
        ix += 36;
    }

    renderTray(scr_w, tb_y, tb_h, t);
}

fn renderTray(scr_w: i32, tb_y: i32, tb_h: i32, t: *const theme.ThemeColors) void {
    const tray_w: i32 = 140;
    const tray_x = scr_w - tray_w - 8;
    const tray_y = tb_y + @divTrunc(tb_h - 24, 2);
    fb.fillRect(tray_x, tray_y, tray_w, 24, t.tray_bg);
    fb.drawTextTransparent(tray_x + 8, tray_y + 4, "12:00 PM", t.clock_text);
    const ac_x = tray_x - 28;
    fb.drawTextTransparent(ac_x + 6, tray_y + 4, "^", t.clock_text);
}

fn renderActionCenter(scr_w: i32, scr_h: i32, t: *const theme.ThemeColors) void {
    const ac_w: i32 = 320;
    const ac_h: i32 = 400;
    const ac_x = scr_w - ac_w - 8;
    const ac_y = scr_h - 48 - ac_h - 8;

    if (dwm.isShadowEnabled()) {
        mat.renderShadow(ac_x, ac_y, ac_w, ac_h, 10, 4);
    }

    fb.fillRect(ac_x, ac_y, ac_w, ac_h, t.window_bg);
    if (dwm.isGlassEnabled()) {
        mat.renderAcrylic(ac_x, ac_y, ac_w, ac_h);
    }
    fb.drawRect(ac_x, ac_y, ac_w, ac_h, t.window_border);

    fb.drawTextTransparent(ac_x + 16, ac_y + 12, "Quick Actions", rgb(0xCC, 0xCC, 0xCC));
    fb.drawHLine(ac_x + 16, ac_y + 32, ac_w - 32, t.tray_border);

    const toggles = [_][]const u8{ "WiFi", "Bluetooth", "Airplane", "Night Light", "Focus", "Location" };
    var ty: i32 = ac_y + 44;
    var col: i32 = 0;
    for (toggles) |toggle| {
        const tx = ac_x + 16 + col * 96;
        fb.fillRect(tx, ty, 84, 36, rgb(0x00, 0x67, 0xC0));
        fb.drawTextTransparent(tx + 8, ty + 10, toggle, rgb(0xFF, 0xFF, 0xFF));
        col += 1;
        if (col >= 3) {
            col = 0;
            ty += 44;
        }
    }

    ty += if (col > 0) 52 else 8;
    fb.drawTextTransparent(ac_x + 16, ty, "Brightness", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRect(ac_x + 16, ty + 18, ac_w - 32, 4, rgb(0x44, 0x44, 0x44));
    fb.fillRect(ac_x + 16, ty + 18, @divTrunc((ac_w - 32) * 3, 4), 4, rgb(0x00, 0x67, 0xC0));

    ty += 36;
    fb.drawTextTransparent(ac_x + 16, ty, "Volume", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRect(ac_x + 16, ty + 18, ac_w - 32, 4, rgb(0x44, 0x44, 0x44));
    fb.fillRect(ac_x + 16, ty + 18, @divTrunc((ac_w - 32) * 2, 3), 4, rgb(0x00, 0x67, 0xC0));
}

fn patchDragBackground(scr_w: i32, scr_h: i32) void {
    const pad: i32 = 10;
    const topc = rgb(0x00, 0x47, 0x8A);
    const botc = rgb(0x00, 0x2A, 0x55);
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
