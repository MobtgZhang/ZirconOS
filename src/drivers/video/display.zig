//! Display Manager / Desktop Compositor
//! Renders ZirconOS desktop environments with selectable themes.
//! Themes: Classic, Luna, Aero, Modern, Fluent, SunValley.
//! Each theme is an original ZirconOS design with unique visual identity.
//!
//! Three distinct rendering pipelines (matching Windows generations):
//!   Aero (NT 6.1):       D3D9 redirected surface → glass blur → specular → shadow
//!   Fluent (NT 6.3):     DirectComposition visual tree → Acrylic → Reveal highlight
//!   SunValley (NT 6.4):  WinUI 3 composition → Mica → SDF rounded corners → Snap Layout

const builtin = @import("builtin");
const io = @import("../../io/io.zig");
const klog = @import("../../rtl/klog.zig");
const vga_driver = @import("vga.zig");
const hdmi_driver = @import("hdmi.zig");
const fb = @import("framebuffer.zig");
const icons = @import("icons.zig");
const startmenu = @import("startmenu.zig");
const dwm_comp = @import("dwm_compositor.zig");
const mat = @import("material.zig");
const vtree = @import("visual_tree.zig");

const is_x86 = (builtin.target.cpu.arch == .x86_64);

// ── Theme Color Set ──

pub const ThemeColors = struct {
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
    button_face: u32,
    button_highlight: u32,
    button_shadow: u32,
    tray_border: u32,
    start_label: []const u8,
};

fn rgb(r: u32, g: u32, b: u32) u32 {
    return r | (g << 8) | (b << 16);
}

// ── Theme Definitions ──

pub const THEME_CLASSIC = ThemeColors{
    .desktop_bg = rgb(0x00, 0x80, 0x80),
    .taskbar_top = rgb(0xC0, 0xC0, 0xC0),
    .taskbar_bottom = rgb(0xC0, 0xC0, 0xC0),
    .start_btn_top = rgb(0xC0, 0xC0, 0xC0),
    .start_btn_bottom = rgb(0xA0, 0xA0, 0xA0),
    .start_btn_text = rgb(0x00, 0x00, 0x00),
    .titlebar_active_left = rgb(0x00, 0x00, 0x80),
    .titlebar_active_right = rgb(0x10, 0x84, 0xD0),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x80, 0x80, 0x80),
    .tray_bg = rgb(0xC0, 0xC0, 0xC0),
    .clock_text = rgb(0x00, 0x00, 0x00),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC0, 0xC0, 0xC0),
    .btn_close_bottom = rgb(0x80, 0x80, 0x80),
    .btn_minmax_top = rgb(0xC0, 0xC0, 0xC0),
    .btn_minmax_bottom = rgb(0x80, 0x80, 0x80),
    .selection_bg = rgb(0x00, 0x00, 0x80),
    .button_face = rgb(0xC0, 0xC0, 0xC0),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x80, 0x80, 0x80),
    .tray_border = rgb(0x80, 0x80, 0x80),
    .start_label = "Start",
};

pub const THEME_LUNA = ThemeColors{
    .desktop_bg = rgb(0x00, 0x4E, 0x98),
    .taskbar_top = rgb(0x00, 0x54, 0xE3),
    .taskbar_bottom = rgb(0x01, 0x50, 0xD0),
    .start_btn_top = rgb(0x3C, 0x8D, 0x2E),
    .start_btn_bottom = rgb(0x3F, 0xAA, 0x3B),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x58, 0xE6),
    .titlebar_active_right = rgb(0x3A, 0x81, 0xE5),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x00, 0x55, 0xE5),
    .tray_bg = rgb(0x0E, 0x8A, 0xEB),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xD4, 0x4A, 0x3C),
    .btn_close_bottom = rgb(0xB0, 0x2C, 0x20),
    .btn_minmax_top = rgb(0x2C, 0x5C, 0xD0),
    .btn_minmax_bottom = rgb(0x1C, 0x48, 0xB0),
    .selection_bg = rgb(0x31, 0x6A, 0xC5),
    .button_face = rgb(0xEC, 0xE9, 0xD8),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0xAC, 0xA8, 0x99),
    .tray_border = rgb(0x00, 0x3C, 0xA0),
    .start_label = "start",
};

pub const THEME_AERO = ThemeColors{
    .desktop_bg = rgb(0x2B, 0x56, 0x7A),
    .taskbar_top = rgb(0x28, 0x3A, 0x54),
    .taskbar_bottom = rgb(0x1C, 0x2A, 0x3E),
    .start_btn_top = rgb(0x3D, 0x79, 0xCB),
    .start_btn_bottom = rgb(0x24, 0x56, 0x9D),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x41, 0x80, 0xC8),
    .titlebar_active_right = rgb(0x6B, 0xA0, 0xD8),
    .titlebar_text = rgb(0x00, 0x00, 0x00),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x50, 0x78, 0xA8),
    .tray_bg = rgb(0x1C, 0x2A, 0x3E),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xE0, 0x4B, 0x3A),
    .btn_close_bottom = rgb(0xC0, 0x30, 0x20),
    .btn_minmax_top = rgb(0x40, 0x60, 0x90),
    .btn_minmax_bottom = rgb(0x30, 0x50, 0x80),
    .selection_bg = rgb(0x33, 0x99, 0xFF),
    .button_face = rgb(0xF0, 0xF0, 0xF0),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0xA0, 0xA0, 0xA0),
    .tray_border = rgb(0x40, 0x58, 0x78),
    .start_label = "Start",
};

pub const THEME_MODERN = ThemeColors{
    .desktop_bg = rgb(0x00, 0x78, 0xD7),
    .taskbar_top = rgb(0x1F, 0x1F, 0x1F),
    .taskbar_bottom = rgb(0x1F, 0x1F, 0x1F),
    .start_btn_top = rgb(0x00, 0x78, 0xD7),
    .start_btn_bottom = rgb(0x00, 0x60, 0xB0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x78, 0xD7),
    .titlebar_active_right = rgb(0x00, 0x78, 0xD7),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x00, 0x78, 0xD7),
    .tray_bg = rgb(0x1F, 0x1F, 0x1F),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xE8, 0x11, 0x23),
    .btn_close_bottom = rgb(0xC0, 0x00, 0x10),
    .btn_minmax_top = rgb(0x2D, 0x2D, 0x2D),
    .btn_minmax_bottom = rgb(0x1F, 0x1F, 0x1F),
    .selection_bg = rgb(0x00, 0x78, 0xD7),
    .button_face = rgb(0xCC, 0xCC, 0xCC),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x80, 0x80, 0x80),
    .tray_border = rgb(0x33, 0x33, 0x33),
    .start_label = "Start",
};

pub const THEME_FLUENT = ThemeColors{
    .desktop_bg = rgb(0x00, 0x47, 0x8A),
    .taskbar_top = rgb(0x20, 0x20, 0x20),
    .taskbar_bottom = rgb(0x20, 0x20, 0x20),
    .start_btn_top = rgb(0x00, 0x67, 0xC0),
    .start_btn_bottom = rgb(0x00, 0x55, 0xA0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x00, 0x5A, 0x9E),
    .titlebar_active_right = rgb(0x00, 0x5A, 0x9E),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xF3, 0xF3, 0xF3),
    .window_border = rgb(0x00, 0x5A, 0x9E),
    .tray_bg = rgb(0x20, 0x20, 0x20),
    .clock_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC4, 0x2B, 0x1C),
    .btn_close_bottom = rgb(0xA0, 0x20, 0x10),
    .btn_minmax_top = rgb(0x2D, 0x2D, 0x2D),
    .btn_minmax_bottom = rgb(0x20, 0x20, 0x20),
    .selection_bg = rgb(0x00, 0x67, 0xC0),
    .button_face = rgb(0xE1, 0xE1, 0xE1),
    .button_highlight = rgb(0xFF, 0xFF, 0xFF),
    .button_shadow = rgb(0x8A, 0x8A, 0x8A),
    .tray_border = rgb(0x38, 0x38, 0x38),
    .start_label = "Start",
};

pub const THEME_SUNVALLEY = ThemeColors{
    .desktop_bg = rgb(0x08, 0x12, 0x22),
    .taskbar_top = rgb(0x1C, 0x1C, 0x1C),
    .taskbar_bottom = rgb(0x1C, 0x1C, 0x1C),
    .start_btn_top = rgb(0x4C, 0xB0, 0xE8),
    .start_btn_bottom = rgb(0x28, 0x80, 0xC0),
    .start_btn_text = rgb(0xFF, 0xFF, 0xFF),
    .titlebar_active_left = rgb(0x1F, 0x1F, 0x1F),
    .titlebar_active_right = rgb(0x1F, 0x1F, 0x1F),
    .titlebar_text = rgb(0xFF, 0xFF, 0xFF),
    .window_bg = rgb(0xFF, 0xFF, 0xFF),
    .window_border = rgb(0x44, 0x44, 0x44),
    .tray_bg = rgb(0x1C, 0x1C, 0x1C),
    .clock_text = rgb(0xDD, 0xDD, 0xDD),
    .icon_text = rgb(0xFF, 0xFF, 0xFF),
    .icon_text_shadow = rgb(0x00, 0x00, 0x00),
    .btn_close_top = rgb(0xC4, 0x2B, 0x1C),
    .btn_close_bottom = rgb(0xA0, 0x20, 0x15),
    .btn_minmax_top = rgb(0x3A, 0x3A, 0x3A),
    .btn_minmax_bottom = rgb(0x30, 0x30, 0x30),
    .selection_bg = rgb(0x4C, 0xB0, 0xE8),
    .button_face = rgb(0x2D, 0x2D, 0x2D),
    .button_highlight = rgb(0x38, 0x38, 0x38),
    .button_shadow = rgb(0x44, 0x44, 0x44),
    .tray_border = rgb(0x40, 0x40, 0x40),
    .start_label = "",
};

// ── Theme Selection ──

pub const ThemeId = enum(u8) {
    classic = 0,
    luna = 1,
    aero = 2,
    modern = 3,
    fluent = 4,
    sunvalley = 5,
};

var active_theme: *const ThemeColors = &THEME_LUNA;
var active_theme_id: ThemeId = .luna;

pub fn setTheme(id: ThemeId) void {
    active_theme_id = id;
    active_theme = switch (id) {
        .classic => &THEME_CLASSIC,
        .luna => &THEME_LUNA,
        .aero => &THEME_AERO,
        .modern => &THEME_MODERN,
        .fluent => &THEME_FLUENT,
        .sunvalley => &THEME_SUNVALLEY,
    };
}

pub fn getActiveTheme() *const ThemeColors {
    return active_theme;
}

pub fn getActiveThemeId() ThemeId {
    return active_theme_id;
}

pub fn getThemeName() []const u8 {
    return switch (active_theme_id) {
        .classic => "Classic",
        .luna => "Luna",
        .aero => "Aero",
        .modern => "Modern",
        .fluent => "Fluent",
        .sunvalley => "Sun Valley",
    };
}

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

pub const CursorState = struct {
    prev_x: i32 = -1,
    prev_y: i32 = -1,
    target_x: i32 = 0,
    target_y: i32 = 0,
    display_x: i32 = 0,
    display_y: i32 = 0,
    sub_x: i32 = 0,
    sub_y: i32 = 0,
    lerp_factor: i32 = 200,
    is_moving: bool = false,
    needs_restore: bool = false,
};

pub const DesktopContext = struct {
    surface: Surface = .{},
    background_color: u32 = 0,
    cursor_x: i32 = 0,
    cursor_y: i32 = 0,
    cursor_visible: bool = true,
    vsync_enabled: bool = true,
    frame_count: u64 = 0,
    smooth_cursor: CursorState = .{},
    dwm_active: bool = false,
};

// ── Global State ──

var display_state: DisplayState = .uninitialized;
var display_mode: DisplayMode = .text;
var desktop_ctx: DesktopContext = .{};

var driver_idx: u32 = 0;
var device_idx: u32 = 0;
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
//  Desktop Rendering (theme-aware)
// ══════════════════════════════════════════════════════════════

pub fn clearFramebuffer() void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    fb.clearScreen(0x00000000);
}

pub fn renderDesktop() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = active_theme;

    renderDesktopBackground(t.desktop_bg);
    renderDesktopIcons(w, h, t);
    renderSampleWindow(w, h, t);
    renderTaskbar(w, h, t);

    if (startmenu.isVisible()) {
        startmenu.render(w, h);
    }

    renderContextMenu();

    renderCursor(desktop_ctx.cursor_x, desktop_ctx.cursor_y);

    desktop_ctx.frame_count += 1;
}

/// Dispatch to the correct theme-specific full desktop renderer.
fn renderCurrentDesktop() void {
    switch (active_theme_id) {
        .aero => renderAeroFrame(),
        .fluent => renderFluentFrame(),
        .sunvalley => renderSunValleyFrame(),
        else => renderDesktop(),
    }
}

/// Returns the taskbar height for the active theme.
pub fn getTaskbarHeight() i32 {
    return switch (active_theme_id) {
        .aero => 40,
        .fluent, .sunvalley => 48,
        else => TASKBAR_H,
    };
}

/// Align DWM smooth-cursor state with the PS/2 driver so the first painted frame
/// shows the pointer at the correct position (typically screen center).
pub fn syncCursorFromMouse() void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    if (!is_x86) return;
    const mouse = @import("../input/mouse.zig");
    const mx = mouse.getX();
    const my = mouse.getY();
    const P: i32 = 256;
    desktop_ctx.smooth_cursor.sub_x = mx * P;
    desktop_ctx.smooth_cursor.sub_y = my * P;
    desktop_ctx.smooth_cursor.display_x = mx;
    desktop_ctx.smooth_cursor.display_y = my;
    desktop_ctx.smooth_cursor.target_x = mx;
    desktop_ctx.smooth_cursor.target_y = my;
    desktop_ctx.smooth_cursor.prev_x = mx;
    desktop_ctx.smooth_cursor.prev_y = my;
    desktop_ctx.cursor_x = mx;
    desktop_ctx.cursor_y = my;
}

fn drawThemeIdentityBanner(scr_w: i32, _: i32) void {
    const text: []const u8 = switch (active_theme_id) {
        .aero => "AERO / Win7  DWM",
        .fluent => "FLUENT / Win10  Acrylic",
        .sunvalley => "SUN VALLEY / Win11  Mica",
        else => return,
    };
    const fg = switch (active_theme_id) {
        .aero => rgb(0xFF, 0xE8, 0xA0),
        .fluent => rgb(0x40, 0xE8, 0xFF),
        .sunvalley => rgb(0x4C, 0xB0, 0xE8),
        else => return,
    };
    const bar_w = @min(scr_w, 460);
    fb.fillRect(0, 0, bar_w, 28, rgb(0x12, 0x12, 0x16));
    fb.drawHLine(0, 28, bar_w, rgb(0x55, 0x55, 0x66));
    fb.drawTextTransparent(10, 8, text, fg);
}

pub fn renderDesktopFrame() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    if (is_x86) {
        const mouse = @import("../../drivers/input/mouse.zig");

        if (mouse.isInterpolating()) {
            mouse.interpolateStep();
        }

        const raw_x = mouse.getX();
        const raw_y = mouse.getY();

        updateSmoothCursor(raw_x, raw_y);

        desktop_ctx.cursor_x = desktop_ctx.smooth_cursor.display_x;
        desktop_ctx.cursor_y = desktop_ctx.smooth_cursor.display_y;

        if (desktop_ctx.smooth_cursor.needs_restore) {
            renderCurrentDesktop();
            desktop_ctx.smooth_cursor.needs_restore = false;
        } else if (cursorPositionChanged()) {
            renderCurrentDesktop();
        } else {
            renderCurrentDesktop();
        }

        mouse.clearCursorMoved();
    } else {
        renderCurrentDesktop();
    }
}

fn updateSmoothCursor(raw_x: i32, raw_y: i32) void {
    const sc = &desktop_ctx.smooth_cursor;
    sc.target_x = raw_x;
    sc.target_y = raw_y;

    const P: i32 = 256;
    const tx = raw_x * P;
    const ty = raw_y * P;
    const dx = tx - sc.sub_x;
    const dy = ty - sc.sub_y;

    // Adaptive lerp: snap faster for large sweeps, smooth for small moves
    const dist_sq = @divTrunc(dx, P) * @divTrunc(dx, P) + @divTrunc(dy, P) * @divTrunc(dy, P);
    var lerp = sc.lerp_factor;
    if (dist_sq > 400) {
        lerp = 252; // near-instant catch-up for big jumps
    } else if (dist_sq > 100) {
        lerp = sc.lerp_factor + 20;
        if (lerp > 255) lerp = 255;
    } else if (dist_sq < 4) {
        lerp = sc.lerp_factor - 40;
        if (lerp < 128) lerp = 128;
    }

    sc.sub_x = sc.sub_x + @divTrunc(dx * lerp, 256);
    sc.sub_y = sc.sub_y + @divTrunc(dy * lerp, 256);

    sc.prev_x = sc.display_x;
    sc.prev_y = sc.display_y;
    sc.display_x = @divTrunc(sc.sub_x + P / 2, P);
    sc.display_y = @divTrunc(sc.sub_y + P / 2, P);

    const w_i32: i32 = @intCast(fb.getWidth());
    const h_i32: i32 = @intCast(fb.getHeight());
    if (sc.display_x < 0) sc.display_x = 0;
    if (sc.display_y < 0) sc.display_y = 0;
    if (sc.display_x >= w_i32) sc.display_x = w_i32 - 1;
    if (sc.display_y >= h_i32) sc.display_y = h_i32 - 1;

    sc.is_moving = (sc.display_x != sc.prev_x or sc.display_y != sc.prev_y);
}

fn cursorPositionChanged() bool {
    const sc = &desktop_ctx.smooth_cursor;
    return sc.display_x != sc.prev_x or sc.display_y != sc.prev_y;
}

fn renderCursorFrame() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    renderCurrentDesktop();
}

pub fn toggleStartMenu() void {
    const style: startmenu.MenuStyle = switch (active_theme_id) {
        .classic => .classic,
        .luna => .luna,
        .aero => .aero,
        .modern => .modern,
        .fluent => .fluent,
        .sunvalley => .sunvalley,
    };
    startmenu.toggle(style);
}

pub fn isStartMenuVisible() bool {
    return startmenu.isVisible();
}

pub fn hideStartMenu() void {
    startmenu.hide();
}

fn isStartButtonClick(click_x: i32, click_y: i32, scr_w: i32, scr_h: i32) bool {
    const tb_h = getTaskbarHeight();
    const tb_y = scr_h - tb_h;
    if (click_y < tb_y) return false;

    return switch (active_theme_id) {
        .sunvalley => {
            const center_x = @divTrunc(scr_w, 2);
            const pinned_count: i32 = 6;
            const icon_spacing: i32 = 40;
            const group_w = pinned_count * icon_spacing;
            const group_start = center_x - @divTrunc(group_w, 2);
            return click_x >= group_start and click_x < group_start + 40;
        },
        .aero => click_x < 44,
        .fluent => click_x < 40,
        else => click_x < START_BTN_W,
    };
}

pub fn handleClick(x: i32, y: i32) void {
    const h: i32 = @intCast(fb.getHeight());
    const w: i32 = @intCast(fb.getWidth());

    if (ctx_menu_visible) {
        if (!isInsideContextMenu(x, y)) {
            hideContextMenu();
        }
        return;
    }

    if (isStartButtonClick(x, y, w, h)) {
        toggleStartMenu();
        return;
    }

    if (startmenu.isVisible()) {
        const menu_r = startmenu.getMenuRect(w, h);
        if (!menu_r.contains(x, y)) {
            startmenu.hide();
        }
        return;
    }

    const wr = getWindowRect(w, h);
    if (x >= wr.x and x < wr.x + wr.w and y >= wr.y and y < wr.y + TITLEBAR_H) {
        drag_active = true;
        drag_offset_x = x - window_x;
        drag_offset_y = y - window_y;
    }
}

pub fn handleRightClick(x: i32, y: i32) void {
    const h: i32 = @intCast(fb.getHeight());
    const tb_y = h - getTaskbarHeight();

    if (startmenu.isVisible()) {
        startmenu.hide();
        return;
    }

    if (y < tb_y) {
        showContextMenu(x, y);
    }
}

pub fn handleMouseMove(x: i32, y: i32) void {
    desktop_ctx.smooth_cursor.target_x = x;
    desktop_ctx.smooth_cursor.target_y = y;

    if (drag_active) {
        const h: i32 = @intCast(fb.getHeight());
        window_x = x - drag_offset_x;
        window_y = y - drag_offset_y;
        if (window_y < 0) window_y = 0;
        if (window_y > h - getTaskbarHeight() - TITLEBAR_H) window_y = h - getTaskbarHeight() - TITLEBAR_H;
    }
}

pub fn handleMouseRelease() void {
    drag_active = false;
}

pub fn renderAeroDesktop() void {
    setTheme(.aero);
    if (!dwm_initialized) {
        initAeroDwm();
    }
    renderAeroFrame();
}

fn renderAeroFrame() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = active_theme;
    const tb_h: i32 = 40;

    renderAeroBackground(w, h, t);
    drawThemeIdentityBanner(w, h);
    renderDesktopIcons(w, h, t);
    renderAeroWindow(w, h, t);
    renderAeroTaskbar(w, h, t, tb_h);

    if (startmenu.isVisible()) {
        startmenu.render(w, h);
    }

    renderContextMenu();
    renderCursor(desktop_ctx.cursor_x, desktop_ctx.cursor_y);
    desktop_ctx.frame_count += 1;
}

fn renderAeroBackground(w: i32, h: i32, t: *const ThemeColors) void {
    _ = w;
    _ = h;
    fb.drawGradientV(0, 0, @intCast(fb.getWidth()), @intCast(fb.getHeight()), t.desktop_bg, rgb(0x16, 0x36, 0x56));
}

fn renderAeroTaskbar(scr_w: i32, scr_h: i32, t: *const ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;

    if (dwm_initialized and dwm_config.glass_enabled) {
        renderGlassEffect(0, tb_y, scr_w, tb_h, t.taskbar_top, dwm_config.glass_opacity);
    } else {
        fb.drawGradientV(0, tb_y, scr_w, tb_h, t.taskbar_top, t.taskbar_bottom);
    }
    fb.drawHLine(0, tb_y, scr_w, rgb(0x50, 0x78, 0xA8));

    // Aero Start Orb (circular glass button)
    const orb_x: i32 = 4;
    const orb_y = tb_y + 2;
    const orb_sz: i32 = 36;
    fb.fillRoundedRect(orb_x, orb_y, orb_sz, orb_sz, 18, rgb(0x34, 0x78, 0xCC));
    fb.fillRoundedRect(orb_x + 2, orb_y + 2, orb_sz - 4, @divTrunc(orb_sz - 4, 2), 14, rgb(0x68, 0xAC, 0xE8));
    renderZirconLogo(orb_x + 11, orb_y + 11);

    // Quick Launch area
    const ql_x: i32 = orb_x + orb_sz + 8;
    const ql_labels = [_][]const u8{ "IE", "Ex", "WP" };
    var qx = ql_x;
    for (ql_labels) |lbl| {
        const qy = tb_y + @divTrunc(tb_h - 24, 2);
        fb.fillRoundedRect(qx, qy, 28, 24, 3, rgb(0x30, 0x50, 0x78));
        fb.drawTextTransparent(qx + 6, qy + 4, lbl, rgb(0xCC, 0xDD, 0xEE));
        qx += 32;
    }

    // Separator between quick launch and taskbar buttons
    fb.drawVLine(qx + 2, tb_y + 4, tb_h - 8, rgb(0x50, 0x78, 0xA8));

    // Running app buttons (glass-styled)
    const app_x = qx + 8;
    const app_labels = [_][]const u8{ "Computer", "Core", "CMD" };
    const app_colors = [_]u32{
        rgb(0x40, 0x78, 0xB8),
        rgb(0x30, 0x58, 0x88),
        rgb(0x20, 0x40, 0x68),
    };
    var ax = app_x;
    for (app_labels, 0..) |lbl, i| {
        const ay = tb_y + @divTrunc(tb_h - 26, 2);
        fb.fillRoundedRect(ax, ay, 88, 26, 3, app_colors[i]);
        // Glass shine on top half
        fb.fillRect(ax + 1, ay + 1, 86, 10, rgb(0x60, 0x98, 0xD0));
        fb.drawTextTransparent(ax + 8, ay + 5, lbl, rgb(0xFF, 0xFF, 0xFF));
        ax += 92;
    }

    // System tray with glass effect
    const tray_w: i32 = 120;
    const tray_x = scr_w - tray_w - 4;
    const tray_y = tb_y + @divTrunc(tb_h - 24, 2);
    fb.fillRoundedRect(tray_x, tray_y, tray_w, 24, 3, rgb(0x20, 0x38, 0x58));
    fb.drawTextTransparent(tray_x + 8, tray_y + 4, "12:00 PM", t.clock_text);

    // Show Desktop button (far right, Aero Peek)
    fb.fillRect(scr_w - 12, tb_y, 12, tb_h, rgb(0x40, 0x68, 0x98));
    fb.drawVLine(scr_w - 12, tb_y + 4, tb_h - 8, rgb(0x60, 0x90, 0xC0));
}

fn renderAeroWindow(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const wr = getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const aero_titlebar_h: i32 = 30;

    // Multi-layer soft shadow
    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(win_x, win_y, win_w, win_h, 10, 4);
    }

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);

    // Glass titlebar
    if (dwm_initialized and dwm_config.glass_enabled) {
        renderGlassEffect(win_x, win_y, win_w, aero_titlebar_h, t.titlebar_active_left, dwm_config.glass_opacity);
    } else {
        fb.drawGradientH(win_x, win_y, win_w, aero_titlebar_h, t.titlebar_active_left, t.titlebar_active_right);
    }

    // Window icon (small computer icon in titlebar)
    fb.fillRect(win_x + 6, win_y + 7, 16, 14, rgb(0x80, 0xB0, 0xE0));
    fb.drawRect(win_x + 6, win_y + 7, 16, 14, rgb(0xFF, 0xFF, 0xFF));

    fb.drawTextTransparent(win_x + 28, win_y + 7, "Computer", t.titlebar_text);

    // Aero caption buttons (rounded glass style)
    const btn_w: i32 = 28;
    const btn_h: i32 = 20;
    const btn_y = win_y + 5;
    const close_x = win_x + win_w - btn_w - 4;
    fb.fillRoundedRect(close_x, btn_y, btn_w, btn_h, 3, t.btn_close_top);
    drawCloseSymbol(close_x, btn_y, btn_w);

    fb.fillRoundedRect(close_x - btn_w - 2, btn_y, btn_w, btn_h, 3, t.btn_minmax_top);
    drawMaxSymbol(close_x - btn_w - 2, btn_y, btn_w);

    fb.fillRoundedRect(close_x - (btn_w + 2) * 2, btn_y, btn_w, btn_h, 3, t.btn_minmax_top);
    drawMinSymbol(close_x - (btn_w + 2) * 2, btn_y, btn_w);

    fb.drawHLine(win_x, win_y + aero_titlebar_h, win_w, t.window_border);

    renderAeroWindowContent(win_x + 1, win_y + aero_titlebar_h, win_w - 2, win_h - aero_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
}

fn renderAeroWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const ThemeColors) void {
    // Toolbar
    fb.fillRect(x, y, w, 24, t.button_face);
    fb.drawHLine(x, y + 24, w, t.button_shadow);

    const toolbar_items = [_][]const u8{ "File", "Edit", "View", "Favorites", "Tools", "Help" };
    var tx: i32 = x + 8;
    for (toolbar_items) |item| {
        fb.drawTextTransparent(tx, y + 4, item, rgb(0x00, 0x00, 0x00));
        tx += fb.textWidth(item) + 16;
    }

    // Address bar with breadcrumb style
    const addr_y = y + 25;
    fb.fillRect(x, addr_y, w, 26, rgb(0xE8, 0xED, 0xF4));
    fb.drawHLine(x, addr_y + 26, w, t.button_shadow);
    fb.fillRoundedRect(x + 60, addr_y + 3, w - 70, 20, 3, rgb(0xFF, 0xFF, 0xFF));
    fb.drawRect(x + 60, addr_y + 3, w - 70, 20, rgb(0xA0, 0xB0, 0xC0));
    fb.drawTextTransparent(x + 8, addr_y + 5, "Address:", rgb(0x40, 0x40, 0x40));
    fb.drawTextTransparent(x + 68, addr_y + 5, "Z:\\", rgb(0x00, 0x00, 0x00));

    // Content area
    const content_y = addr_y + 27;
    const content_h = h - 73;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, rgb(0xFF, 0xFF, 0xFF));

        // Navigation pane (left side)
        const nav_w: i32 = 140;
        fb.fillRect(x, content_y, nav_w, content_h, rgb(0xE8, 0xED, 0xF4));
        fb.drawVLine(x + nav_w, content_y, content_h, rgb(0xD8, 0xD8, 0xD8));
        fb.drawTextTransparent(x + 10, content_y + 8, "Favorites", rgb(0x00, 0x3C, 0xA0));
        fb.drawTextTransparent(x + 16, content_y + 26, "Desktop", rgb(0x00, 0x00, 0x00));
        fb.drawTextTransparent(x + 16, content_y + 42, "Downloads", rgb(0x00, 0x00, 0x00));
        fb.drawTextTransparent(x + 10, content_y + 66, "Computer", rgb(0x00, 0x3C, 0xA0));
        fb.drawTextTransparent(x + 16, content_y + 84, "C:\\", rgb(0x00, 0x00, 0x00));
        fb.drawTextTransparent(x + 16, content_y + 100, "D:\\", rgb(0x00, 0x00, 0x00));

        // File list
        const items = [_]struct { name: []const u8, icon_id: icons.IconId }{
            .{ .name = "Users", .icon_id = .documents },
            .{ .name = "Programs", .icon_id = .documents },
            .{ .name = "System", .icon_id = .documents },
            .{ .name = "3rdparty", .icon_id = .documents },
            .{ .name = "boot.cfg", .icon_id = .computer },
            .{ .name = "zloader", .icon_id = .computer },
        };

        var iy: i32 = content_y + 8;
        for (items) |item| {
            if (iy + 20 > content_y + content_h) break;
            drawThemedIconForActiveTheme(item.icon_id, x + nav_w + 10, iy + 1, 1);
            fb.drawTextTransparent(x + nav_w + 32, iy + 2, item.name, rgb(0x00, 0x00, 0x00));
            iy += 22;
        }

        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + nav_w + 10, iy + 4, "Theme: Aero Glass (DWM)", rgb(0x40, 0x80, 0xC8));
            iy += 18;
        }
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + nav_w + 10, iy + 4, "DWM: Glass + Blur + Specular", rgb(0x80, 0x80, 0x80));
        }

        // Scrollbar
        const sb_x = x + w - 17;
        fb.fillRect(sb_x, content_y, 17, content_h, rgb(0xE8, 0xE8, 0xEB));
        fb.drawVLine(sb_x, content_y, content_h, t.button_shadow);
        fb.fillRect(sb_x + 1, content_y + 17, 16, 40, rgb(0xC1, 0xC1, 0xC6));
    }

    // Status bar
    fb.fillRect(x, y + h - 22, w, 22, t.button_face);
    fb.drawHLine(x, y + h - 22, w, t.button_shadow);
    fb.drawTextTransparent(x + 8, y + h - 18, "6 objects | Aero Glass DWM | D3D9 compositor", rgb(0x00, 0x00, 0x00));
}

pub fn initAeroDwm() void {
    if (!dwm_initialized) {
        initDwm(.{
            .glass_enabled = true,
            .glass_opacity = 180,
            .glass_blur_radius = 12,
            .glass_saturation = 200,
            .glass_tint_color = 0x4068A0,
            .glass_tint_opacity = 60,
            .animation_enabled = true,
            .peek_enabled = true,
            .shadow_enabled = true,
            .vsync_compositor = true,
            .smooth_cursor = true,
            .cursor_lerp_factor = 220,
        });

        dwm_comp.initAero(.{
            .glass_enabled = true,
            .glass_opacity = 180,
            .blur_radius = 12,
            .blur_passes = 3,
            .saturation = 200,
            .tint_color = 0x4068A0,
            .tint_opacity = 60,
            .specular_intensity = 35,
            .shadow_layers = 4,
            .shadow_offset = 8,
            .peek_enabled = true,
            .flip3d_enabled = true,
            .animation_speed = 250,
        });
    }
}

/// Initialize the Fluent (Win10) DWM compositor.
/// Uses DirectComposition visual tree with Acrylic material, Reveal highlight,
/// depth shadows, and virtual desktop support. Compatible with NT 6.3 kernel.
///
/// Integration (win10Desktop.md architecture):
///   - ZirconOSFluent/resources: primary Fluent UI assets
///   - ZirconOSAero/resources: fallback graphical window chrome
///   - ZirconOSFonts: NotoSans, SourceCodePro, NotoSansCJK-SC, etc.
///   - ZirconOS/src: minimized Core, CMD, PowerShell windows on taskbar
///
/// Rendering pipeline per frame (win10Desktop.md §7):
///   Visual Tree → Z-order sort → per-node Transform→Clip→Effect→Blend
///   Acrylic: blur→noise→tint→luminosity (§6.1)
///   Reveal: radial gradient at pointer (§6.3)
///   WDDM 2.x → MPO → Present → VSync
pub fn initFluentDwm() void {
    if (!dwm_initialized) {
        initDwm(.{
            .glass_enabled = true,
            .glass_opacity = 200,
            .glass_blur_radius = 20,
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
            .acrylic_blur_radius = 20,
            .acrylic_blur_passes = 4,
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
}

/// Initialize the Sun Valley (Win11) DWM compositor.
/// Extends Fluent with Mica material, SDF-based rounded corner clipping,
/// Snap Layout geometry, centered taskbar, and Dynamic Refresh Rate.
/// Compatible with NT 6.4 kernel; mirrors ShellExperienceHost.exe process split.
///
/// Integration (win11Desktop.md architecture):
///   - ZirconOSSunValley/resources: primary Sun Valley UI assets (icons, cursors, wallpapers, themes)
///   - ZirconOSFonts: NotoSans, SourceCodePro, NotoSansCJK-SC, LXGWWenKai, etc.
///   - ZirconOS/src: minimized Core, CMD, PowerShell windows on centered taskbar
///
/// Rendering pipeline per frame (win11Desktop.md §2-§4):
///   WinUI 3 Composition Layer → Visual Tree Z-order sort
///   → per-node Transform → Clip (SDF rounded 8px) → Effect → Blend
///   → Shell Visuals: centered taskbar (Mica), start menu (Acrylic 2.0),
///     widget panel (Acrylic 2.0), quick settings (Acrylic 2.0)
///   → Snap Layout overlay (§8) → Cursor (smooth subpixel) → DRR VSync
///
/// Material effects (§4):
///   Mica:       wallpaper sample → blur(r=60) → desaturate → theme tint → luminosity
///   Acrylic 2.0: behind-content blur → luminosity blend → tint → noise
///   Shadow:     multi-layer depth shadow with rounded geometry
///   Rounded:    SDF antialiased corner clipping (8px) at compositor level
///
/// WDDM 3.x features (§7):
///   Dynamic Refresh Rate (60-120Hz), GPU priority scheduling,
///   per-display independent SwapChain, VRR support

pub fn renderLunaDesktop() void {
    setTheme(.luna);
    renderDesktop();
}

/// Render the complete Fluent (Win10) desktop.
/// Architecture follows win10Desktop.md:
///   UEFI boot → DirectComposition Visual Tree → Acrylic material pipeline
///   → Reveal highlight → Multi-layer depth shadow → Smooth cursor
/// Resources: ZirconOSFluent (primary) + ZirconOSAero (fallback chrome)
/// Fonts: ZirconOSFonts (NotoSans, SourceCodePro, NotoSansCJK-SC)
/// OS interfaces: Minimized Core, CMD, PowerShell on taskbar
pub fn renderFluentDesktop() void {
    setTheme(.fluent);
    if (!dwm_initialized) {
        initFluentDwm();
    }
    renderFluentFrame();
}

fn renderFluentFrame() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = active_theme;
    const tb_h: i32 = 48;

    // Stage 1: Desktop background (Fluent hero wallpaper style - blue gradient)
    fb.drawGradientV(0, 0, w, h, rgb(0x00, 0x47, 0x8A), rgb(0x00, 0x2A, 0x55));
    drawThemeIdentityBanner(w, h);

    // Stage 2: Desktop icons (Fluent icons with Aero fallback)
    renderDesktopIcons(w, h, t);

    // Stage 3: Windows with Acrylic titlebar (win10Desktop.md §6.1)
    renderFluentWindow(w, h, t);

    // Stage 4: Minimized OS interface windows (ZirconOS/src)
    renderFluentOsInterfaceWindows(w, h, t, tb_h);

    // Stage 5: Taskbar with Acrylic backdrop
    renderFluentTaskbar(w, h, t, tb_h);

    // Stage 6: Overlays
    if (startmenu.isVisible()) {
        startmenu.render(w, h);
    }

    if (fluent_action_center_visible) {
        renderFluentActionCenter(w, h, t);
    }

    renderContextMenu();

    // Stage 7: Cursor with smooth interpolation
    renderCursor(desktop_ctx.cursor_x, desktop_ctx.cursor_y);
    desktop_ctx.frame_count += 1;
}

/// Render minimized OS interface indicators on the taskbar.
/// These represent Core, CMD, and PowerShell from ZirconOS/src,
/// shown as small indicators near the tray area.
fn renderFluentOsInterfaceWindows(scr_w: i32, scr_h: i32, t: *const ThemeColors, tb_h: i32) void {
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

fn renderFluentTaskbar(scr_w: i32, scr_h: i32, t: *const ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;

    if (dwm_initialized and dwm_config.glass_enabled) {
        mat.renderAcrylic(0, tb_y, scr_w, tb_h);
    } else {
        fb.fillRect(0, tb_y, scr_w, tb_h, t.taskbar_top);
    }
    fb.drawHLine(0, tb_y, scr_w, t.tray_border);

    // Start button (Fluent: left-aligned with accent underline)
    const start_y = tb_y + @divTrunc(tb_h - 32, 2);
    fb.fillRoundedRect(4, start_y, 36, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    renderZirconLogo(15, start_y + 9);
    fb.fillRect(12, tb_y + tb_h - 3, 20, 2, rgb(0x00, 0x67, 0xC0));

    // Search bar (Fluent: wide bar with icon + text)
    const search_x: i32 = 48;
    const search_w: i32 = 220;
    const search_y = tb_y + @divTrunc(tb_h - 32, 2);
    fb.fillRoundedRect(search_x, search_y, search_w, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    fb.drawRect(search_x, search_y, search_w, 32, rgb(0x44, 0x44, 0x44));
    fb.drawTextTransparent(search_x + 10, search_y + 8, "S", rgb(0x88, 0x88, 0x88));
    fb.drawTextTransparent(search_x + 24, search_y + 8, "Type here to search", rgb(0x66, 0x66, 0x66));

    // Task View button
    const tv_x = search_x + search_w + 6;
    fb.fillRoundedRect(tv_x, start_y, 36, 32, 4, rgb(0x2D, 0x2D, 0x2D));
    fb.drawRect(tv_x + 8, start_y + 6, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 18, start_y + 6, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 8, start_y + 16, 8, 8, rgb(0xAA, 0xAA, 0xAA));
    fb.drawRect(tv_x + 18, start_y + 16, 8, 8, rgb(0xAA, 0xAA, 0xAA));

    // Pinned app buttons (Fluent: icon-only with underline indicator)
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

    // OS interface indicators (Core, CMD, PS)
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

    renderFluentTray(scr_w, tb_y, tb_h, t);
}

fn renderFluentTray(scr_w: i32, tb_y: i32, tb_h: i32, t: *const ThemeColors) void {
    const tray_w: i32 = 140;
    const tray_x = scr_w - tray_w - 8;
    const tray_y = tb_y + @divTrunc(tb_h - 24, 2);

    fb.fillRect(tray_x, tray_y, tray_w, 24, t.tray_bg);
    fb.drawTextTransparent(tray_x + 8, tray_y + 4, "12:00 PM", t.clock_text);

    const ac_x = tray_x - 28;
    fb.drawTextTransparent(ac_x + 6, tray_y + 4, "^", t.clock_text);
}

fn renderFluentWindow(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const wr = getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const fl_titlebar_h: i32 = 32;

    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(win_x, win_y, win_w, win_h, 12, 5);
    }

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);

    // Acrylic titlebar
    if (dwm_initialized and dwm_config.glass_enabled) {
        mat.renderAcrylic(win_x, win_y, win_w, fl_titlebar_h);
    } else {
        fb.fillRect(win_x, win_y, win_w, fl_titlebar_h, t.titlebar_active_left);
    }

    // Fluent icon (Segoe MDL2 style icon placeholder)
    fb.fillRoundedRect(win_x + 8, win_y + 6, 20, 20, 3, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(win_x + 14, win_y + 8, "F", rgb(0xFF, 0xFF, 0xFF));

    fb.drawTextTransparent(win_x + 34, win_y + 8, "File Explorer", t.titlebar_text);

    // Fluent caption buttons (no borders, flat hover areas)
    const btn_w: i32 = 46;
    const btn_h: i32 = fl_titlebar_h;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, btn_h, t.btn_close_top);
    drawCloseSymbol(close_x, win_y, btn_w);

    fb.fillRect(close_x - btn_w, win_y, btn_w, btn_h, t.btn_minmax_top);
    drawMaxSymbol(close_x - btn_w, win_y, btn_w);

    fb.fillRect(close_x - btn_w * 2, win_y, btn_w, btn_h, t.btn_minmax_top);
    drawMinSymbol(close_x - btn_w * 2, win_y, btn_w);

    fb.drawHLine(win_x, win_y + fl_titlebar_h, win_w, t.tray_border);

    renderFluentWindowContent(win_x + 1, win_y + fl_titlebar_h, win_w - 2, win_h - fl_titlebar_h - 1, t);
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
}

fn renderFluentWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const ThemeColors) void {
    // Fluent Ribbon bar (simplified)
    fb.fillRect(x, y, w, 36, rgb(0xF3, 0xF3, 0xF3));
    fb.drawHLine(x, y + 36, w, t.button_shadow);

    // Tab buttons (Fluent style)
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

    // Address bar (Fluent TextBox style with accent border)
    const addr_y = y + 37;
    fb.fillRect(x, addr_y, w, 28, rgb(0xF9, 0xF9, 0xF9));
    fb.drawHLine(x, addr_y + 28, w, t.button_shadow);
    fb.fillRoundedRect(x + 8, addr_y + 3, w - 16, 22, 3, rgb(0xFF, 0xFF, 0xFF));
    fb.drawRect(x + 8, addr_y + 3, w - 16, 22, rgb(0x80, 0x80, 0x80));
    fb.fillRect(x + 8, addr_y + 23, w - 16, 2, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(x + 16, addr_y + 7, "> This PC > C:\\", rgb(0x00, 0x00, 0x00));

    // Content area with navigation pane
    const content_y = addr_y + 29;
    const content_h = h - 93;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, rgb(0xFF, 0xFF, 0xFF));

        // Navigation pane (Fluent style)
        const nav_w: i32 = 150;
        fb.fillRect(x, content_y, nav_w, content_h, rgb(0xF3, 0xF3, 0xF3));
        fb.drawVLine(x + nav_w, content_y, content_h, rgb(0xE0, 0xE0, 0xE0));

        // Nav items with Reveal highlight hover simulation
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

        // File list
        const items = [_]struct { name: []const u8, icon_id: icons.IconId }{
            .{ .name = "Users", .icon_id = .documents },
            .{ .name = "Programs", .icon_id = .documents },
            .{ .name = "System", .icon_id = .documents },
            .{ .name = "3rdparty", .icon_id = .documents },
            .{ .name = "boot.cfg", .icon_id = .computer },
            .{ .name = "zloader", .icon_id = .computer },
        };

        var iy: i32 = content_y + 8;
        for (items) |item| {
            if (iy + 20 > content_y + content_h) break;
            drawThemedIconForActiveTheme(item.icon_id, x + nav_w + 10, iy + 1, 1);
            fb.drawTextTransparent(x + nav_w + 32, iy + 2, item.name, rgb(0x00, 0x00, 0x00));
            iy += 22;
        }

        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + nav_w + 10, iy + 4, "Theme: Fluent Design", rgb(0x00, 0x67, 0xC0));
            iy += 18;
        }
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + nav_w + 10, iy + 4, "DWM: Acrylic + Reveal + DirectComposition", rgb(0x80, 0x80, 0x80));
        }
    }

    // Status bar (Fluent)
    fb.fillRect(x, y + h - 24, w, 24, rgb(0x00, 0x67, 0xC0));
    fb.drawTextTransparent(x + 8, y + h - 19, "6 objects | Fluent Design | Acrylic DWM", rgb(0xFF, 0xFF, 0xFF));
}

var fluent_action_center_visible: bool = false;

pub fn toggleFluentActionCenter() void {
    fluent_action_center_visible = !fluent_action_center_visible;
}

fn renderFluentActionCenter(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const ac_w: i32 = 320;
    const ac_h: i32 = 400;
    const ac_x = scr_w - ac_w - 8;
    const ac_y = scr_h - 48 - ac_h - 8;

    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(ac_x, ac_y, ac_w, ac_h, 10, 4);
    }

    fb.fillRect(ac_x, ac_y, ac_w, ac_h, t.window_bg);

    if (dwm_initialized and dwm_config.glass_enabled) {
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

/// Entry point for Sun Valley desktop rendering.
/// Sets theme to Sun Valley, initializes DWM if needed, and renders the frame.
/// Resources: ZirconOSSunValley + ZirconOSFonts
/// Boot path: UEFI → GRUB/ZBM → Multiboot2 → kernel → desktop=sunvalley
pub fn renderSunValleyDesktop() void {
    setTheme(.sunvalley);
    if (!dwm_initialized) {
        initSunValleyDwm();
    }
    renderSunValleyFrame();
}

var sv_widget_panel_visible: bool = false;
var sv_quick_settings_visible: bool = false;

pub fn toggleSunValleyWidgetPanel() void {
    sv_widget_panel_visible = !sv_widget_panel_visible;
}

pub fn toggleSunValleyQuickSettings() void {
    sv_quick_settings_visible = !sv_quick_settings_visible;
}

/// Initialize the Sun Valley (Win11) DWM compositor.
/// Follows win11Desktop.md architecture:
///   §2: WinUI 3 Composition visual tree (ContainerVisual / SpriteVisual / LayerVisual)
///   §3: Multi-process Shell (Explorer + ShellExperienceHost + StartMenuExperienceHost + Taskbar)
///   §4: Mica (wallpaper-sampled, blur r=60) + Acrylic 2.0 (luminosity blend)
///   §5: Dynamic Refresh Rate (60-120Hz adaptive)
///   §7: WDDM 3.x driver model (GPU priority scheduling)
///   §8: Snap Layout (6-zone, spring animation)
///   §9: Win32 backward-compatible composition (auto rounded corners + shadow)
///
/// Resources:
///   ZirconOSSunValley/resources/wallpapers/ — Mica sampling source
///   ZirconOSSunValley/resources/icons/      — WinUI 3 style icons
///   ZirconOSSunValley/resources/cursors/    — Cursor sprites
///   ZirconOSSunValley/resources/themes/     — Dark/Light/Contrast themes
///   ZirconOSFonts/fonts/western/            — NotoSans, SourceCodePro, DejaVu, Lato
///   ZirconOSFonts/fonts/cjk/               — NotoSansCJK-SC, LXGWWenKai, ZhuQueFangSong
///
/// OS Interfaces (minimized on centered taskbar):
///   Core   — ZirconOS kernel services from src/
///   CMD    — Win32 command shell from src/subsystems/win32/cmd.zig
///   PS     — PowerShell from src/subsystems/win32/powershell.zig
pub fn initSunValleyDwm() void {
    if (!dwm_initialized) {
        initDwm(.{
            .glass_enabled = true,
            .glass_opacity = 210,
            .glass_blur_radius = 20,
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

        // Win11 DWM compositor: Mica + Acrylic 2.0 + SDF + Snap + DRR
        dwm_comp.initSunValley(.{
            .mica_enabled = true,
            .mica_blur_radius = 60,
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

        // WinUI 3 Composition Visual Tree (§2)
        vtree.init();
        vtree.createTree();
    }
}

/// Render one full Sun Valley desktop composition frame.
/// Architecture follows win11Desktop.md §2 DWM composition pipeline:
///   Stage 1: Background — wallpaper fill (ZirconOSSunValley/resources/wallpapers/)
///   Stage 2: Desktop icons — grid layout from ZirconOSSunValley/resources/icons/
///   Stage 3: Windows — Mica titlebar + SDF rounded corners + depth shadow
///   Stage 4: Minimized OS interface windows (Core, CMD, PowerShell from ZirconOS/src)
///   Stage 5: Taskbar — centered layout, Mica backdrop, pill indicators
///   Stage 6: Overlays — Start menu, Widget panel, Quick settings (Acrylic 2.0)
///   Stage 7: Context menu — rounded flyout with Acrylic backdrop
///   Stage 8: Cursor — smooth subpixel interpolation (ZirconOSSunValley/resources/cursors/)
///   Stage 9: Present → DRR VSync
/// Fonts: ZirconOSFonts (NotoSans, SourceCodePro, NotoSansCJK-SC, LXGWWenKai)
fn renderSunValleyFrame() void {
    if (!use_framebuffer or !fb.isInitialized()) return;

    const w: i32 = @intCast(fb.getWidth());
    const h: i32 = @intCast(fb.getHeight());
    const t = active_theme;
    const tb_h: i32 = 48;

    // Stage 1: Desktop background (gradient dark)
    fb.drawGradientV(0, 0, w, h, rgb(0x08, 0x12, 0x22), rgb(0x0A, 0x1E, 0x3A));
    drawThemeIdentityBanner(w, h);

    // Stage 2: Desktop icons (ZirconOSSunValley/resources/icons/)
    renderDesktopIcons(w, h, t);

    // Stage 3: Window with Mica titlebar + SDF rounded corners (win11Desktop.md §3.2, §4.1)
    renderSunValleyWindow(w, h, t);

    // Stage 4: Minimized OS interface windows on centered taskbar
    renderSunValleyOsInterfaceWindows(w, h, t, tb_h);

    // Stage 5: Taskbar — centered layout, Mica backdrop, pill indicators (win11Desktop.md §3.1)
    renderSunValleyTaskbar(w, h, t, tb_h);

    // Stage 6: Overlays — all shell components as independent processes (§3.1)
    if (startmenu.isVisible()) {
        startmenu.render(w, h);
    }

    if (sv_widget_panel_visible) {
        renderSunValleyWidgetPanel(w, h, t);
    }

    if (sv_quick_settings_visible) {
        renderSunValleyQuickSettings(w, h, t);
    }

    // Stage 7: Context menu
    renderContextMenu();

    // Stage 8: Cursor (ZirconOSSunValley/resources/cursors/zircon_arrow.svg)
    renderCursor(desktop_ctx.cursor_x, desktop_ctx.cursor_y);

    // Stage 9: Present → DRR VSync (60-120Hz adaptive)
    desktop_ctx.frame_count += 1;
}

/// Widget panel — Acrylic 2.0 backdrop (win11Desktop.md §4.2)
/// Independent shell process per Win11 architecture (§3.1).
/// Uses ZirconOSSunValley/resources/icons/widgets.svg for panel icon.
fn renderSunValleyWidgetPanel(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    _ = scr_w;
    const panel_w: i32 = 360;
    const panel_h: i32 = scr_h - 48 - 16;
    const panel_x: i32 = 8;
    const panel_y: i32 = 8;

    // Depth shadow
    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(panel_x, panel_y, panel_w, panel_h, 12, 5);
    }

    // Acrylic 2.0 backdrop (§4.2: blur → luminosity blend → tint → noise)
    fb.fillRoundedRect(panel_x, panel_y, panel_w, panel_h, 8, t.window_bg);

    if (dwm_initialized and dwm_config.glass_enabled) {
        mat.renderMica(panel_x, panel_y, panel_w, panel_h);
    }

    mat.applyRoundedClip(panel_x, panel_y, panel_w, panel_h, 8);
    fb.drawTextTransparent(panel_x + 16, panel_y + 12, "Widgets", rgb(0xCC, 0xCC, 0xCC));
    fb.drawHLine(panel_x + 16, panel_y + 32, panel_w - 32, t.tray_border);

    // Widget cards (rounded, WinUI 3 card layout)
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

/// Quick Settings panel — Acrylic 2.0 backdrop (win11Desktop.md §4.2)
/// Features toggle buttons (WiFi, Bluetooth, etc.), brightness/volume sliders.
/// Independent shell process per Win11 architecture (§3.1).
fn renderSunValleyQuickSettings(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const qs_w: i32 = 340;
    const qs_h: i32 = 360;
    const qs_x = scr_w - qs_w - 12;
    const qs_y = scr_h - 48 - qs_h - 12;

    // Depth shadow
    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(qs_x, qs_y, qs_w, qs_h, 12, 5);
    }

    // Acrylic 2.0 backdrop with SDF rounded corners
    fb.fillRoundedRect(qs_x, qs_y, qs_w, qs_h, 8, t.window_bg);

    if (dwm_initialized and dwm_config.glass_enabled) {
        mat.renderAcrylic(qs_x, qs_y, qs_w, qs_h);
    }

    mat.applyRoundedClip(qs_x, qs_y, qs_w, qs_h, 8);

    // Toggle buttons (pill-shaped, WinUI 3 ToggleButton style)
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

    // Brightness slider (WinUI 3 Slider style)
    ty += if (col > 0) 56 else 8;
    fb.drawTextTransparent(qs_x + 16, ty, "Brightness", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 6, 3, rgb(0x44, 0x44, 0x44));
    const bright_w = @divTrunc((qs_w - 32) * 3, 4);
    fb.fillRoundedRect(qs_x + 16, ty + 18, bright_w, 6, 3, rgb(0x4C, 0xB0, 0xE8));
    // Thumb
    fb.fillRoundedRect(qs_x + 16 + bright_w - 8, ty + 14, 16, 14, 7, rgb(0xFF, 0xFF, 0xFF));

    // Volume slider
    ty += 38;
    fb.drawTextTransparent(qs_x + 16, ty, "Volume", rgb(0xAA, 0xAA, 0xAA));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 6, 3, rgb(0x44, 0x44, 0x44));
    const vol_w = @divTrunc((qs_w - 32) * 2, 3);
    fb.fillRoundedRect(qs_x + 16, ty + 18, vol_w, 6, 3, rgb(0x4C, 0xB0, 0xE8));
    // Thumb
    fb.fillRoundedRect(qs_x + 16 + vol_w - 8, ty + 14, 16, 14, 7, rgb(0xFF, 0xFF, 0xFF));

    // Battery info
    ty += 38;
    fb.drawTextTransparent(qs_x + 16, ty, "Battery: 85%", rgb(0x88, 0x88, 0x88));
    fb.fillRoundedRect(qs_x + 16, ty + 18, qs_w - 32, 4, 2, rgb(0x44, 0x44, 0x44));
    fb.fillRoundedRect(qs_x + 16, ty + 18, @divTrunc((qs_w - 32) * 85, 100), 4, 2, rgb(0x0F, 0x7B, 0x0F));
}

/// Render minimized OS interface indicators on the Sun Valley centered taskbar.
/// These represent Core, CMD, and PowerShell from ZirconOS/src,
/// shown as small rounded pill-shaped indicators near the right side of
/// the centered icon group.
fn renderSunValleyOsInterfaceWindows(scr_w: i32, scr_h: i32, t: *const ThemeColors, tb_h: i32) void {
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
        // Pill indicator at bottom
        const pill_x = bx + @divTrunc(btn_w - 12, 2);
        const pill_y = btn_y + btn_h - 3;
        fb.fillRect(pill_x, pill_y, 12, 2, item.pill);
    }
}

/// Sun Valley Taskbar — centered layout with Mica backdrop (win11Desktop.md §3)
/// Features: centered pinned app icons, pill active indicators, search bar,
/// system tray with date/time. Mica material samples wallpaper texture.
/// Shell components run as independent processes per Win11 architecture (§3.1).
fn renderSunValleyTaskbar(scr_w: i32, scr_h: i32, t: *const ThemeColors, tb_h: i32) void {
    const tb_y = scr_h - tb_h;

    // Mica backdrop for taskbar (win11Desktop.md §4.1: wallpaper-sampled blur)
    if (dwm_initialized and dwm_config.glass_enabled) {
        renderGlassEffect(0, tb_y, scr_w, tb_h, t.taskbar_top, dwm_config.glass_opacity);
    } else {
        fb.fillRect(0, tb_y, scr_w, tb_h, t.taskbar_top);
    }
    fb.drawHLine(0, tb_y, scr_w, t.tray_border);

    // Centered icon group (Win11 centered taskbar layout)
    const center_x = @divTrunc(scr_w, 2);
    const pinned_count: i32 = 6;
    const icon_spacing: i32 = 40;
    const group_w = pinned_count * icon_spacing;
    const group_start = center_x - @divTrunc(group_w, 2);

    // Start button (ZirconOS logo) — ZirconOSSunValley/resources/start_button.svg
    renderZirconLogo(group_start + 12, tb_y + @divTrunc(tb_h - 14, 2));

    // Pill active indicator under Start button
    const pill_y = tb_y + tb_h - 5;
    fb.fillRoundedRect(group_start + 8, pill_y, 20, 3, 1, t.selection_bg);

    // Search button
    const search_x = group_start + icon_spacing;
    const search_y = tb_y + @divTrunc(tb_h - 28, 2);
    fb.fillRoundedRect(search_x, search_y, 28, 28, 6, rgb(0x2D, 0x2D, 0x2D));
    fb.drawTextTransparent(search_x + 8, search_y + 6, "S", rgb(0x88, 0x88, 0x88));

    // Pinned app icons (File Manager, Browser, Terminal, Settings, Store)
    const icon_labels = [_][]const u8{ "E", "B", "T", "S", "M" };
    var i: i32 = 2;
    while (i < pinned_count) : (i += 1) {
        const ix = group_start + i * icon_spacing + 16;
        const iy = tb_y + @divTrunc(tb_h - 16, 2);
        const idx: usize = @intCast(i - 2);
        if (idx < icon_labels.len) {
            fb.drawTextTransparent(ix, iy, icon_labels[idx], t.clock_text);
        }
        // Pill indicator for running apps (first 2 have active indicators)
        if (i < 4) {
            const p_x = group_start + i * icon_spacing + 14;
            const p_color: u32 = if (i == 2) t.selection_bg else rgb(0x60, 0x60, 0x60);
            fb.fillRoundedRect(p_x, pill_y, 12, 3, 1, p_color);
        }
    }

    renderSunValleyTray(scr_w, tb_y, tb_h, t);
}

fn renderSunValleyTray(scr_w: i32, tb_y: i32, tb_h: i32, t: *const ThemeColors) void {
    const tray_w: i32 = 140;
    const tray_x = scr_w - tray_w - 12;
    const tray_y = tb_y + @divTrunc(tb_h - 32, 2);

    // System tray background with rounded corners
    fb.fillRoundedRect(tray_x, tray_y, tray_w, 32, 4, t.tray_bg);

    // Status icons (WiFi, Volume, Battery)
    fb.drawTextTransparent(tray_x + 8, tray_y + 8, "W", rgb(0xAA, 0xAA, 0xAA));
    fb.drawTextTransparent(tray_x + 24, tray_y + 8, "V", rgb(0xAA, 0xAA, 0xAA));
    fb.drawTextTransparent(tray_x + 40, tray_y + 8, "B", rgb(0xAA, 0xAA, 0xAA));

    // Date/Time
    fb.drawTextTransparent(tray_x + 60, tray_y + 2, "12:00 PM", t.clock_text);
    fb.drawTextTransparent(tray_x + 60, tray_y + 16, "2026/3/21", rgb(0x99, 0x99, 0x99));

    // Notification bell (far right)
    const bell_x = scr_w - 28;
    fb.drawTextTransparent(bell_x, tb_y + @divTrunc(tb_h - 16, 2), "N", rgb(0x88, 0x88, 0x88));
}

/// Render a Sun Valley window with Mica titlebar, SDF rounded corners,
/// depth shadow, and caption button group (minimize/maximize/close).
/// Implements win11Desktop.md §3.2 (rounded corner composition) and §4.1 (Mica).
/// Window chrome uses ZirconOSSunValley/resources/themes/ color scheme.
fn renderSunValleyWindow(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const wr = getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;
    const corner_r: i32 = 8;
    const sv_titlebar_h: i32 = 32;

    // Multi-layer depth shadow (win11Desktop.md §9: DWM auto-enhancement for Win32 windows)
    if (dwm_initialized and dwm_config.shadow_enabled) {
        mat.renderShadow(win_x, win_y, win_w, win_h, 12, 5);
    }

    // Window body with SDF rounded corners (§3.2)
    fb.fillRoundedRect(win_x, win_y, win_w, win_h, corner_r, t.window_bg);

    // Mica titlebar (§4.1: wallpaper sample → blur → desaturate → theme tint → luminosity)
    if (dwm_initialized and dwm_config.glass_enabled) {
        mat.renderMica(win_x, win_y, win_w, sv_titlebar_h);
    } else {
        fb.fillRect(win_x, win_y, win_w, sv_titlebar_h, t.titlebar_active_left);
    }

    // Title text (rendered with ZirconOSFonts/NotoSans)
    fb.drawTextTransparent(win_x + 12, win_y + 8, "Computer", t.titlebar_text);

    // Caption button group (pill-style layout, §3.2 rounded decorations)
    const btn_w: i32 = 46;
    const btn_h: i32 = sv_titlebar_h;
    const close_x = win_x + win_w - btn_w;
    fb.fillRect(close_x, win_y, btn_w, btn_h, t.btn_close_top);
    drawCloseSymbol(close_x, win_y, btn_w);

    fb.fillRect(close_x - btn_w, win_y, btn_w, btn_h, t.btn_minmax_top);
    drawMaxSymbol(close_x - btn_w, win_y, btn_w);

    fb.fillRect(close_x - btn_w * 2, win_y, btn_w, btn_h, t.btn_minmax_top);
    drawMinSymbol(close_x - btn_w * 2, win_y, btn_w);

    fb.drawHLine(win_x, win_y + sv_titlebar_h, win_w, t.tray_border);

    renderSunValleyWindowContent(win_x + 1, win_y + sv_titlebar_h, win_w - 2, win_h - sv_titlebar_h - 1, t);

    // 1px border + SDF rounded corner clipping (§3.2)
    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);
    mat.applyRoundedClip(win_x, win_y, win_w, win_h, @intCast(corner_r));
}

/// Render Sun Valley window content area showing filesystem items,
/// font info (ZirconOSFonts), resource info (ZirconOSSunValley), and
/// DWM compositor status. Uses WinUI 3 controls layout.
fn renderSunValleyWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const ThemeColors) void {
    // Navigation bar (WinUI 3 CommandBar style)
    fb.fillRect(x, y, w, 24, t.button_face);
    fb.drawHLine(x, y + 24, w, t.button_shadow);

    const toolbar_items = [_][]const u8{ "File", "Edit", "View", "Tools", "Help" };
    var tx: i32 = x + 8;
    for (toolbar_items) |item| {
        fb.drawTextTransparent(tx, y + 4, item, rgb(0x00, 0x00, 0x00));
        tx += fb.textWidth(item) + 16;
    }

    // Address bar (rounded, WinUI 3 TextBox style)
    const addr_y = y + 25;
    fb.fillRect(x, addr_y, w, 24, t.button_face);
    fb.drawHLine(x, addr_y + 24, w, t.button_shadow);
    fb.drawTextTransparent(x + 8, addr_y + 4, "Address: Z:\\", rgb(0x00, 0x00, 0x00));

    // Content area
    const content_y = addr_y + 25;
    const content_h = h - 71;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, rgb(0xFF, 0xFF, 0xFF));

        // Filesystem items (icons from ZirconOSSunValley/resources/icons/)
        const items = [_]struct { name: []const u8, icon_id: icons.IconId }{
            .{ .name = "Users", .icon_id = .documents },
            .{ .name = "Programs", .icon_id = .documents },
            .{ .name = "System", .icon_id = .documents },
            .{ .name = "3rdparty", .icon_id = .documents },
            .{ .name = "boot.cfg", .icon_id = .computer },
            .{ .name = "zloader", .icon_id = .computer },
        };

        var iy: i32 = content_y + 8;
        for (items) |item| {
            if (iy + 20 > content_y + content_h) break;
            drawThemedIconForActiveTheme(item.icon_id, x + 10, iy + 1, 1);
            fb.drawTextTransparent(x + 32, iy + 2, item.name, rgb(0x00, 0x00, 0x00));
            iy += 22;
        }

        // Sun Valley resource info line
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + 10, iy + 4, "Theme: Sun Valley (ZirconOSSunValley)", rgb(0x4C, 0xB0, 0xE8));
            iy += 18;
        }

        // Font info line (rendered with ZirconOSFonts typeface)
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + 10, iy + 4, "Font: Noto Sans (ZirconOSFonts)", rgb(0x80, 0x80, 0x80));
            iy += 18;
        }

        // DWM compositor info
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + 10, iy + 4, "DWM: Mica + Acrylic 2.0 + SDF Rounded", rgb(0x80, 0x80, 0x80));
            iy += 18;
        }

        // WDDM version info
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + 10, iy + 4, "WDDM 3.1 | DRR 60-120Hz | WinUI 3", rgb(0x99, 0x99, 0x99));
            iy += 18;
        }

        // Scrollbar
        const sb_x = x + w - 17;
        fb.fillRect(sb_x, content_y, 17, content_h, rgb(0xE8, 0xE8, 0xEB));
        fb.drawVLine(sb_x, content_y, content_h, t.button_shadow);
        fb.fillRoundedRect(sb_x + 2, content_y + 17, 13, 40, 6, rgb(0xC1, 0xC1, 0xC6));
    }

    // Status bar with resource and font info
    fb.fillRect(x, y + h - 24, w, 24, t.button_face);
    fb.drawHLine(x, y + h - 24, w, t.button_shadow);
    fb.drawTextTransparent(x + 8, y + h - 19, "6 objects | SunValley resources | NotoSans+CJK font | Mica DWM", rgb(0x00, 0x00, 0x00));
}

// ── Desktop Window Manager (DWM) Compositor ──

pub const DwmConfig = struct {
    glass_enabled: bool = true,
    glass_opacity: u8 = 180,
    glass_blur_radius: u8 = 12,
    glass_saturation: u8 = 200,
    glass_tint_color: u32 = 0x4068A0,
    glass_tint_opacity: u8 = 60,
    animation_enabled: bool = true,
    peek_enabled: bool = true,
    shadow_enabled: bool = true,
    vsync_compositor: bool = true,
    smooth_cursor: bool = true,
    cursor_lerp_factor: i32 = 200,
};

var dwm_config: DwmConfig = .{};
var dwm_initialized: bool = false;

pub fn initDwm(cfg: DwmConfig) void {
    dwm_config = cfg;
    dwm_initialized = true;
    desktop_ctx.dwm_active = cfg.glass_enabled;
    desktop_ctx.smooth_cursor.lerp_factor = cfg.cursor_lerp_factor;
}

pub fn isDwmEnabled() bool {
    return dwm_initialized and dwm_config.glass_enabled;
}

pub fn getDwmConfig() *const DwmConfig {
    return &dwm_config;
}

pub fn setDwmGlass(enabled: bool) void {
    dwm_config.glass_enabled = enabled;
    desktop_ctx.dwm_active = enabled;
}

pub fn setSmoothCursorFactor(factor: i32) void {
    desktop_ctx.smooth_cursor.lerp_factor = if (factor < 64) 64 else if (factor > 255) 255 else factor;
}

pub fn renderGlassEffect(x: i32, y: i32, w: i32, h: i32, tint: u32, opacity: u8) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    if (!dwm_config.glass_enabled) {
        fb.fillRect(x, y, w, h, tint);
        return;
    }

    const eff_opacity = if (opacity == 0) dwm_config.glass_opacity else opacity;
    const eff_tint = if (tint == 0) dwm_config.glass_tint_color else tint;
    const blur_r = @as(u32, dwm_config.glass_blur_radius);

    // Step 1: Multi-pass box blur on the background already rendered
    // (3 passes of box blur approximates Gaussian blur)
    if (blur_r > 0) {
        fb.boxBlurRect(x, y, w, h, blur_r, 3);
    }

    // Step 2: Desaturate + alpha-blend tint color
    fb.blendTintRect(x, y, w, h, eff_tint, eff_opacity, dwm_config.glass_saturation);

    // Step 3: Specular highlight band on upper third
    if (eff_opacity < 220) {
        const shine_h = @divTrunc(h, 3);
        if (shine_h > 1) {
            fb.addSpecularBand(x, y, w, shine_h, 35);

            // Thin bright edge at very top (1px)
            const edge_color = rgb(0xFF, 0xFF, 0xFF);
            fb.drawHLine(x, y, w, edge_color);
        }
    }
}

pub fn renderAeroGlassBar(x: i32, y: i32, w: i32, h: i32) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    const t = active_theme;

    if (dwm_initialized and dwm_config.glass_enabled) {
        // Real Aero glass: blur background → tint → highlight → top edge
        renderGlassEffect(x, y, w, h, t.taskbar_top, dwm_config.glass_opacity);
        fb.drawHLine(x, y, w, t.tray_border);
    } else {
        fb.drawGradientV(x, y, w, h, t.taskbar_top, t.taskbar_bottom);
        fb.drawHLine(x, y, w, t.tray_border);
    }
}

pub fn renderAeroTitlebar(x: i32, y: i32, w: i32, h: i32, is_active: bool) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    const t = active_theme;

    if (dwm_initialized and dwm_config.glass_enabled and is_active) {
        // Active Aero glass titlebar with blur + tint + specular
        renderGlassEffect(x, y, w, h, t.titlebar_active_left, dwm_config.glass_opacity);
    } else if (dwm_initialized and dwm_config.glass_enabled) {
        // Inactive glass titlebar: more transparent, less saturated
        renderGlassEffect(x, y, w, h, rgb(0x80, 0x90, 0xA0), dwm_config.glass_opacity / 2);
    } else {
        fb.drawGradientH(x, y, w, h, t.titlebar_active_left, t.titlebar_active_right);
    }
}

pub fn renderShadow(x: i32, y: i32, w: i32, h: i32, size: i32) void {
    if (!use_framebuffer or !dwm_config.shadow_enabled) return;
    if (size <= 0) return;

    // Multi-layer soft shadow with true alpha blending: each successive
    // layer has a smaller offset and decreasing opacity for soft edges.
    var layer: i32 = 0;
    while (layer < 4) : (layer += 1) {
        const offset = size - layer * 2;
        if (offset <= 0) break;
        // Darken the existing background by a small alpha (outer = darker, inner = lighter)
        const shadow_alpha: u8 = @intCast(@as(u32, @intCast(25 - layer * 5)));
        fb.blendTintRect(x + offset, y + offset, w, h, rgb(0x00, 0x00, 0x00), shadow_alpha, 255);
    }
}

// ── Desktop Background ──

pub fn renderDesktopBackground(color: u32) void {
    if (!use_framebuffer or !fb.isInitialized()) return;
    desktop_ctx.background_color = color;
    fb.clearScreen(color);
}

// ── Desktop Icons (with pixel art) ──

const IconDef = struct {
    label: []const u8,
    id: icons.IconId,
};

const desktop_icon_list = [_]IconDef{
    .{ .label = "Computer", .id = .computer },
    .{ .label = "Documents", .id = .documents },
    .{ .label = "Network", .id = .network },
    .{ .label = "Recycle Bin", .id = .recycle_bin },
    .{ .label = "Browser", .id = .browser },
};

fn renderDesktopIcons(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    _ = scr_w;
    const base_x: i32 = 20;
    var base_y: i32 = 16;
    const avail_h = scr_h - getTaskbarHeight() - 16;
    const icon_scale: u32 = 2;

    const icon_style: icons.ThemeStyle = switch (active_theme_id) {
        .classic => .classic,
        .luna => .luna,
        .aero => .aero,
        .modern => .modern,
        .fluent => .fluent,
        .sunvalley => .sunvalley,
    };

    for (desktop_icon_list) |icon_def| {
        if (base_y + ICON_GRID_Y > avail_h) break;
        renderOneIcon(base_x, base_y, icon_def, icon_scale, t, icon_style);
        base_y += ICON_GRID_Y;
    }
}

fn getActiveIconStyle() icons.ThemeStyle {
    return switch (active_theme_id) {
        .classic => .classic,
        .luna => .luna,
        .aero => .aero,
        .modern => .modern,
        .fluent => .fluent,
        .sunvalley => .sunvalley,
    };
}

fn drawThemedIconForActiveTheme(id: icons.IconId, x: i32, y: i32, scale: u32) void {
    icons.drawThemedIcon(id, x, y, scale, getActiveIconStyle());
}

fn renderOneIcon(x: i32, y: i32, icon_def: IconDef, scale: u32, t: *const ThemeColors, style: icons.ThemeStyle) void {
    const icon_drawn_size = icons.getIconTotalSize(scale);
    const ix = x + @divTrunc(ICON_GRID_X - icon_drawn_size, 2);
    const iy = y;

    icons.drawThemedIcon(icon_def.id, ix, iy, scale, style);

    const label = icon_def.label;
    const label_w = fb.textWidth(label);
    const tx = x + @divTrunc(ICON_GRID_X - label_w, 2);
    const ty = iy + icon_drawn_size + 4;

    fb.drawTextTransparent(tx + 1, ty + 1, label, t.icon_text_shadow);
    fb.drawTextTransparent(tx, ty, label, t.icon_text);
}

// ── Taskbar ──

fn renderTaskbar(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const tb_y = scr_h - TASKBAR_H;

    if (dwm_initialized and dwm_config.glass_enabled) {
        renderGlassEffect(0, tb_y, scr_w, TASKBAR_H, t.taskbar_top, dwm_config.glass_opacity);
    } else {
        fb.drawGradientV(0, tb_y, scr_w, TASKBAR_H, t.taskbar_top, t.taskbar_bottom);
    }
    fb.drawHLine(0, tb_y, scr_w, t.tray_border);

    renderStartButton(0, tb_y, START_BTN_W, TASKBAR_H, t);
    renderSystemTray(scr_w, tb_y, t);
}

fn renderStartButton(x: i32, y: i32, w: i32, h: i32, t: *const ThemeColors) void {
    fb.fillRoundedRect(x + 1, y + 1, w, h - 1, 6, t.start_btn_bottom);
    fb.fillRoundedRect(x, y, w, h - 1, 6, t.start_btn_top);
    fb.drawGradientV(x + 6, y + 2, w - 12, h - 4, t.start_btn_top, t.start_btn_bottom);

    renderZirconLogo(x + 8, y + 7);

    fb.drawTextTransparent(x + 28, y + 7, t.start_label, t.start_btn_text);
}

fn renderZirconLogo(x: i32, y: i32) void {
    const blue = rgb(0x3F, 0xA3, 0xD8);
    const dark = rgb(0x0A, 0x3A, 0x6A);
    const white = rgb(0xFF, 0xFF, 0xFF);
    fb.fillRect(x, y, 14, 14, blue);
    fb.fillRect(x + 1, y + 1, 12, 12, dark);
    fb.drawHLine(x + 3, y + 3, 8, white);
    var i: i32 = 0;
    while (i < 8) : (i += 1) {
        fb.putPixel32(@intCast(x + 10 - i), @intCast(y + 4 + i), white);
    }
    fb.drawHLine(x + 3, y + 11, 8, white);
}

fn renderSystemTray(scr_w: i32, tb_y: i32, t: *const ThemeColors) void {
    const tray_w: i32 = TRAY_CLOCK_W + 40;
    const tray_x = scr_w - tray_w;
    const tray_y = tb_y + @divTrunc(TASKBAR_H - TRAY_H, 2);

    fb.fillRect(tray_x, tray_y, tray_w, TRAY_H, t.tray_bg);
    fb.drawVLine(tray_x, tray_y, TRAY_H, t.tray_border);

    fb.drawTextTransparent(tray_x + 8, tray_y + 3, "12:00 PM", t.clock_text);
}

// ── Sample Window ──

fn renderSampleWindow(scr_w: i32, scr_h: i32, t: *const ThemeColors) void {
    const wr = getWindowRect(scr_w, scr_h);
    const win_w = wr.w;
    const win_h = wr.h;
    const win_x = wr.x;
    const win_y = wr.y;

    if (dwm_initialized and dwm_config.shadow_enabled) {
        renderShadow(win_x, win_y, win_w, win_h, 6);
    } else {
        fb.fillRect(win_x + 4, win_y + 4, win_w, win_h, rgb(0x00, 0x00, 0x00) & 0x20000000);
    }

    fb.fillRect(win_x, win_y, win_w, win_h, t.window_bg);

    if (dwm_initialized and dwm_config.glass_enabled) {
        renderGlassEffect(win_x, win_y, win_w, TITLEBAR_H, t.titlebar_active_left, dwm_config.glass_opacity);
    } else {
        fb.drawGradientH(win_x, win_y, win_w, TITLEBAR_H, t.titlebar_active_left, t.titlebar_active_right);
    }

    renderTitlebarButtons(win_x, win_y, win_w, t);

    fb.drawTextTransparent(win_x + 8, win_y + 5, "Computer", t.titlebar_text);

    fb.drawRect(win_x, win_y, win_w, win_h, t.window_border);

    renderWindowContent(win_x + WINDOW_BORDER, win_y + TITLEBAR_H, win_w - 2 * WINDOW_BORDER, win_h - TITLEBAR_H - WINDOW_BORDER, t);
}

fn renderTitlebarButtons(win_x: i32, win_y: i32, win_w: i32, t: *const ThemeColors) void {
    const btn_y = win_y + @divTrunc(TITLEBAR_H - BTN_SIZE, 2);
    const close_x = win_x + win_w - BTN_SIZE - 4;
    const max_x = close_x - BTN_SIZE - 2;
    const min_x = max_x - BTN_SIZE - 2;

    fb.fillRoundedRect(close_x, btn_y, BTN_SIZE, BTN_SIZE, 3, t.btn_close_top);
    drawCloseSymbol(close_x, btn_y, BTN_SIZE);

    fb.fillRoundedRect(max_x, btn_y, BTN_SIZE, BTN_SIZE, 3, t.btn_minmax_top);
    drawMaxSymbol(max_x, btn_y, BTN_SIZE);

    fb.fillRoundedRect(min_x, btn_y, BTN_SIZE, BTN_SIZE, 3, t.btn_minmax_top);
    drawMinSymbol(min_x, btn_y, BTN_SIZE);
}

fn drawCloseSymbol(bx: i32, by: i32, bs: i32) void {
    const cx = bx + @divTrunc(bs, 2);
    const cy = by + @divTrunc(bs, 2);
    const white = rgb(0xFF, 0xFF, 0xFF);
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
    const white = rgb(0xFF, 0xFF, 0xFF);
    const ox = bx + 5;
    const oy = by + 5;
    const sz = bs - 10;
    fb.drawRect(ox, oy, sz, sz, white);
    fb.drawHLine(ox, oy + 1, sz, white);
}

fn drawMinSymbol(bx: i32, by: i32, bs: i32) void {
    const white = rgb(0xFF, 0xFF, 0xFF);
    fb.fillRect(bx + 5, by + bs - 8, bs - 10, 3, white);
}

fn renderWindowContent(x: i32, y: i32, w: i32, h: i32, t: *const ThemeColors) void {
    fb.fillRect(x, y, w, 24, t.button_face);
    fb.drawHLine(x, y + 24, w, t.button_shadow);

    const toolbar_items = [_][]const u8{ "File", "Edit", "View", "Favorites", "Tools", "Help" };
    var tx: i32 = x + 8;
    for (toolbar_items) |item| {
        fb.drawTextTransparent(tx, y + 4, item, rgb(0x00, 0x00, 0x00));
        tx += fb.textWidth(item) + 16;
    }

    const addr_y = y + 25;
    fb.fillRect(x, addr_y, w, 22, t.button_face);
    fb.drawHLine(x, addr_y + 22, w, t.button_shadow);
    fb.drawTextTransparent(x + 8, addr_y + 3, "Address: Z:\\", rgb(0x00, 0x00, 0x00));

    const content_y = addr_y + 23;
    const content_h = h - 47;
    if (content_h > 0) {
        fb.fillRect(x, content_y, w, content_h, rgb(0xFF, 0xFF, 0xFF));

        const items = [_]struct { name: []const u8, icon_id: icons.IconId }{
            .{ .name = "Users", .icon_id = .documents },
            .{ .name = "Programs", .icon_id = .documents },
            .{ .name = "System", .icon_id = .documents },
            .{ .name = "3rdparty", .icon_id = .documents },
            .{ .name = "boot.cfg", .icon_id = .computer },
            .{ .name = "zloader", .icon_id = .computer },
        };

        var iy: i32 = content_y + 8;
        for (items) |item| {
            if (iy + 20 > content_y + content_h) break;

            drawThemedIconForActiveTheme(item.icon_id, x + 10, iy + 1, 1);

            fb.drawTextTransparent(x + 32, iy + 2, item.name, rgb(0x00, 0x00, 0x00));
            iy += 22;
        }

        // Font info line (rendered with ZirconOSFonts typeface)
        if (iy + 20 <= content_y + content_h) {
            fb.drawTextTransparent(x + 10, iy + 4, "Font: Noto Sans (ZirconOSFonts)", rgb(0x80, 0x80, 0x80));
            iy += 20;
        }

        const sb_x = x + w - 17;
        fb.fillRect(sb_x, content_y, 17, content_h, rgb(0xE8, 0xE8, 0xEB));
        fb.drawVLine(sb_x, content_y, content_h, t.button_shadow);
        fb.fillRect(sb_x + 1, content_y + 17, 16, 40, rgb(0xC1, 0xC1, 0xC6));
    }

    fb.fillRect(x, y + h - 22, w, 22, t.button_face);
    fb.drawHLine(x, y + h - 22, w, t.button_shadow);

    const status_text = if (active_theme_id == .sunvalley)
        "6 objects | SunValley resources | NotoSans+CJK font | Mica DWM"
    else if (active_theme_id == .fluent)
        "6 objects | Fluent+Aero resources | NotoSans font"
    else
        "6 objects";

    fb.drawTextTransparent(x + 8, y + h - 18, status_text, rgb(0x00, 0x00, 0x00));
}

// ── Window Drag State ──

var drag_active: bool = false;
var drag_offset_x: i32 = 0;
var drag_offset_y: i32 = 0;
var window_x: i32 = 0;
var window_y: i32 = 0;
var window_placed: bool = false;

fn initWindowPosition(scr_w: i32, scr_h: i32) void {
    if (!window_placed) {
        const win_w: i32 = if (scr_w > 600) 520 else scr_w - 140;
        const win_h: i32 = if (scr_h > 500) 380 else scr_h - 160;
        window_x = @divTrunc(scr_w - win_w, 2) + 30;
        window_y = @divTrunc(scr_h - getTaskbarHeight() - win_h, 2);
        window_placed = true;
    }
}

fn getWindowRect(scr_w: i32, scr_h: i32) struct { x: i32, y: i32, w: i32, h: i32 } {
    initWindowPosition(scr_w, scr_h);
    const win_w: i32 = if (scr_w > 600) 520 else scr_w - 140;
    const win_h: i32 = if (scr_h > 500) 380 else scr_h - 160;
    return .{ .x = window_x, .y = window_y, .w = win_w, .h = win_h };
}

// ── Right-Click Context Menu ──

var ctx_menu_visible: bool = false;
var ctx_menu_x: i32 = 0;
var ctx_menu_y: i32 = 0;

const ctx_menu_items = [_][]const u8{
    "View",
    "Sort By",
    "Refresh",
    "---",
    "New",
    "---",
    "Display Settings",
    "Personalize",
};

const CTX_ITEM_H: i32 = 24;
const CTX_MENU_W: i32 = 180;
const CTX_SEP_H: i32 = 8;

fn ctxMenuHeight() i32 {
    var h: i32 = 8;
    for (ctx_menu_items) |item| {
        if (item.len == 3 and item[0] == '-') {
            h += CTX_SEP_H;
        } else {
            h += CTX_ITEM_H;
        }
    }
    return h + 4;
}

pub fn showContextMenu(x: i32, y: i32) void {
    const h: i32 = @intCast(fb.getHeight());
    const w: i32 = @intCast(fb.getWidth());
    ctx_menu_x = if (x + CTX_MENU_W > w) w - CTX_MENU_W - 2 else x;
    const menu_h = ctxMenuHeight();
    const tb_h = getTaskbarHeight();
    ctx_menu_y = if (y + menu_h > h - tb_h) h - tb_h - menu_h - 2 else y;
    ctx_menu_visible = true;
}

pub fn hideContextMenu() void {
    ctx_menu_visible = false;
}

fn renderContextMenu() void {
    if (!ctx_menu_visible) return;
    const t = active_theme;
    const menu_h = ctxMenuHeight();

    fb.fillRect(ctx_menu_x + 2, ctx_menu_y + 2, CTX_MENU_W, menu_h, rgb(0x20, 0x20, 0x20));

    fb.fillRect(ctx_menu_x, ctx_menu_y, CTX_MENU_W, menu_h, t.window_bg);
    fb.drawRect(ctx_menu_x, ctx_menu_y, CTX_MENU_W, menu_h, t.window_border);

    var iy: i32 = ctx_menu_y + 4;
    for (ctx_menu_items) |item| {
        if (item.len == 3 and item[0] == '-') {
            fb.drawHLine(ctx_menu_x + 4, iy + 3, CTX_MENU_W - 8, t.button_shadow);
            iy += CTX_SEP_H;
        } else {
            fb.drawTextTransparent(ctx_menu_x + 28, iy + 4, item, rgb(0x1A, 0x1A, 0x1A));
            iy += CTX_ITEM_H;
        }
    }
}

fn isInsideContextMenu(x: i32, y: i32) bool {
    if (!ctx_menu_visible) return false;
    const menu_h = ctxMenuHeight();
    return x >= ctx_menu_x and x < ctx_menu_x + CTX_MENU_W and
        y >= ctx_menu_y and y < ctx_menu_y + menu_h;
}

// ── Cursor Rendering (ZirconOS Aero Crystal Style) ──
// The cursor uses a crystal/glass design with:
//   - Dark teal outline for sharp definition
//   - White fill for high visibility
//   - Glass highlight for upper-left interior (Aero reflective effect)
//   - Inner glow tint for depth perception
//   - Optional drop shadow when DWM is active

pub fn renderCursor(x: i32, y: i32) void {
    if (!use_framebuffer) return;

    const w_i32: i32 = @intCast(fb.getWidth());
    const h_i32: i32 = @intCast(fb.getHeight());

    // 0=transparent, 1=fill, 2=outline, 3=glass_highlight, 4=inner_glow, 5=shadow
    const cursor_shape = [_][14]u3{
        .{ 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 3, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 3, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 3, 3, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 3, 3, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 4, 3, 3, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0 },
        .{ 2, 4, 3, 3, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0 },
        .{ 2, 4, 4, 3, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0 },
        .{ 2, 4, 4, 3, 1, 1, 1, 1, 1, 1, 2, 0, 0, 0 },
        .{ 2, 4, 4, 3, 1, 1, 1, 2, 2, 2, 2, 2, 0, 0 },
        .{ 2, 1, 1, 1, 1, 1, 2, 0, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 1, 2, 4, 1, 1, 2, 0, 0, 0, 0, 0, 0 },
        .{ 2, 1, 2, 0, 2, 4, 1, 1, 2, 0, 0, 0, 0, 0 },
        .{ 2, 2, 0, 0, 2, 4, 1, 1, 2, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 4, 1, 1, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 2, 4, 1, 1, 2, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0, 0 },
        .{ 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0 },
    };

    const outline = rgb(0x06, 0x28, 0x28);
    const fill = rgb(0xFF, 0xFF, 0xFF);
    const glass_hi = rgb(0xA8, 0xF0, 0xF0);
    const inner_glow = rgb(0x2A, 0xBF, 0xBF);

    if (dwm_initialized and dwm_config.shadow_enabled) {
        const shadow_color = rgb(0x00, 0x00, 0x00);
        for (cursor_shape, 0..) |row, dy| {
            for (row, 0..) |pixel, dx| {
                if (pixel == 2) {
                    const sx = x + @as(i32, @intCast(dx)) + 1;
                    const sy = y + @as(i32, @intCast(dy)) + 1;
                    if (sx >= 0 and sx < w_i32 and sy >= 0 and sy < h_i32) {
                        fb.putPixel32(@intCast(sx), @intCast(sy), shadow_color & 0x30000000);
                    }
                }
            }
        }
    }

    for (cursor_shape, 0..) |row, dy| {
        for (row, 0..) |pixel, dx| {
            if (pixel != 0) {
                const px = x + @as(i32, @intCast(dx));
                const py = y + @as(i32, @intCast(dy));
                if (px >= 0 and px < w_i32 and py >= 0 and py < h_i32) {
                    const color: u32 = switch (pixel) {
                        1 => fill,
                        2 => outline,
                        3 => glass_hi,
                        4 => inner_glow,
                        else => fill,
                    };
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

pub fn renderLegacyTaskbar(x: i32, y: i32, w: i32, h: i32, top_color: u32, bottom_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(x, y, w, h, top_color, bottom_color);
}

pub fn renderLegacyStartButton(x: i32, y: i32, w: i32, h: i32, top_color: u32, bottom_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(x, y, w, h, top_color, bottom_color);
    fb.drawRect(x, y, w, h, rgb(0xFF, 0xFF, 0xFF));
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
    fb.drawRect(x + 4, y + 4, icon_size - 8, icon_size - 8, rgb(0x80, 0x80, 0x80));
    if (selected) {
        fb.drawRect(x, y, icon_size, icon_size, rgb(0x31, 0x6A, 0xC5));
    }
}

pub fn renderStartMenu(x: i32, y: i32, w: i32, h: i32, bg_color: u32, header_color: u32, header_height: i32) void {
    if (!use_framebuffer) return;
    fb.fillRect(x, y, w, h, bg_color);
    fb.fillRect(x, y, w, header_height, header_color);
    fb.drawRect(x, y, w, h, rgb(0x80, 0x80, 0x80));
}

pub fn renderLoginScreen(width: u32, height: u32, top_color: u32, bottom_color: u32, panel_color: u32) void {
    if (!use_framebuffer) return;
    fb.drawGradientV(0, 0, @intCast(width), @intCast(height), top_color, bottom_color);
    const pw: i32 = 400;
    const ph: i32 = 300;
    const px: i32 = @intCast((width - @as(u32, @intCast(pw))) / 2);
    const py: i32 = @intCast((height - @as(u32, @intCast(ph))) / 2);
    fb.fillRect(px, py, pw, ph, panel_color);
    fb.drawRect(px, py, pw, ph, rgb(0x80, 0x80, 0x80));
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
