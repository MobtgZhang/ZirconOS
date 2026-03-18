//! Process Server - NT style system service
//! Handles process/thread creation and termination via IPC
//!
//! Opcodes:
//!   1 = create_process
//!   2 = create_thread
//!   3 = terminate_process

const process = @import("process.zig");
const ipc = @import("../lpc/ipc.zig");
const FrameAllocator = @import("../mm/frame.zig").FrameAllocator;
const klog = @import("../rtl/klog.zig");

pub const PROCESS_SERVER_PID: u32 = 1;

pub const OP_CREATE_PROCESS: u32 = 1;
pub const OP_CREATE_THREAD: u32 = 2;
pub const OP_TERMINATE_PROCESS: u32 = 3;

var frame_alloc: ?*FrameAllocator = null;

pub fn init(alloc: *FrameAllocator) void {
    frame_alloc = alloc;
    process.init();
    const p = process.createProcess(alloc);
    if (p) |proc| {
        proc.is_process_server = true;
        process.setCurrentProcess(proc.pid);
        klog.info("Process Server (PID %u) started", .{proc.pid});
    } else {
        klog.err("Failed to create Process Server", .{});
    }
}

pub fn handleMessage() void {
    const msg = ipc.receive(PROCESS_SERVER_PID) orelse return;

    const sender = msg.sender;
    const opcode = msg.opcode;

    var reply_data: [ipc.MSG_DATA_SIZE]u8 = undefined;
    @memset(&reply_data, 0);

    switch (opcode) {
        OP_CREATE_PROCESS => {
            if (frame_alloc) |alloc| {
                const p = process.createProcess(alloc);
                if (p) |proc| {
                    reply_data[0] = @intCast(proc.pid & 0xFF);
                    reply_data[1] = @intCast((proc.pid >> 8) & 0xFF);
                    reply_data[2] = @intCast((proc.pid >> 16) & 0xFF);
                    reply_data[3] = @intCast((proc.pid >> 24) & 0xFF);
                }
            }
        },
        OP_CREATE_THREAD => {},
        OP_TERMINATE_PROCESS => {
            const pid = @as(u32, msg.data[0]) |
                (@as(u32, msg.data[1]) << 8) |
                (@as(u32, msg.data[2]) << 16) |
                (@as(u32, msg.data[3]) << 24);
            const p = process.findProcess(pid);
            if (p) |proc| {
                proc.state = .terminated;
            }
        },
        else => {
            klog.warn("Process Server: unknown opcode %u from sender %u", .{ opcode, sender });
        },
    }

    _ = ipc.send(PROCESS_SERVER_PID, sender, opcode, &reply_data);
}
