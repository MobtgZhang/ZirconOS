//! ZirconOS Driver Module Root
//! Provides centralized initialization and access to all kernel-mode drivers.
//! Reference: ReactOS drivers/ directory layout and NT driver model
//!
//! Driver categories:
//!   video/   - Display drivers (VGA, HDMI, Framebuffer, Display Manager)
//!   audio/   - Audio drivers (AC97, event system)
//!   input/   - Input drivers (PS/2 Mouse)
//!
//! Each driver registers with the I/O Manager as a DriverObject + DeviceObject
//! and handles IRPs through its dispatch function.

const builtin = @import("builtin");
const klog = @import("../rtl/klog.zig");

const is_x86 = (builtin.target.cpu.arch == .x86_64);

pub const video = struct {
    pub const vga = @import("video/vga.zig");
    pub const hdmi = @import("video/hdmi.zig");
    pub const framebuffer = @import("video/framebuffer.zig");
    pub const display = @import("video/display.zig");
    pub const icons = @import("video/icons.zig");
    pub const startmenu = @import("video/startmenu.zig");
    pub const dwm_compositor = @import("video/dwm_compositor.zig");
    pub const material = @import("video/material.zig");
    pub const visual_tree = @import("video/visual_tree.zig");
};

pub const audio = struct {
    pub const core = @import("audio/audio.zig");
    pub const ac97 = @import("audio/ac97.zig");
};

pub const input = if (is_x86) struct {
    pub const mouse = @import("input/mouse.zig");
} else struct {};

var drivers_initialized: bool = false;

pub fn init() void {
    klog.info("Drivers: Initializing driver stack...", .{});

    video.display.init();

    drivers_initialized = true;

    klog.info("Drivers: Video ready (VGA=%s, HDMI=%s, Display=%s)", .{
        if (video.vga.isInitialized()) "yes" else "no",
        if (video.hdmi.isInitialized()) "yes" else "no",
        if (video.display.isInitialized()) "yes" else "no",
    });
}

pub fn initInputDrivers() void {
    if (is_x86) {
        input.mouse.init();

        klog.info("Drivers: Input ready (Mouse=%s)", .{
            if (input.mouse.isInitialized()) "yes" else "no",
        });
    } else {
        klog.info("Drivers: Input skipped (no PS/2 on this arch)", .{});
    }
}

pub fn initAudioDrivers() void {
    audio.ac97.init();

    klog.info("Drivers: Audio ready (AC97=%s)", .{
        if (audio.ac97.isInitialized()) "yes" else "no",
    });
}

pub fn initDesktopMode(fb_addr: usize, width: u32, height: u32, pitch: u32, bpp: u8) void {
    video.display.initDesktopMode(fb_addr, width, height, pitch, bpp);

    if (is_x86) {
        input.mouse.setScreenBounds(@intCast(width), @intCast(height));
        input.mouse.setPosition(@intCast(width / 2), @intCast(height / 2));
    }

    klog.info("Drivers: Desktop display mode enabled (%ux%u@%ubpp)", .{ width, height, bpp });
}

pub fn isInitialized() bool {
    return drivers_initialized;
}

pub fn isDesktopReady() bool {
    return video.display.isDesktopReady();
}
