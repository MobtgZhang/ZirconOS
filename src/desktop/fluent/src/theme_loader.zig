//! Theme Loader — ZirconOS Fluent Desktop
//! Parses .theme configuration files and applies settings to the
//! runtime theme state. Theme files follow the INI-like format used
//! by the extracted Windows 10 themes in other/resources/Fluent/.
//!
//! The loader supports [DWM.Acrylic], [DWM.Reveal], [DWM.Shadow],
//! [Colors.Dark], [Colors.Light], and [Layout] sections.

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
    active_metadata.display_name_len = setStr(&active_metadata.display_name, "ZirconOS Fluent");
    active_metadata.theme_id_len = setStr(&active_metadata.theme_id, "fluent");
    active_metadata.color_scheme = .dark;
    active_metadata.compositor_backend_len = setStr(&active_metadata.compositor_backend, "DirectComposition_VisualTree");
    active_metadata.compatible_kernel_len = setStr(&active_metadata.compatible_kernel, "NT6.3");
}

/// Load a built-in theme by scheme.
/// In a full implementation this would read and parse the .theme file;
/// here we apply the known Zig-defined constants.
pub fn loadBuiltinTheme(cs: theme.ColorScheme) ThemeLoadResult {
    active_metadata.color_scheme = cs;

    const name = switch (cs) {
        .dark => "ZirconOS Fluent Dark",
        .light => "ZirconOS Fluent Light",
    };
    active_metadata.display_name_len = setStr(&active_metadata.display_name, name);

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
