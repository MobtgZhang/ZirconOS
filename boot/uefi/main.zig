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

// ── ZirconOS Boot Manager Constants ──

const ZBM_VERSION = "1.0";
const TIMER_INTERVAL: u64 = 10_000_000; // 1 second in 100ns units
const DEFAULT_TIMEOUT: u32 = 10;
const MAX_ENTRIES: usize = 8;

const KERNEL_PATH = "\\boot\\kernel.elf";
const BCD_PATH = "\\boot\\BCD";

// ── Boot Entry ──

const BootEntry = struct {
    description: []const u8,
    kernel_path: []const u8,
    cmdline: []const u8,
    is_default: bool,
};

// ── Boot Manager State ──

var entries: [MAX_ENTRIES]BootEntry = undefined;
var entry_count: usize = 0;
var selected: usize = 0;
var countdown: u32 = DEFAULT_TIMEOUT;
var timer_active: bool = true;

fn initBootEntries() void {
    addEntry("ZirconOS v1.0", KERNEL_PATH, "console=serial,vga debug=0", true);
    addEntry("ZirconOS v1.0 [Debug Mode]", KERNEL_PATH, "console=serial,vga debug=1 verbose=1", false);
    addEntry("ZirconOS v1.0 [Safe Mode]", KERNEL_PATH, "safe_mode=1 debug=0 minimal=1", false);
    addEntry("ZirconOS v1.0 [Safe Mode with Networking]", KERNEL_PATH, "safe_mode=1 network=1", false);
    addEntry("ZirconOS v1.0 [Recovery Console]", KERNEL_PATH, "recovery=1 console=serial,vga debug=1", false);
    addEntry("ZirconOS v1.0 [Last Known Good Configuration]", KERNEL_PATH, "lastknowngood=1", false);
}

fn addEntry(desc: []const u8, path: []const u8, cmdline: []const u8, is_default: bool) void {
    if (entry_count >= MAX_ENTRIES) return;
    entries[entry_count] = .{
        .description = desc,
        .kernel_path = path,
        .cmdline = cmdline,
        .is_default = is_default,
    };
    entry_count += 1;
}

// ── UEFI Boot Manager Entry Point ──

pub fn main() noreturn {
    const st = uefi.system_table;
    const out = st.con_out orelse halt();
    const bs = st.boot_services orelse halt();

    out.reset(false) catch {};

    // Set console mode to 80x25 (mode 0) if available
    _ = out.setMode(0) catch {};

    initBootEntries();

    // ── Display Boot Manager Menu ──
    displayBootManagerMenu(out);

    // ── Interactive Menu Loop ──
    const cin = st.con_in orelse {
        // No input — auto-boot default after display
        displayBootProgress(out);
        halt();
    };

    while (true) {
        // Check for keypress
        if (readKey(cin)) |key| {
            timer_active = false;

            switch (key.scan_code) {
                0x01 => { // Up arrow
                    if (selected > 0) selected -= 1;
                    displayBootManagerMenu(out);
                },
                0x02 => { // Down arrow
                    if (selected + 1 < entry_count) selected += 1;
                    displayBootManagerMenu(out);
                },
                0x0D => { // Enter (scan code for some UEFI)
                    break; // Boot selected
                },
                0x17 => { // ESC
                    displayAdvancedOptions(out);
                },
                else => {
                    if (key.unicode_char == '\r' or key.unicode_char == '\n') {
                        break; // Boot selected
                    }
                    // Number keys 1-6
                    if (key.unicode_char >= '1' and key.unicode_char <= '6') {
                        const idx: usize = key.unicode_char - '1';
                        if (idx < entry_count) {
                            selected = idx;
                            break;
                        }
                    }
                },
            }
        }

        // Timer tick (simple busy wait, ~1 second intervals)
        if (timer_active) {
            waitOneSecond(bs);
            if (countdown > 0) {
                countdown -= 1;
                updateTimerDisplay(out);
            } else {
                break; // Timeout: boot default
            }
        }
    }

    // ── Boot the selected entry ──
    out.reset(false) catch {};
    displayBootProgress(out);

    // Attempt to load kernel from ESP
    loadAndBootKernel(out, bs);

    // If kernel load failed, show error
    puts(out, "\r\n");
    puts(out, "  [!!] Failed to load kernel image.\r\n");
    puts(out, "  [!!] Please use GRUB for full kernel boot.\r\n");
    puts(out, "  [!!] System halted.\r\n");
    halt();
}

// ── Menu Display ──

fn displayBootManagerMenu(out: anytype) void {
    out.reset(false) catch {};

    // Set text attribute: white on blue for header
    _ = out.setAttribute(0x1F) catch {};

    puts(out, "\r\n");
    puts(out, "                    ZirconOS Boot Manager                                     \r\n");
    puts(out, "                         Version " ++ ZBM_VERSION ++ "                                             \r\n");

    // Reset to normal text
    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");
    puts(out, "    Choose an operating system to start:\r\n");
    puts(out, "    (Use the arrow keys to highlight your choice, then press ENTER.)\r\n");
    puts(out, "\r\n");

    // Display entries
    for (0..entry_count) |i| {
        if (i == selected) {
            _ = out.setAttribute(0x70) catch {}; // Highlighted
            puts(out, "  > ");
        } else {
            _ = out.setAttribute(0x07) catch {}; // Normal
            puts(out, "    ");
        }
        puts(out, entries[i].description);
        puts(out, "\r\n");
    }

    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");
    puts(out, "    ");
    for (0..72) |_| puts(out, "-");
    puts(out, "\r\n\r\n");

    // Timer
    if (timer_active and countdown > 0) {
        _ = out.setAttribute(0x0E) catch {}; // Yellow
        puts(out, "    Seconds until the highlighted choice will be started automatically: ");
        printDecimal(out, countdown);
        puts(out, "\r\n");
    }

    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");

    // Description of selected entry
    _ = out.setAttribute(0x0B) catch {}; // Light cyan
    puts(out, "    ");
    displayEntryDescription(out, selected);
    puts(out, "\r\n");

    // Footer
    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");
    _ = out.setAttribute(0x17) catch {}; // White on blue
    puts(out, "  ENTER=Choose | ESC=Advanced Options | F1=Help                                \r\n");
    _ = out.setAttribute(0x07) catch {};

    // System info
    puts(out, "\r\n");
    puts(out, "    Architecture: " ++ arch_name ++ "  |  Boot: UEFI");
    if (debug_mode) {
        puts(out, "  |  Build: DEBUG\r\n");
    } else {
        puts(out, "  |  Build: RELEASE\r\n");
    }
}

fn displayEntryDescription(out: anytype, index: usize) void {
    if (index == 0) {
        puts(out, "Start ZirconOS normally.");
    } else if (index == 1) {
        puts(out, "Start with debug logging and serial output enabled.");
    } else if (index == 2) {
        puts(out, "Start with minimal drivers and services.");
    } else if (index == 3) {
        puts(out, "Start in safe mode with network support.");
    } else if (index == 4) {
        puts(out, "Start the Recovery Console for system repair.");
    } else if (index == 5) {
        puts(out, "Use the last configuration that worked.");
    }
}

fn updateTimerDisplay(out: anytype) void {
    // Redraw the full menu for simplicity (UEFI text output has no cursor positioning)
    displayBootManagerMenu(out);
}

fn displayAdvancedOptions(out: anytype) void {
    out.reset(false) catch {};
    _ = out.setAttribute(0x1F) catch {};
    puts(out, "\r\n");
    puts(out, "                ZirconOS Advanced Boot Options                                 \r\n");
    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");
    puts(out, "    Boot Information:\r\n");
    puts(out, "      Architecture : " ++ arch_name ++ "\r\n");
    puts(out, "      Boot Method  : UEFI Application\r\n");
    puts(out, "      Firmware     : ");
    _ = out.outputString(uefi.system_table.firmware_vendor) catch false;
    puts(out, "\r\n");

    printUefiVersion(out, uefi.system_table.hdr.revision);

    puts(out, "\r\n");
    puts(out, "    Partition Information:\r\n");
    puts(out, "      Scheme       : GPT (GUID Partition Table)\r\n");
    puts(out, "      Boot Partition: EFI System Partition (ESP)\r\n");
    puts(out, "      Kernel Path  : " ++ KERNEL_PATH ++ "\r\n");
    puts(out, "\r\n");
    puts(out, "    Boot Configuration Data (BCD):\r\n");
    puts(out, "      Store        : In-memory (default entries)\r\n");
    puts(out, "      Entries      : ");
    printDecimal(out, @intCast(entry_count));
    puts(out, "\r\n");
    puts(out, "      Default      : ");
    puts(out, entries[0].description);
    puts(out, "\r\n");
    puts(out, "      Timeout      : ");
    printDecimal(out, DEFAULT_TIMEOUT);
    puts(out, " seconds\r\n");
    puts(out, "\r\n");

    if (debug_mode) {
        puts(out, "    Debug Features:\r\n");
        puts(out, "      [*] Verbose kernel log (EMERG..DEBUG)\r\n");
        puts(out, "      [*] Dual output: VGA + Serial (COM1)\r\n");
        puts(out, "      [*] GDB remote debugging support\r\n");
        puts(out, "\r\n");
    }

    puts(out, "    Supported Boot Paths:\r\n");
    puts(out, "      UEFI    : EFI Application -> ZBM -> kernel.elf (GPT)\r\n");
    puts(out, "      BIOS    : MBR -> VBR -> stage2 -> ZBM -> kernel.elf\r\n");
    puts(out, "      GRUB    : GRUB2 Multiboot2 -> kernel.elf\r\n");
    puts(out, "\r\n");

    puts(out, "    Boot Chain:\r\n");
    puts(out, "      zbmfw.efi -> zbmload -> kernel -> HAL\r\n");
    puts(out, "        -> Executive Init -> smss -> csrss -> shell\r\n");
    puts(out, "\r\n");
    puts(out, "    Kernel Phases (0-11):\r\n");
    puts(out, "      0: Early Init          6: I/O + FS + Drivers\r\n");
    puts(out, "      1: Boot + Hardware     7: PE/ELF Loader\r\n");
    puts(out, "      2: Trap/Timer/Sched    8: Native Userland\r\n");
    puts(out, "      3: VM + User Mode      9: Win32 Subsystem\r\n");
    puts(out, "      4: Object/Handle      10: GUI (user32/gdi32)\r\n");
    puts(out, "      5: IPC + Services     11: WOW64 (32-bit)\r\n");
    puts(out, "\r\n");

    _ = out.setAttribute(0x17) catch {};
    puts(out, "  Press any key to return to boot menu...                                     \r\n");
    _ = out.setAttribute(0x07) catch {};

    // Wait for keypress
    if (uefi.system_table.con_in) |cin| {
        waitForKey(cin);
    }

    timer_active = false;
    displayBootManagerMenu(out);
}

// ── Boot Progress Display ──

fn displayBootProgress(out: anytype) void {
    _ = out.setAttribute(0x1F) catch {};
    puts(out, "\r\n");
    puts(out, "                    ZirconOS Boot Manager                                     \r\n");
    _ = out.setAttribute(0x07) catch {};
    puts(out, "\r\n");
    puts(out, "    Booting: ");
    puts(out, entries[selected].description);
    puts(out, "\r\n\r\n");
    puts(out, "    Command line: ");
    puts(out, entries[selected].cmdline);
    puts(out, "\r\n\r\n");

    puts(out, "    [*] UEFI Console initialized\r\n");

    displayMemoryMap(out, uefi.system_table.boot_services orelse return);

    puts(out, "    [*] Loading kernel image...\r\n");
    puts(out, "    [*] Path: " ++ KERNEL_PATH ++ "\r\n");
    puts(out, "\r\n");
}

// ── Kernel Loading (UEFI) ──

fn loadAndBootKernel(out: anytype, bs: *uefi.tables.BootServices) void {
    _ = out;
    _ = bs;

    // TODO: Implement UEFI file protocol to load kernel.elf from ESP
    //
    // Implementation outline:
    //   1. Get loaded image protocol to find boot device
    //   2. Open Simple File System protocol on boot device
    //   3. Open volume root
    //   4. Open kernel.elf file
    //   5. Read ELF header, parse program headers
    //   6. Allocate pages for each LOAD segment
    //   7. Read segments into memory
    //   8. Build Multiboot2-compatible boot info structure
    //   9. Exit boot services
    //  10. Jump to kernel entry point with magic + info pointer
    //
    // This will be implemented in the next iteration when the
    // kernel supports direct UEFI boot handoff.
}

// ── UEFI Helper Functions ──

fn readKey(cin: anytype) ?uefi.protocols.InputKey {
    var key: uefi.protocols.InputKey = undefined;
    if (cin.readKeyStroke(&key)) |_| {
        return key;
    } else |_| {
        return null;
    }
}

fn waitForKey(cin: anytype) void {
    while (true) {
        if (readKey(cin) != null) return;
    }
}

fn waitOneSecond(bs: *uefi.tables.BootServices) void {
    _ = bs;
    // Simple busy loop fallback
    var i: u64 = 0;
    while (i < 100_000_000) : (i += 1) {
        asm volatile ("" ::: "memory");
    }
}

fn displayMemoryMap(out: anytype, bs: *uefi.tables.BootServices) void {
    const info = bs.getMemoryMapInfo() catch {
        puts(out, "    [!] Memory map unavailable\r\n");
        return;
    };

    puts(out, "    [*] Memory map: ");
    printDecimal(out, @intCast(info.len));
    puts(out, " entries\r\n");
}

fn printUefiVersion(out: anytype, revision: u32) void {
    const major = revision >> 16;
    const minor = revision & 0xFFFF;

    puts(out, "      UEFI Rev     : ");
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
