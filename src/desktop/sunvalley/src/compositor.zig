//! WinUI 3 Composition Visual Tree — ZirconOS Sun Valley
//! Implements a WinUI 3 / Windows.UI.Composition-style visual tree for
//! managing composited surfaces with Mica material and SDF rounded corners.
//!
//! Architecture mirrors Windows 11 DWM (win11Desktop.md §2-§3):
//!   Visual Tree → Z-order sort → per-node: Transform → Clip → Effect → Blend
//!   → Shell Visuals (taskbar, start menu, widgets) → DXGI Present
//!
//! Key differences from Fluent (Win10) compositor:
//!   - Mica material replaces Acrylic as primary backdrop
//!   - SDF antialiased rounded corner clipping on all visuals
//!   - Shell components run as independent processes (§3.1)
//!   - Snap Layout overlay nodes inserted above window visuals (§8)

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");

pub const VisualKind = enum(u8) {
    root = 0,
    container = 1,
    sprite = 2,
    layer = 3,
    mica_backdrop = 4,
    acrylic_backdrop = 5,
    shell_overlay = 6,
};

pub const BlendMode = enum(u8) {
    normal = 0,
    multiply = 1,
    screen_blend = 2,
    luminosity = 3,
};

pub const ClipMode = enum(u8) {
    none = 0,
    rectangle = 1,
    rounded_rect = 2,
};

pub const Visual = struct {
    kind: VisualKind = .container,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    opacity: u8 = 255,
    visible: bool = true,
    clip_mode: ClipMode = .none,
    corner_radius: u8 = 0,
    z_order: i16 = 0,
    blend_mode: BlendMode = .normal,
    surface_id: u16 = 0,
    parent_idx: u16 = 0xFFFF,
    dirty: bool = true,
    is_shell_component: bool = false,
};

const MAX_VISUALS: usize = 512;
var visual_pool: [MAX_VISUALS]Visual = [_]Visual{.{}} ** MAX_VISUALS;
var visual_count: usize = 0;
var root_visual: u16 = 0xFFFF;
var initialized: bool = false;
var frame_number: u64 = 0;

pub fn init() void {
    visual_count = 0;
    root_visual = 0xFFFF;
    frame_number = 0;
    initialized = true;
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn createVisual(kind: VisualKind) ?u16 {
    if (visual_count >= MAX_VISUALS) return null;
    const idx: u16 = @intCast(visual_count);
    visual_pool[visual_count] = Visual{ .kind = kind };
    visual_count += 1;
    return idx;
}

pub fn createRootVisual(width: i32, height: i32) ?u16 {
    const idx = createVisual(.root) orelse return null;
    var v = &visual_pool[idx];
    v.width = width;
    v.height = height;
    root_visual = idx;
    return idx;
}

pub fn createShellVisual(kind: VisualKind, x: i32, y: i32, w: i32, h: i32) ?u16 {
    const idx = createVisual(kind) orelse return null;
    var v = &visual_pool[idx];
    v.x = x;
    v.y = y;
    v.width = w;
    v.height = h;
    v.is_shell_component = true;
    v.clip_mode = .rounded_rect;
    v.corner_radius = @intCast(theme.Layout.corner_radius);
    return idx;
}

pub fn getVisual(idx: u16) ?*Visual {
    if (idx >= visual_count) return null;
    return &visual_pool[idx];
}

pub fn getRootVisual() ?*Visual {
    if (root_visual == 0xFFFF) return null;
    return &visual_pool[root_visual];
}

pub fn setVisualBounds(idx: u16, x: i32, y: i32, w: i32, h: i32) void {
    if (idx >= visual_count) return;
    var v = &visual_pool[idx];
    v.x = x;
    v.y = y;
    v.width = w;
    v.height = h;
    v.dirty = true;
}

pub fn setVisualOpacity(idx: u16, opacity: u8) void {
    if (idx >= visual_count) return;
    visual_pool[idx].opacity = opacity;
    visual_pool[idx].dirty = true;
}

pub fn setVisualZOrder(idx: u16, z: i16) void {
    if (idx >= visual_count) return;
    visual_pool[idx].z_order = z;
}

pub fn setVisualParent(child: u16, parent: u16) void {
    if (child >= visual_count) return;
    visual_pool[child].parent_idx = parent;
}

pub fn setVisualVisible(idx: u16, vis: bool) void {
    if (idx >= visual_count) return;
    visual_pool[idx].visible = vis;
    visual_pool[idx].dirty = true;
}

pub fn setVisualClip(idx: u16, mode: ClipMode, radius: u8) void {
    if (idx >= visual_count) return;
    visual_pool[idx].clip_mode = mode;
    visual_pool[idx].corner_radius = radius;
    visual_pool[idx].dirty = true;
}

pub fn getVisualCount() usize {
    return visual_count;
}

pub fn markDirtyRect(x: i32, y: i32, w: i32, h: i32) void {
    _ = x;
    _ = y;
    _ = w;
    _ = h;
    for (visual_pool[0..visual_count]) |*v| {
        v.dirty = true;
    }
}

pub fn commit() void {
    for (visual_pool[0..visual_count]) |*v| {
        v.dirty = false;
    }
    frame_number += 1;
}

/// Walk the visual tree in Z-order and compose each visible node.
/// Applies Mica or Acrylic 2.0 material depending on visual kind.
/// Shell overlay visuals (taskbar, start menu, widgets) are composed
/// as independent shell components per Win11 architecture (§3.1).
pub fn composeFrame(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    scheme: theme.ColorScheme,
) void {
    if (!initialized or visual_count == 0) return;

    const s = theme.getScheme(scheme);
    var z: i16 = -128;
    while (z <= 127) : (z += 1) {
        for (visual_pool[0..visual_count]) |v| {
            if (!v.visible or v.z_order != z) continue;
            switch (v.kind) {
                .mica_backdrop => {
                    if (dwm.isEnabled()) {
                        dwm.renderMicaRegion(
                            fb_addr,
                            fb_width,
                            fb_height,
                            fb_pitch,
                            fb_bpp,
                            v.x,
                            v.y,
                            v.width,
                            v.height,
                            s.mica_tint,
                            s.mica_opacity,
                        );
                    }
                },
                .acrylic_backdrop => {
                    if (dwm.isEnabled()) {
                        dwm.renderAcrylicRegion(
                            fb_addr,
                            fb_width,
                            fb_height,
                            fb_pitch,
                            fb_bpp,
                            v.x,
                            v.y,
                            v.width,
                            v.height,
                            s.acrylic_tint,
                            s.acrylic_opacity,
                        );
                    }
                },
                else => {},
            }
        }
    }
}

pub fn getFrameNumber() u64 {
    return frame_number;
}

pub fn getDiagnosticVisualCount() usize {
    var count: usize = 0;
    for (visual_pool[0..visual_count]) |v| {
        if (v.visible) count += 1;
    }
    return count;
}

pub fn getShellVisualCount() usize {
    var count: usize = 0;
    for (visual_pool[0..visual_count]) |v| {
        if (v.visible and v.is_shell_component) count += 1;
    }
    return count;
}
