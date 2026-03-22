//! Fluent UI Controls
//! Styled UI primitives: buttons, text boxes, checkboxes, toggles,
//! sliders, progress bars, and combo boxes. Implements reveal highlight
//! hover effect and Fluent motion states (rest, hover, pressed, disabled).

const theme = @import("theme.zig");

pub const ControlState = enum {
    rest,
    hover,
    pressed,
    disabled,
};

pub const Button = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 120,
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
                .rest => s.accent,
                .hover => s.accent_light,
                .pressed => s.accent_dark,
                .disabled => s.surface_variant,
            };
        }
        return switch (self.state) {
            .rest => s.surface,
            .hover => s.surface_variant,
            .pressed => s.divider,
            .disabled => s.surface_variant,
        };
    }

    pub fn getTextColor(self: *const Button) u32 {
        const s = theme.getScheme(self.color_scheme);
        if (self.is_accent) return theme.rgb(0xFF, 0xFF, 0xFF);
        return if (self.state == .disabled) s.text_secondary else s.text_primary;
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
    cursor_pos: u16 = 0,
    focused: bool = false,
    placeholder: [64]u8 = [_]u8{0} ** 64,
    placeholder_len: u8 = 0,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getBackgroundColor(self: *const TextBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        return s.surface;
    }

    pub fn getBorderColor(self: *const TextBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.focused) s.accent else s.divider;
    }

    pub fn getTextColor(self: *const TextBox) u32 {
        return theme.getScheme(self.color_scheme).text_primary;
    }

    pub fn getPlaceholderColor(self: *const TextBox) u32 {
        return theme.getScheme(self.color_scheme).text_secondary;
    }
};

pub const CheckBox = struct {
    x: i32 = 0,
    y: i32 = 0,
    checked: bool = false,
    state: ControlState = .rest,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getBoxColor(self: *const CheckBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        if (self.checked) return s.accent;
        return switch (self.state) {
            .rest => s.surface,
            .hover => s.surface_variant,
            .pressed => s.divider,
            .disabled => s.surface_variant,
        };
    }

    pub fn getBorderColor(self: *const CheckBox) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.checked) s.accent else s.divider;
    }
};

pub const ToggleSwitch = struct {
    x: i32 = 0,
    y: i32 = 0,
    on: bool = false,
    state: ControlState = .rest,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getTrackColor(self: *const ToggleSwitch) u32 {
        const s = theme.getScheme(self.color_scheme);
        return if (self.on) s.accent else s.surface_variant;
    }

    pub fn getThumbColor(self: *const ToggleSwitch) u32 {
        _ = self;
        return theme.rgb(0xFF, 0xFF, 0xFF);
    }
};

pub const Slider = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 200,
    value: u8 = 50,
    min_val: u8 = 0,
    max_val: u8 = 100,
    dragging: bool = false,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getFilledColor(self: *const Slider) u32 {
        return theme.getScheme(self.color_scheme).accent;
    }

    pub fn getTrackColor(self: *const Slider) u32 {
        return theme.getScheme(self.color_scheme).divider;
    }

    pub fn getThumbPosition(self: *const Slider) i32 {
        const range = @as(i32, self.max_val) - @as(i32, self.min_val);
        if (range == 0) return self.x;
        return self.x + (@as(i32, self.value) - @as(i32, self.min_val)) * self.width / range;
    }
};

pub const ProgressBar = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 200,
    height: i32 = 4,
    progress: u8 = 0,
    indeterminate: bool = false,
    color_scheme: theme.ColorScheme = .dark,

    pub fn getFilledColor(self: *const ProgressBar) u32 {
        return theme.getScheme(self.color_scheme).accent;
    }

    pub fn getTrackColor(self: *const ProgressBar) u32 {
        return theme.getScheme(self.color_scheme).surface_variant;
    }

    pub fn getFilledWidth(self: *const ProgressBar) i32 {
        return @divTrunc(self.width * @as(i32, self.progress), 100);
    }
};
