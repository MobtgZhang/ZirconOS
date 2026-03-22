//! Fluent Desktop Shell
//! Orchestrates the desktop session: initializes DWM compositor,
//! coordinates desktop, taskbar, start menu, action center, and
//! manages window focus, virtual desktops, and snap layouts.
//!
//! OS Interface Integration (ZirconOS/src):
//!   The shell creates minimized windows for Core, CMD, and PowerShell
//!   which appear in the taskbar. These provide access to the kernel's
//!   subsystem interfaces without cluttering the desktop.

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");
const desktop_mod = @import("desktop.zig");
const taskbar_mod = @import("taskbar.zig");
const startmenu_mod = @import("startmenu.zig");
const winlogon_mod = @import("winlogon.zig");
const action_center_mod = @import("action_center.zig");

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

const MAX_VIRTUAL_DESKTOPS: usize = 16;
var virtual_desktops: [MAX_VIRTUAL_DESKTOPS]VirtualDesktop = [_]VirtualDesktop{.{}} ** MAX_VIRTUAL_DESKTOPS;
var vd_count: usize = 0;
var active_vd: usize = 0;

var state: ShellState = .initializing;
var color_scheme: theme.ColorScheme = .dark;

pub fn getState() ShellState {
    return state;
}

pub fn getColorScheme() theme.ColorScheme {
    return color_scheme;
}

pub fn initShell() void {
    initShellWithScheme(.dark);
}

pub fn initShellWithScheme(scheme: theme.ColorScheme) void {
    color_scheme = scheme;

    dwm.init(.{
        .composition_enabled = true,
        .acrylic_enabled = true,
        .acrylic_opacity = theme.DwmDefaults.acrylic_opacity,
        .blur_radius = theme.DwmDefaults.blur_radius,
        .blur_passes = theme.DwmDefaults.blur_passes,
        .noise_opacity = theme.DwmDefaults.noise_opacity,
        .luminosity_blend = theme.DwmDefaults.luminosity_blend,
        .shadow_enabled = true,
        .shadow_size = theme.DwmDefaults.shadow_size,
        .shadow_layers = theme.DwmDefaults.shadow_layers,
        .shadow_opacity = theme.DwmDefaults.shadow_opacity,
        .animation_enabled = true,
        .reveal_enabled = true,
    });

    desktop_mod.init(scheme);

    taskbar_mod.init(.{
        .acrylic_enabled = true,
        .height = theme.Layout.taskbar_height,
        .show_search = true,
        .show_task_view = true,
        .color_scheme = scheme,
    });

    startmenu_mod.init(scheme);
    winlogon_mod.init(scheme);
    action_center_mod.init(scheme);

    initVirtualDesktops();
    initOsInterfaceWindows();

    state = .desktop;
}

/// Register minimized OS interface windows (Core, CMD, PowerShell)
/// in the taskbar. These represent the kernel subsystems from ZirconOS/src
/// and start in minimized state on the taskbar.
fn initOsInterfaceWindows() void {
    taskbar_mod.setActive(0);
}

fn initVirtualDesktops() void {
    vd_count = 1;
    var vd = &virtual_desktops[0];
    const name = "Desktop 1";
    for (name, 0..) |ch, i| {
        vd.name[i] = ch;
    }
    vd.name_len = @intCast(name.len);
    vd.active = true;
    active_vd = 0;
}

pub fn addVirtualDesktop() void {
    if (vd_count >= MAX_VIRTUAL_DESKTOPS) return;
    var vd = &virtual_desktops[vd_count];
    vd.active = false;

    const prefix = "Desktop ";
    for (prefix, 0..) |ch, i| {
        vd.name[i] = ch;
    }
    const digit: u8 = @intCast(vd_count + 1);
    if (digit < 10) {
        vd.name[prefix.len] = '0' + digit;
        vd.name_len = @intCast(prefix.len + 1);
    } else {
        vd.name[prefix.len] = '0' + digit / 10;
        vd.name[prefix.len + 1] = '0' + digit % 10;
        vd.name_len = @intCast(prefix.len + 2);
    }
    vd_count += 1;
}

pub fn switchVirtualDesktop(index: usize) void {
    if (index >= vd_count) return;
    virtual_desktops[active_vd].active = false;
    active_vd = index;
    virtual_desktops[active_vd].active = true;
}

pub fn getVirtualDesktopCount() usize {
    return vd_count;
}

pub fn getActiveVirtualDesktop() usize {
    return active_vd;
}

pub fn handleStartButton() void {
    if (action_center_mod.isVisible()) {
        action_center_mod.hide();
    }
    startmenu_mod.toggle();
}

pub fn handleActionCenter() void {
    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
    }
    action_center_mod.toggle_visibility();
}

pub fn handleDesktopClick(x: i32, y: i32, screen_h: i32) void {
    if (startmenu_mod.isVisible()) {
        if (!startmenu_mod.contains(screen_h, x, y)) {
            startmenu_mod.hide();
        }
        return;
    }

    if (action_center_mod.isVisible()) {
        action_center_mod.hide();
        return;
    }

    if (taskbar_mod.isClickOnStartButton(x, y, screen_h)) {
        handleStartButton();
        return;
    }

    if (taskbar_mod.isClickOnTaskbar(x, y, screen_h)) {
        return;
    }

    // Desktop icon click
    if (desktop_mod.iconHitTest(x, y)) |idx| {
        desktop_mod.selectIcon(idx);
        return;
    }

    desktop_mod.deselectAll();
}

pub fn handleDesktopRightClick(x: i32, y: i32, screen_h: i32) void {
    _ = screen_h;
    if (startmenu_mod.isVisible()) {
        startmenu_mod.hide();
        return;
    }
    if (action_center_mod.isVisible()) {
        action_center_mod.hide();
        return;
    }
    desktop_mod.showContextMenu(x, y);
}

pub fn lockDesktop() void {
    state = .lock_screen;
    winlogon_mod.lockSession();
}

pub fn shutdown() void {
    state = .shutting_down;
}
