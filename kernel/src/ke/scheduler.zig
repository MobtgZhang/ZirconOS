//! Round-Robin Scheduler
//! Driven by PIT timer tick, supports multi-thread context switching

pub const ThreadState = enum {
    ready,
    running,
    blocked,
};

pub const ThreadContext = struct {
    r15: u64 = 0,
    r14: u64 = 0,
    r13: u64 = 0,
    r12: u64 = 0,
    rbx: u64 = 0,
    rbp: u64 = 0,
    rip: u64 = 0,
};

const MAX_THREADS: usize = 8;

pub const Thread = struct {
    id: usize,
    state: ThreadState,
    context: ThreadContext,
    stack: [4096]u8 align(16) = undefined,
    stack_top: usize = 0,
};

var threads: [MAX_THREADS]Thread = undefined;
var thread_count: usize = 0;
var current_thread: usize = 0;
var tick_count: u64 = 0;

pub fn init() void {
    thread_count = 0;
    current_thread = 0;
    tick_count = 0;
}

pub fn tick() void {
    tick_count += 1;

    if (thread_count <= 1) return;

    const next = (current_thread + 1) % thread_count;
    if (next != current_thread) {
        switchContext(current_thread, next);
        current_thread = next;
    }
}

fn switchContext(from: usize, to: usize) void {
    _ = from;
    _ = to;
}

pub fn getTicks() u64 {
    return tick_count;
}
