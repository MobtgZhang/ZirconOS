pub const MULTIBOOT2_BOOTLOADER_MAGIC: u32 = 0x36d76289;

// Multiboot2 header (very minimal, 24 bytes):
// GRUB will scan the first ~32KiB for this header in the kernel ELF.
// Spec: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html
//
// Layout (little-endian):
// - magic        u32 = 0xE85250D6
// - arch         u32 = 0
// - header_len   u32 = 24 (0x18)
// - checksum     u32 = -(magic + arch + header_len) mod 2^32 = 0x17ADAF12
// - end tag: type u16=0, flags u16=0, size u32=8
export const multiboot2_header: [24]u8 align(8) linksection(".multiboot2") = .{
    0xD6, 0x50, 0x52, 0xE8, // magic
    0x00, 0x00, 0x00, 0x00, // architecture
    0x18, 0x00, 0x00, 0x00, // header_length
    0x12, 0xAF, 0xAD, 0x17, // checksum
    0x00, 0x00, 0x00, 0x00, // end tag: type, flags
    0x08, 0x00, 0x00, 0x00, // end tag: size
};

