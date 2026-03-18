//! Object Manager (NT style)
//! Manages kernel objects with unified header, handle table, and namespace
//!
//! v1.0: Interface definitions and stubs for future implementation
//! Full implementation will provide:
//!   - Object type registry
//!   - Handle table per process
//!   - Object namespace (\ObjectTypes, \Devices, \Sessions, etc.)
//!   - Reference counting and lifecycle management

pub const ObjectType = enum(u16) {
    process = 0,
    thread = 1,
    address_space = 2,
    section = 3,
    token = 4,
    event = 5,
    mutex = 6,
    semaphore = 7,
    port = 8,
    file = 9,
    device = 10,
    driver = 11,
    directory = 12,
    symbolic_link = 13,
};

pub const ObjectHeader = struct {
    obj_type: ObjectType,
    ref_count: u32 = 1,
    handle_count: u32 = 0,
    flags: u32 = 0,
    name_ptr: u64 = 0,
};

pub const Handle = u32;
pub const INVALID_HANDLE: Handle = 0xFFFFFFFF;

pub const ACCESS_MASK = u32;
pub const GENERIC_READ: ACCESS_MASK = 0x80000000;
pub const GENERIC_WRITE: ACCESS_MASK = 0x40000000;
pub const GENERIC_EXECUTE: ACCESS_MASK = 0x20000000;
pub const GENERIC_ALL: ACCESS_MASK = 0x10000000;

pub const HandleEntry = struct {
    object_ptr: u64 = 0,
    granted_access: ACCESS_MASK = 0,
    flags: u32 = 0,
};

const MAX_HANDLES: usize = 256;

pub const HandleTable = struct {
    entries: [MAX_HANDLES]HandleEntry = [_]HandleEntry{.{}} ** MAX_HANDLES,
    count: usize = 0,

    pub fn allocHandle(self: *HandleTable, object_ptr: u64, access: ACCESS_MASK) ?Handle {
        for (self.entries, 0..) |*entry, i| {
            if (entry.object_ptr == 0) {
                entry.object_ptr = object_ptr;
                entry.granted_access = access;
                self.count += 1;
                return @intCast(i);
            }
        }
        return null;
    }

    pub fn closeHandle(self: *HandleTable, handle: Handle) bool {
        if (handle >= MAX_HANDLES) return false;
        const entry = &self.entries[handle];
        if (entry.object_ptr == 0) return false;
        entry.* = .{};
        if (self.count > 0) self.count -= 1;
        return true;
    }

    pub fn lookupHandle(self: *const HandleTable, handle: Handle) ?*const HandleEntry {
        if (handle >= MAX_HANDLES) return null;
        const entry = &self.entries[handle];
        if (entry.object_ptr == 0) return null;
        return entry;
    }
};
