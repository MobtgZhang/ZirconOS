//! Kernel Timer Module
//! Wraps architecture-specific timer hardware

const arch = @import("../arch.zig");
const scheduler = @import("scheduler.zig");

pub fn init() void {
    arch.initTimer();
}

pub fn getTicks() u64 {
    return scheduler.getTicks();
}
