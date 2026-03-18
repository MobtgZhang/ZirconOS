pub inline fn outb(port: u16, value: u8) void {
    asm volatile ("outb %%al, %%dx"
        :
        : [value] "{al}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inb(port: u16) u8 {
    var value: u8 = 0;
    asm volatile ("inb %%dx, %%al"
        : [value] "={al}" (value)
        : [port] "{dx}" (port),
    );
    return value;
}

pub inline fn outw(port: u16, value: u16) void {
    asm volatile ("outw %%ax, %%dx"
        :
        : [value] "{ax}" (value),
          [port] "{dx}" (port),
    );
}

pub inline fn inw(port: u16) u16 {
    var value: u16 = 0;
    asm volatile ("inw %%dx, %%ax"
        : [value] "={ax}" (value)
        : [port] "{dx}" (port),
    );
    return value;
}

pub inline fn ioWait() void {
    outb(0x80, 0);
}
