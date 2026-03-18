//! Kernel Interrupt Dispatch
//! Routes exceptions and IRQs to appropriate handlers

const arch = @import("../arch.zig");
const klog = @import("../rtl/klog.zig");
const scheduler = @import("scheduler.zig");

const EXCEPTION_NAMES: [32][]const u8 = .{
    "Divide Error",
    "Debug",
    "NMI",
    "Breakpoint",
    "Overflow",
    "BOUND Range Exceeded",
    "Invalid Opcode",
    "Device Not Available",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Invalid TSS",
    "Segment Not Present",
    "Stack-Segment Fault",
    "General Protection",
    "Page Fault",
    "Reserved",
    "x87 FPU Error",
    "Alignment Check",
    "Machine Check",
    "SIMD Error",
    "Virtualization",
    "Control Protection",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
};

pub fn handle(vector: u8, error_code: u64) void {
    if (vector < 32) {
        handleException(vector, error_code);
    } else if (vector >= 32 and vector < 48) {
        handleIrq(vector - 32);
    } else {
        klog.warn("Unknown interrupt vector %d", .{vector});
    }
}

fn handleException(vector: u8, error_code: u64) void {
    const name = if (vector < EXCEPTION_NAMES.len) EXCEPTION_NAMES[vector] else "Unknown";
    klog.err("Exception %d (%s) error_code=0x%x", .{ vector, name, error_code });

    if (vector == 8 or vector == 13 or vector == 14) {
        arch.halt();
    }
}

fn handleIrq(irq: u8) void {
    switch (irq) {
        0 => scheduler.tick(),
        else => klog.debug("IRQ %d", .{irq}),
    }
    arch.sendEoi(irq);
}
