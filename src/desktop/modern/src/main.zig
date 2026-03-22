//! ZirconOS Modern Desktop — Metro Compositor Entry Point
//!
//! Implements the Windows 8 basic compositor architecture:
//!   1. Each window renders to its own surface (no glass/blur)
//!   2. Compositor reads all surfaces and blits by Z-order
//!   3. Flat solid-color window chrome, no transparency
//!   4. VSync-aligned frame presentation
//!
//! Resources: 本目录下 `resources/`
//! Fonts: `src/fonts/`

const std = @import("std");
const root = @import("root.zig");
const theme = root.theme;
const shell = root.shell;
const desktop = root.desktop;
const taskbar = root.taskbar;
const startmenu = root.startmenu;
const compositor = @import("compositor.zig");
const resource_loader = @import("resource_loader.zig");
const font_loader = @import("font_loader.zig");

const SCREEN_W: u32 = 1024;
const SCREEN_H: u32 = 768;

const OsWindow = struct {
    title: []const u8,
    icon_id: u16,
    minimized: bool,
};

const os_windows = [_]OsWindow{
    .{ .title = "ZirconOS Core", .icon_id = 1, .minimized = true },
    .{ .title = "Command Prompt", .icon_id = 4, .minimized = true },
    .{ .title = "PowerShell", .icon_id = 4, .minimized = true },
};

fn p(out: *std.Io.Writer, comptime fmt: []const u8, args: anytype) void {
    out.print(fmt, args) catch {};
}

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    const out = &w.interface;

    p(out, "╔══════════════════════════════════════════╗\n", .{});
    p(out, "║  ZirconOS {s} v{s}                    ║\n", .{ root.theme_name, root.theme_version });
    p(out, "║  Metro Flat Desktop Compositor            ║\n", .{});
    p(out, "╚══════════════════════════════════════════╝\n\n", .{});

    // ── Phase 1: Load Resources ──
    p(out, "--- Phase 1: Loading Resources ---\n", .{});

    resource_loader.init();
    p(out, "  Wallpapers : {d} loaded\n", .{resource_loader.getWallpaperCount()});
    p(out, "  Icons      : {d} loaded\n", .{resource_loader.getIconCount()});
    p(out, "  Cursors    : {d} loaded\n", .{resource_loader.getCursorCount()});
    p(out, "  Themes     : {d} loaded\n", .{resource_loader.getThemeFileCount()});

    // ── Phase 2: Load Fonts ──
    p(out, "\n--- Phase 2: Loading Fonts ---\n", .{});

    font_loader.init();
    p(out, "  Western fonts : {d} families\n", .{font_loader.getWesternFontCount()});
    p(out, "  CJK fonts     : {d} families\n", .{font_loader.getCjkFontCount()});
    p(out, "  System font   : {s}\n", .{font_loader.getSystemFontName()});
    p(out, "  Mono font     : {s}\n", .{font_loader.getMonoFontName()});
    p(out, "  CJK font      : {s}\n", .{font_loader.getCjkFontName()});

    // ── Phase 3: Initialize Compositor ──
    p(out, "\n--- Phase 3: Basic Compositor Init ---\n", .{});

    shell.initShell();
    compositor.init(SCREEN_W, SCREEN_H);

    p(out, "  Glass enabled  : {}\n", .{theme.isGlassEnabled()});
    p(out, "  Accent color   : 0x{X:0>6}\n", .{root.getAccentColor()});
    p(out, "  Shadow enabled : {}\n", .{theme.CompositorDefaults.shadow_enabled});
    p(out, "  Screen size    : {d}x{d}\n", .{ SCREEN_W, SCREEN_H });

    // ── Phase 4: Create Surfaces ──
    p(out, "\n--- Phase 4: Creating Surfaces ---\n", .{});

    const desktop_surface = compositor.createSurface(SCREEN_W, SCREEN_H, .{
        .has_alpha = false,
        .is_visible = true,
        .is_desktop = true,
    });
    compositor.setSurfaceZOrder(desktop_surface, compositor.DESKTOP_SURFACE_Z);
    p(out, "  Desktop surface   : id={d}\n", .{desktop_surface});

    const window_surface = compositor.createSurface(520, 380, .{
        .has_alpha = false,
        .is_visible = true,
        .is_opaque = true,
    });
    compositor.moveSurface(window_surface, 200, 80);
    compositor.setSurfaceZOrder(window_surface, 100);
    p(out, "  Window surface    : id={d} (flat opaque)\n", .{window_surface});

    const taskbar_surface = compositor.createSurface(SCREEN_W, 30, .{
        .has_alpha = false,
        .is_visible = true,
        .is_opaque = true,
    });
    compositor.moveSurface(taskbar_surface, 0, @intCast(SCREEN_H - 30));
    compositor.setSurfaceZOrder(taskbar_surface, 200);
    p(out, "  Taskbar surface   : id={d} (flat dark)\n", .{taskbar_surface});

    for (os_windows, 0..) |win, i| {
        taskbar.addTask(win.title, win.icon_id);
        p(out, "  OS Window [{d}]     : \"{s}\" (minimized to taskbar)\n", .{ i, win.title });
    }

    p(out, "  Total surfaces    : {d}\n", .{compositor.getSurfaceCount()});

    // ── Phase 5: Render Desktop Frame ──
    p(out, "\n--- Phase 5: Composition ---\n", .{});

    compositor.compose();
    const stats = compositor.getStats();

    p(out, "  Total frames      : {d}\n", .{stats.total_frames});
    p(out, "  Dirty frames      : {d}\n", .{stats.dirty_frames});
    p(out, "  Surfaces composited: {d}\n", .{stats.surfaces_composited});

    // ── Phase 6: Desktop Layout Report ──
    p(out, "\n--- Phase 6: Desktop Layout ---\n", .{});

    p(out, "  Wallpaper          : {s}\n", .{root.getWallpaperPath()});
    p(out, "  Desktop background : 0x{X:0>6}\n", .{root.getDesktopBackground()});
    p(out, "  Desktop icons      : {d}\n", .{desktop.getIconCount()});
    for (desktop.getIcons()) |icon| {
        if (icon.visible) {
            p(out, "    [{d},{d}] {s}\n", .{
                icon.grid_x, icon.grid_y, icon.name[0..icon.name_len],
            });
        }
    }

    p(out, "  Taskbar height     : {d}px\n", .{root.getTaskbarHeight()});
    p(out, "  Titlebar height    : {d}px\n", .{root.getTitlebarHeight()});
    p(out, "  Start screen       : visible={}\n", .{startmenu.isVisible()});

    // ── Phase 7: Theme Variants ──
    p(out, "\n--- Phase 7: Available Themes ({d}) ---\n", .{root.getAvailableThemeCount()});
    for (root.available_themes, 0..) |name, i| {
        const marker: []const u8 = if (i == 0) " [active]" else "";
        p(out, "  [{d}] {s}{s}\n", .{ i, name, marker });
    }

    // ── Phase 8: Metro Rendering Pipeline Summary ──
    p(out, "\n--- Metro Rendering Pipeline ---\n", .{});
    p(out, "  ┌─────────────────────────────────────────┐\n", .{});
    p(out, "  │ Application → Surface (off-screen buf)  │\n", .{});
    p(out, "  │         (each window has its own)       │\n", .{});
    p(out, "  ├─────────────────────────────────────────┤\n", .{});
    p(out, "  │ Basic Compositor reads all surfaces     │\n", .{});
    p(out, "  │   ├─ Sort by Z-order                    │\n", .{});
    p(out, "  │   ├─ Flat solid blit (no blur/glass)    │\n", .{});
    p(out, "  │   └─ No shadow, no transparency         │\n", .{});
    p(out, "  ├─────────────────────────────────────────┤\n", .{});
    p(out, "  │ VSync-aligned present → Front Buffer    │\n", .{});
    p(out, "  └─────────────────────────────────────────┘\n", .{});

    // ── Phase 9: Font Integration Summary ──
    p(out, "\n--- Font Integration (ZirconOSFonts) ---\n", .{});
    p(out, "  System UI    : {s} ({d}pt)\n", .{ font_loader.getSystemFontName(), theme.FONT_SYSTEM_SIZE });
    p(out, "  Terminal     : {s} ({d}pt)\n", .{ font_loader.getMonoFontName(), theme.FONT_MONO_SIZE });
    p(out, "  CJK Fallback : {s}\n", .{font_loader.getCjkFontName()});

    // ── Phase 10: Start Screen Tile Grid ──
    p(out, "\n--- Start Screen (Metro Tile Grid) ---\n", .{});
    const tiles = startmenu.getTiles();
    for (tiles, 0..) |tile, i| {
        p(out, "  Tile [{d}] {s} (color=0x{X:0>6})\n", .{
            i, tile.name[0..tile.name_len], tile.color,
        });
    }

    p(out, "\n═══ Modern Desktop Ready ═══\n", .{});
    p(out, "Metro compositor running with {d} surfaces, flat_design=true\n", .{
        compositor.getSurfaceCount(),
    });
    p(out, "OS windows minimized to taskbar: ", .{});
    for (os_windows, 0..) |win, i| {
        if (i > 0) p(out, ", ", .{});
        p(out, "{s}", .{win.title});
    }
    p(out, "\n", .{});

    out.flush() catch {};
}
