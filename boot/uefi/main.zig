const std = @import("std");
const uefi = std.os.uefi;
const builtin = @import("builtin");
const unicode = std.unicode;

const arch_name = switch (builtin.target.cpu.arch) {
    .x86_64 => "x86_64",
    .aarch64 => "aarch64",
    .riscv64 => "riscv64",
    .loongarch64 => "loongarch64",
    else => "unknown",
};

const debug_mode = @import("build_options").debug;

pub fn main() noreturn {
    const st = uefi.system_table;
    const out = st.con_out orelse halt();
    const bs = st.boot_services orelse halt();

    out.reset(false) catch {};

    puts(out, "\r\n");
    puts(out, " =====================================================\r\n");
    puts(out, "      ZirconOS v1.0  UEFI Boot Manager\r\n");
    puts(out, "   NT-style Hybrid Microkernel OS (Zig lang)\r\n");
    puts(out, " =====================================================\r\n");
    puts(out, "\r\n");
    puts(out, "  Architecture : " ++ arch_name ++ "\r\n");
    puts(out, "  Boot method  : UEFI\r\n");

    if (debug_mode) {
        puts(out, "  Build mode   : DEBUG (verbose logging enabled)\r\n");
    } else {
        puts(out, "  Build mode   : RELEASE (optimized, minimal logging)\r\n");
    }

    puts(out, "  Firmware     : ");
    _ = out.outputString(st.firmware_vendor) catch false;
    puts(out, "\r\n");

    printUefiVersion(out, st.hdr.revision);

    puts(out, "\r\n");
    puts(out, "  [OK] UEFI console initialized\r\n");

    displayMemoryMap(out, bs);

    puts(out, "\r\n");
    puts(out, " --- Kernel Boot Sequence (Phase 0-11) ---\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 0] Early Init\r\n");
    puts(out, "    Serial port (COM1) + VGA text console\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 1] Boot + Early Kernel\r\n");
    puts(out, "    GDT/TSS, Frame Allocator, Kernel Heap\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 2] Trap / Timer / Scheduler\r\n");
    puts(out, "    IDT (256 vectors), PIC+PIT 100Hz, Round-Robin scheduler\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 3] VM + User Mode\r\n");
    puts(out, "    4-level paging, Identity mapping, Kernel address space\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 4] Object / Handle / Process Core\r\n");
    puts(out, "    Object Manager, Handle Table, Namespace, Security Token\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 5] IPC + System Services\r\n");
    puts(out, "    LPC ports, Process Server (PID 1), Session Manager (smss)\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 6] I/O + File System + Driver\r\n");
    puts(out, "    VFS, FAT32 (C:\\), NTFS (D:\\), Device/Driver/IRP\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 7] Loader\r\n");
    puts(out, "    PE32+ loader (DLL/EXE), ELF64 loader, Section mapping\r\n");
    puts(out, "    System DLLs: ntdll.dll, kernel32.dll, kernelbase.dll\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 8] Native Userland\r\n");
    puts(out, "    ntdll (Native API), kernel32 (Win32 API), Console Runtime\r\n");
    puts(out, "    CMD.EXE (Command Prompt), PowerShell 7.4\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 9] Win32 Subsystem\r\n");
    puts(out, "    csrss (Win32 Subsystem Server)\r\n");
    puts(out, "    Win32 App Execution Engine (PE load + DLL bind)\r\n");
    puts(out, "    Window Station / Desktop management\r\n");
    puts(out, "    FindFirstFile/FindNextFile, LoadLibrary, GetProcAddress\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 10] Graphical Subsystem\r\n");
    puts(out, "    user32 (Window management, Message queue, UI primitives)\r\n");
    puts(out, "    gdi32 (Device Contexts, Drawing, Fonts, Bitmaps)\r\n");
    puts(out, "    csrss GUI dispatch, Window Station/Desktop enhancement\r\n");
    puts(out, "    CreateWindow, GetMessage, DispatchMessage, BeginPaint\r\n");
    puts(out, "    TextOut, Rectangle, Ellipse, BitBlt, CreateFont\r\n");
    puts(out, "\r\n");

    puts(out, "  [Phase 11] WOW64 (32-bit Compatibility)\r\n");
    puts(out, "    PE32 loader (IMAGE_FILE_MACHINE_I386)\r\n");
    puts(out, "    32-bit ntdll/kernel32 shim DLLs\r\n");
    puts(out, "    wow64.dll, wow64cpu.dll, wow64win.dll\r\n");
    puts(out, "    Syscall thunking (32->64 bit translation)\r\n");
    puts(out, "    32-bit PEB/TEB, CONTEXT32, address space (2GB)\r\n");
    puts(out, "\r\n");

    puts(out, " --- File Systems ---\r\n");
    puts(out, "    C:\\ -> FAT32  (System volume, boot partition)\r\n");
    puts(out, "    D:\\ -> NTFS   (Data volume, user files)\r\n");
    puts(out, "\r\n");

    puts(out, " --- Shell Environments ---\r\n");
    puts(out, "    CMD.EXE        - Windows Command Prompt\r\n");
    puts(out, "      Commands: dir, cd, cls, echo, type, mkdir, del, ver,\r\n");
    puts(out, "                help, set, date, time, systeminfo, tasklist,\r\n");
    puts(out, "                hostname, whoami, vol, title, color, path\r\n");
    puts(out, "    PowerShell 7.4 - Advanced object-oriented shell\r\n");
    puts(out, "      Cmdlets: Get-ChildItem, Set-Location, Get-Process,\r\n");
    puts(out, "               Get-Date, Get-Help, Get-Service, Get-Command,\r\n");
    puts(out, "               New-Item, Remove-Item, Test-Path, Get-History\r\n");
    puts(out, "\r\n");

    if (debug_mode) {
        puts(out, " --- DEBUG Mode Features ---\r\n");
        puts(out, "    [*] Verbose kernel log at all levels (EMERG..DEBUG)\r\n");
        puts(out, "    [*] Dual output: VGA + Serial (COM1 0x3F8)\r\n");
        puts(out, "    [*] GDB remote debugging support (QEMU -S -s)\r\n");
        puts(out, "    [*] Object/Handle tracking and namespace dump\r\n");
        puts(out, "    [*] DbgPrint / DbgBreakPoint support\r\n");
        puts(out, "    [*] PE/ELF section and import logging\r\n");
        puts(out, "    [*] Process/Thread lifecycle tracing\r\n");
        puts(out, "    [*] IPC message tracing\r\n");
        puts(out, "\r\n");
    } else {
        puts(out, " --- RELEASE Mode ---\r\n");
        puts(out, "    [*] Optimized binary (ReleaseSafe)\r\n");
        puts(out, "    [*] Minimal logging (ERR and above only)\r\n");
        puts(out, "    [*] Reduced serial output\r\n");
        puts(out, "\r\n");
    }

    puts(out, " --- NT Compatibility Layer ---\r\n");
    puts(out, "    ntdll.dll      - Native API\r\n");
    puts(out, "      NtCreateProcess, NtTerminateProcess, NtCreateThread\r\n");
    puts(out, "      NtCreateFile, NtOpenFile, NtReadFile, NtWriteFile, NtClose\r\n");
    puts(out, "      NtCreateEvent, NtWaitForSingleObject, NtCreateSection\r\n");
    puts(out, "      NtAllocateVirtualMemory, NtFreeVirtualMemory\r\n");
    puts(out, "      NtCreatePort, NtConnectPort, NtRequestWaitReplyPort\r\n");
    puts(out, "      NtQuerySystemInformation, NtQueryInformationProcess\r\n");
    puts(out, "      RTL: RtlGetVersion, RtlNtStatusToDosError, memory utils\r\n");
    puts(out, "    kernel32.dll   - Win32 Base API\r\n");
    puts(out, "      CreateProcessA, ExitProcess, WaitForSingleObject\r\n");
    puts(out, "      CreateFileA, ReadFile, WriteFile, FindFirstFileA\r\n");
    puts(out, "      LoadLibraryA, GetProcAddress, GetModuleHandleA\r\n");
    puts(out, "      VirtualAlloc/Free, HeapAlloc/Free\r\n");
    puts(out, "      GetSystemInfo, GetVersionExA, GetEnvironmentVariableA\r\n");
    puts(out, "    kernelbase.dll - Base API forwarder\r\n");
    puts(out, "    user32.dll     - Window/Message API\r\n");
    puts(out, "      RegisterClass, CreateWindowEx, DestroyWindow, ShowWindow\r\n");
    puts(out, "      GetMessage, PeekMessage, PostMessage, DispatchMessage\r\n");
    puts(out, "      BeginPaint, EndPaint, SetFocus, MessageBox, SetTimer\r\n");
    puts(out, "    gdi32.dll      - Graphics Device Interface\r\n");
    puts(out, "      CreateDC, SelectObject, CreatePen, CreateSolidBrush\r\n");
    puts(out, "      Rectangle, Ellipse, LineTo, TextOut, BitBlt, CreateFont\r\n");
    puts(out, "    PEB/TEB        - Process/Thread Environment Block\r\n");
    puts(out, "\r\n");

    puts(out, " --- WOW64 Layer ---\r\n");
    puts(out, "    wow64.dll      - WOW64 core (syscall dispatch)\r\n");
    puts(out, "    wow64cpu.dll   - CPU context management (x86 emulation)\r\n");
    puts(out, "    wow64win.dll   - Win32k thunks\r\n");
    puts(out, "    ntdll32.dll    - 32-bit Native API shim\r\n");
    puts(out, "    kernel3232.dll - 32-bit Win32 Base API shim\r\n");
    puts(out, "\r\n");

    puts(out, " --- Boot Configuration ---\r\n");
    puts(out, "    BIOS boot  : GRUB Multiboot2 -> kernel.elf\r\n");
    puts(out, "      Modes: Normal, Debug (GDB), Serial Debug, Safe Mode\r\n");
    puts(out, "    UEFI boot  : EFI Application -> Boot Manager\r\n");
    puts(out, "      Modes: Normal, Debug (GDB), Release\r\n");
    puts(out, "    Boot chain : bootmgfw -> winload -> kernel -> HAL\r\n");
    puts(out, "              -> Executive Init -> smss -> csrss -> shell\r\n");
    puts(out, "\r\n");

    puts(out, " --- Supported Architectures ---\r\n");
    puts(out, "    x86_64   : Full (BIOS + UEFI)\r\n");
    puts(out, "    aarch64  : Boot + UART (UEFI)\r\n");
    puts(out, "    loong64  : Stub\r\n");
    puts(out, "    riscv64  : Stub\r\n");
    puts(out, "    mips64el : Stub\r\n");
    puts(out, "\r\n");

    puts(out, "  =====================================================\r\n");
    puts(out, "  ZirconOS v1.0 UEFI Boot Manager - System Ready\r\n");
    puts(out, "  All kernel phases (0-11) available for loading.\r\n");
    puts(out, "  Phase 0-8 : Core kernel + Native userland\r\n");
    puts(out, "  Phase 9   : Win32 subsystem + App execution\r\n");
    puts(out, "  Phase 10  : GUI subsystem (user32/gdi32)\r\n");
    puts(out, "  Phase 11  : WOW64 (32-bit compatibility)\r\n");
    puts(out, "  =====================================================\r\n");
    puts(out, "\r\n");
    puts(out, "  [..] Kernel image load pending (v1.1: direct UEFI->kernel)\r\n");
    puts(out, "  [!!] System halted - use BIOS/GRUB for full kernel boot.\r\n");

    halt();
}

fn displayMemoryMap(out: anytype, bs: *uefi.tables.BootServices) void {
    const info = bs.getMemoryMapInfo() catch {
        puts(out, "  Memory map   : (unavailable)\r\n");
        return;
    };

    puts(out, "  Memory map   : ");
    printDecimal(out, @intCast(info.len));
    puts(out, " entries (desc_size=");
    printDecimal(out, @intCast(info.descriptor_size));
    puts(out, ")\r\n");

    if (debug_mode) {
        puts(out, "  [DEBUG] Memory map descriptor_size=");
        printDecimal(out, @intCast(info.descriptor_size));
        puts(out, "\r\n");
    }
}

fn printUefiVersion(out: anytype, revision: u32) void {
    const major = revision >> 16;
    const minor = revision & 0xFFFF;

    puts(out, "  UEFI rev     : ");
    printDecimal(out, major);
    puts(out, ".");
    printDecimal(out, minor);
    puts(out, "\r\n");
}

fn printDecimal(out: anytype, value: u32) void {
    if (value >= 10) printDecimal(out, value / 10);
    var buf: [1:0]u16 = .{@as(u16, @intCast('0' + (value % 10)))};
    _ = out.outputString(&buf) catch false;
}

fn printHex(out: anytype, value: u32) void {
    const hex_chars = "0123456789ABCDEF";
    var i: u5 = 8;
    while (i > 0) {
        i -= 1;
        const nibble = (value >> (@as(u5, i) * 4)) & 0xF;
        var buf: [1:0]u16 = .{@as(u16, hex_chars[@intCast(nibble)])};
        _ = out.outputString(&buf) catch false;
    }
}

fn puts(out: anytype, comptime s: []const u8) void {
    _ = out.outputString(unicode.utf8ToUtf16LeStringLiteral(s)) catch false;
}

fn halt() noreturn {
    while (true) {
        switch (builtin.target.cpu.arch) {
            .x86_64 => asm volatile ("hlt"),
            .aarch64 => asm volatile ("wfi"),
            .riscv64 => asm volatile ("wfi"),
            else => {},
        }
    }
}
