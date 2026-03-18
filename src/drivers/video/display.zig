//! Display Manager / Desktop Compositor
//! Renders a complete Windows XP Luna Blue desktop environment using
//! the framebuffer driver. References ZirconOSLuna theme definitions and
//! ReactOS win32ss/ display architecture.

const io = @import("../../io/io.zig");
const klog = @import("../../rtl/klog.zig");
const vga_driver = @import("vga.zig");
const hdmi_driver = @import("hdmi.zig");
const fb = @import("framebuffer.zig");

// ── Luna Blue Theme Colors (matching 3rdparty/ZirconOSLuna/src/theme.zig) ──

const LunaColors = struct {
    desktop_bg: u32,
    taskbar_top: u32,
    taskbar_bottom: u32,
    start_btn_top: u32,
    start_btn_bottom: u32,
    start_btn_text: u32,
    titlebar_active_left: u32,
    titlebar_active_right: u32,
    titlebar_text: u32,
    window_bg: u32,
    window_border: u32,
    tray_bg: u32,
    clock_text: u32,
    icon_text: u32,
    icon_text_shadow: u32,
    btn_close_top: u32,
    btn_close_bottom: u32,
    btn_minmax_top: u32,
    btn_minmax_bottom: u32,
    selection_bg: u32,
    tooltip_bg: u32,
    button_face: u32,
    button_highlight: u32,
    button_shadow: u32,
    menu_bg: u32,
    menu_separator: u32,
    start_header_top: u32,
    start_header_bottom: u32,
    start_right_bg: u32,
    tray_border: u32,
};

fn lunaRGB(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

const LUNA_BLUE = LunaColors{
    .desktop_bg = lunaRGB(0x00, 0x4E, 0x98),
    .taskbar_top = lunaRGB(0x00, 0x54, 0xE3),
    .taskbar_bottom = lunaRGB(0x01, 0x50, 0xD0),
    .start_btn_top = lunaRGB(0x3C, 0x8D, 0x2E),
    .start_btn_bottom = lunaRGB(0x3F, 0xAA, 0x3B),
    .start_btn_text = lunaRGB(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = lunaRGB(0x00, 0x58, 0xE6),
    .titlebar_active_right = lunaRGB(0x3A, 0x81, 0xE5),
    .titlebar_text = lunaRGB(0xFF, 0xFF, 0xFF),
    .window_bg = lunaRGB(0xFF, 0xFF, 0xFF),
    .window_border = lunaRGB(0x00, 0x55, 0xE5),
    .tray_bg = lunaRGB(0x0E, 0x8A, 0xEB),
    .clock_text = lunaRGB(0xFF, 0xFF, 0xFF),
    .icon_text = lunaRGB(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = lunaRGB(0x00, 0x00, 0x00),
    .btn_close_top = lunaRGB(0xD4, 0x4A, 0x3C),
    .btn_close_bottom = lunaRGB(0xB0, 0x2C, 0x20),
    .btn_minmax_top = lunaRGB(0x2C, 0x5C, 0xD0),
    .btn_minmax_bottom = lunaRGB(0x1C, 0x48, 0xB0),
    .selection_bg = lunaRGB(0x31, 0x6A, 0xC5),
    .tooltip_bg = lunaRGB(0xFF, 0xFF, 0xE1),
    .button_face = lunaRGB(0xEC, 0xE9, 0xD8),
    .button_highlight = lunaRGB(0xFF, 0xFF, 0xFF),
    .button_shadow = lunaRGB(0xAC, 0xA8, 0x99),
    .menu_bg = lunaRGB(0xFF, 0xFF, 0xFF),
    .menu_separator = lunaRGB(0xC5, 0xC5, 0xC5),
    .start_header_top = lunaRGB(0x00, 0x55, 0xE5),
    .start_header_bottom = lunaRGB(0x00, 0x3D, 0xB0),
    .start_right_bg = lunaRGB(0xD3, 0xE5, 0xFA),
    .tray_border = lunaRGB(0x00, 0x3C, 0xA0),
};

const theme = LUNA_BLUE;

// ── Display Mode / State ──

pub const DisplayMode = enum(u8) { text = 0, graphics_lowres = 1, graphics_svga = 2, graphics_hd = 3, desktop = 4 };
pub const DisplayState = enum(u8) { uninitialized = 0, text_mode = 1, graphics_mode = 2, desktop_mode = 3, suspended = 4 };

pub const Surface = struct {
    width: u32 = 0,
    height: u32 = 0,
    bpp: u8 = 0,
    pitch: u32 = 0,
    address: usize = 0,
    format: fb.PixelFormat = .xrgb8888,
};

pub const DesktopContext = struct {
    surface: Surface = .{},
    background_color: u32 = 0,
    cursor_x: i32 = 0,
    cursor_y: i32 = 0,
    cursor_visible: bool = true,
    vsync_enabled: bool = true,
    frame_count: u64 = 0,
};

// ── Global State ──

var display_state: DisplayState = .uninitialized;
var display_mode: DisplayMode = .text;
var desktop_ctx: DesktopContext = .{};

var driver_idx: u32 = 0xFFFFFFFF;
var device_idx: u32 = 0xFFFFFFFF;
var driver_initialized: bool = false;

var use_framebuffer: bool = false;
var use_hdmi: bool = false;

// ── Layout Constants ──

const TASKBAR_H: i32 = 30;
const TITLEBAR_H: i32 = 26;
const START_BTN_W: i32 = 108;
const ICON_GRID_X: i32 = 75;
const ICON_GRID_Y: i32 = 75;
const ICON_SIZE: i32 = 32;
const TRAY_CLOCK_W: i32 = 64;
const TRAY_H: i32 = 22;
const WINDOW_BORDER: i32 = 3;
const BTN_SIZE: i32 = 21;

// ── IOCTL Codes ──

pub const IOCTL_DISPLAY_GET_STATE: u32 = 0x000A0000;
pub const IOCTL_DISPLAY_SET_MODE: u32 = 0x000A0004;
pub const IOCTL_DISPLAY_GET_SURFACE: u32 = 0x000A0008;
pub const IOCTL_DISPLAY_SET_BG_COLOR: u32 = 0x000A000C;
pub const IOCTL_DISPLAY_SET_CURSOR: u32 = 0x000A0010;
pub const IOCTL_DISPLAY_PRESENT: u32 = 0x000A0014;
pub const IOCTL_DISPLAY_ENUMERATE: u32 = 0x000A0018;

// ── Display Initialization ──

pub fn initDesktopMode(fb_addr: usize, width: u32, height: u32, pitch: u32, bpp: u8) void {
    fb.init(fb_addr, width, height, pitch, bpp);
    use_framebuffer = true;

    desktop_ctx.surface = .{
        .width = width,
        .height = height,
        .bpp = bpp,
        .pitch = pitch,
        .address = fb_addr,
        .format = if (bpp == 32) .xrgb8888 else if (bpp == 24) .rgb888 else .rgb565,
    };

    display_state = .desktop_mode;
    display_mode = .desktop;
}

pub fn initTextMode() void {
    vga_driver.init();
    vga_driver.setTextMode();
    display_state = .text_mode;
    display_mode = .text;
}

// ══════════════════════════════════════════════════════════════
//  Complete Luna Blue Desktop Rendering
// ══════════════════════════════════════════════════════════════

pub fn renderLunaDesktop() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());

    renderDesktopBackground(theme.desktop_bg);

    renderDesktopIcons(w, h);

    renderSampleWindow(w, h);

    renderLunaTaskbar(w, h);

    renderCursor(@divTrunc(w, 2), @divTrunc(h, 2));

    desktop_ctx.frame_count += 1;
}

// ── Desktop Background ──

pub fn renderDesktopBackground(color: u32) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    desktop_ctx.background_color = color;
    fb.clearScreen(color);
}

// ── Desktop Icons ──

const IconInfo = struct {
    label: []const u8,
    color: u32,
};

const desktop_icons = [_]IconInfo{
    .{ .label = "My Computer", .color = lunaRGB(0xE0, 0xC0, 0x30) },
    .{ .label = "My Documents", .color = lunaRGB(0xFF, 0xE0, 0x80) },
    .{ .label = "Network", .color = lunaRGB(0x40, 0x60, 0xA0) },
    .{ .label = "Recycle Bin", .color = lunaRGB(0x80, 0x80, 0x80) },
    .{ .label = "Internet", .color = lunaRGB(0x00, 0x60, 0xE0) },
};

fn renderDesktopIcons(scr_w: i32, scr_h: i32) void {
    _ = scr_w;
    const base_x: i32 = 20;
    var base_y: i32 = 16;
    const avail_h = scr_h - TASKBAR_H - 16;

    for (desktop_icons) |icon| {
        if (base_y + ICON_GRID_Y > avail_h) break;
        renderOneIcon(base_x, base_y, icon);
        base_y += ICON_GRID_Y;
    }
}

fn renderOneIcon(x: i32, y: i32, icon: IconInfo) void {
    const ix = x + @divTrunc(ICON_GRID_X - ICON_SIZE, 2);
    const iy = y;

    fb.fillRoundedRect(ix + 2, iy + 2, ICON_SIZE, ICON_SIZE, 4, lunaRGB(0x00, 0x00, 0x00) & 0x40000000);

    fb.fillRoundedRect(ix, iy, ICON_SIZE, ICON_SIZE, 4, icon.color);
    fb.drawRect(ix, iy, ICON_SIZE, ICON_SIZE, lunaRGB(0x80, 0x80, 0x80));

    drawIconDetail(ix, iy, icon.color);

    const label = icon.label;
    const label_w = fb.textWidth(label);
    const tx = x + @divTrunc(ICON_GRID_X - label_w, 2);
    const ty = iy + ICON_SIZE + 4;

    fb.drawTextTransparent(tx + 1, ty + 1, label, theme.icon_text_shadow);
    fb.drawTextTransparent(tx, ty, label, theme.icon_text);
}

fn drawIconDetail(ix: i32, iy: i32, color: u32) void {
    _ = color;
    const cx = ix + @divTrunc(ICON_SIZE, 2);
    const cy = iy + @divTrunc(ICON_SIZE, 2);
    fb.fillRect(cx - 6, cy - 6, 12, 12, lunaRGB(0xFF, 0xFF, 0xFF));
    fb.drawRect(cx - 6, cy - 6, 12, 12, lunaRGB(0x40, 0x40, 0x40));
}

// ── Taskbar ──

fn renderLunaTaskbar(scr_w: i32, scr_h: i32) void {
    const tb_y = scr_h - TASKBAR_H;

    fb.drawGradientV(0, tb_y, scr_w, TASKBAR_H, theme.taskbar_top, theme.taskbar_bottom);
    fb.drawHLine(0, tb_y, scr_w, lunaRGB(0x00, 0x40, 0xD0));

    renderLunaStartButton(0, tb_y, START_BTN_W, TASKBAR_H);

    renderSystemTray(scr_w, tb_y, scr_h);
}

fn renderLunaStartButton(x: i32, y: i32, w: i32, h: i32) void {
    fb.fillRoundedRect(x + 1, y + 1, w, h - 1, 6, theme.start_btn_bottom);
    fb.fillRoundedRect(x, y, w, h - 1, 6, theme.start_btn_top);
    fb.drawGradientV(x + 6, y + 2, w - 12, h - 4, theme.start_btn_top, theme.start_btn_bottom);

    renderWindowsFlag(x + 8, y + 7);

    fb.drawTextTransparent(x + 28, y + 7, "start", theme.start_btn_text);
}

fn renderWindowsFlag(x: i32, y: i32) void {
    fb.fillRect(x, y, 6, 6, lunaRGB(0xFF, 0x00, 0x00));
    fb.fillRect(x + 7, y, 6, 6, lunaRGB(0x00, 0xAA, 0x00));
    fb.fillRect(x, y + 7, 6, 6, lunaRGB(0x00, 0x00, 0xFF));
    fb.fillRect(x + 7, y + 7, 6, 6, lunaRGB(0xFF, 0xCC, 0x00));
}

fn renderSystemTray(scr_w: i32, tb_y: i32, scr_h: i32) void {
    _ = scr_h;
    const tray_w: i32 = TRAY_CLOCK_W + 40;
    const tray_x = scr_w - tray_w;
    const tray_y = tb_y + @divTrunc(TASKBAR_H - TRAY_H, 2);

    fb.fillRect(tray_x, tray_y, tray_w, TRAY_H, theme.tray_bg);
    fb.drawVLine(tray_x, tray_y, TRAY_H, theme.tray_border);

    fb.drawTextTransparent(tray_x + 8, tray_y + 3, "12:00 PM", theme.clock_text);
}

// ── Sample Window ──

fn renderSampleWindow(scr_w: i32, scr_h: i32) void {
    const win_w: i32 = if (scr_w > 600) 520 else scr_w - 140;
    const win_h: i32 = if (scr_h > 500) 380 else scr_h - 160;
    const win_x: i32 = @divTrunc(scr_w - win_w, 2) + 30;
    const win_y: i32 = @divTrunc(scr_h - TASKBAR_H - win_h, 2);

    fb.fillRect(win_x + 4, win_y + 4, win_w, win_h, lunaRGB(0x00, 0x00, 0x00) & 0x20000000);

    fb.fillRect(win_x, win_y, win_w, win_h, theme.window_bg);

    fb.drawGradientH(win_x, win_y, win_w, TITLEBAR_H, theme.titlebar_active_left, theme.titlebar_active_right);

    renderTitlebarButtons(win_x, win_y, win_w);

    fb.drawTextTransparent(win_x + 8, win_y + 5, "My Computer", theme.titlebar_text);

    fb.drawRect(win_x, win_y, win_w, win_h, theme.window_border);
    fb.drawRect(win_x + 1, win_y + 1, win_w - 2, win_h - 2, lunaRGB(0x40, 0x80, 0xE0));

    renderWindowContent(win_x + WINDOW_BORDER, win_y + TITLEBAR_H, win_w - 2 * WINDOW_BORDER, win_h - TITLEBAR_H - WINDOW_BORDER);
}

fn renderTitlebarButtons(win_x: i32, win_y: i32, win_w: i32) void {
    const btn_y = win_y + @divTrunc(TITLEBAR_H - BTN_SIZE, 2);
    const close_x = win_x + win_w - BTN_SIZE - 4;
    const max_x = close_x - BTN_SIZE - 2;
    const min_x = max_x - BTN_SIZE - 2;

    fb.fillRoundedRect(close_x, btn_y, BTN_SIZE, BTN_SIZE, 3, theme.btn_close_top);
    drawCloseSymbol(close_x, btn_y, BTN_SIZE);

    fb.fillRoundedRect(max_x, btn_y, BTN_SIZE, BTN_SIZE, 3, theme.btn_minmax_top);
    drawMaxSymbol(max_x, btn_y, BTN_SIZE);

    fb.fillRoundedRect(min_x, btn_y, BTN_SIZE, BTN_SIZE, 3, theme.btn_minmax_top);
    drawMinSymbol(min_x, btn_y, BTN_SIZE);
}

fn drawCloseSymbol(bx: i32, by: i32, bs: i32) void {
    const cx = bx + @divTrunc(bs, 2);
    const cy = by + @divTrunc(bs, 2);
    const white = lunaRGB(0xFF, 0xFF, 0xFF);
    var i: i32 = -3;
    while (i <= 3) : (i += 1) {
        fb.putPixel32(@intCast(cx + i), @intCast(cy + i), white);
        fb.putPixel32(@intCast(cx + i), @intCast(cy - i), white);
        if (i > -3 and i < 3) {
            fb.putPixel32(@intCast(cx + i + 1), @intCast(cy + i), white);
            fb.putPixel32(@intCast(cx + i + 1), @intCast(cy - i), white);
        }
    }
}

fn drawMaxSymbol(bx: i32, by: i32, bs: i32) void {
    const white = lunaRGB(0xFF, 0xFF, 0xFF);
    const ox = bx + 5;
    const oy = by + 5;
    const sz = bs - 10;
    fb.drawRect(ox, oy, sz, sz, white);
    fb.drawHLine(ox, oy + 1, sz, white);
}

fn drawMinSymbol(bx: i32, by: i32, bs: i32) void {
    const white = lunaRGB(0xFF, 0xFF, 0xFF);
    fb.fillRect(bx + 5, by + bs - 8, bs - 10, 3, white);
}

fn renderWindowContent(x: i32, y: i32, w: i32, h: i32) void {
    fb.fillRect(x, y, w, 24, theme.button_face);
    fb.drawHLine(x, y + 24, w, theme.button_shadow);

    const toolbar_items = [_][]const u8{ "File", "Edit", "View", "Favorites", "Tools", "Help" };
    var tx: i32 = x + 8;
    for (toolbar_items) |item| {
        fb.drawTextTransparent(tx, y + 4, item, lunaRGB(0x00, 0x00, 0x00));
        tx += fb.textWidth(item) + 16;
    }

    const addr_y = y + 25;
    fb.fillRect(x, addr_y, w, 22, theme.button_face);
    fb.drawHLine(x, addr_y + 22, w, theme.button_shadow);
    fb.drawTextTransparent(x + 8, addr_y + 3, "Address: C:\\", lunaRGB(0x00, 0x00, 0x00));

    const content_y = addr_y + 23;
    const content_h = h - 47;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, lunaRGB(0xFF, 0xFF, 0xFF));

        const items = [_]struct { name: []const u8, color: u32 }{
            .{ .name = "Documents and Settings", .color = lunaRGB(0xFF, 0xE0, 0x80) },
            .{ .name = "Program Files", .color = lunaRGB(0xFF, 0xE0, 0x80) },
            .{ .name = "Windows", .color = lunaRGB(0xFF, 0xE0, 0x80) },
            .{ .name = "AUTOEXEC.BAT", .color = lunaRGB(0xC0, 0xC0, 0xC0) },
            .{ .name = "boot.ini", .color = lunaRGB(0xC0, 0xC0, 0xC0) },
            .{ .name = "ntldr", .color = lunaRGB(0xC0, 0xC0, 0xC0) },
        };

        var iy: i32 = content_y + 8;
        for (items) |item| {
            if (iy + 20 > content_y + content_h) break;

            fb.fillRect(x + 10, iy + 2, 16, 14, item.color);
            fb.drawRect(x + 10, iy + 2, 16, 14, lunaRGB(0x80, 0x80, 0x80));

            fb.drawTextTransparent(x + 32, iy + 2, item.name, lunaRGB(0x00, 0x00, 0x00));
            iy += 22;
        }

        const sb_x = x + w - 17;
        fb.fillRect(sb_x, content_y, 17, content_h, lunaRGB(0xE8, 0xE8, 0xEB));
        fb.drawVLine(sb_x, content_y, content_h, theme.button_shadow);
        fb.fillRect(sb_x + 1, content_y + 17, 16, 40, lunaRGB(0xC1, 0xC1, 0xC6));
    }

    fb.fillRect(x, y + h - 22, w, 22, theme.button_face);
    fb.drawHLine(x, y + h - 22, w, theme.button_shadow);
    fb.drawTextTransparent(x + 8, y + h - 18, "6 objects", lunaRGB(0x00, 0x00, 0x00));
}

// ── Cursor Rendering ──

pub fn renderCursor(x: i32, y: i32) void {
    if (!use_framebuffer) return;

    const outline = lunaRGB(0x00, 0x00, 0x00);
    const fill = lunaRGB(0xFF, 0xFF, 0xFF);
    const w_i32: i32 = @intCast(fb.getWidth());
    const h_i32: i32 = @intCast(fb.getHeight());

    const cursor_shape = [_][12]u2{
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
        .{ 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 0, 0 },
        .{ 2, 1, 1, 2, 1, 1, 2, 0, 0, 0, 0, 0 },
        .{ 2, 1, 2, 0, 2, 1, 1, 2, 0, 0, 0, 0 },
        .{ 2, 2, 0, 0, 2, 1, 1, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 1, 1, 2, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 1, 1, 2, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0 },
    };

    for (cursor_shape, 0..) |row, dy| {
        for (row, 0..) |pixel, dx| {
            if (pixel != 0) {
                const px = x + @as(i32, @intCast(dx));
                const py = y + @as(i32, @intCast(dy));
                if (px >= 0 and px < w_i32 and py >= 0 and py < h_i32) {
                    const color: u32 = if (pixel == 1) fill else outline;
                    fb.putPixel32(@intCast(px), @intCast(py), color);
                }
            }
        }
    }
}

// ── Legacy Render Functions (backward compatibility) ──

pub fn renderGradientBackground(top_color: u32, bottom_color: u32) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    fb.drawGradientV(0, 0, @intCast(desktop_ctx.surface.width), @intCast(desktop_ctx.surface.height), top_color, bottom_color);
    desktop_ctx.frame_count += 1;
}

pub fn renderTaskbar(x: i32, y: i32, w: i32, h: i32, top_color: u32, bottom_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(x, y, w, h, top_color, bottom_color);
}

pub fn renderStartButton(x: i32, y: i32, w: i32, h: i32, top_color: u32, bottom_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(x, y, w, h, top_color, bottom_color);
    fb.drawRect(x, y, w, h, lunaRGB(0xFF, 0xFF, 0xFF));
}

pub fn renderWindow(x: i32, y: i32, w: i32, h: i32, titlebar_left: u32, titlebar_right: u32, border_color: u32, bg_color: u32, titlebar_height: i32) void {
    if (!use_framebuffer) return;
    fb.fillRect(x, y + titlebar_height, w, h - titlebar_height, bg_color);
    fb.drawGradientH(x, y, w, titlebar_height, titlebar_left, titlebar_right);
    fb.drawRect(x, y, w, h, border_color);
}

pub fn renderDesktopIcon(x: i32, y: i32, icon_size: i32, icon_color: u32, selected: bool) void {
    if (!use_framebuffer) return;
    fb.fillRect(x + 4, y + 4, icon_size - 8, icon_size - 8, icon_color);
    fb.drawRect(x + 4, y + 4, icon_size - 8, icon_size - 8, lunaRGB(0x80, 0x80, 0x80));
    if (selected) {
        fb.drawRect(x, y, icon_size, icon_size, lunaRGB(0x31, 0x6A, 0xC5));
    }
}

pub fn renderStartMenu(x: i32, y: i32, w: i32, h: i32, bg_color: u32, header_color: u32, header_height: i32) void {
    if (!use_framebuffer) return;
    fb.fillRect(x, y, w, h, bg_color);
    fb.fillRect(x, y, w, header_height, header_color);
    fb.drawRect(x, y, w, h, lunaRGB(0x80, 0x80, 0x80));
}

pub fn renderLoginScreen(width: u32, height: u32, top_color: u32, bottom_color: u32, panel_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(0, 0, @intCast(width), @intCast(height), top_color, bottom_color);
    const pw: i32 = 400;
    const ph: i32 = 300;
    const px: i32 = @intCast((width - @as(u32, @intCast(pw))) / 2);
    const py: i32 = @intCast((height - @as(u32, @intCast(ph))) / 2);
    fb.fillRect(px, py, pw, ph, panel_color);
    fb.drawRect(px, py, pw, ph, lunaRGB(0x80, 0x80, 0x80));
}

// ── Present / VSync ──

pub fn present() void {
    if (!use_framebuffer) return;
    fb.flipDirty();
    desktop_ctx.frame_count += 1;
}

pub fn presentFull() void {
    if (!use_framebuffer) return;
    fb.flip();
    desktop_ctx.frame_count += 1;
}

pub fn setCursorPosition(x: i32, y: i32) void {
    desktop_ctx.cursor_x = x;
    desktop_ctx.cursor_y = y;
}

// ── IRP Dispatch ──

fn displayDispatch(irp: *io.Irp) io.IoStatus {
    switch (irp.major_function) {
        .create, .close => {
            irp.complete(.success, 0);
            return .success;
        },
        .ioctl => return handleIoctl(irp),
        else => {
            irp.complete(.not_implemented, 0);
            return .not_implemented;
        },
    }
}

fn handleIoctl(irp: *io.Irp) io.IoStatus {
    switch (irp.ioctl_code) {
        IOCTL_DISPLAY_GET_STATE => {
            irp.complete(.success, @intFromEnum(display_state));
            return .success;
        },
        IOCTL_DISPLAY_GET_SURFACE => {
            irp.buffer_ptr = desktop_ctx.surface.address;
            irp.bytes_transferred = desktop_ctx.surface.pitch * desktop_ctx.surface.height;
            irp.complete(.success, desktop_ctx.surface.width);
            return .success;
        },
        IOCTL_DISPLAY_SET_BG_COLOR => {
            const color: u32 = @truncate(irp.buffer_ptr);
            renderDesktopBackground(color);
            irp.complete(.success, 0);
            return .success;
        },
        IOCTL_DISPLAY_PRESENT => {
            present();
            irp.complete(.success, 0);
            return .success;
        },
        IOCTL_DISPLAY_ENUMERATE => {
            irp.complete(.success, if (use_hdmi) hdmi_driver.getOutputCount() else 1);
            return .success;
        },
        else => {
            irp.complete(.not_implemented, 0);
            return .not_implemented;
        },
    }
}

// ── State Query ──

pub fn getDisplayState() DisplayState {
    return display_state;
}

pub fn getDisplayMode() DisplayMode {
    return display_mode;
}

pub fn getSurface() *const Surface {
    return &desktop_ctx.surface;
}

pub fn getDesktopContext() *const DesktopContext {
    return &desktop_ctx;
}

pub fn getFrameCount() u64 {
    return desktop_ctx.frame_count;
}

pub fn isDesktopReady() bool {
    return display_state == .desktop_mode and use_framebuffer and fb.isInitialized();
}

pub fn isInitialized() bool {
    return driver_initialized;
}

// ── Initialization ──

pub fn init() void {
    vga_driver.init();
    hdmi_driver.init();
    use_hdmi = hdmi_driver.isInitialized();

    driver_idx = io.registerDriver("\\Driver\\Display", displayDispatch) orelse {
        klog.err("Display: Failed to register driver", .{});
        return;
    };

    device_idx = io.createDevice("\\Device\\Display0", .framebuffer, driver_idx) orelse {
        klog.err("Display: Failed to create device", .{});
        return;
    };

    driver_initialized = true;

    klog.info("Display Manager: initialized (VGA=%s, HDMI=%s)", .{
        if (vga_driver.isInitialized()) "ready" else "n/a",
        if (use_hdmi) "ready" else "n/a",
    });
}
