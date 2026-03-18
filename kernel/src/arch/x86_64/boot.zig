//! Multiboot2 header and boot info parsing for x86_64
//! Reference: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html

pub const MULTIBOOT2_BOOTLOADER_MAGIC: u32 = 0x36d76289;

pub export const multiboot2_header: [24]u8 align(8) linksection(".multiboot2") = .{
    0xD6, 0x50, 0x52, 0xE8, // magic
    0x00, 0x00, 0x00, 0x00, // architecture (i386)
    0x18, 0x00, 0x00, 0x00, // header_length (24)
    0x12, 0xAF, 0xAD, 0x17, // checksum
    0x00, 0x00, 0x00, 0x00, // end tag: type=0, flags=0
    0x08, 0x00, 0x00, 0x00, // end tag: size=8
};

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

pub const BootInfo = struct {
    mem_lower_kb: u32,
    mem_upper_kb: u32,
    mmap_ptr: [*]const u8,
    mmap_entry_count: usize,
    mmap_entry_size: u32,

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
            else => {},
        }
        offset += (tag_size + 7) & ~@as(usize, 7);
    }

    return info;
}
