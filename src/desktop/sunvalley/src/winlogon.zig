//! Sun Valley Login Screen
//! Full-screen lock/login with blurred wallpaper backdrop,
//! rounded credential panel, user avatar, and session management.

const theme = @import("theme.zig");

pub const LoginState = enum {
    lock_screen,
    credential_entry,
    authenticating,
    loading_profile,
    session_ready,
    failed,
};

pub const UserAccount = struct {
    username: [32]u8 = [_]u8{0} ** 32,
    username_len: u8 = 0,
    display_name: [64]u8 = [_]u8{0} ** 64,
    display_name_len: u8 = 0,
    avatar_id: u16 = 0,
    has_password: bool = true,
    has_pin: bool = false,
    has_fingerprint: bool = false,
    logged_in: bool = false,
};

const MAX_USERS: usize = 8;
var users: [MAX_USERS]UserAccount = [_]UserAccount{.{}} ** MAX_USERS;
var user_count: usize = 0;
var selected_user: usize = 0;
var login_state: LoginState = .lock_screen;
var auth_attempts: u8 = 0;

pub fn init() void {
    login_state = .lock_screen;
    auth_attempts = 0;
    user_count = 0;
    addDefaultUser();
}

fn setStr(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addDefaultUser() void {
    if (user_count >= MAX_USERS) return;
    var u = &users[user_count];
    u.username_len = setStr(&u.username, "admin");
    u.display_name_len = setStr(&u.display_name, "Administrator");
    u.avatar_id = 1;
    u.has_password = true;
    user_count += 1;
}

pub fn getState() LoginState {
    return login_state;
}

pub fn getSelectedUser() ?*const UserAccount {
    if (selected_user < user_count) return &users[selected_user];
    return null;
}

pub fn dismissLockScreen() void {
    if (login_state == .lock_screen) {
        login_state = .credential_entry;
    }
}

pub fn selectUser(index: usize) void {
    if (index < user_count) {
        selected_user = index;
        login_state = .credential_entry;
    }
}

pub fn attemptLogin(password_hash: u64) bool {
    _ = password_hash;
    auth_attempts += 1;
    login_state = .authenticating;

    if (auth_attempts <= 3) {
        login_state = .loading_profile;
        if (selected_user < user_count) {
            users[selected_user].logged_in = true;
        }
        login_state = .session_ready;
        return true;
    }

    login_state = .failed;
    return false;
}

pub fn lockSession() void {
    login_state = .lock_screen;
    auth_attempts = 0;
}

pub fn isSessionReady() bool {
    return login_state == .session_ready;
}

pub fn getLoginPanelBg() u32 {
    return theme.login_panel_bg;
}

pub fn getLoginPanelStroke() u32 {
    return theme.login_panel_stroke;
}

pub fn getInputBg() u32 {
    return theme.login_input_bg;
}

pub fn getInputFocusColor() u32 {
    return theme.login_input_focus;
}

pub fn getSubmitButtonBg() u32 {
    return theme.login_btn_bg;
}

pub fn getBackgroundColor() u32 {
    return theme.login_bg;
}
