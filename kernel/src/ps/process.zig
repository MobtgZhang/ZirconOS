//! Process & Thread Model (NT style)
//! Kernel provides process/thread abstraction
//! Process Server handles creation policy via IPC

const vm = @import("../mm/vm.zig");
const FrameAllocator = @import("../mm/frame.zig").FrameAllocator;

pub const MAX_PROCESSES: usize = 32;
pub const MAX_THREADS_PER_PROCESS: usize = 8;

pub const ProcessState = enum {
    active,
    terminated,
};

pub const Process = struct {
    pid: u32,
    state: ProcessState,
    address_space: ?vm.AddressSpace,
    thread_count: usize,
    is_process_server: bool,

    pub fn init(pid: u32) Process {
        return .{
            .pid = pid,
            .state = .active,
            .address_space = null,
            .thread_count = 0,
            .is_process_server = false,
        };
    }
};

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

pub const Thread = struct {
    id: usize,
    process_id: u32,
    state: ThreadState,
    context: ThreadContext,
    stack: [4096]u8 align(16) = undefined,
    stack_top: usize = 0,
};

var processes: [MAX_PROCESSES]Process = undefined;
var process_count: usize = 0;
var next_pid: u32 = 1;
var current_pid: u32 = 0;

pub fn init() void {
    process_count = 0;
    next_pid = 1;
    current_pid = 0;
    for (&processes) |*p| {
        p.* = Process.init(0);
    }
}

pub fn allocPid() ?u32 {
    if (next_pid == 0) return null;
    const pid = next_pid;
    next_pid += 1;
    return pid;
}

pub fn createProcess(frame_alloc: *FrameAllocator) ?*Process {
    if (process_count >= MAX_PROCESSES) return null;
    const pid = allocPid() orelse return null;

    const space = vm.createAddressSpace(frame_alloc) orelse return null;

    var p = &processes[process_count];
    p.* = Process.init(pid);
    p.address_space = space;
    p.state = .active;
    process_count += 1;
    return p;
}

pub fn findProcess(pid: u32) ?*Process {
    for (processes[0..process_count]) |*p| {
        if (p.pid == pid) return p;
    }
    return null;
}

pub fn setCurrentProcess(pid: u32) void {
    current_pid = pid;
}

pub fn getCurrentPid() u32 {
    return current_pid;
}

pub fn getCurrentProcess() ?*Process {
    return findProcess(current_pid);
}
