const builtin = @import("builtin");

pub const impl = switch (builtin.target.cpu.arch) {
    .x86_64 => @import("arch/x86_64/mod.zig"),
    .aarch64 => @import("arch/aarch64/mod.zig"),
    .loongarch64 => @import("arch/loong64/mod.zig"),
    .riscv64 => @import("arch/riscv64/mod.zig"),
    .mips64el => @import("arch/mips64el/mod.zig"),
    else => @compileError("Unsupported architecture"),
};

pub const PAGE_SIZE: usize = impl.PAGE_SIZE;
pub const PAGE_MASK: usize = PAGE_SIZE - 1;

pub fn consoleWrite(s: []const u8) void {
    impl.consoleWrite(s);
}

pub fn consoleClear() void {
    impl.consoleClear();
}

pub fn halt() noreturn {
    impl.halt();
}

pub fn sendEoi(irq: u8) void {
    impl.sendEoi(irq);
}

pub fn initTimer() void {
    impl.initTimer();
}

pub fn initPic() void {
    impl.initPic();
}

pub fn unmaskIrq(irq: u8) void {
    impl.unmaskIrq(irq);
}

pub fn enableInterrupts() void {
    impl.enableInterrupts();
}

pub fn disableInterrupts() void {
    impl.disableInterrupts();
}
