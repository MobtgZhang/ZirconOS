//! Modern UI Controls
//! Styled UI primitives with Metro flat aesthetic: sharp-edged buttons,
//! flat text fields, accent-colored toggles, and no 3D effects.

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
    width: i32 = 80,
    height: i32 = 28,
    label: [32]u8 = [_]u8{0} ** 32,
    label_len: u8 = 0,
    state: ControlState = .rest,
    is_default: bool = false,

    pub fn getBackgroundColor(self: *const Button) u32 {
        if (self.is_default) {
            return switch (self.state) {
                .rest => theme.scheme_blue.accent,
                .hover => theme.scheme_blue.accent_light,
                .pressed => theme.scheme_blue.accent_dark,
                .disabled => theme.button_shadow,
            };
        }
        return switch (self.state) {
            .rest => theme.button_face,
            .hover => theme.button_highlight,
            .pressed => theme.button_shadow,
            .disabled => theme.button_face,
        };
    }

    pub fn getTextColor(self: *const Button) u32 {
        if (self.is_default) return theme.rgb(0xFF, 0xFF, 0xFF);
        return if (self.state == .disabled)
            theme.rgb(0x80, 0x80, 0x80)
        else
            theme.rgb(0x00, 0x00, 0x00);
    }

    pub fn contains(self: *const Button, px: i32, py: i32) bool {
        return px >= self.x and px < self.x + self.width and
            py >= self.y and py < self.y + self.height;
    }
};

pub const TextBox = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 160,
    height: i32 = 26,
    text: [256]u8 = [_]u8{0} ** 256,
    text_len: u16 = 0,
    focused: bool = false,

    pub fn getBackgroundColor(_: *const TextBox) u32 {
        return theme.window_bg;
    }

    pub fn getBorderColor(self: *const TextBox) u32 {
        return if (self.focused) theme.selection_bg else theme.button_shadow;
    }
};

pub const CheckBox = struct {
    x: i32 = 0,
    y: i32 = 0,
    checked: bool = false,
    state: ControlState = .rest,

    pub fn getBoxColor(self: *const CheckBox) u32 {
        return if (self.checked) theme.selection_bg else theme.window_bg;
    }

    pub fn getBorderColor(self: *const CheckBox) u32 {
        return switch (self.state) {
            .rest => theme.button_shadow,
            .hover => theme.selection_bg,
            .pressed => theme.scheme_blue.accent_dark,
            .disabled => theme.button_shadow,
        };
    }
};

pub const ToggleSwitch = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 44,
    height: i32 = 20,
    on: bool = false,
    state: ControlState = .rest,

    pub fn getTrackColor(self: *const ToggleSwitch) u32 {
        return if (self.on) theme.selection_bg else theme.button_shadow;
    }

    pub fn getThumbColor(_: *const ToggleSwitch) u32 {
        return theme.rgb(0xFF, 0xFF, 0xFF);
    }

    pub fn getThumbX(self: *const ToggleSwitch) i32 {
        return if (self.on) self.x + self.width - self.height else self.x;
    }
};

pub const ProgressBar = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 200,
    height: i32 = 4,
    progress: u8 = 0,

    pub fn getFilledColor(_: *const ProgressBar) u32 {
        return theme.scheme_blue.accent;
    }

    pub fn getTrackColor(_: *const ProgressBar) u32 {
        return theme.button_face;
    }

    pub fn getFilledWidth(self: *const ProgressBar) i32 {
        return @divTrunc(self.width * @as(i32, self.progress), 100);
    }
};

pub const AppTile = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = theme.Layout.startscreen_tile_size,
    height: i32 = theme.Layout.startscreen_tile_size,
    color: u32 = theme.tile_blue,
    label: [32]u8 = [_]u8{0} ** 32,
    label_len: u8 = 0,
    icon_id: u16 = 0,
    state: ControlState = .rest,

    pub fn getBackgroundColor(self: *const AppTile) u32 {
        return switch (self.state) {
            .rest => self.color,
            .hover => theme.alphaBlend(theme.rgb(0xFF, 0xFF, 0xFF), self.color, 40),
            .pressed => theme.alphaBlend(theme.rgb(0x00, 0x00, 0x00), self.color, 40),
            .disabled => theme.button_shadow,
        };
    }

    pub fn contains(self: *const AppTile, px: i32, py: i32) bool {
        return px >= self.x and px < self.x + self.width and
            py >= self.y and py < self.y + self.height;
    }
};
