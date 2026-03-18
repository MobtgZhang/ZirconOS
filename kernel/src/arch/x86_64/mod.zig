pub const boot = @import("boot.zig");
pub const paging = @import("paging.zig");
const vga = @import("../../hal/x86_64/vga.zig");
const pic = @import("../../hal/x86_64/pic.zig");
const pit = @import("../../hal/x86_64/pit.zig");
pub const serial = @import("../../hal/x86_64/serial.zig");
pub const gdt = @import("../../hal/x86_64/gdt.zig");

pub const name: []const u8 = "x86_64";
pub const PAGE_SIZE: usize = 4096;

comptime {
    _ = boot.multiboot2_header;
    if (@import("build_options").enable_idt) {
        _ = @import("isr.zig");
        _ = @import("syscall.zig");
    }
}

pub fn consoleWrite(s: []const u8) void {
    vga.write(s);
    if (serial.isReady()) {
        serial.write(s);
    }
}

pub fn consoleClear() void {
    vga.clear();
}

pub fn serialWrite(s: []const u8) void {
    serial.write(s);
}

pub fn initSerial() void {
    serial.init();
}

pub fn initGdt(kernel_stack: u64) void {
    gdt.init(kernel_stack);
}

pub fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

pub fn sendEoi(irq: u8) void {
    pic.sendEoi(irq);
}

pub fn initTimer() void {
    pit.init();
}

pub fn initPic() void {
    pic.init();
}

pub fn unmaskIrq(irq: u8) void {
    pic.unmaskIrq(irq);
}

pub fn enableInterrupts() void {
    asm volatile ("sti");
}

pub fn disableInterrupts() void {
    asm volatile ("cli");
}
