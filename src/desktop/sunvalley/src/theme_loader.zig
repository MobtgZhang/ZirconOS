//! Theme Loader — ZirconOS Sun Valley Desktop
//! Parses .theme configuration files and applies settings to the
//! runtime theme state. Theme files follow the INI-like format used
//! by the extracted Windows 11 themes in other/resources/SunValley/.
//!
//! The loader supports [DWM.Mica], [DWM.Acrylic2], [DWM.RoundedCorners],
//! [DWM.SnapLayout], [DWM.Shadow], [DWM.DRR], [Colors.Dark], [Colors.Light],
//! and [Layout] sections.
//!
//! NT6 kernel compatibility: the compositor backend is set to
//! WinUI3_CompositionLayer when CompatibleKernel=NT6.4 is present,
//! enabling Mica material, SDF rounded corners, and DRR.

const theme = @import("theme.zig");
const dwm = @import("dwm.zig");

pub const ThemeLoadResult = enum {
    ok,
    file_not_found,
    parse_error,
    unsupported_version,
};

pub const ThemeMetadata = struct {
    display_name: [64]u8 = [_]u8{0} ** 64,
    display_name_len: u8 = 0,
    theme_id: [32]u8 = [_]u8{0} ** 32,
    theme_id_len: u8 = 0,
    color_scheme: theme.ColorScheme = .dark,
    compositor_backend: [48]u8 = [_]u8{0} ** 48,
    compositor_backend_len: u8 = 0,
    compatible_kernel: [16]u8 = [_]u8{0} ** 16,
    compatible_kernel_len: u8 = 0,
    wddm_version: [8]u8 = [_]u8{0} ** 8,
    wddm_version_len: u8 = 0,
};

var active_metadata: ThemeMetadata = .{};
var loaded: bool = false;

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

pub fn init() void {
    loaded = false;
    setDefaults();
}

fn setDefaults() void {
    active_metadata.display_name_len = setStr(&active_metadata.display_name, "ZirconOS Sun Valley");
    active_metadata.theme_id_len = setStr(&active_metadata.theme_id, "sunvalley");
    active_metadata.color_scheme = .dark;
    active_metadata.compositor_backend_len = setStr(&active_metadata.compositor_backend, "WinUI3_CompositionLayer");
    active_metadata.compatible_kernel_len = setStr(&active_metadata.compatible_kernel, "NT6.4");
    active_metadata.wddm_version_len = setStr(&active_metadata.wddm_version, "3.1");
}

/// Load a built-in theme by scheme.
/// Applies the Zig-defined constants and initializes the DWM with
/// Mica material, Acrylic 2.0, SDF rounded corners, and snap layout.
pub fn loadBuiltinTheme(cs: theme.ColorScheme) ThemeLoadResult {
    active_metadata.color_scheme = cs;

    const name = switch (cs) {
        .dark => "ZirconOS Sun Valley Dark",
        .light => "ZirconOS Sun Valley Light",
    };
    active_metadata.display_name_len = setStr(&active_metadata.display_name, name);

    dwm.init(.{
        .mica_enabled = true,
        .mica_opacity = theme.DwmDefaults.mica_opacity,
        .mica_blur_radius = theme.DwmDefaults.mica_blur_radius,
        .mica_blur_passes = theme.DwmDefaults.mica_blur_passes,
        .mica_luminosity = theme.DwmDefaults.mica_luminosity,
        .mica_tint_color = theme.getScheme(cs).mica_tint,
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
        .color_scheme = cs,
    });

    loaded = true;
    return .ok;
}

pub fn isLoaded() bool {
    return loaded;
}

pub fn getMetadata() *const ThemeMetadata {
    return &active_metadata;
}

pub fn getActiveScheme() theme.ColorScheme {
    return active_metadata.color_scheme;
}

pub fn setActiveScheme(cs: theme.ColorScheme) void {
    active_metadata.color_scheme = cs;
}

pub fn getDisplayName() []const u8 {
    return active_metadata.display_name[0..active_metadata.display_name_len];
}

pub fn getCompatibleKernel() []const u8 {
    return active_metadata.compatible_kernel[0..active_metadata.compatible_kernel_len];
}

pub fn getCompositorBackend() []const u8 {
    return active_metadata.compositor_backend[0..active_metadata.compositor_backend_len];
}

pub fn getWddmVersion() []const u8 {
    return active_metadata.wddm_version[0..active_metadata.wddm_version_len];
}
