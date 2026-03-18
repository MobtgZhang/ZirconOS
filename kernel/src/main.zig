const builtin = @import("builtin");
const arch = @import("arch.zig");
const klog = @import("rtl/klog.zig");

const KERNEL_END_FALLBACK: usize = 4 * 1024 * 1024;

comptime {
    switch (builtin.target.cpu.arch) {
        .aarch64 => _ = @import("arch/aarch64/mod.zig"),
        .loongarch64 => _ = @import("arch/loong64/mod.zig"),
        .riscv64 => _ = @import("arch/riscv64/mod.zig"),
        .mips64el => _ = @import("arch/mips64el/mod.zig"),
        else => {},
    }
}

pub export fn kernel_main(magic: u32, info_addr: usize) callconv(.c) noreturn {
    switch (builtin.target.cpu.arch) {
        .x86_64 => startX86_64(magic, info_addr),
        .aarch64 => startAarch64(),
        else => startStub(),
    }
}

fn startX86_64(magic: u32, info_addr: usize) noreturn {
    const boot = arch.impl.boot;
    const paging = arch.impl.paging;
    const frame = @import("mm/frame.zig");
    const vm = @import("mm/vm.zig");
    const server = @import("ps/server.zig");

    arch.consoleClear();

    if (magic != boot.MULTIBOOT2_BOOTLOADER_MAGIC) {
        arch.consoleWrite("Invalid multiboot magic!\n");
        arch.halt();
    }

    klog.info("ZirconOS v1.0 (NT-style Microkernel / x86_64) booting...", .{});
    if (klog.DEBUG_MODE) {
        klog.info("Debug mode: ON", .{});
    }

    const kernel_end = KERNEL_END_FALLBACK;
    const boot_info = boot.parse(info_addr);
    if (boot_info) |info| {
        klog.info("Multiboot2: mem_lower=%u KB, mem_upper=%u KB, mmap_entries=%u", .{
            info.mem_lower_kb,
            info.mem_upper_kb,
            info.mmap_entry_count,
        });
    }

    var alloc: frame.FrameAllocator = undefined;
    alloc.init(boot_info, kernel_end, info_addr);
    klog.info("Frame allocator: total_frames=%u", .{alloc.total_frames});

    var kernel_space = vm.createAddressSpace(&alloc) orelse {
        klog.err("Failed to create kernel address space", .{});
        arch.halt();
    };

    const identity_pages: usize = 1024;
    var i: usize = 0;
    while (i < identity_pages) : (i += 1) {
        const virt = i * paging.page_size;
        const flags = vm.MapFlags{ .writable = true, .executable = true };
        if (!kernel_space.mapPage(virt, virt, flags)) {
            klog.err("Identity map failed at virt=0x%x", .{virt});
            arch.halt();
        }
    }
    klog.info("Identity mapping: 0-4MB OK", .{});

    kernel_space.activate();
    enablePagingX86();
    klog.info("Paging enabled", .{});

    server.init(&alloc);

    if (@import("build_options").enable_idt) {
        const idt = @import("arch/x86_64/idt.zig");
        idt.init();
        klog.info("IDT initialized", .{});
    }

    klog.info("=== ZirconOS v1.0 Kernel Ready ===", .{});
    klog.info("Architecture: x86_64", .{});
    klog.info("Modules: ke(sched/timer/intr) mm(frame/vm) ps(proc/server) lpc(ipc) ob se io", .{});

    while (true) {
        server.handleMessage();
        asm volatile ("hlt");
    }
}

fn enablePagingX86() void {
    asm volatile (
        \\ mov %%cr0, %%rax
        \\ or $0x80000000, %%eax
        \\ mov %%rax, %%cr0
        :
        :
        : .{ .rax = true, .memory = true }
    );
}

fn startAarch64() noreturn {
    const uart = @import("hal/aarch64/uart.zig");
    uart.init();
    uart.write("ZirconOS v1.0 (aarch64) booting...\n");
    uart.write("NT-style Microkernel / AArch64 stub\n");
    arch.halt();
}

fn startStub() noreturn {
    arch.halt();
}
