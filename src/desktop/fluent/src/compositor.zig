//! DirectComposition Visual Tree Compositor — ZirconOS Fluent
//! Implements a simplified DirectComposition-style visual tree for
//! managing composited surfaces. Each visual node represents a
//! screen region with properties: transform, opacity, clip, effect.
//!
//! The compositor walks the tree in Z-order and produces the final
//! composited frame by applying Acrylic, Reveal, and shadow effects
//! through the DWM pipeline.
//!
//! Architecture mirrors Windows 10 DWM:
//!   Visual Tree → Z-order sort → per-node: Transform → Clip → Effect → Blend
//!   → DXGI Present

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");

pub const VisualKind = enum(u8) {
    root = 0,
    container = 1,
    sprite = 2,
    layer = 3,
    backdrop = 4,
};

pub const BlendMode = enum(u8) {
    normal = 0,
    multiply = 1,
    screen_blend = 2,
    overlay = 3,
};

pub const Visual = struct {
    kind: VisualKind = .container,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    opacity: u8 = 255,
    visible: bool = true,
    clip_enabled: bool = false,
    z_order: i16 = 0,
    blend_mode: BlendMode = .normal,
    surface_id: u16 = 0,
    parent_idx: u16 = 0xFFFF,
    dirty: bool = true,
};

const MAX_VISUALS: usize = 256;
var visual_pool: [MAX_VISUALS]Visual = [_]Visual{.{}} ** MAX_VISUALS;
var visual_count: usize = 0;
var root_visual: u16 = 0xFFFF;
var initialized: bool = false;

pub fn init() void {
    visual_count = 0;
    root_visual = 0xFFFF;
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

pub fn getVisualCount() usize {
    return visual_count;
}

/// Marks a rectangular damage region that needs recomposition.
pub fn markDirtyRect(x: i32, y: i32, w: i32, h: i32) void {
    _ = x;
    _ = y;
    _ = w;
    _ = h;
    for (visual_pool[0..visual_count]) |*v| {
        v.dirty = true;
    }
}

/// Commit pending visual tree changes for next frame composition.
pub fn commit() void {
    for (visual_pool[0..visual_count]) |*v| {
        v.dirty = false;
    }
}

/// Walk the visual tree in Z-order and compose each visible node.
/// In real implementation this would call into the DWM render pipeline;
/// here we provide the traversal skeleton and apply Acrylic where needed.
pub fn composeFrame(
    fb_addr: usize,
    fb_width: u32,
    fb_height: u32,
    fb_pitch: u32,
    fb_bpp: u8,
    scheme: theme.ColorScheme,
) void {
    if (!initialized or visual_count == 0) return;

    const tint = theme.getScheme(scheme).acrylic_tint;
    const opacity = theme.getScheme(scheme).acrylic_opacity;

    var z: i16 = -128;
    while (z <= 127) : (z += 1) {
        for (visual_pool[0..visual_count]) |v| {
            if (!v.visible or v.z_order != z) continue;
            if (v.kind == .backdrop and dwm.isEnabled()) {
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
                    tint,
                    opacity,
                );
            }
        }
    }
}

/// Report total committed visual node count (for diagnostics).
pub fn getDiagnosticVisualCount() usize {
    var count: usize = 0;
    for (visual_pool[0..visual_count]) |v| {
        if (v.visible) count += 1;
    }
    return count;
}
