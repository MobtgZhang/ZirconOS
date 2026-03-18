//! 8254 PIT (Programmable Interval Timer)
//! Channel 0 produces periodic interrupts at ~100Hz

const portio = @import("portio.zig");

const PIT_CH0: u16 = 0x40;
const PIT_CMD: u16 = 0x43;

const CMD_CH0: u8 = 0x00;
const CMD_LOHI: u8 = 0x30;
const CMD_SQUARE: u8 = 0x06;

const PIT_FREQ: u32 = 1193182;

pub fn init() void {
    const divisor: u16 = @intCast(PIT_FREQ / 100);
    portio.outb(PIT_CMD, CMD_CH0 | CMD_LOHI | CMD_SQUARE);
    portio.outb(PIT_CH0, @as(u8, @truncate(divisor)));
    portio.outb(PIT_CH0, @as(u8, @truncate(divisor >> 8)));
}
