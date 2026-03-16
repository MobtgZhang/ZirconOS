const builtin = @import("builtin");

/// 内核主入口。x86_64 时作为 _start 被 GRUB Multiboot2 调用；其他架构由各 arch/entry.zig 调用。
pub export fn kernel_main(magic: u32, info_addr: usize) callconv(.c) noreturn {
    switch (builtin.target.cpu.arch) {
        .x86_64 => start_x86_64(magic, info_addr),
        .aarch64 => start_aarch64(),
        else => unreachable, // 目前只支持 x86_64 与 aarch64 两条启动路径
    }
}

fn start_x86_64(magic: u32, info_addr: usize) noreturn {
    const vga = @import("hal/x86_64/vga_text.zig");
    const mb2 = @import("arch/x86_64/multiboot2.zig");

    vga.clear();

    if (magic != mb2.MULTIBOOT2_BOOTLOADER_MAGIC) {
        vga.write("Hello  ZirconOS!\n");
        hang_x86();
    }

    _ = info_addr; // 预留：后续解析 multiboot2 信息结构
    vga.write("Hello  ZirconOS!\n");

    hang_x86();
}

fn start_aarch64() noreturn {
    const uart = @import("hal/arm64/uart_pl011.zig");
    const Arch = @import("arch/arm64/mod.zig").Arch;

    uart.init();
    uart.write("ZirconOS kernel (");
    uart.write(Arch.name);
    uart.write(") booting...\n");
    uart.write("Hello ZirconOS from AArch64!\n");

    hang_aarch64();
}

fn hang_x86() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

fn hang_aarch64() noreturn {
    while (true) {
        asm volatile ("wfi");
    }
}
