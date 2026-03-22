//! Sun Valley Start Menu
//! Centered flyout with pinned apps grid, recommended section,
//! user profile, power controls, and integrated search bar.
//! Features rounded corners and Mica/Acrylic backdrop.

const theme = @import("theme.zig");

pub const PinnedItem = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    icon_id: u16 = 0,
};

pub const RecommendedItem = struct {
    name: [48]u8 = [_]u8{0} ** 48,
    name_len: u8 = 0,
    icon_id: u16 = 0,
    subtitle: [32]u8 = [_]u8{0} ** 32,
    subtitle_len: u8 = 0,
};

const MAX_PINNED: usize = 18;
const MAX_RECOMMENDED: usize = 8;
const MAX_ALL_APPS: usize = 64;

var pinned_items: [MAX_PINNED]PinnedItem = [_]PinnedItem{.{}} ** MAX_PINNED;
var pinned_count: usize = 0;

var recommended: [MAX_RECOMMENDED]RecommendedItem = [_]RecommendedItem{.{}} ** MAX_RECOMMENDED;
var recommended_count: usize = 0;

var all_apps: [MAX_ALL_APPS]PinnedItem = [_]PinnedItem{.{}} ** MAX_ALL_APPS;
var all_apps_count: usize = 0;

var visible: bool = false;
var showing_all_apps: bool = false;
var search_text: [128]u8 = [_]u8{0} ** 128;
var search_len: usize = 0;

pub fn init() void {
    pinned_count = 0;
    recommended_count = 0;
    all_apps_count = 0;
    visible = false;
    showing_all_apps = false;
    search_len = 0;
    addDefaultPinned();
    addDefaultRecommended();
    addDefaultAllApps();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addPinned(name: []const u8, icon_id: u16) void {
    if (pinned_count >= MAX_PINNED) return;
    var item = &pinned_items[pinned_count];
    item.name_len = setStr(&item.name, name);
    item.icon_id = icon_id;
    pinned_count += 1;
}

fn addRecommended(name: []const u8, subtitle: []const u8, icon_id: u16) void {
    if (recommended_count >= MAX_RECOMMENDED) return;
    var item = &recommended[recommended_count];
    item.name_len = setStr(&item.name, name);
    item.subtitle_len = setStr(&item.subtitle, subtitle);
    item.icon_id = icon_id;
    recommended_count += 1;
}

fn addAllApp(name: []const u8, icon_id: u16) void {
    if (all_apps_count >= MAX_ALL_APPS) return;
    var item = &all_apps[all_apps_count];
    item.name_len = setStr(&item.name, name);
    item.icon_id = icon_id;
    all_apps_count += 1;
}

pub const identity = struct {
    pub const title = "Windows 11 - Sun Valley";
    pub const search_placeholder = "Type here to search";
    pub const pinned_header = "Pinned";
    pub const all_apps = "All apps >";
    pub const header_sub = "ZirconOS - Mica + WinUI 3";
    pub const user_name = "ZirconOS User";
    pub const version_tag = "Sun Valley WinUI 3 v1.0";
};

fn addDefaultPinned() void {
    addPinned("Edge", 6);
    addPinned("File Explorer", 5);
    addPinned("Terminal", 4);
    addPinned("Settings", 7);
    addPinned("Store", 8);
    addPinned("Photos", 11);
    addPinned("Mail", 14);
    addPinned("Teams", 14);
    addPinned("Widgets", 10);
    addPinned("Calculator", 8);
    addPinned("Clock", 13);
    addPinned("Camera", 12);
}

fn addDefaultRecommended() void {
    addRecommended("Document.txt", "Recently opened", 2);
    addRecommended("screenshot.png", "Today", 11);
    addRecommended("project/", "Yesterday", 5);
    addRecommended("notes.md", "Last week", 9);
}

fn addDefaultAllApps() void {
    addAllApp("Browser", 6);
    addAllApp("Calculator", 8);
    addAllApp("Calendar", 13);
    addAllApp("Camera", 14);
    addAllApp("Clock", 15);
    addAllApp("File Manager", 5);
    addAllApp("Music", 11);
    addAllApp("Network", 16);
    addAllApp("Photos", 10);
    addAllApp("Settings", 7);
    addAllApp("Store", 12);
    addAllApp("Terminal", 4);
    addAllApp("Text Editor", 9);
}

pub fn toggle() void {
    visible = !visible;
    if (!visible) {
        search_len = 0;
        showing_all_apps = false;
    }
}

pub fn show() void {
    visible = true;
}

pub fn hide() void {
    visible = false;
    search_len = 0;
    showing_all_apps = false;
}

pub fn isVisible() bool {
    return visible;
}

pub fn toggleAllApps() void {
    showing_all_apps = !showing_all_apps;
}

pub fn isShowingAllApps() bool {
    return showing_all_apps;
}

pub fn contains(screen_w: i32, screen_h: i32, x: i32, y: i32) bool {
    const menu_w = theme.Layout.startmenu_width;
    const menu_h = theme.Layout.startmenu_height;
    const taskbar_h = theme.Layout.taskbar_height;
    const menu_x = @divTrunc(screen_w - menu_w, 2);
    const menu_y = screen_h - taskbar_h - menu_h;
    return x >= menu_x and x < menu_x + menu_w and y >= menu_y and y < menu_y + menu_h;
}

pub fn getPinnedItems() []const PinnedItem {
    return pinned_items[0..pinned_count];
}

pub fn getRecommendedItems() []const RecommendedItem {
    return recommended[0..recommended_count];
}

pub fn getAllApps() []const PinnedItem {
    return all_apps[0..all_apps_count];
}

pub fn getBackgroundColor(scheme: theme.ColorScheme) u32 {
    return switch (scheme) {
        .dark => theme.start_dark_bg,
        .light => theme.start_light_bg,
    };
}

pub fn getSearchBackground(scheme: theme.ColorScheme) u32 {
    return switch (scheme) {
        .dark => theme.start_search_bg_dark,
        .light => theme.start_search_bg_light,
    };
}
