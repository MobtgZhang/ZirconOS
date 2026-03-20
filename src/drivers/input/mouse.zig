//! PS/2 Mouse Driver (NT-style)
//! Handles PS/2 mouse input via IRQ12 (i8042 auxiliary port).
//! Provides absolute/relative position tracking, button states,
//! and a mouse event queue for the desktop compositor.
//! Reference: OSDev PS/2 Mouse, ReactOS drivers/input/i8042prt/

const io = @import("../../io/io.zig");
const klog = @import("../../rtl/klog.zig");
const portio = @import("../../hal/x86_64/portio.zig");

const KB_DATA_PORT: u16 = 0x60;
const KB_STATUS_PORT: u16 = 0x64;
const KB_CMD_PORT: u16 = 0x64;

pub const MouseButton = enum(u8) {
    none = 0,
    left = 1,
    right = 2,
    middle = 4,
};

pub const MouseEvent = struct {
    dx: i16 = 0,
    dy: i16 = 0,
    buttons: u8 = 0,
    scroll: i8 = 0,
};

pub const MouseState = struct {
    x: i32 = 0,
    y: i32 = 0,
    buttons: u8 = 0,
    left_pressed: bool = false,
    right_pressed: bool = false,
    middle_pressed: bool = false,
    screen_width: i32 = 1024,
    screen_height: i32 = 768,
};

const EVENT_QUEUE_SIZE: usize = 64;
var event_queue: [EVENT_QUEUE_SIZE]MouseEvent = [_]MouseEvent{.{}} ** EVENT_QUEUE_SIZE;
var queue_head: usize = 0;
var queue_tail: usize = 0;

var packet_buf: [4]u8 = [_]u8{0} ** 4;
var packet_idx: usize = 0;
var has_scroll_wheel: bool = false;

var mouse_state: MouseState = .{};
var driver_idx: u32 = 0;
var device_idx: u32 = 0;
var driver_initialized: bool = false;
var total_events: u64 = 0;

pub const IOCTL_MOUSE_GET_STATE: u32 = 0x000B0000;
pub const IOCTL_MOUSE_SET_BOUNDS: u32 = 0x000B0004;
pub const IOCTL_MOUSE_GET_EVENTS: u32 = 0x000B0008;
pub const IOCTL_MOUSE_RESET: u32 = 0x000B000C;

fn waitForInput() void {
    var timeout: u32 = 100000;
    while (timeout > 0) : (timeout -= 1) {
        if (portio.inb(KB_STATUS_PORT) & 0x01 != 0) return;
    }
}

fn waitForOutput() void {
    var timeout: u32 = 100000;
    while (timeout > 0) : (timeout -= 1) {
        if (portio.inb(KB_STATUS_PORT) & 0x02 == 0) return;
    }
}

fn sendCommand(cmd: u8) void {
    waitForOutput();
    portio.outb(KB_CMD_PORT, cmd);
}

fn sendData(data: u8) void {
    waitForOutput();
    portio.outb(KB_DATA_PORT, data);
}

fn readData() u8 {
    waitForInput();
    return portio.inb(KB_DATA_PORT);
}

fn mouseWrite(byte: u8) u8 {
    sendCommand(0xD4);
    sendData(byte);
    return readData();
}

pub fn handleIrq() void {
    const status = portio.inb(KB_STATUS_PORT);
    if (status & 0x20 == 0) return;

    const data = portio.inb(KB_DATA_PORT);

    if (packet_idx == 0 and (data & 0x08 == 0)) return;

    packet_buf[packet_idx] = data;
    packet_idx += 1;

    const expected_len: usize = if (has_scroll_wheel) 4 else 3;
    if (packet_idx < expected_len) return;

    packet_idx = 0;

    var event = MouseEvent{};

    event.buttons = packet_buf[0] & 0x07;

    var dx: i16 = @intCast(packet_buf[1]);
    var dy: i16 = @intCast(packet_buf[2]);

    if (packet_buf[0] & 0x10 != 0) dx -= 256;
    if (packet_buf[0] & 0x20 != 0) dy -= 256;

    if (packet_buf[0] & 0x40 != 0 or packet_buf[0] & 0x80 != 0) return;

    event.dx = dx;
    event.dy = -dy;

    if (has_scroll_wheel and expected_len == 4) {
        const scroll_raw: i8 = @bitCast(packet_buf[3]);
        event.scroll = scroll_raw;
    }

    mouse_state.buttons = event.buttons;
    mouse_state.left_pressed = (event.buttons & 0x01) != 0;
    mouse_state.right_pressed = (event.buttons & 0x02) != 0;
    mouse_state.middle_pressed = (event.buttons & 0x04) != 0;

    mouse_state.x += @as(i32, event.dx);
    mouse_state.y += @as(i32, event.dy);

    if (mouse_state.x < 0) mouse_state.x = 0;
    if (mouse_state.y < 0) mouse_state.y = 0;
    if (mouse_state.x >= mouse_state.screen_width) mouse_state.x = mouse_state.screen_width - 1;
    if (mouse_state.y >= mouse_state.screen_height) mouse_state.y = mouse_state.screen_height - 1;

    pushEvent(event);
}

fn pushEvent(event: MouseEvent) void {
    const next = (queue_head + 1) % EVENT_QUEUE_SIZE;
    if (next == queue_tail) {
        queue_tail = (queue_tail + 1) % EVENT_QUEUE_SIZE;
    }
    event_queue[queue_head] = event;
    queue_head = next;
    total_events += 1;
}

pub fn popEvent() ?MouseEvent {
    if (queue_head == queue_tail) return null;
    const event = event_queue[queue_tail];
    queue_tail = (queue_tail + 1) % EVENT_QUEUE_SIZE;
    return event;
}

pub fn hasEvents() bool {
    return queue_head != queue_tail;
}

pub fn getState() *const MouseState {
    return &mouse_state;
}

pub fn setScreenBounds(width: i32, height: i32) void {
    mouse_state.screen_width = width;
    mouse_state.screen_height = height;
    if (mouse_state.x >= width) mouse_state.x = width - 1;
    if (mouse_state.y >= height) mouse_state.y = height - 1;
}

pub fn setPosition(x: i32, y: i32) void {
    mouse_state.x = x;
    mouse_state.y = y;
}

pub fn getX() i32 {
    return mouse_state.x;
}

pub fn getY() i32 {
    return mouse_state.y;
}

pub fn isLeftPressed() bool {
    return mouse_state.left_pressed;
}

pub fn isRightPressed() bool {
    return mouse_state.right_pressed;
}

fn mouseDispatch(irp: *io.Irp) io.IoStatus {
    switch (irp.major_function) {
        .create, .close => {
            irp.complete(.success, 0);
            return .success;
        },
        .ioctl => return handleIoctl(irp),
        .read => {
            if (popEvent()) |event| {
                irp.buffer_ptr = @as(u64, @intCast(@as(u32, @bitCast([2]u16{ @bitCast(event.dx), @bitCast(event.dy) }))));
                irp.bytes_transferred = @intCast(event.buttons);
                irp.complete(.success, 1);
            } else {
                irp.complete(.success, 0);
            }
            return .success;
        },
        else => {
            irp.complete(.not_implemented, 0);
            return .not_implemented;
        },
    }
}

fn handleIoctl(irp: *io.Irp) io.IoStatus {
    switch (irp.ioctl_code) {
        IOCTL_MOUSE_GET_STATE => {
            irp.buffer_ptr = @bitCast([2]u32{
                @bitCast(mouse_state.x),
                @bitCast(mouse_state.y),
            });
            irp.bytes_transferred = mouse_state.buttons;
            irp.complete(.success, 0);
            return .success;
        },
        IOCTL_MOUSE_SET_BOUNDS => {
            const w: i32 = @intCast(@as(u32, @truncate(irp.buffer_ptr & 0xFFFF)));
            const h: i32 = @intCast(@as(u32, @truncate((irp.buffer_ptr >> 16) & 0xFFFF)));
            setScreenBounds(w, h);
            irp.complete(.success, 0);
            return .success;
        },
        IOCTL_MOUSE_RESET => {
            queue_head = 0;
            queue_tail = 0;
            mouse_state = .{};
            irp.complete(.success, 0);
            return .success;
        },
        else => {
            irp.complete(.not_implemented, 0);
            return .not_implemented;
        },
    }
}

pub fn isInitialized() bool {
    return driver_initialized;
}

pub fn getTotalEvents() u64 {
    return total_events;
}

pub fn init() void {
    sendCommand(0xA8);
    portio.ioWait();

    sendCommand(0x20);
    portio.ioWait();
    const config = readData();
    const new_config = (config | 0x02) & ~@as(u8, 0x20);
    sendCommand(0x60);
    sendData(new_config);

    _ = mouseWrite(0xFF);
    portio.ioWait();
    _ = readData();
    _ = readData();

    _ = mouseWrite(0xF6);

    _ = mouseWrite(0xF3);
    _ = mouseWrite(200);
    _ = mouseWrite(0xF3);
    _ = mouseWrite(100);
    _ = mouseWrite(0xF3);
    _ = mouseWrite(80);

    _ = mouseWrite(0xF2);
    portio.ioWait();
    const mouse_id = readData();
    has_scroll_wheel = (mouse_id == 3 or mouse_id == 4);

    _ = mouseWrite(0xF4);

    mouse_state.x = @divTrunc(mouse_state.screen_width, 2);
    mouse_state.y = @divTrunc(mouse_state.screen_height, 2);

    driver_idx = io.registerDriver("\\Driver\\Mouse", mouseDispatch) orelse {
        klog.err("Mouse: Failed to register driver", .{});
        return;
    };

    device_idx = io.createDevice("\\Device\\Mouse0", .mouse, driver_idx) orelse {
        klog.err("Mouse: Failed to create device", .{});
        return;
    };

    driver_initialized = true;

    klog.info("Mouse Driver: PS/2 initialized (scroll_wheel=%s)", .{
        if (has_scroll_wheel) "yes" else "no",
    });
}
