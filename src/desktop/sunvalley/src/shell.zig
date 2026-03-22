//! Sun Valley Desktop Shell
//! Orchestrates the desktop session: initializes Mica compositor,
//! coordinates desktop, centered taskbar, start menu, widget panel,
//! quick settings, and manages window focus/snap layout and session lifecycle.

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");
const desktop_mod = @import("desktop.zig");
const taskbar_mod = @import("taskbar.zig");
const startmenu_mod = @import("startmenu.zig");
const winlogon_mod = @import("winlogon.zig");
const widget_mod = @import("widget_panel.zig");
const quick_mod = @import("quick_settings.zig");

pub const ShellState = enum {
    initializing,
    login,
    desktop,
    lock_screen,
    shutting_down,
};

pub const VirtualDesktop = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    active: bool = false,
};

const MAX_VIRTUAL_DESKTOPS: usize = 8;
var virtual_desktops: [MAX_VIRTUAL_DESKTOPS]VirtualDesktop = [_]VirtualDesktop{.{}} ** MAX_VIRTUAL_DESKTOPS;
var vd_count: usize = 0;
var current_vd: usize = 0;

var state: ShellState = .initializing;
var color_scheme: theme.ColorScheme = .dark;

pub fn getState() ShellState {
    return state;
}

pub fn getColorScheme() theme.ColorScheme {
    return color_scheme;
}

pub fn setColorScheme(scheme: theme.ColorScheme) void {
    color_scheme = scheme;
    dwm.setColorScheme(scheme);
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addVirtualDesktop(name: []const u8) void {
    if (vd_count >= MAX_VIRTUAL_DESKTOPS) return;
    var vd = &virtual_desktops[vd_count];
    vd.name_len = setStr(&vd.name, name);
    vd.active = (vd_count == 0);
    vd_count += 1;
}

pub fn initShell() void {
    initShellWithScheme(.dark);
}

pub fn initShellWithScheme(scheme: theme.ColorScheme) void {
    color_scheme = scheme;

    dwm.init(.{
        .mica_enabled = true,
        .mica_opacity = theme.DwmDefaults.mica_opacity,
        .mica_blur_radius = theme.DwmDefaults.mica_blur_radius,
        .mica_blur_passes = theme.DwmDefaults.mica_blur_passes,
        .mica_luminosity = theme.DwmDefaults.mica_luminosity,
        .mica_tint_color = theme.getScheme(scheme).mica_tint,
        .mica_tint_opacity = theme.DwmDefaults.mica_tint_opacity,
        .acrylic_enabled = true,
        .acrylic_blur_radius = theme.DwmDefaults.acrylic_blur_radius,
        .acrylic_blur_passes = theme.DwmDefaults.acrylic_blur_passes,
        .acrylic_noise_opacity = theme.DwmDefaults.acrylic_noise_opacity,
        .round_corners = true,
        .corner_radius = theme.DwmDefaults.corner_radius,
        .shadow_enabled = true,
        .shadow_size = theme.DwmDefaults.shadow_size,
        .shadow_layers = theme.DwmDefaults.shadow_layers,
        .shadow_spread = theme.DwmDefaults.shadow_spread,
        .snap_assist = true,
        .color_scheme = scheme,
    });

    desktop_mod.init();

    taskbar_mod.init(.{
        .centered = true,
        .height = theme.Layout.taskbar_height,
        .color_scheme = scheme,
    });

    startmenu_mod.init();
    widget_mod.init();
    quick_mod.init(scheme);
    winlogon_mod.init();

    vd_count = 0;
    addVirtualDesktop("Desktop 1");

    state = .desktop;
}

pub fn handleStartButton() void {
    widget_mod.hide();
    quick_mod.hide();
    startmenu_mod.toggle();
}

pub fn handleWidgetButton() void {
    startmenu_mod.hide();
    quick_mod.hide();
    widget_mod.toggle();
}

pub fn handleQuickSettings() void {
    startmenu_mod.hide();
    widget_mod.hide();
    quick_mod.toggle();
}

pub fn handleDesktopClick(x: i32, y: i32, screen_w: i32, screen_h: i32) void {
    if (startmenu_mod.isVisible()) {
        if (!startmenu_mod.contains(screen_w, screen_h, x, y)) {
            startmenu_mod.hide();
        }
        return;
    }

    if (widget_mod.isVisible()) {
        widget_mod.hide();
        return;
    }

    if (quick_mod.isVisible()) {
        quick_mod.hide();
        return;
    }

    if (taskbar_mod.isClickOnStartButton(x, y, screen_w, screen_h)) {
        handleStartButton();
        return;
    }

    if (taskbar_mod.isClickOnTaskbar(x, y, screen_h)) {
        return;
    }

    if (desktop_mod.iconHitTest(x, y)) |idx| {
        desktop_mod.selectIcon(idx);
        return;
    }

    desktop_mod.deselectAll();
}

pub fn handleDesktopRightClick(x: i32, y: i32, _: i32, _: i32) void {
    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        return;
    }
    desktop_mod.showContextMenu(x, y);
}

pub fn switchVirtualDesktop(index: usize) void {
    if (index >= vd_count) return;
    for (virtual_desktops[0..vd_count]) |*vd| {
        vd.active = false;
    }
    virtual_desktops[index].active = true;
    current_vd = index;
}

pub fn addNewVirtualDesktop() void {
    var name_buf: [32]u8 = [_]u8{0} ** 32;
    const prefix = "Desktop ";
    for (0..prefix.len) |i| {
        name_buf[i] = prefix[i];
    }
    name_buf[prefix.len] = '0' + @as(u8, @intCast(vd_count + 1));
    addVirtualDesktop(name_buf[0 .. prefix.len + 1]);
}

pub fn getVirtualDesktops() []const VirtualDesktop {
    return virtual_desktops[0..vd_count];
}

pub fn lockDesktop() void {
    state = .lock_screen;
    winlogon_mod.lockSession();
}

pub fn shutdown() void {
    state = .shutting_down;
}
