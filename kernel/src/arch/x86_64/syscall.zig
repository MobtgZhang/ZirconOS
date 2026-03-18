//! Syscall dispatch for x86_64
//! int 0x80 (vector 128): rax=syscall_no, rdi,rsi,rdx,r10,r8,r9=args
//!
//! Syscall table:
//!   0 = NtCreateProcess
//!   1 = NtCreateThread
//!   2 = NtSendMessage (IPC send)
//!   3 = NtReceiveMessage (IPC receive)
//!   4 = NtMapMemory

const ipc = @import("../../lpc/ipc.zig");
const process = @import("../../ps/process.zig");
const klog = @import("../../rtl/klog.zig");

pub const SYS_CREATE_PROCESS: u64 = 0;
pub const SYS_CREATE_THREAD: u64 = 1;
pub const SYS_IPC_SEND: u64 = 2;
pub const SYS_IPC_RECEIVE: u64 = 3;
pub const SYS_MAP_MEMORY: u64 = 4;

pub const ERR_OK: i64 = 0;
pub const ERR_INVALID: i64 = -1;
pub const ERR_QUEUE_FULL: i64 = -2;
pub const ERR_NO_MSG: i64 = -3;

const SyscallArgs = extern struct {
    syscall_no: u64,
    arg1: u64,
    arg2: u64,
    arg3: u64,
    arg4: u64,
    arg5: u64,
    arg6: u64,
};

export fn syscall_dispatch(args_ptr: [*]const u64) callconv(.c) i64 {
    const args = @as(*const SyscallArgs, @ptrCast(args_ptr));
    const syscall_no = args.syscall_no;

    return switch (syscall_no) {
        SYS_IPC_SEND => handleIpcSend(args.arg1, args.arg2, args.arg3),
        SYS_IPC_RECEIVE => handleIpcReceive(args.arg1),
        SYS_CREATE_PROCESS => handleCreateProcess(args.arg1),
        SYS_CREATE_THREAD => handleCreateThread(args.arg1, args.arg2),
        SYS_MAP_MEMORY => handleMapMemory(args.arg1, args.arg2, args.arg3),
        else => {
            klog.warn("Unknown syscall %u", .{syscall_no});
            return ERR_INVALID;
        },
    };
}

fn handleIpcSend(sender: u64, receiver: u64, opcode: u64) i64 {
    return ipc.send(@intCast(sender), @intCast(receiver), @intCast(opcode), null);
}

fn handleIpcReceive(_: u64) i64 {
    const msg = ipc.receive(process.getCurrentPid());
    if (msg) |m| {
        return @intCast(m.sender);
    }
    return ERR_NO_MSG;
}

fn handleCreateProcess(frame_alloc_ptr: u64) i64 {
    const alloc = @as(*@import("../../mm/frame.zig").FrameAllocator, @ptrFromInt(frame_alloc_ptr));
    const p = process.createProcess(alloc);
    if (p) |proc| {
        return @intCast(proc.pid);
    }
    return ERR_INVALID;
}

fn handleCreateThread(_: u64, _: u64) i64 {
    return 0;
}

fn handleMapMemory(_: u64, _: u64, _: u64) i64 {
    return ERR_INVALID;
}
