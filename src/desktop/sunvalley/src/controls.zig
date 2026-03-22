//! Sun Valley UI Controls
//! Rounded, layered UI primitives: pill buttons, rounded text fields,
//! toggle switches, sliders, progress rings, and info bars.
//! Supports light/dark mode and focus indicators.

const theme = @import("theme.zig");

pub const ControlState = enum {
    rest,
    hover,
    pressed,
    disabled,
    focused,
};

pub const Button = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 100,
    height: i32 = 32,
    label: [32]u8 = [_]u8{0} ** 32,
    label_len: u8 = 0,
    state: ControlState = .rest,
    is_accent: bool = false,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getBackgroundColor(self: *const Button) u32 {
        const s = theme.getScheme(self.color_scheme);
        if (self.is_accent) {
            return switch (self.state) {
                .rest, .focused => s.accent,
                .hover => s.accent_light,
                .pressed => s.accent_dark,
                .disabled => s.surface_variant,
            };
        }
        return switch (self.state) {
            .rest => s.surface_variant,
            .hover => s.card_bg,
            .pressed => s.layer_bg,
            .disabled => s.surface_variant,
            .focused => s.surface_variant,
        };
    }

    pub fn getTextColor(self: *const Button) u32 {
        const s = theme.getScheme(self.color_scheme);
        if (self.is_accent) return theme.rgb(0xFF, 0xFF, 0xFF);
        return if (self.state == .disabled) s.text_disabled else s.text_primary;
    }

    pub fn getBorderColor(self: *const Button) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.state == .focused) s.accent else s.surface_stroke;
    }

    pub fn contains(self: *const Button, px: i32, py: i32) bool {
        return px >= self.x and px < self.x + self.width and
            py >= self.y and py < self.y + self.height;
    }
};

pub const TextBox = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 200,
    height: i32 = 32,
    text: [256]u8 = [_]u8{0} ** 256,
    text_len: u16 = 0,
    placeholder: [64]u8 = [_]u8{0} ** 64,
    placeholder_len: u8 = 0,
    focused: bool = false,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getBackgroundColor(self: *const TextBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        return s.surface_variant;
    }

    pub fn getBorderColor(self: *const TextBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.focused) s.accent else s.surface_stroke;
    }

    pub fn getBottomAccent(self: *const TextBox) ?u32 {
        if (self.focused) {
            return theme.getScheme(self.color_scheme).accent;
        }
        return null;
    }
};

pub const ToggleSwitch = struct {
    x: i32 = 0,
    y: i32 = 0,
    on: bool = false,
    state: ControlState = .rest,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getTrackColor(self: *const ToggleSwitch) u32 {
        if (self.on) return theme.getScheme(self.color_scheme).accent;
        return theme.getScheme(self.color_scheme).surface_stroke;
    }

    pub fn getThumbColor(_: *const ToggleSwitch) u32 {
        return theme.rgb(0xFF, 0xFF, 0xFF);
    }

    pub fn getThumbX(self: *const ToggleSwitch) i32 {
        return if (self.on) self.x + 24 else self.x + 4;
    }
};

pub const Slider = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 200,
    value: u8 = 50,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getTrackColor(self: *const Slider) u32 {
        return theme.getScheme(self.color_scheme).surface_stroke;
    }

    pub fn getFillColor(self: *const Slider) u32 {
        return theme.getScheme(self.color_scheme).accent;
    }

    pub fn getThumbX(self: *const Slider) i32 {
        return self.x + @divTrunc(self.width * @as(i32, self.value), 100);
    }
};

pub const ProgressRing = struct {
    cx: i32 = 0,
    cy: i32 = 0,
    radius: i32 = 16,
    progress: u8 = 0,
    indeterminate: bool = false,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getColor(self: *const ProgressRing) u32 {
        return theme.getScheme(self.color_scheme).accent;
    }

    pub fn getTrackColor(self: *const ProgressRing) u32 {
        return theme.getScheme(self.color_scheme).surface_stroke;
    }

    pub fn getArcEnd(self: *const ProgressRing) u16 {
        return @as(u16, self.progress) * 360 / 100;
    }
};

pub const InfoBar = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 320,
    height: i32 = 48,
    severity: enum { info, success, warning, critical } = .info,
    message: [128]u8 = [_]u8{0} ** 128,
    message_len: u8 = 0,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getAccentColor(self: *const InfoBar) u32 {
        return switch (self.severity) {
            .info => theme.getScheme(self.color_scheme).accent,
            .success => theme.rgb(0x0F, 0x7B, 0x0F),
            .warning => theme.rgb(0x9D, 0x5D, 0x00),
            .critical => theme.rgb(0xC4, 0x2B, 0x1C),
        };
    }

    pub fn getBackgroundColor(self: *const InfoBar) u32 {
        return theme.getScheme(self.color_scheme).card_bg;
    }
};
