//! ZirconOS Sun Valley Desktop — Executable Entry Point
//! Integration test and demo entry for the Sun Valley theme.

const std = @import("std");
const root = @import("root.zig");
const theme = @import("theme.zig");

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buf);
    const w = &file_writer.interface;
    try w.print("ZirconOS {s} v{s}\n", .{ root.theme_name, root.theme_version });
    try w.print("{s}\n\n", .{root.theme_description});

    try w.print("=== Dark Mode ===\n", .{});
    try w.print("Desktop background : 0x{X:0>6}\n", .{root.getDesktopBackground(.dark)});
    try w.print("Mica tint          : 0x{X:0>6}\n", .{root.getMicaTintColor(.dark)});
    try w.print("Mica opacity       : {d}\n", .{root.getMicaOpacity(.dark)});

    try w.print("\n=== Light Mode ===\n", .{});
    try w.print("Desktop background : 0x{X:0>6}\n", .{root.getDesktopBackground(.light)});
    try w.print("Mica tint          : 0x{X:0>6}\n", .{root.getMicaTintColor(.light)});
    try w.print("Mica opacity       : {d}\n", .{root.getMicaOpacity(.light)});

    try w.print("\nTaskbar height     : {d}px\n", .{root.getTaskbarHeight()});
    try w.print("Titlebar height    : {d}px\n", .{root.getTitlebarHeight()});
    try w.print("Corner radius      : {d}px\n", .{theme.Layout.corner_radius});
    try w.print("Centered taskbar   : {}\n", .{theme.Layout.taskbar_centered});

    try w.print("\nSun Valley theme loaded successfully.\n", .{});
    try w.flush();
}
