//! LoongArch64 boot info stub
//! Real implementation will parse firmware-provided memory map

pub const MULTIBOOT2_BOOTLOADER_MAGIC: u32 = 0;

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

pub const BootInfo = struct {
    mem_lower_kb: u32 = 0,
    mem_upper_kb: u32 = 0,
    mmap_ptr: [*]const u8 = @as([*]const u8, @ptrFromInt(0x1000)),
    mmap_entry_count: usize = 0,
    mmap_entry_size: u32 = 0,

    pub fn getMmapEntry(self: BootInfo, i: usize) ?MmapEntry {
        _ = self;
        _ = i;
        return null;
    }
};

pub fn parse(_: usize) ?BootInfo {
    return null;
}
