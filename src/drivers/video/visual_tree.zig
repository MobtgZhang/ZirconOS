//! Visual Tree Composition Engine
//! Implements the DirectComposition / Windows.UI.Composition visual tree model
//! used by Win10 Fluent and Win11 Sun Valley desktops.
//!
//! Architecture (mirrors the real Windows composition stack):
//!
//!   ┌─ Visual Tree ─────────────────────────────────────────┐
//!   │  RootVisual                                           │
//!   │   ├── DesktopVisual (wallpaper layer)                 │
//!   │   ├── WindowVisual[] (per-window, Z-ordered)          │
//!   │   │    ├── TitlebarVisual (Mica/Acrylic brush)        │
//!   │   │    ├── ContentVisual (app surface)                │
//!   │   │    └── ShadowVisual (drop shadow layer)           │
//!   │   ├── ShellVisual                                     │
//!   │   │    ├── TaskbarVisual                              │
//!   │   │    ├── StartMenuVisual                            │
//!   │   │    ├── ActionCenterVisual (Fluent)                │
//!   │   │    ├── WidgetPanelVisual (SunValley)              │
//!   │   │    └── QuickSettingsVisual (SunValley)            │
//!   │   └── CursorVisual (topmost)                          │
//!   └───────────────────────────────────────────────────────┘
//!
//! The tree is traversed depth-first in Z-order during composition.
//! Each node carries a CompositionBrush (solid, surface, or effect)
//! and an optional CompositionAnimation.

const fb = @import("framebuffer.zig");
const material = @import("material.zig");

// ── Visual Node Types ──

pub const VisualType = enum(u8) {
    container = 0,
    sprite = 1,
    layer = 2,
    shape = 3,
    shadow = 4,
};

pub const BrushType = enum(u8) {
    none = 0,
    color = 1,
    surface = 2,
    effect_glass = 3,
    effect_acrylic = 4,
    effect_mica = 5,
    effect_acrylic2 = 6,
    gradient_linear = 7,
    gradient_radial = 8,
};

pub const AnimationType = enum(u8) {
    none = 0,
    keyframe_linear = 1,
    keyframe_cubic = 2,
    expression = 3,
    spring = 4,
    implicit_fade = 5,
    implicit_offset = 6,
};

// ── Visual Node ──

pub const Visual = struct {
    id: u16 = 0,
    parent_id: u16 = 0xFFFF,
    visual_type: VisualType = .container,
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
    z_order: i16 = 0,
    opacity: u8 = 255,
    visible: bool = true,
    brush: BrushType = .none,
    brush_color: u32 = 0,
    animation: AnimationType = .none,
    animation_progress: u16 = 0,
    corner_radius: u8 = 0,
    clip_to_bounds: bool = false,
    is_dirty: bool = true,
    child_count: u8 = 0,
    first_child_id: u16 = 0xFFFF,
    next_sibling_id: u16 = 0xFFFF,

    /// Tag for semantic identification in the visual tree
    tag: VisualTag = .generic,
};

pub const VisualTag = enum(u8) {
    generic = 0,
    root = 1,
    desktop_wallpaper = 2,
    window_frame = 3,
    window_titlebar = 4,
    window_content = 5,
    window_shadow = 6,
    taskbar = 7,
    start_menu = 8,
    action_center = 9,
    widget_panel = 10,
    quick_settings = 11,
    notification = 12,
    cursor = 13,
    snap_overlay = 14,
    context_menu = 15,
};

// ── Visual Tree State ──

const MAX_VISUALS: usize = 512;

var visuals: [MAX_VISUALS]Visual = [_]Visual{.{}} ** MAX_VISUALS;
var visual_count: u16 = 0;
var root_visual_id: u16 = 0xFFFF;
var tree_initialized: bool = false;
var composition_frame: u64 = 0;

// ── Tree Construction ──

pub fn init() void {
    visual_count = 0;
    root_visual_id = 0xFFFF;
    tree_initialized = false;
}

pub fn createTree() void {
    if (tree_initialized) return;

    const root_id = createVisual(.{
        .visual_type = .container,
        .width = fb.getWidth(),
        .height = fb.getHeight(),
        .tag = .root,
    });

    if (root_id) |rid| {
        root_visual_id = rid;
        tree_initialized = true;
    }
}

pub fn createVisual(template: Visual) ?u16 {
    if (visual_count >= MAX_VISUALS) return null;
    const id = visual_count;
    visuals[id] = template;
    visuals[id].id = id;
    visual_count += 1;
    return id;
}

pub fn addChild(parent_id: u16, child_id: u16) void {
    if (parent_id >= visual_count or child_id >= visual_count) return;
    visuals[child_id].parent_id = parent_id;

    if (visuals[parent_id].first_child_id == 0xFFFF) {
        visuals[parent_id].first_child_id = child_id;
    } else {
        var current = visuals[parent_id].first_child_id;
        while (visuals[current].next_sibling_id != 0xFFFF) {
            current = visuals[current].next_sibling_id;
        }
        visuals[current].next_sibling_id = child_id;
    }
    visuals[parent_id].child_count += 1;
}

pub fn removeVisual(id: u16) void {
    if (id >= visual_count) return;
    visuals[id].visible = false;
    visuals[id].parent_id = 0xFFFF;
}

// ── Visual Property Setters ──

pub fn setPosition(id: u16, x: i32, y: i32) void {
    if (id >= visual_count) return;
    visuals[id].x = x;
    visuals[id].y = y;
    visuals[id].is_dirty = true;
}

pub fn setSize(id: u16, w: u32, h: u32) void {
    if (id >= visual_count) return;
    visuals[id].width = w;
    visuals[id].height = h;
    visuals[id].is_dirty = true;
}

pub fn setOpacity(id: u16, opacity: u8) void {
    if (id >= visual_count) return;
    visuals[id].opacity = opacity;
    visuals[id].is_dirty = true;
}

pub fn setBrush(id: u16, brush: BrushType, color: u32) void {
    if (id >= visual_count) return;
    visuals[id].brush = brush;
    visuals[id].brush_color = color;
    visuals[id].is_dirty = true;
}

pub fn setAnimation(id: u16, anim: AnimationType) void {
    if (id >= visual_count) return;
    visuals[id].animation = anim;
    visuals[id].animation_progress = 0;
}

pub fn setCornerRadius(id: u16, radius: u8) void {
    if (id >= visual_count) return;
    visuals[id].corner_radius = radius;
    visuals[id].is_dirty = true;
}

// ── Composition Traversal ──

/// Traverse the visual tree depth-first and render each visible node.
/// Material brushes are applied per-node based on brush type.
pub fn compose() void {
    if (!tree_initialized or root_visual_id == 0xFFFF) return;
    composeVisual(root_visual_id, 0, 0);
    composition_frame += 1;
}

fn composeVisual(id: u16, parent_x: i32, parent_y: i32) void {
    if (id >= visual_count) return;
    const v = &visuals[id];
    if (!v.visible) return;

    const abs_x = parent_x + v.x;
    const abs_y = parent_y + v.y;
    const w: i32 = @intCast(v.width);
    const h: i32 = @intCast(v.height);

    switch (v.brush) {
        .color => {
            if (v.opacity == 255) {
                fb.fillRect(abs_x, abs_y, w, h, v.brush_color);
            } else {
                fb.blendTintRect(abs_x, abs_y, w, h, v.brush_color, v.opacity, 255);
            }
        },
        .effect_glass => material.renderGlass(abs_x, abs_y, w, h),
        .effect_acrylic => material.renderAcrylic(abs_x, abs_y, w, h),
        .effect_mica => material.renderMica(abs_x, abs_y, w, h),
        .effect_acrylic2 => material.renderAcrylic2(abs_x, abs_y, w, h),
        else => {},
    }

    if (v.corner_radius > 0) {
        material.applyRoundedClip(abs_x, abs_y, w, h, v.corner_radius);
    }

    if (v.first_child_id != 0xFFFF) {
        var child_id = v.first_child_id;
        while (child_id != 0xFFFF and child_id < visual_count) {
            composeVisual(child_id, abs_x, abs_y);
            child_id = visuals[child_id].next_sibling_id;
        }
    }

    v.is_dirty = false;
}

// ── Shell Visual Helpers ──

/// Create a complete window visual subtree:
///   WindowFrame (container)
///     ├── Shadow (shadow visual)
///     ├── Titlebar (sprite with material brush)
///     └── Content (sprite with surface brush)
pub fn createWindowVisual(x: i32, y: i32, w: u32, h: u32, titlebar_h: u32, mat: BrushType, corner_r: u8) ?u16 {
    const frame = createVisual(.{
        .visual_type = .container,
        .x = x,
        .y = y,
        .width = w,
        .height = h,
        .tag = .window_frame,
        .corner_radius = corner_r,
        .clip_to_bounds = true,
    }) orelse return null;

    const shadow = createVisual(.{
        .visual_type = .shadow,
        .x = 0,
        .y = 0,
        .width = w,
        .height = h,
        .tag = .window_shadow,
        .opacity = 40,
    }) orelse return frame;
    addChild(frame, shadow);

    const titlebar = createVisual(.{
        .visual_type = .sprite,
        .x = 0,
        .y = 0,
        .width = w,
        .height = titlebar_h,
        .brush = mat,
        .tag = .window_titlebar,
    }) orelse return frame;
    addChild(frame, titlebar);

    const content = createVisual(.{
        .visual_type = .sprite,
        .x = 0,
        .y = @intCast(titlebar_h),
        .width = w,
        .height = h - titlebar_h,
        .brush = .color,
        .brush_color = 0x00FFFFFF,
        .tag = .window_content,
    }) orelse return frame;
    addChild(frame, content);

    if (root_visual_id != 0xFFFF) {
        addChild(root_visual_id, frame);
    }

    return frame;
}

pub fn createTaskbarVisual(scr_w: u32, scr_h: u32, h: u32, mat: BrushType, color: u32) ?u16 {
    const tb = createVisual(.{
        .visual_type = .layer,
        .x = 0,
        .y = @intCast(scr_h - h),
        .width = scr_w,
        .height = h,
        .brush = mat,
        .brush_color = color,
        .tag = .taskbar,
    }) orelse return null;

    if (root_visual_id != 0xFFFF) {
        addChild(root_visual_id, tb);
    }

    return tb;
}

pub fn createStartMenuVisual(x: i32, y: i32, w: u32, h: u32, mat: BrushType, color: u32, corner_r: u8) ?u16 {
    const sm = createVisual(.{
        .visual_type = .layer,
        .x = x,
        .y = y,
        .width = w,
        .height = h,
        .brush = mat,
        .brush_color = color,
        .tag = .start_menu,
        .corner_radius = corner_r,
        .visible = false,
    }) orelse return null;

    if (root_visual_id != 0xFFFF) {
        addChild(root_visual_id, sm);
    }

    return sm;
}

// ── Query ──

pub fn getVisual(id: u16) ?*Visual {
    if (id >= visual_count) return null;
    return &visuals[id];
}

pub fn getVisualCount() u16 {
    return visual_count;
}

pub fn getRootId() u16 {
    return root_visual_id;
}

pub fn isTreeInitialized() bool {
    return tree_initialized;
}

pub fn getCompositionFrame() u64 {
    return composition_frame;
}

/// Find the first visual matching the given tag.
pub fn findByTag(tag: VisualTag) ?u16 {
    var i: u16 = 0;
    while (i < visual_count) : (i += 1) {
        if (visuals[i].tag == tag and visuals[i].visible) return i;
    }
    return null;
}
