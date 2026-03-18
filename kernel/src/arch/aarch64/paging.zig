//! AArch64 paging stub (4KB granule, 4-level translation)
//! Real implementation will use TTBR0/TTBR1

pub const page_size: usize = 4096;
pub const page_mask: usize = page_size - 1;

pub const Present: u64 = 1 << 0;
pub const Write: u64 = 1 << 1;
pub const User: u64 = 1 << 2;
pub const WriteThrough: u64 = 1 << 3;
pub const CacheDisable: u64 = 1 << 4;
pub const Accessed: u64 = 1 << 5;
pub const Dirty: u64 = 1 << 6;
pub const LargePage: u64 = 1 << 7;
pub const Global: u64 = 1 << 8;
pub const NoExecute: u64 = 1 << 63;

pub const PageTableEntry = packed struct(u64) {
    raw: u64 = 0,

    pub fn isPresent(self: PageTableEntry) bool {
        return (self.raw & 1) != 0;
    }
    pub fn toFrame(self: PageTableEntry) u64 {
        return self.raw & 0x000FFFFFFFFFF000;
    }
    pub fn fromFrame(frame: u64, flags: u64) PageTableEntry {
        return .{ .raw = (frame & 0x000FFFFFFFFFF000) | flags };
    }
};

pub const PageTable = struct {
    entries: [512]PageTableEntry,

    pub fn zero(self: *PageTable) void {
        for (&self.entries) |*e| e.* = .{};
    }
};

pub const VirtAddr = struct {
    value: u64,

    pub fn pml4Index(self: VirtAddr) u9 {
        return @truncate((self.value >> 39) & 0x1FF);
    }
    pub fn pdptIndex(self: VirtAddr) u9 {
        return @truncate((self.value >> 30) & 0x1FF);
    }
    pub fn pdIndex(self: VirtAddr) u9 {
        return @truncate((self.value >> 21) & 0x1FF);
    }
    pub fn ptIndex(self: VirtAddr) u9 {
        return @truncate((self.value >> 12) & 0x1FF);
    }
};

pub const AllocFrameFn = *const fn (?*anyopaque) ?u64;

pub fn mapPage(_: u64, _: u64, _: u64, _: u64, _: AllocFrameFn, _: ?*anyopaque) bool {
    return false;
}

pub fn unmapPage(_: u64, _: u64) bool {
    return false;
}

pub fn loadCr3(_: u64) void {}
