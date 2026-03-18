const std = @import("std");
const uefi = std.os.uefi;
const builtin = @import("builtin");
const unicode = std.unicode;

const arch_name = switch (builtin.target.cpu.arch) {
    .x86_64 => "x86_64",
    .aarch64 => "aarch64",
    .riscv64 => "riscv64",
    .loongarch64 => "loongarch64",
    else => "unknown",
};

pub fn main() noreturn {
    const st = uefi.system_table;
    const out = st.con_out orelse halt();

    out.reset(false) catch {};

    puts(out, "\r\n");
    puts(out, " ========================================\r\n");
    puts(out, "      ZirconOS v1.0  UEFI Boot\r\n");
    puts(out, "   NT-style Microkernel OS (Zig lang)\r\n");
    puts(out, " ========================================\r\n");
    puts(out, "\r\n");
    puts(out, "  Architecture : " ++ arch_name ++ "\r\n");
    puts(out, "  Boot method  : UEFI\r\n");
    puts(out, "  Firmware     : ");
    _ = out.outputString(st.firmware_vendor) catch false;
    puts(out, "\r\n\r\n");

    printUefiVersion(out, st.hdr.revision);

    puts(out, "  [OK] UEFI console initialized\r\n");
    puts(out, "  [..] Kernel loader pending (v1.1)\r\n");
    puts(out, "  [!!] System halted.\r\n");

    halt();
}

fn printUefiVersion(out: anytype, revision: u32) void {
    const major = revision >> 16;
    const minor = revision & 0xFFFF;

    puts(out, "  UEFI rev     : ");
    printDecimal(out, major);
    puts(out, ".");
    printDecimal(out, minor);
    puts(out, "\r\n");
}

fn printDecimal(out: anytype, value: u32) void {
    if (value >= 10) printDecimal(out, value / 10);
    var buf: [1:0]u16 = .{@as(u16, @intCast('0' + (value % 10)))};
    _ = out.outputString(&buf) catch false;
}

fn puts(out: anytype, comptime s: []const u8) void {
    _ = out.outputString(unicode.utf8ToUtf16LeStringLiteral(s)) catch false;
}

fn halt() noreturn {
    while (true) {
        switch (builtin.target.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            .aarch64 => asm volatile ("wfi"),
            .riscv64 => asm volatile ("wfi"),
            else => {},
        }
    }
}
