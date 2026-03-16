const UART0_BASE: usize = 0x0900_0000; // QEMU virt machine PL011 UART

fn reg(offset: usize) *volatile u32 {
    return @ptrFromInt(UART0_BASE + offset);
}

const DR_OFFSET = 0x00;
const FR_OFFSET = 0x18;
const FR_TXFF: u32 = 1 << 5;

pub fn init() void {
    // 对 PL011 来说，QEMU 默认已经初始化为 115200 8N1，这里先不改波特率等配置。
}

fn writeByte(b: u8) void {
    // 等待 TX FIFO 有空位
    while (reg(FR_OFFSET).* & FR_TXFF != 0) {}
    reg(DR_OFFSET).* = b;
}

pub fn write(s: []const u8) void {
    for (s) |c| {
        if (c == '\n') writeByte('\r');
        writeByte(c);
    }
}

