const builtin = @import("builtin");
const arch = @import("arch.zig");
const klog = @import("rtl/klog.zig");

const KERNEL_END_FALLBACK: usize = 4 * 1024 * 1024;

extern const stack_top: u8;

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
    const heap = @import("mm/heap.zig");
    const server = @import("ps/server.zig");
    const smss = @import("ps/smss.zig");
    const ob = @import("ob/object.zig");
    const se = @import("se/token.zig");
    const io = @import("io/io.zig");
    const scheduler = @import("ke/scheduler.zig");
    const timer = @import("ke/timer.zig");
    const port = @import("lpc/port.zig");
    const vfs_mod = @import("fs/vfs.zig");
    const fat32_mod = @import("fs/fat32.zig");
    const ntfs_mod = @import("fs/ntfs.zig");
    const pe_loader = @import("loader/pe.zig");
    const elf_loader = @import("loader/elf.zig");
    const ntdll = @import("win32/ntdll.zig");
    const kernel32 = @import("win32/kernel32.zig");
    const console_mod = @import("win32/console.zig");
    const cmd_mod = @import("win32/cmd.zig");
    const ps_mod = @import("win32/powershell.zig");
    const subsys = @import("win32/subsystem.zig");
    const exec = @import("win32/exec.zig");
    const user32_mod = @import("win32/user32.zig");
    const gdi32_mod = @import("win32/gdi32.zig");
    const wow64_mod = @import("win32/wow64.zig");

    // ═══ Phase 0: Early Init ═══
    arch.initSerial();
    arch.consoleClear();

    klog.info("========================================", .{});
    klog.info("  ZirconOS v1.0 (NT-style Hybrid Microkernel)", .{});
    klog.info("  Architecture: x86_64", .{});
    klog.info("========================================", .{});

    if (klog.DEBUG_MODE) {
        klog.info("Build: DEBUG mode (verbose logging enabled)", .{});
    } else {
        klog.info("Build: RELEASE mode (optimized)", .{});
    }

    // ═══ Phase 1: Boot Verification + Hardware Init ═══
    klog.info("--- Phase 1: Boot + Early Kernel ---", .{});

    if (magic != boot.MULTIBOOT2_BOOTLOADER_MAGIC) {
        klog.err("Invalid multiboot2 magic: 0x%x (expected 0x%x)", .{
            magic, boot.MULTIBOOT2_BOOTLOADER_MAGIC,
        });
        arch.halt();
    }

    const kernel_stack_addr = @intFromPtr(&stack_top);
    arch.initGdt(kernel_stack_addr);
    klog.info("GDT/TSS initialized (kernel stack=0x%x)", .{kernel_stack_addr});

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
    klog.info("Frame allocator: total_frames=%u, frame_size=%u", .{
        alloc.total_frames, frame.FRAME_SIZE,
    });

    heap.init();
    klog.info("Kernel heap: %u bytes available", .{heap.freeBytes()});

    // ═══ Phase 2: Trap / Timer / Scheduler ═══
    klog.info("--- Phase 2: Trap / Timer / Scheduler ---", .{});

    scheduler.init();

    if (@import("build_options").enable_idt) {
        const idt = @import("arch/x86_64/idt.zig");
        idt.init();
        klog.info("IDT initialized (256 vectors, vector 128 = syscall)", .{});

        timer.init();
        klog.info("Timer: PIC + PIT ready (~100Hz)", .{});

        arch.enableInterrupts();
        klog.info("Interrupts enabled", .{});
    }

    // ═══ Phase 3: VM + User Mode ═══
    klog.info("--- Phase 3: VM + User Mode ---", .{});

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
            klog.err("Identity map failed at 0x%x", .{virt});
            arch.halt();
        }
    }
    klog.info("VM: Identity mapping 0-%uMB OK", .{identity_pages * paging.page_size / (1024 * 1024)});

    kernel_space.activate();
    klog.info("VM: Kernel page tables loaded", .{});

    // ═══ Phase 4: Object / Handle / Process Core ═══
    klog.info("--- Phase 4: Object / Handle / Process Core ---", .{});

    ob.init();
    ob.initNamespace();
    se.init();
    io.init();

    // ═══ Phase 5: IPC + System Services ═══
    klog.info("--- Phase 5: IPC + System Services ---", .{});

    server.init(&alloc);

    _ = port.createPort(1, "\\LPC\\PsServer");
    _ = port.createPort(1, "\\LPC\\ObServer");
    _ = port.createPort(1, "\\LPC\\IoServer");
    klog.info("LPC: System service ports created", .{});

    smss.init(&alloc);

    // ═══ Phase 6: I/O + File System + Driver ═══
    klog.info("--- Phase 6: I/O + File + Driver ---", .{});

    vfs_mod.init();
    fat32_mod.init();
    ntfs_mod.init();

    klog.info("File Systems: FAT32 (C:\\) + NTFS (D:\\) mounted", .{});
    klog.info("VFS: %u mount points, %u open files", .{
        vfs_mod.getMountCount(), vfs_mod.getFileCount(),
    });

    // ═══ Phase 7: Loader (Enhanced) ═══
    klog.info("--- Phase 7: Loader (PE/ELF Enhanced) ---", .{});

    elf_loader.init();
    pe_loader.init();

    klog.info("Loader: ELF=%u images, PE=%u images (%u DLLs)", .{
        elf_loader.getImageCount(), pe_loader.getImageCount(), pe_loader.getDllCount(),
    });

    // ═══ Phase 8: Native Userland (Enhanced) ═══
    klog.info("--- Phase 8: Native Userland (Enhanced) ---", .{});

    ntdll.init();
    kernel32.init();
    console_mod.init();
    cmd_mod.init();
    ps_mod.init();

    // ═══ Phase 9: Win32 Subsystem ═══
    klog.info("--- Phase 9: Win32 Subsystem ---", .{});

    subsys.init();
    exec.init();

    // ═══ Phase 10: Graphical Subsystem ═══
    klog.info("--- Phase 10: Graphical Subsystem ---", .{});

    user32_mod.init();
    gdi32_mod.init();
    subsys.initGuiSubsystem();

    klog.info("GUI: user32 + gdi32 initialized", .{});
    klog.info("GUI: Window classes=%u, GDI stock objects=%u", .{
        user32_mod.getClassCount(), gdi32_mod.getGdiObjectCount(),
    });

    // ═══ Phase 11: WOW64 ═══
    klog.info("--- Phase 11: WOW64 (32-bit Compatibility) ---", .{});

    wow64_mod.init();

    klog.info("WOW64: PE32 support active, thunk table=%u entries", .{
        wow64_mod.getThunkCount(),
    });

    // ═══ Boot Complete Summary ═══
    klog.info("", .{});
    klog.info("=== ZirconOS v1.0 Kernel Ready (Phase 0-11) ===", .{});
    klog.info("Architecture : x86_64", .{});
    klog.info("Boot method  : BIOS/Multiboot2", .{});
    if (klog.DEBUG_MODE) {
        klog.info("Build mode   : DEBUG", .{});
    } else {
        klog.info("Build mode   : RELEASE", .{});
    }
    klog.info("", .{});
    klog.info("Kernel Modules:", .{});
    klog.info("  ke  : scheduler, timer, interrupt, sync", .{});
    klog.info("  mm  : frame allocator, virtual memory, heap", .{});
    klog.info("  ob  : object manager, handle table, namespace, waitable", .{});
    klog.info("  ps  : process manager, server, session manager (smss)", .{});
    klog.info("  se  : security token, SID, access check", .{});
    klog.info("  io  : device/driver objects, IRP dispatch", .{});
    klog.info("  lpc : IPC message passing, LPC ports", .{});
    klog.info("  fs  : VFS, FAT32 (C:\\), NTFS (D:\\)", .{});
    klog.info("  ldr : PE32/PE32+ loader (DLL/EXE), ELF64 loader", .{});
    klog.info("  win32: ntdll, kernel32, console, CMD, PowerShell", .{});
    klog.info("  csrss: Win32 subsystem server, window station, desktops", .{});
    klog.info("  exec : Win32 app execution engine, DLL binding", .{});
    klog.info("  user32: window management, message queue, UI primitives", .{});
    klog.info("  gdi32: device contexts, drawing, fonts, bitmaps", .{});
    klog.info("  wow64: 32-bit compatibility, thunking, PE32 support", .{});
    klog.info("", .{});
    klog.info("System Status:", .{});
    klog.info("  Processes  : %u", .{@import("ps/process.zig").getProcessCount()});
    klog.info("  Sessions   : %u", .{smss.getSessionCount()});
    klog.info("  Heap       : %u/%u bytes used", .{ heap.usedBytes(), heap.totalBytes() });
    klog.info("  Mounts     : %u file systems", .{vfs_mod.getMountCount()});
    klog.info("  PE Images  : %u total (%u DLLs, %u EXEs)", .{
        pe_loader.getImageCount(), pe_loader.getDllCount(), pe_loader.getExeCount(),
    });
    klog.info("  ELF Images : %u total (%u shared objects)", .{
        elf_loader.getImageCount(), elf_loader.getSharedCount(),
    });
    klog.info("  Consoles   : %u", .{console_mod.getConsoleCount()});
    klog.info("  Win32 Procs: %u registered", .{subsys.getWin32ProcessCount()});
    klog.info("  WinStations: %u", .{subsys.getStationCount()});
    klog.info("  Desktops   : %u", .{subsys.getTotalDesktopCount()});
    klog.info("  GUI Windows: %u", .{user32_mod.getWindowCount()});
    klog.info("  GDI Objects: %u", .{gdi32_mod.getGdiObjectCount()});
    klog.info("  WOW64 Procs: %u (thunks=%u)", .{
        wow64_mod.getActiveWow64Count(), wow64_mod.getThunkCount(),
    });
    klog.info("  PE32 Images: %u (32-bit), PE64: %u (64-bit)", .{
        pe_loader.getPe32Count(), pe_loader.getPe64Count(),
    });
    klog.info("", .{});

    // ═══ Boot Shell Sequence ═══
    klog.info("--- Starting CMD Shell ---", .{});
    klog.info("", .{});

    cmd_mod.runBootSequence();

    klog.info("", .{});
    klog.info("--- Starting PowerShell Session ---", .{});
    klog.info("", .{});

    ps_mod.runBootSequence();

    // ═══ Phase 9: Win32 App Demo ═══
    klog.info("", .{});
    klog.info("--- Phase 9: Win32 Application Execution Demo ---", .{});
    klog.info("", .{});

    exec.runDemoApps();

    // ═══ Phase 10: GUI Demo ═══
    klog.info("", .{});
    klog.info("--- Phase 10: Graphical Subsystem Demo ---", .{});
    klog.info("", .{});

    gdi32_mod.runGdiDemo();
    user32_mod.runGuiDemo();

    // ═══ Phase 11: WOW64 Demo ═══
    klog.info("", .{});
    klog.info("--- Phase 11: WOW64 Compatibility Demo ---", .{});
    klog.info("", .{});

    wow64_mod.runWow64Demo();

    // ═══ System Ready ═══
    klog.info("", .{});
    klog.info("=== System Ready (Phase 0-11 Complete) ===", .{});
    klog.info("Win32 subsystem: %u processes, %u API calls", .{
        subsys.getWin32ProcessCount(), subsys.getApiCallCount(),
    });
    klog.info("Exec engine: %u apps launched, %u running", .{
        exec.getTotalLaunched(), exec.getRunningCount(),
    });
    klog.info("GUI subsystem: %u windows, %u messages, %u GDI draw calls", .{
        user32_mod.getTotalWindowsCreated(),
        user32_mod.getTotalMessagesProcessed(),
        gdi32_mod.getTotalDrawCalls(),
    });
    klog.info("WOW64: %u 32-bit processes, %u syscall translations", .{
        wow64_mod.getTotalWow64Count(),
        wow64_mod.getTotalSyscallTranslations(),
    });

    // Main kernel loop
    while (true) {
        server.handleMessage();
        smss.handleMessage();
        subsys.handleMessage();
        asm volatile ("hlt");
    }
}

fn startAarch64() noreturn {
    const uart = @import("hal/aarch64/uart.zig");
    uart.init();
    uart.write("========================================\n");
    uart.write("  ZirconOS v1.0 (aarch64) booting...\n");
    uart.write("  NT-style Hybrid Microkernel\n");
    uart.write("========================================\n");
    uart.write("\n");
    uart.write("Kernel modules (Phase 0-11):\n");
    uart.write("  ke mm ob ps se io lpc fs ldr win32 csrss exec\n");
    uart.write("  user32 gdi32 wow64\n");
    uart.write("\n");
    uart.write("System halted.\n");
    arch.halt();
}

fn startStub() noreturn {
    arch.halt();
}
