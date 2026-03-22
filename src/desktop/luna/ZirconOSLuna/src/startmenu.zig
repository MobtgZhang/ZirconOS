//! Start Menu - ZirconOS Luna XP-Style Start Menu
//! Implements the two-column Windows XP Start Menu with user header,
//! pinned programs, MFU list, and system locations.
//! Reference: ReactOS explorer (base/shell/explorer/startmenu.cpp)

const theme = @import("theme.zig");

pub const COLORREF = theme.COLORREF;

// ── Menu Item ──

pub const MAX_MENU_ITEMS: usize = 32;
pub const MAX_ITEM_NAME_LEN: usize = 48;
pub const MAX_ITEM_PATH_LEN: usize = 128;

pub const MenuColumn = enum(u8) {
    left_pinned = 0,
    left_mfu = 1,
    right = 2,
};

pub const MenuItemType = enum(u8) {
    program = 0,
    folder = 1,
    separator = 2,
    system_link = 3,
    action = 4,
};

pub const MenuItem = struct {
    name: [MAX_ITEM_NAME_LEN]u8 = [_]u8{0} ** MAX_ITEM_NAME_LEN,
    name_len: usize = 0,
    description: [64]u8 = [_]u8{0} ** 64,
    description_len: usize = 0,
    target_path: [MAX_ITEM_PATH_LEN]u8 = [_]u8{0} ** MAX_ITEM_PATH_LEN,
    target_path_len: usize = 0,
    icon_id: u32 = 0,
    column: MenuColumn = .left_pinned,
    item_type: MenuItemType = .program,
    is_bold: bool = false,
    has_arrow: bool = false,
    is_highlighted: bool = false,
    is_visible: bool = true,
    y_offset: i32 = 0,

    pub fn getName(self: *const MenuItem) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getDescription(self: *const MenuItem) []const u8 {
        return self.description[0..self.description_len];
    }
};

// ── Start Menu Sections ──

pub const StartMenuState = enum(u8) {
    closed = 0,
    opening = 1,
    open = 2,
    closing = 3,
    submenu_open = 4,
};

pub const FooterButton = enum(u8) {
    log_off = 0,
    shut_down = 1,
};

// ── Global State ──

var left_pinned_items: [MAX_MENU_ITEMS]MenuItem = [_]MenuItem{.{}} ** MAX_MENU_ITEMS;
var left_pinned_count: usize = 0;

var left_mfu_items: [MAX_MENU_ITEMS]MenuItem = [_]MenuItem{.{}} ** MAX_MENU_ITEMS;
var left_mfu_count: usize = 0;

var right_items: [MAX_MENU_ITEMS]MenuItem = [_]MenuItem{.{}} ** MAX_MENU_ITEMS;
var right_count: usize = 0;

var menu_state: StartMenuState = .closed;
var highlight_column: MenuColumn = .left_pinned;
var highlight_index: i32 = -1;
var footer_highlight: i32 = -1;

var user_display_name: [64]u8 = [_]u8{0} ** 64;
var user_display_name_len: usize = 0;
var user_avatar_id: u32 = 0;

var menu_x: i32 = 0;
var menu_y: i32 = 0;
var startmenu_initialized: bool = false;

// ── Menu Construction ──

fn addItem(
    list: []MenuItem,
    count: *usize,
    name: []const u8,
    desc: []const u8,
    path: []const u8,
    icon_id: u32,
    column: MenuColumn,
    item_type: MenuItemType,
    bold: bool,
    arrow: bool,
) void {
    if (count.* >= list.len) return;
    var item = &list[count.*];
    item.* = .{};
    item.icon_id = icon_id;
    item.column = column;
    item.item_type = item_type;
    item.is_bold = bold;
    item.has_arrow = arrow;
    item.is_visible = true;

    const nn = @min(name.len, MAX_ITEM_NAME_LEN);
    @memcpy(item.name[0..nn], name[0..nn]);
    item.name_len = nn;

    const dd = @min(desc.len, item.description.len);
    @memcpy(item.description[0..dd], desc[0..dd]);
    item.description_len = dd;

    const pp = @min(path.len, MAX_ITEM_PATH_LEN);
    @memcpy(item.target_path[0..pp], path[0..pp]);
    item.target_path_len = pp;

    count.* += 1;
}

fn buildDefaultMenu() void {
    left_pinned_count = 0;
    left_mfu_count = 0;
    right_count = 0;

    addItem(
        &left_pinned_items, &left_pinned_count,
        "Internet", "Internet Explorer", "C:\\Program Files\\Internet Explorer\\iexplore.exe",
        20, .left_pinned, .program, true, false,
    );
    addItem(
        &left_pinned_items, &left_pinned_count,
        "E-mail", "Outlook Express", "C:\\Program Files\\Outlook Express\\msimn.exe",
        21, .left_pinned, .program, true, false,
    );

    addItem(
        &left_mfu_items, &left_mfu_count,
        "Windows Media Player", "", "C:\\Program Files\\Windows Media Player\\wmplayer.exe",
        30, .left_mfu, .program, false, false,
    );
    addItem(
        &left_mfu_items, &left_mfu_count,
        "Command Prompt", "", "C:\\WINDOWS\\system32\\cmd.exe",
        31, .left_mfu, .program, false, false,
    );
    addItem(
        &left_mfu_items, &left_mfu_count,
        "Notepad", "", "C:\\WINDOWS\\system32\\notepad.exe",
        32, .left_mfu, .program, false, false,
    );
    addItem(
        &left_mfu_items, &left_mfu_count,
        "Paint", "", "C:\\WINDOWS\\system32\\mspaint.exe",
        33, .left_mfu, .program, false, false,
    );
    addItem(
        &left_mfu_items, &left_mfu_count,
        "Calculator", "", "C:\\WINDOWS\\system32\\calc.exe",
        34, .left_mfu, .program, false, false,
    );

    addItem(
        &left_mfu_items, &left_mfu_count,
        "", "", "", 0, .left_mfu, .separator, false, false,
    );
    addItem(
        &left_mfu_items, &left_mfu_count,
        "All Programs", "", "", 40, .left_mfu, .folder, false, true,
    );

    addItem(
        &right_items, &right_count,
        "My Documents", "", "C:\\Documents and Settings\\User\\My Documents",
        50, .right, .system_link, true, false,
    );
    addItem(
        &right_items, &right_count,
        "My Recent Documents", "", "", 51, .right, .system_link, false, true,
    );
    addItem(
        &right_items, &right_count,
        "My Pictures", "", "C:\\Documents and Settings\\User\\My Documents\\My Pictures",
        52, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "My Music", "", "C:\\Documents and Settings\\User\\My Documents\\My Music",
        53, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "My Computer", "", "C:\\",
        54, .right, .system_link, true, false,
    );
    addItem(
        &right_items, &right_count,
        "", "", "", 0, .right, .separator, false, false,
    );
    addItem(
        &right_items, &right_count,
        "Control Panel", "", "C:\\WINDOWS\\system32\\control.exe",
        60, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "Printers and Faxes", "", "",
        61, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "Help and Support", "", "",
        62, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "Search", "", "",
        63, .right, .system_link, false, false,
    );
    addItem(
        &right_items, &right_count,
        "Run...", "", "",
        64, .right, .system_link, false, false,
    );
}

// ── Menu State ──

pub fn openMenu(x: i32, y: i32) void {
    menu_x = x;
    menu_y = y - theme.STARTMENU_HEIGHT;
    menu_state = .open;
    highlight_index = -1;
    footer_highlight = -1;
}

pub fn closeMenu() void {
    menu_state = .closed;
    highlight_index = -1;
    footer_highlight = -1;
}

pub fn isOpen() bool {
    return menu_state == .open or menu_state == .submenu_open;
}

pub fn getState() StartMenuState {
    return menu_state;
}

// ── Menu Geometry ──

pub fn getMenuRect() struct { x: i32, y: i32, w: i32, h: i32 } {
    return .{
        .x = menu_x,
        .y = menu_y,
        .w = theme.STARTMENU_WIDTH,
        .h = theme.STARTMENU_HEIGHT,
    };
}

pub fn getHeaderRect() struct { x: i32, y: i32, w: i32, h: i32 } {
    return .{
        .x = menu_x,
        .y = menu_y,
        .w = theme.STARTMENU_WIDTH,
        .h = theme.STARTMENU_HEADER_HEIGHT,
    };
}

pub fn getFooterRect() struct { x: i32, y: i32, w: i32, h: i32 } {
    return .{
        .x = menu_x,
        .y = menu_y + theme.STARTMENU_HEIGHT - theme.STARTMENU_FOOTER_HEIGHT,
        .w = theme.STARTMENU_WIDTH,
        .h = theme.STARTMENU_FOOTER_HEIGHT,
    };
}

// ── Data Access ──

pub fn getLeftPinnedItems() []const MenuItem {
    return left_pinned_items[0..left_pinned_count];
}

pub fn getLeftMfuItems() []const MenuItem {
    return left_mfu_items[0..left_mfu_count];
}

pub fn getRightItems() []const MenuItem {
    return right_items[0..right_count];
}

pub fn getHighlight() struct { column: MenuColumn, index: i32 } {
    return .{ .column = highlight_column, .index = highlight_index };
}

pub fn setHighlight(column: MenuColumn, index: i32) void {
    highlight_column = column;
    highlight_index = index;
}

pub fn setFooterHighlight(index: i32) void {
    footer_highlight = index;
}

pub fn getFooterHighlight() i32 {
    return footer_highlight;
}

// ── User Info ──

pub fn setUserInfo(name: []const u8, avatar_id: u32) void {
    const n = @min(name.len, user_display_name.len);
    @memcpy(user_display_name[0..n], name[0..n]);
    user_display_name_len = n;
    user_avatar_id = avatar_id;
}

pub fn getUserDisplayName() []const u8 {
    return user_display_name[0..user_display_name_len];
}

pub fn getUserAvatarId() u32 {
    return user_avatar_id;
}

// ── Menu Colors ──

pub fn getMenuColors() struct {
    header_left: COLORREF,
    header_right: COLORREF,
    header_text: COLORREF,
    left_bg: COLORREF,
    right_bg: COLORREF,
    highlight: COLORREF,
    highlight_text: COLORREF,
    text: COLORREF,
    footer_bg: COLORREF,
    separator: COLORREF,
} {
    const colors = theme.getColors();
    return .{
        .header_left = colors.titlebar_active_left,
        .header_right = colors.titlebar_active_right,
        .header_text = colors.titlebar_text_active,
        .left_bg = theme.RGB(0xFF, 0xFF, 0xFF),
        .right_bg = theme.RGB(0xD3, 0xE5, 0xFA),
        .highlight = colors.menu_highlight,
        .highlight_text = colors.menu_highlight_text,
        .text = colors.menu_text,
        .footer_bg = theme.RGB(0xD7, 0xE4, 0xF2),
        .separator = colors.menu_separator,
    };
}

// ── Initialization ──

pub fn init() void {
    menu_state = .closed;
    highlight_index = -1;
    footer_highlight = -1;

    buildDefaultMenu();

    setUserInfo("ZirconOS User", 0);
    startmenu_initialized = true;
}
