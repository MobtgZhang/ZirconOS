//! ZirconOSLuna - Desktop Shell Entry Point
//! Standalone test runner and integration demo for the Luna desktop.

const std = @import("std");
const luna = @import("ZirconOSLuna");

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("=== ZirconOS Luna Desktop ===\n", .{});
    try stdout.print("Version: {s}\n", .{luna.getVersion()});
    try stdout.print("\n", .{});

    try stdout.print("[Phase 1] Initializing Luna theme...\n", .{});
    const config = luna.ShellConfig{
        .screen_width = 1024,
        .screen_height = 768,
        .color_depth = 32,
        .color_scheme = .blue,
    };
    luna.initLunaDesktop(config);
    try stdout.print("  Theme: {s}\n", .{luna.getThemeName()});
    try stdout.print("  Resolution: {d}x{d}\n", .{ config.screen_width, config.screen_height });
    try stdout.print("\n", .{});

    try stdout.print("[Phase 2] Login screen active\n", .{});
    try stdout.print("  State: login_screen = {}\n", .{luna.isLoginScreen()});
    try stdout.print("\n", .{});

    try stdout.print("[Phase 3] Performing user login...\n", .{});
    _ = luna.selectLoginUser(1);
    const auth_result = luna.submitLoginPassword("");
    try stdout.print("  Auth result: {}\n", .{@intFromEnum(auth_result)});
    try stdout.print("  Logged in user: {s}\n", .{luna.getCurrentUsername()});
    try stdout.print("  Desktop active: {}\n", .{luna.isDesktopActive()});
    try stdout.print("\n", .{});

    try stdout.print("[Phase 4] Desktop components:\n", .{});
    try stdout.print("  Desktop icons: {d}\n", .{luna.desktop.getIconCount()});
    try stdout.print("  Taskbar tasks: {d}\n", .{luna.taskbar.getTaskCount()});
    try stdout.print("  Tray icons: {d}\n", .{luna.taskbar.getTrayIconCount()});
    try stdout.print("\n", .{});

    if (luna.desktop.getIcon(0)) |icon| {
        try stdout.print("  Icon 0: {s}\n", .{icon.getName()});
    }

    try stdout.print("\n", .{});
    try stdout.print("[Phase 5] Testing start menu...\n", .{});
    luna.handleShellEvent(.start_menu_toggle, 0, 0);
    try stdout.print("  Start menu open: {}\n", .{luna.startmenu.isOpen()});
    try stdout.print("  User display: {s}\n", .{luna.startmenu.getUserDisplayName()});

    const left_items = luna.startmenu.getLeftPinnedItems();
    try stdout.print("  Pinned programs: {d}\n", .{left_items.len});
    for (left_items) |item| {
        try stdout.print("    - {s}\n", .{item.getName()});
    }

    const right_items = luna.startmenu.getRightItems();
    try stdout.print("  System links: {d}\n", .{right_items.len});
    for (right_items) |item| {
        if (item.item_type != .separator) {
            try stdout.print("    - {s}\n", .{item.getName()});
        }
    }
    try stdout.print("\n", .{});

    try stdout.print("[Phase 6] Testing color schemes...\n", .{});
    luna.setColorScheme(.olive_green);
    try stdout.print("  Switched to: {s}\n", .{luna.getThemeName()});
    luna.setColorScheme(.silver);
    try stdout.print("  Switched to: {s}\n", .{luna.getThemeName()});
    luna.setColorScheme(.blue);
    try stdout.print("  Switched to: {s}\n", .{luna.getThemeName()});
    try stdout.print("\n", .{});

    try stdout.print("[Phase 7] Testing session control...\n", .{});
    luna.lockWorkstation();
    try stdout.print("  Locked: {}\n", .{luna.winlogon.isLocked()});
    try stdout.print("\n", .{});

    try stdout.print("=== Luna Desktop Test Complete ===\n", .{});

    try stdout.flush();
}

test "theme initialization" {
    luna.theme.init();
    try std.testing.expectEqual(luna.theme.ColorScheme.blue, luna.theme.getColorScheme());
}

test "theme color schemes" {
    luna.theme.setColorScheme(.olive_green);
    try std.testing.expectEqual(luna.theme.ColorScheme.olive_green, luna.theme.getColorScheme());
    luna.theme.setColorScheme(.blue);
}

test "user creation and authentication" {
    luna.winlogon.init();
    const user = luna.winlogon.createUser("testuser", "Test User", "password123", .standard);
    try std.testing.expect(user != null);

    const result = luna.winlogon.authenticate("testuser", "password123");
    try std.testing.expectEqual(luna.winlogon.AuthResult.success, result);

    const bad_result = luna.winlogon.authenticate("testuser", "wrongpassword");
    try std.testing.expectEqual(luna.winlogon.AuthResult.invalid_password, bad_result);
}

test "desktop icons" {
    luna.desktop.init();
    try std.testing.expect(luna.desktop.getIconCount() > 0);
    const icon = luna.desktop.getIcon(0);
    try std.testing.expect(icon != null);
}

test "controls creation" {
    var btn = luna.controls.PushButton{};
    btn.setLabel("OK");
    try std.testing.expectEqualStrings("OK", btn.getLabel());
    try std.testing.expect(btn.hitTest(btn.x + 1, btn.y + 1));

    var tb = luna.controls.TextBox{};
    _ = tb.insertChar('A');
    try std.testing.expectEqualStrings("A", tb.getText());
    _ = tb.deleteChar();
    try std.testing.expectEqual(@as(usize, 0), tb.text_len);
}

test "color interpolation" {
    const white = luna.RGB(255, 255, 255);
    const black = luna.RGB(0, 0, 0);
    const mid = luna.theme.interpolateColor(black, white, 1, 2);
    _ = mid;
}
