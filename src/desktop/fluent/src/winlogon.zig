//! Fluent Login Screen (winlogon equivalent)
//! Manages user authentication flow: lock screen → credentials →
//! session initialization. Uses acrylic blurred wallpaper backdrop.

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
    logged_in: bool = false,
};

const MAX_USERS: usize = 8;
var users: [MAX_USERS]UserAccount = [_]UserAccount{.{}} ** MAX_USERS;
var user_count: usize = 0;
var selected_user: usize = 0;
var login_state: LoginState = .lock_screen;
var color_scheme: theme.ColorScheme = .dark;
var auth_attempts: u8 = 0;

pub fn init(scheme: theme.ColorScheme) void {
    color_scheme = scheme;
    login_state = .lock_screen;
    auth_attempts = 0;
    user_count = 0;
    selected_user = 0;

    addDefaultUser();
}

fn setString(dest: []u8, src: []const u8) u8 {
    const len = @min(src.len, dest.len);
    for (0..len) |i| {
        dest[i] = src[i];
    }
    return @intCast(len);
}

fn addDefaultUser() void {
    if (user_count >= MAX_USERS) return;
    var u = &users[user_count];
    u.username_len = setString(&u.username, "admin");
    u.display_name_len = setString(&u.display_name, "Administrator");
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

pub fn getUserCount() usize {
    return user_count;
}

pub fn dismissLockScreen() void {
    if (login_state == .lock_screen) {
        login_state = .credential_entry;
    }
}

pub fn attemptLogin(password_hash: u64) bool {
    _ = password_hash;
    auth_attempts += 1;

    if (auth_attempts <= 3) {
        login_state = .authenticating;
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

pub fn getBackgroundColor() u32 {
    return theme.getScheme(color_scheme).desktop_bg;
}

pub fn getAccentColor() u32 {
    return theme.getScheme(color_scheme).accent;
}

pub fn getTextColor() u32 {
    return theme.getScheme(color_scheme).text_primary;
}
