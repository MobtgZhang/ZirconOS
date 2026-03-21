//! DWM Compositor — Unified Desktop Window Manager Abstraction
//! Provides a common compositor interface with per-theme rendering backends:
//!   - Aero (NT 6.1):  D3D9-style redirected surface, Gaussian blur glass, specular highlights
//!   - Fluent (NT 6.3): DirectComposition visual tree, Acrylic material, Reveal highlight
//!   - SunValley (NT 6.4): WinUI 3 composition, Mica material, rounded SDF clipping, Snap Layout
//!
//! Architecture follows ReactOS win32ss/user/ntuser model: the compositor runs
//! in a privileged user-mode process (dwm.exe equivalent) and communicates with
//! the kernel display driver via IOCTL-based IRP dispatch.

const klog = @import("../../rtl/klog.zig");
const fb = @import("framebuffer.zig");
const material = @import("material.zig");

// ── Compositor Backend Selection ──

pub const CompositorBackend = enum(u8) {
    none = 0,
    aero_d3d9 = 1,
    fluent_dcomp = 2,
    sunvalley_winui = 3,
};

pub const CompositorState = enum(u8) {
    uninitialized = 0,
    initializing = 1,
    ready = 2,
    composing = 3,
    suspended = 4,
    error_state = 5,
};

// ── Redirected Surface (NT6 DWM core concept) ──
// Each window renders into its own off-screen surface. The compositor
// reads all surfaces and alpha-blends them by Z-order onto the final
// frame buffer (front buffer). This eliminates overdraw artifacts.

pub const RedirectedSurface = struct {
    id: u16 = 0,
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
    z_order: i16 = 0,
    opacity: u8 = 255,
    visible: bool = true,
    dirty: bool = true,
    owner_pid: u32 = 0,
    buffer_addr: usize = 0,
    buffer_pitch: u32 = 0,
    material_type: material.MaterialType = .opaque_solid,
    corner_radius: u8 = 0,
    shadow_size: u8 = 0,
    flags: SurfaceFlags = .{},
};

pub const SurfaceFlags = struct {
    topmost: bool = false,
    layered: bool = false,
    popup: bool = false,
    child: bool = false,
    has_caption: bool = true,
    dwm_blur_behind: bool = false,
    dwm_ncrendering: bool = true,
    snap_target: bool = false,
};

// ── Compositor Configuration ──

pub const AeroConfig = struct {
    glass_enabled: bool = true,
    glass_opacity: u8 = 180,
    blur_radius: u8 = 12,
    blur_passes: u8 = 3,
    saturation: u8 = 200,
    tint_color: u32 = 0x4068A0,
    tint_opacity: u8 = 60,
    specular_intensity: u8 = 35,
    shadow_layers: u8 = 4,
    shadow_offset: u8 = 8,
    peek_enabled: bool = true,
    flip3d_enabled: bool = true,
    animation_speed: u16 = 250,
};

pub const FluentConfig = struct {
    acrylic_enabled: bool = true,
    acrylic_blur_radius: u8 = 20,
    acrylic_blur_passes: u8 = 4,
    noise_opacity: u8 = 8,
    luminosity_blend: u8 = 140,
    tint_color: u32 = 0x202020,
    tint_opacity: u8 = 70,
    reveal_enabled: bool = true,
    reveal_radius: u16 = 100,
    reveal_opacity: u8 = 60,
    depth_shadow_layers: u8 = 5,
    depth_shadow_base: u8 = 12,
    virtual_desktops_max: u8 = 16,
    animation_spring_stiffness: u16 = 300,
    animation_damping: u16 = 20,
    mpo_enabled: bool = true,
};

pub const SunValleyConfig = struct {
    mica_enabled: bool = true,
    mica_blur_radius: u8 = 60,
    mica_opacity: u8 = 200,
    mica_luminosity: u8 = 160,
    mica_tint_color: u32 = 0x202020,
    acrylic2_enabled: bool = true,
    acrylic2_luminosity_blend: u8 = 160,
    corner_radius: u8 = 8,
    snap_layout_enabled: bool = true,
    snap_zones: u8 = 6,
    taskbar_centered: bool = true,
    widget_panel_enabled: bool = true,
    quick_settings_enabled: bool = true,
    drr_enabled: bool = true,
    drr_min_hz: u8 = 60,
    drr_max_hz: u8 = 120,
    auto_hdr: bool = false,
    shell_process_split: bool = true,
    animation_implicit: bool = true,
    sdf_antialias: bool = true,
};

pub const CompositorConfig = union {
    aero: AeroConfig,
    fluent: FluentConfig,
    sunvalley: SunValleyConfig,
};

// ── Compositor Instance ──

const MAX_SURFACES: usize = 128;

var backend: CompositorBackend = .none;
var state: CompositorState = .uninitialized;
var surfaces: [MAX_SURFACES]RedirectedSurface = [_]RedirectedSurface{.{}} ** MAX_SURFACES;
var surface_count: u16 = 0;
var frame_number: u64 = 0;
var vsync_enabled: bool = true;
var wallpaper_surface_id: u16 = 0;

var aero_cfg: AeroConfig = .{};
var fluent_cfg: FluentConfig = .{};
var sunvalley_cfg: SunValleyConfig = .{};

var cursor_surface_id: u16 = 0;
var compositor_initialized: bool = false;

// ── Initialization (ReactOS-style NT6 session init) ──

/// Initialize the compositor for the Aero backend.
/// Equivalent to ReactOS NtUserInitializeClientPfnArrays + DWM session creation.
/// The Aero compositor uses D3D9-style redirected surfaces where each window
/// paints into an independent GPU texture; the DWM reads all textures and
/// composites them with Gaussian blur glass, specular highlights, and shadows.
pub fn initAero(cfg: AeroConfig) void {
    if (compositor_initialized) return;
    backend = .aero_d3d9;
    aero_cfg = cfg;
    state = .initializing;

    material.init(.glass);
    material.configureGlass(.{
        .blur_radius = cfg.blur_radius,
        .blur_passes = cfg.blur_passes,
        .tint_color = cfg.tint_color,
        .tint_opacity = cfg.tint_opacity,
        .saturation = cfg.saturation,
        .specular_intensity = cfg.specular_intensity,
    });

    allocateDesktopSurface();
    allocateCursorSurface();

    state = .ready;
    compositor_initialized = true;
    klog.info("DWM: Aero compositor initialized (glass=%s, blur=%u, shadow=%u)", .{
        if (cfg.glass_enabled) "on" else "off",
        @as(u32, cfg.blur_radius),
        @as(u32, cfg.shadow_layers),
    });
}

/// Initialize the Fluent compositor backend.
/// Uses DirectComposition-style visual tree: each visual node owns a
/// CompositionSurface, CompositionBrush, and CompositionAnimation set.
/// Acrylic material pipelines run entirely on the GPU side.
pub fn initFluent(cfg: FluentConfig) void {
    if (compositor_initialized) return;
    backend = .fluent_dcomp;
    fluent_cfg = cfg;
    state = .initializing;

    material.init(.acrylic);
    material.configureAcrylic(.{
        .blur_radius = cfg.acrylic_blur_radius,
        .blur_passes = cfg.acrylic_blur_passes,
        .noise_opacity = cfg.noise_opacity,
        .luminosity_blend = cfg.luminosity_blend,
        .tint_color = cfg.tint_color,
        .tint_opacity = cfg.tint_opacity,
    });

    allocateDesktopSurface();
    allocateCursorSurface();

    state = .ready;
    compositor_initialized = true;
    klog.info("DWM: Fluent compositor initialized (acrylic=%s, reveal=%s, vdesktops=%u)", .{
        if (cfg.acrylic_enabled) "on" else "off",
        if (cfg.reveal_enabled) "on" else "off",
        @as(u32, cfg.virtual_desktops_max),
    });
}

/// Initialize the Sun Valley compositor backend.
/// Extends the Fluent visual tree with Mica material (wallpaper-sampled),
/// SDF-based rounded corner clipping, Snap Layout geometry, and Dynamic
/// Refresh Rate management.
pub fn initSunValley(cfg: SunValleyConfig) void {
    if (compositor_initialized) return;
    backend = .sunvalley_winui;
    sunvalley_cfg = cfg;
    state = .initializing;

    material.init(.mica);
    material.configureMica(.{
        .blur_radius = cfg.mica_blur_radius,
        .opacity = cfg.mica_opacity,
        .luminosity = cfg.mica_luminosity,
        .tint_color = cfg.mica_tint_color,
    });

    if (cfg.acrylic2_enabled) {
        material.configureAcrylic(.{
            .blur_radius = 20,
            .blur_passes = 4,
            .noise_opacity = 6,
            .luminosity_blend = cfg.acrylic2_luminosity_blend,
            .tint_color = cfg.mica_tint_color,
            .tint_opacity = 70,
        });
    }

    allocateDesktopSurface();
    allocateCursorSurface();

    state = .ready;
    compositor_initialized = true;
    klog.info("DWM: Sun Valley compositor initialized (mica=%s, corner_r=%u, snap=%s, drr=%s)", .{
        if (cfg.mica_enabled) "on" else "off",
        @as(u32, cfg.corner_radius),
        if (cfg.snap_layout_enabled) "on" else "off",
        if (cfg.drr_enabled) "on" else "off",
    });
}

// ── Surface Management ──

pub fn createSurface(x: i32, y: i32, width: u32, height: u32, owner_pid: u32) ?u16 {
    if (surface_count >= MAX_SURFACES) return null;
    const id = surface_count;
    surfaces[id] = .{
        .id = id,
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .z_order = @intCast(id),
        .owner_pid = owner_pid,
        .dirty = true,
    };

    if (backend == .sunvalley_winui) {
        surfaces[id].corner_radius = sunvalley_cfg.corner_radius;
        surfaces[id].shadow_size = 12;
    } else if (backend == .fluent_dcomp) {
        surfaces[id].shadow_size = fluent_cfg.depth_shadow_base;
    } else if (backend == .aero_d3d9) {
        surfaces[id].shadow_size = aero_cfg.shadow_offset;
    }

    surface_count += 1;
    return id;
}

pub fn destroySurface(id: u16) void {
    if (id >= surface_count) return;
    surfaces[id].visible = false;
    surfaces[id].owner_pid = 0;
}

pub fn moveSurface(id: u16, x: i32, y: i32) void {
    if (id >= surface_count) return;
    surfaces[id].x = x;
    surfaces[id].y = y;
    surfaces[id].dirty = true;
}

pub fn resizeSurface(id: u16, width: u32, height: u32) void {
    if (id >= surface_count) return;
    surfaces[id].width = width;
    surfaces[id].height = height;
    surfaces[id].dirty = true;
}

pub fn setSurfaceZOrder(id: u16, z: i16) void {
    if (id >= surface_count) return;
    surfaces[id].z_order = z;
}

pub fn setSurfaceMaterial(id: u16, mat: material.MaterialType) void {
    if (id >= surface_count) return;
    surfaces[id].material_type = mat;
}

pub fn setSurfaceOpacity(id: u16, opacity: u8) void {
    if (id >= surface_count) return;
    surfaces[id].opacity = opacity;
    surfaces[id].dirty = true;
}

pub fn markSurfaceDirty(id: u16) void {
    if (id >= surface_count) return;
    surfaces[id].dirty = true;
}

// ── Composition (per-backend) ──

/// Compose all visible surfaces onto the front buffer.
/// The algorithm differs by backend:
///   Aero:       Sort by Z-order → blur glass regions → alpha-blend → specular → shadow
///   Fluent:     Walk visual tree → apply effect graph per node → GPU-side animations
///   SunValley:  Walk visual tree → SDF round clip → Mica/Acrylic2 → Snap geometry
pub fn compose() void {
    if (state != .ready) return;
    state = .composing;

    switch (backend) {
        .aero_d3d9 => composeAero(),
        .fluent_dcomp => composeFluent(),
        .sunvalley_winui => composeSunValley(),
        .none => {},
    }

    frame_number += 1;
    state = .ready;
}

fn composeAero() void {
    var i: u16 = 0;
    while (i < surface_count) : (i += 1) {
        const s = &surfaces[i];
        if (!s.visible or !s.dirty) continue;

        if (s.shadow_size > 0 and aero_cfg.glass_enabled) {
            material.renderShadow(s.x, s.y, @intCast(s.width), @intCast(s.height), s.shadow_size, 4);
        }

        if (s.material_type == .glass and aero_cfg.glass_enabled) {
            material.renderGlass(s.x, s.y, @intCast(s.width), @intCast(s.height));
        }

        s.dirty = false;
    }
}

fn composeFluent() void {
    var i: u16 = 0;
    while (i < surface_count) : (i += 1) {
        const s = &surfaces[i];
        if (!s.visible or !s.dirty) continue;

        if (s.shadow_size > 0) {
            material.renderShadow(s.x, s.y, @intCast(s.width), @intCast(s.height), s.shadow_size, fluent_cfg.depth_shadow_layers);
        }

        switch (s.material_type) {
            .acrylic => material.renderAcrylic(s.x, s.y, @intCast(s.width), @intCast(s.height)),
            .glass => material.renderGlass(s.x, s.y, @intCast(s.width), @intCast(s.height)),
            else => {},
        }

        s.dirty = false;
    }
}

fn composeSunValley() void {
    var i: u16 = 0;
    while (i < surface_count) : (i += 1) {
        const s = &surfaces[i];
        if (!s.visible or !s.dirty) continue;

        if (s.shadow_size > 0) {
            material.renderShadow(s.x, s.y, @intCast(s.width), @intCast(s.height), s.shadow_size, 5);
        }

        if (s.corner_radius > 0 and sunvalley_cfg.sdf_antialias) {
            material.applyRoundedClip(s.x, s.y, @intCast(s.width), @intCast(s.height), s.corner_radius);
        }

        switch (s.material_type) {
            .mica => material.renderMica(s.x, s.y, @intCast(s.width), @intCast(s.height)),
            .acrylic => material.renderAcrylic(s.x, s.y, @intCast(s.width), @intCast(s.height)),
            .glass => material.renderGlass(s.x, s.y, @intCast(s.width), @intCast(s.height)),
            else => {},
        }

        s.dirty = false;
    }
}

// ── Reveal Highlight (Fluent-specific) ──

pub fn renderRevealHighlight(cx: i32, cy: i32) void {
    if (backend != .fluent_dcomp or !fluent_cfg.reveal_enabled) return;
    material.renderRevealHighlight(cx, cy, fluent_cfg.reveal_radius, fluent_cfg.reveal_opacity);
}

// ── Snap Layout (SunValley-specific) ──

pub const SnapZone = enum(u8) {
    left_half = 0,
    right_half = 1,
    top_left = 2,
    top_right = 3,
    bottom_left = 4,
    bottom_right = 5,
};

pub fn getSnapRect(zone: SnapZone, scr_w: i32, scr_h: i32, taskbar_h: i32) struct { x: i32, y: i32, w: i32, h: i32 } {
    const usable_h = scr_h - taskbar_h;
    const half_w = @divTrunc(scr_w, 2);
    const half_h = @divTrunc(usable_h, 2);
    return switch (zone) {
        .left_half => .{ .x = 0, .y = 0, .w = half_w, .h = usable_h },
        .right_half => .{ .x = half_w, .y = 0, .w = scr_w - half_w, .h = usable_h },
        .top_left => .{ .x = 0, .y = 0, .w = half_w, .h = half_h },
        .top_right => .{ .x = half_w, .y = 0, .w = scr_w - half_w, .h = half_h },
        .bottom_left => .{ .x = 0, .y = half_h, .w = half_w, .h = usable_h - half_h },
        .bottom_right => .{ .x = half_w, .y = half_h, .w = scr_w - half_w, .h = usable_h - half_h },
    };
}

pub fn snapSurface(id: u16, zone: SnapZone, scr_w: i32, scr_h: i32, taskbar_h: i32) void {
    if (backend != .sunvalley_winui or !sunvalley_cfg.snap_layout_enabled) return;
    if (id >= surface_count) return;
    const rect = getSnapRect(zone, scr_w, scr_h, taskbar_h);
    surfaces[id].x = rect.x;
    surfaces[id].y = rect.y;
    surfaces[id].width = @intCast(rect.w);
    surfaces[id].height = @intCast(rect.h);
    surfaces[id].flags.snap_target = true;
    surfaces[id].dirty = true;
}

// ── Internal Helpers ──

fn allocateDesktopSurface() void {
    _ = createSurface(0, 0, fb.getWidth(), fb.getHeight(), 0);
    wallpaper_surface_id = 0;
}

fn allocateCursorSurface() void {
    const id = createSurface(0, 0, 14, 20, 0);
    if (id) |cid| {
        cursor_surface_id = cid;
        surfaces[cid].z_order = 32767;
        surfaces[cid].flags.topmost = true;
        surfaces[cid].flags.has_caption = false;
    }
}

// ── Query ──

pub fn getBackend() CompositorBackend {
    return backend;
}

pub fn getState() CompositorState {
    return state;
}

pub fn getSurfaceCount() u16 {
    return surface_count;
}

pub fn getFrameNumber() u64 {
    return frame_number;
}

pub fn isInitialized() bool {
    return compositor_initialized;
}

pub fn getAeroConfig() *const AeroConfig {
    return &aero_cfg;
}

pub fn getFluentConfig() *const FluentConfig {
    return &fluent_cfg;
}

pub fn getSunValleyConfig() *const SunValleyConfig {
    return &sunvalley_cfg;
}
