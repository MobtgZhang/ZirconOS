//! Multiboot2 header and boot info parsing for x86_64
//! Reference: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

pub const MULTIBOOT2_BOOTLOADER_MAGIC: u32 = 0x36d76289;

extern const multiboot2_header: [48]u8;

pub const BootInfoHeader = struct {
    total_size: u32,
    reserved: u32,
};

pub const TagHeader = struct {
    type: u32,
    size: u32,
};

pub const TagType = enum(u32) {
    end = 0,
    cmdline = 1,
    boot_loader_name = 2,
    module = 3,
    basic_meminfo = 4,
    bootdev = 5,
    mmap = 6,
    vbe = 7,
    framebuffer = 8,
    elf_sections = 9,
    apm = 10,
    efi32 = 11,
    efi64 = 12,
    smbios = 13,
    acpi_old = 14,
    acpi_new = 15,
    network = 16,
    efi_mmap = 17,
    efi_bs_not_term = 18,
    efi32_ih = 19,
    efi64_ih = 20,
    load_base_addr = 21,
};

pub const BasicMemInfoTag = struct {
    type: u32,
    size: u32,
    mem_lower: u32,
    mem_upper: u32,
};

pub const MmapEntryType = enum(u32) {
    available = 1,
    reserved = 2,
    acpi_reclaimable = 3,
    nvs = 4,
    bad = 5,
    _,
};

pub const MmapEntry = struct {
    base_addr: u64,
    length: u64,
    type: u32,
    reserved: u32,
};

pub const MmapTag = struct {
    type: u32,
    size: u32,
    entry_size: u32,
    entry_version: u32,
};

pub const FramebufferInfo = struct {
    addr: u64,
    pitch: u32,
    width: u32,
    height: u32,
    bpp: u8,
    fb_type: u8, // 0=indexed, 1=RGB, 2=EGA text
};

pub const BootMode = enum {
    normal,
    cmd,
    powershell,
};

pub const BootInfo = struct {
    mem_lower_kb: u32,
    mem_upper_kb: u32,
    mmap_ptr: [*]const u8,
    mmap_entry_count: usize,
    mmap_entry_size: u32,
    cmdline_ptr: ?[*]const u8 = null,
    cmdline_len: usize = 0,
    boot_mode: BootMode = .normal,
    fb_info: ?FramebufferInfo = null,

    pub fn getMmapEntry(self: BootInfo, i: usize) ?MmapEntry {
        if (i >= self.mmap_entry_count or self.mmap_entry_size < 24) return null;
        const ptr = self.mmap_ptr + i * self.mmap_entry_size;
        return @as(*const MmapEntry, @alignCast(@ptrCast(ptr))).*;
    }
};

pub fn parse(phys_addr: usize) ?BootInfo {
    const addr = phys_addr & ~@as(usize, 7);
    const header = @as(*const BootInfoHeader, @ptrFromInt(addr));
    if (header.total_size < 8) return null;

    var info: BootInfo = .{
        .mem_lower_kb = 0,
        .mem_upper_kb = 0,
        .mmap_ptr = undefined,
        .mmap_entry_count = 0,
        .mmap_entry_size = 0,
    };

    var offset: usize = 8;
    const total = header.total_size;

    while (offset + 8 <= total) {
        const tag = @as(*const TagHeader, @ptrFromInt(addr + offset));
        const tag_size = @max(tag.size, 8);
        if (offset + tag_size > total) break;

        switch (@as(TagType, @enumFromInt(tag.type))) {
            .end => break,
            .cmdline => {
                const str_start = addr + offset + 8;
                const str_len = tag_size - 8;
                if (str_len > 0) {
                    info.cmdline_ptr = @ptrFromInt(str_start);
                    info.cmdline_len = str_len;
                    info.boot_mode = parseCmdlineBootMode(@as([*]const u8, @ptrFromInt(str_start))[0..str_len]);
                }
            },
            .basic_meminfo => {
                const t = @as(*const BasicMemInfoTag, @ptrFromInt(addr + offset));
                info.mem_lower_kb = t.mem_lower;
                info.mem_upper_kb = t.mem_upper;
            },
            .mmap => {
                const t = @as(*const MmapTag, @ptrFromInt(addr + offset));
                info.mmap_entry_size = t.entry_size;
                const entries_start = addr + offset + 16;
                const entries_len = tag_size - 16;
                info.mmap_entry_count = entries_len / t.entry_size;
                info.mmap_ptr = @ptrFromInt(entries_start);
            },
            .framebuffer => {
                // Read fields at fixed byte offsets to avoid Zig struct layout issues.
                // Multiboot2 framebuffer tag layout (byte offsets from tag start):
                //   0: type(u32) 4: size(u32) 8: addr(u64) 16: pitch(u32)
                //   20: width(u32) 24: height(u32) 28: bpp(u8) 29: fb_type(u8)
                const base = addr + offset;
                const p8 = @as([*]const u8, @ptrFromInt(base));
                const fb_addr_lo = @as(*const u32, @alignCast(@ptrCast(p8 + 8))).*;
                const fb_addr_hi = @as(*const u32, @alignCast(@ptrCast(p8 + 12))).*;
                const fb_pitch = @as(*const u32, @alignCast(@ptrCast(p8 + 16))).*;
                const fb_width = @as(*const u32, @alignCast(@ptrCast(p8 + 20))).*;
                const fb_height = @as(*const u32, @alignCast(@ptrCast(p8 + 24))).*;
                const fb_bpp = p8[28];
                const fb_type_val = p8[29];
                info.fb_info = .{
                    .addr = @as(u64, fb_addr_hi) << 32 | @as(u64, fb_addr_lo),
                    .pitch = fb_pitch,
                    .width = fb_width,
                    .height = fb_height,
                    .bpp = fb_bpp,
                    .fb_type = fb_type_val,
                };
            },
            else => {},
        }
        offset += (tag_size + 7) & ~@as(usize, 7);
    }

    return info;
}

fn parseCmdlineBootMode(cmdline: []const u8) BootMode {
    var i: usize = 0;
    while (i + 6 <= cmdline.len) {
        if (cmdline[i] == 's' and i + 10 <= cmdline.len and
            cmdline[i + 1] == 'h' and cmdline[i + 2] == 'e' and
            cmdline[i + 3] == 'l' and cmdline[i + 4] == 'l' and
            cmdline[i + 5] == '=')
        {
            const val_start = i + 6;
            var val_end = val_start;
            while (val_end < cmdline.len and cmdline[val_end] != ' ' and cmdline[val_end] != 0) {
                val_end += 1;
            }
            const val = cmdline[val_start..val_end];
            if (val.len == 3 and val[0] == 'c' and val[1] == 'm' and val[2] == 'd') {
                return .cmd;
            }
            if (val.len == 10 and val[0] == 'p' and val[1] == 'o' and val[2] == 'w' and
                val[3] == 'e' and val[4] == 'r' and val[5] == 's' and val[6] == 'h' and
                val[7] == 'e' and val[8] == 'l' and val[9] == 'l')
            {
                return .powershell;
            }
        }
        i += 1;
    }
    return .normal;
}
