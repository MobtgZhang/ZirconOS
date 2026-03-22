//! Font Loader — ZirconOS Fluent Desktop
//! Manages font resources for the Fluent desktop shell, integrating with
//! Font files under src/fonts/ provide a complete
//! font registry for text rendering.
//!
//! Font families loaded:
//!   Western:  NotoSans, NotoSansMono, NotoSerif, SourceCodePro, SourceSansPro,
//!             DejaVu, Lato, Inconsolata, LibertinusSerif, STIX, EmbedSerif, RobotizationMono
//!   CJK:     NotoSansCJK-SC, NotoSerifCJK-SC, LXGWWenKai, ZhuQueFangSong
//!
//! The font search path is: src/fonts/{western,cjk}/
//! In kernel mode, text is rendered from embedded bitmap glyphs; this module
//! supplies the logical font selection and fallback chain.

pub const FontWeight = enum(u16) {
    thin = 100,
    extra_light = 200,
    light = 300,
    regular = 400,
    medium = 500,
    semi_bold = 600,
    bold = 700,
    extra_bold = 800,
    black = 900,
};

pub const FontStyle = enum(u8) {
    normal = 0,
    italic = 1,
    oblique = 2,
};

pub const FontCategory = enum(u8) {
    sans_serif = 0,
    serif = 1,
    monospace = 2,
    cjk = 3,
    symbol = 4,
};

pub const FontFamily = struct {
    name: [48]u8 = [_]u8{0} ** 48,
    name_len: u8 = 0,
    path: [96]u8 = [_]u8{0} ** 96,
    path_len: u8 = 0,
    em_size: u16 = 2048,
    ascent: i16 = 1800,
    descent: i16 = -500,
    line_gap: i16 = 0,
    cap_height: i16 = 1400,
    x_height: i16 = 1000,
    is_monospace: bool = false,
    available: bool = false,
    category: FontCategory = .sans_serif,
    weight: FontWeight = .regular,
    style: FontStyle = .normal,
};

const MAX_FONTS: usize = 48;
var font_registry: [MAX_FONTS]FontFamily = [_]FontFamily{.{}} ** MAX_FONTS;
var font_count: usize = 0;
var default_font: usize = 0;
var monospace_font: usize = 0;
var serif_font: usize = 0;
var cjk_font: usize = 0;
var initialized: bool = false;

const FONT_BASE_PATH = "src/fonts";

fn setName(dest: *[48]u8, src: []const u8) u8 {
    const len = @min(src.len, 48);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn setPath(dest: *[96]u8, src: []const u8) u8 {
    const len = @min(src.len, 96);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addFont(name: []const u8, path: []const u8, cat: FontCategory, mono: bool) void {
    if (font_count >= MAX_FONTS) return;
    var f = &font_registry[font_count];
    f.name_len = setName(&f.name, name);
    f.path_len = setPath(&f.path, path);
    f.is_monospace = mono;
    f.category = cat;
    f.available = true;
    font_count += 1;
}

fn addFontFull(name: []const u8, path: []const u8, cat: FontCategory, mono: bool, wt: FontWeight, sty: FontStyle) void {
    if (font_count >= MAX_FONTS) return;
    var f = &font_registry[font_count];
    f.name_len = setName(&f.name, name);
    f.path_len = setPath(&f.path, path);
    f.is_monospace = mono;
    f.category = cat;
    f.weight = wt;
    f.style = sty;
    f.available = true;
    font_count += 1;
}

pub fn init() void {
    if (initialized) return;
    font_count = 0;

    registerWesternFonts();
    registerCjkFonts();
    registerSystemAliases();

    default_font = 0;
    resolveDefaultIndices();
    initialized = true;
}

fn registerWesternFonts() void {
    addFont("Noto Sans", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false);
    addFontFull("Noto Sans Bold", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false, .bold, .normal);
    addFontFull("Noto Sans Italic", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false, .regular, .italic);
    addFont("Noto Sans Mono", FONT_BASE_PATH ++ "/western/NotoSansMono", .monospace, true);
    addFont("Noto Serif", FONT_BASE_PATH ++ "/western/NotoSerif", .serif, false);
    addFont("Source Code Pro", FONT_BASE_PATH ++ "/western/SourceCodePro", .monospace, true);
    addFontFull("Source Code Pro Bold", FONT_BASE_PATH ++ "/western/SourceCodePro", .monospace, true, .bold, .normal);
    addFont("Source Sans Pro", FONT_BASE_PATH ++ "/western/SourceSansPro", .sans_serif, false);
    addFont("DejaVu Sans", FONT_BASE_PATH ++ "/western/DejaVu", .sans_serif, false);
    addFont("DejaVu Sans Mono", FONT_BASE_PATH ++ "/western/DejaVu", .monospace, true);
    addFont("DejaVu Serif", FONT_BASE_PATH ++ "/western/DejaVu", .serif, false);
    addFont("Lato", FONT_BASE_PATH ++ "/western/Lato", .sans_serif, false);
    addFont("Inconsolata", FONT_BASE_PATH ++ "/western/Inconsolata", .monospace, true);
    addFont("Libertinus Serif", FONT_BASE_PATH ++ "/western/LibertinusSerif", .serif, false);
    addFont("STIX Two Math", FONT_BASE_PATH ++ "/western/STIX", .symbol, false);
    addFont("Embed Serif", FONT_BASE_PATH ++ "/western/EmbedSerif", .serif, false);
    addFont("Robotization Mono", FONT_BASE_PATH ++ "/western/RobotizationMono", .monospace, true);
}

fn registerCjkFonts() void {
    addFont("Noto Sans CJK SC", FONT_BASE_PATH ++ "/cjk/NotoSansCJK-SC", .cjk, false);
    addFont("Noto Serif CJK SC", FONT_BASE_PATH ++ "/cjk/NotoSerifCJK-SC", .cjk, false);
    addFont("LXGW WenKai", FONT_BASE_PATH ++ "/cjk/LXGWWenKai", .cjk, false);
    addFont("ZhuQue FangSong", FONT_BASE_PATH ++ "/cjk/ZhuQueFangSong", .cjk, false);
}

fn registerSystemAliases() void {
    addFont("ZirconOS Sans", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false);
    addFontFull("ZirconOS Sans Light", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false, .light, .normal);
    addFontFull("ZirconOS Sans Bold", FONT_BASE_PATH ++ "/western/NotoSans", .sans_serif, false, .bold, .normal);
    addFont("ZirconOS Mono", FONT_BASE_PATH ++ "/western/SourceCodePro", .monospace, true);
    addFont("ZirconOS Serif", FONT_BASE_PATH ++ "/western/NotoSerif", .serif, false);
    addFont("ZirconOS CJK", FONT_BASE_PATH ++ "/cjk/NotoSansCJK-SC", .cjk, false);
}

fn resolveDefaultIndices() void {
    for (font_registry[0..font_count], 0..) |f, i| {
        const name = f.name[0..f.name_len];
        if (nameEq(name, "Noto Sans") and f.weight == .regular and f.style == .normal) {
            default_font = i;
        }
        if (nameEq(name, "Source Code Pro") and f.weight == .regular) {
            monospace_font = i;
        }
        if (nameEq(name, "Noto Serif") and f.weight == .regular) {
            serif_font = i;
        }
        if (nameEq(name, "Noto Sans CJK SC")) {
            cjk_font = i;
        }
    }
}

fn nameEq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, 0..) |c, i| {
        if (c != b[i]) return false;
    }
    return true;
}

pub fn isInitialized() bool {
    return initialized;
}

pub fn getDefaultFont() *const FontFamily {
    return &font_registry[default_font];
}

pub fn getMonospaceFont() *const FontFamily {
    return &font_registry[monospace_font];
}

pub fn getSerifFont() *const FontFamily {
    return &font_registry[serif_font];
}

pub fn getCjkFont() *const FontFamily {
    return &font_registry[cjk_font];
}

pub fn getFontCount() usize {
    return font_count;
}

pub fn getFontByIndex(idx: usize) ?*const FontFamily {
    if (idx >= font_count) return null;
    return &font_registry[idx];
}

pub fn findFontByName(name: []const u8) ?*const FontFamily {
    for (font_registry[0..font_count]) |*f| {
        const stored = f.name[0..f.name_len];
        if (nameEq(stored, name)) return f;
    }
    return null;
}

pub fn findFontsByCategory(cat: FontCategory) struct { start: usize, count: usize } {
    var start: usize = 0;
    var count: usize = 0;
    var found_first = false;
    for (font_registry[0..font_count], 0..) |f, i| {
        if (f.category == cat) {
            if (!found_first) {
                start = i;
                found_first = true;
            }
            count += 1;
        }
    }
    return .{ .start = start, .count = count };
}

pub fn getLineHeight(font_size_px: u16) u16 {
    const f = &font_registry[default_font];
    const total_units: u32 = @intCast(@as(i32, f.ascent) - @as(i32, f.descent) + @as(i32, f.line_gap));
    return @intCast((@as(u32, font_size_px) * total_units) / f.em_size);
}

pub fn getFontSearchPath() []const u8 {
    return FONT_BASE_PATH;
}
