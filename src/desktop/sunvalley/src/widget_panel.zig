//! Sun Valley Widget Panel
//! Side panel with customizable info cards: weather, calendar,
//! news headlines, and system stats. Features Acrylic backdrop
//! and rounded card layout.

const theme = @import("theme.zig");

pub const WidgetCard = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    widget_type: WidgetType = .info,
    width_units: u8 = 1,
    height_units: u8 = 1,
    enabled: bool = true,
};

pub const WidgetType = enum {
    weather,
    calendar,
    headlines,
    system_stats,
    clock,
    notes,
    info,
};

const MAX_WIDGETS: usize = 12;
var widgets: [MAX_WIDGETS]WidgetCard = [_]WidgetCard{.{}} ** MAX_WIDGETS;
var widget_count: usize = 0;
var visible: bool = false;

pub fn init() void {
    widget_count = 0;
    visible = false;
    addDefaultWidgets();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addWidget(name: []const u8, wtype: WidgetType, w: u8, h: u8) void {
    if (widget_count >= MAX_WIDGETS) return;
    var card = &widgets[widget_count];
    card.name_len = setStr(&card.name, name);
    card.widget_type = wtype;
    card.width_units = w;
    card.height_units = h;
    widget_count += 1;
}

fn addDefaultWidgets() void {
    addWidget("Weather", .weather, 2, 1);
    addWidget("Calendar", .calendar, 1, 1);
    addWidget("System", .system_stats, 1, 1);
    addWidget("Clock", .clock, 1, 1);
    addWidget("Notes", .notes, 2, 1);
}

pub fn toggle() void {
    visible = !visible;
}

pub fn show() void {
    visible = true;
}

pub fn hide() void {
    visible = false;
}

pub fn isVisible() bool {
    return visible;
}

pub fn getWidgets() []const WidgetCard {
    return widgets[0..widget_count];
}

pub fn getPanelWidth() i32 {
    return theme.Layout.widget_panel_width;
}

pub fn getBackgroundColor(scheme: theme.ColorScheme) u32 {
    return switch (scheme) {
        .dark => theme.widget_bg_dark,
        .light => theme.widget_bg_light,
    };
}

pub fn getCardColor(scheme: theme.ColorScheme) u32 {
    return switch (scheme) {
        .dark => theme.widget_card_dark,
        .light => theme.widget_card_light,
    };
}

pub fn getCardStroke(scheme: theme.ColorScheme) u32 {
    return switch (scheme) {
        .dark => theme.widget_card_stroke_dark,
        .light => theme.widget_card_stroke_light,
    };
}
