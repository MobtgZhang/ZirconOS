const std = @import("std");

const uefi = std.os.uefi;

pub fn main() uefi.Status {
    const st = uefi.system_table;
    const con = st.con_out orelse return .load_error;
    const bs = st.boot_services orelse return .load_error;

    // Ensure console is usable and clear it for a clean output.
    con.reset(false) catch {};
    con.clearScreen() catch {};

    const msg = std.unicode.utf8ToUtf16LeStringLiteral("Hello  ZirconOS!\r\n");
    _ = con.outputString(msg) catch {};

    // Stall a bit so the message is visible even if GRUB returns.
    // (Some firmwares return immediately to the boot manager.)
    bs.stall(2_000_000) catch {}; // 2s

    return .success;
}

