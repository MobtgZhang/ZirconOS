//! IPC (Inter-Process Communication) - LPC style message passing
//! NT style Microkernel core: all system services communicate via IPC
//!
//! Message format: sender, receiver, opcode, data
//! Each process has a message queue; send enqueues to target, receive dequeues from own

pub const MSG_DATA_SIZE: usize = 64;

pub const Message = struct {
    sender: u32,
    receiver: u32,
    opcode: u32,
    data: [MSG_DATA_SIZE]u8,

    pub fn init(sender_pid: u32, receiver_pid: u32, op: u32) Message {
        var msg: Message = undefined;
        msg.sender = sender_pid;
        msg.receiver = receiver_pid;
        msg.opcode = op;
        for (&msg.data) |*b| b.* = 0;
        return msg;
    }
};

const QUEUE_SIZE: usize = 16;

const MessageQueue = struct {
    messages: [QUEUE_SIZE]Message,
    head: usize,
    tail: usize,
    count: usize,

    fn reset(self: *MessageQueue) void {
        self.head = 0;
        self.tail = 0;
        self.count = 0;
    }

    fn push(self: *MessageQueue, msg: Message) bool {
        if (self.count >= QUEUE_SIZE) return false;
        self.messages[self.tail] = msg;
        self.tail = (self.tail + 1) % QUEUE_SIZE;
        self.count += 1;
        return true;
    }

    fn pop(self: *MessageQueue) ?Message {
        if (self.count == 0) return null;
        const msg = self.messages[self.head];
        self.head = (self.head + 1) % QUEUE_SIZE;
        self.count -= 1;
        return msg;
    }
};

const MAX_QUEUES: usize = 32;
var message_queues: [MAX_QUEUES]MessageQueue = undefined;
var queues_initialized: bool = false;

fn ensureQueues() void {
    if (!queues_initialized) {
        for (&message_queues) |*q| q.reset();
        queues_initialized = true;
    }
}

fn pidToIndex(pid: u32) ?usize {
    if (pid == 0 or pid > MAX_QUEUES) return null;
    return pid - 1;
}

pub fn send(sender_pid: u32, receiver_pid: u32, opcode: u32, data: ?*const [MSG_DATA_SIZE]u8) i64 {
    ensureQueues();
    const recv_idx = pidToIndex(receiver_pid) orelse return -1;

    var msg = Message.init(sender_pid, receiver_pid, opcode);
    if (data) |d| {
        @memcpy(&msg.data, d);
    }

    if (!message_queues[recv_idx].push(msg)) {
        return -2;
    }
    return 0;
}

pub fn receive(receiver_pid: u32) ?Message {
    ensureQueues();
    const idx = pidToIndex(receiver_pid) orelse return null;
    return message_queues[idx].pop();
}

pub fn tryReceive(receiver_pid: u32) ?Message {
    return receive(receiver_pid);
}
