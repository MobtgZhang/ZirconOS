pub const boot = @import("boot.zig");
pub const paging = @import("paging.zig");
const uart = @import("../../hal/aarch64/uart.zig");

pub const name: []const u8 = "aarch64";
pub const PAGE_SIZE: usize = 4096;

extern fn kernel_main(magic: u32, info_addr: usize) callconv(.c) noreturn;

pub export fn _start() callconv(.c) noreturn {
    kernel_main(0, 0);
}

pub fn consoleWrite(s: []const u8) void {
    uart.write(s);
}

pub fn consoleClear() void {}

pub fn halt() noreturn {
    while (true) {
        asm volatile ("wfi");
    }
}

pub fn sendEoi(_: u8) void {}
pub fn initTimer() void {}
pub fn initPic() void {}
pub fn unmaskIrq(_: u8) void {}
pub fn enableInterrupts() void {}
pub fn disableInterrupts() void {}
