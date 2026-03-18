pub const boot = @import("boot.zig");
pub const paging = @import("paging.zig");

pub const name: []const u8 = "loong64";
pub const PAGE_SIZE: usize = 16384;

extern fn kernel_main(magic: u32, info_addr: usize) callconv(.c) noreturn;

pub export fn _start() callconv(.c) noreturn {
    kernel_main(0, 0);
}

pub fn consoleWrite(_: []const u8) void {}
pub fn consoleClear() void {}

pub fn halt() noreturn {
    while (true) {
        asm volatile ("idle 0");
    }
}

pub fn sendEoi(_: u8) void {}
pub fn initTimer() void {}
pub fn initPic() void {}
pub fn unmaskIrq(_: u8) void {}
pub fn enableInterrupts() void {}
pub fn disableInterrupts() void {}
