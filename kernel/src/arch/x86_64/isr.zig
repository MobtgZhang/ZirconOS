//! x86_64 ISR (Interrupt Service Routine) declarations
//! Stubs are defined in isr_common.s (assembly)
//! Address table (isr_table) is also in assembly (.rodata)

pub const STUB_COUNT: usize = 48;

extern const isr_table: [STUB_COUNT]usize;
extern const isr_default_entry: usize;

pub fn getStubAddr(idx: usize) usize {
    if (idx < STUB_COUNT) return isr_table[idx];
    return isr_default_entry;
}

pub fn getDefaultAddr() usize {
    return isr_default_entry;
}

export fn isr_common_handler(vector: u8, error_code: u64) void {
    const interrupt = @import("../../ke/interrupt.zig");
    interrupt.handle(vector, error_code);
}
