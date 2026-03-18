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
