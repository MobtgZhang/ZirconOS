#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
ARCH="${ARCH:-x86_64}"
DEBUG="${DEBUG:-true}"
ENABLE_IDT="${ENABLE_IDT:-true}"
QEMU_MEM="${QEMU_MEM:-256M}"
DESKTOP="${DESKTOP:-}"

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
TMP_DIR="$BUILD_DIR/tmp"
RELEASE_DIR="$BUILD_DIR/release"

KERNEL_PREFIX="$TMP_DIR/kernel-prefix"
KERNEL_CACHE="$TMP_DIR/zig-cache"
KERNEL_ELF="$KERNEL_PREFIX/bin/kernel"

ISO_DIR="$TMP_DIR/isofiles"
BOOT_DIR="$ISO_DIR/boot"
GRUB_DIR="$BOOT_DIR/grub"
ISO="$RELEASE_DIR/zirconos-${VERSION}-${ARCH}.iso"

UEFI_PREFIX="$TMP_DIR/uefi-prefix"
UEFI_CACHE="$TMP_DIR/uefi-cache"
UEFI_EFI="$UEFI_PREFIX/bin/zirconos.efi"
ESP_IMG="$BUILD_DIR/esp-${ARCH}.img"

OVMF_CODE="${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}"
OVMF_VARS="${OVMF_VARS:-/usr/share/OVMF/OVMF_VARS_4M.fd}"
AAVMF_CODE="${AAVMF_CODE:-/usr/share/AAVMF/AAVMF_CODE.fd}"
AAVMF_VARS="${AAVMF_VARS:-/usr/share/AAVMF/AAVMF_VARS.fd}"

VALID_DESKTOPS="classic luna aero modern fluent sunvalley"

info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

check_tool() {
    command -v "$1" >/dev/null 2>&1 || error "Missing tool: $1 ($2)"
}

validate_desktop() {
    local dt="$1"
    if [[ -z "$dt" ]]; then
        return 0
    fi
    for valid in $VALID_DESKTOPS; do
        if [[ "$dt" == "$valid" ]]; then
            return 0
        fi
    done
    error "Invalid desktop theme: $dt (valid: $VALID_DESKTOPS)"
}

# Generate grub.cfg with the selected desktop theme (if any).
# If DESKTOP is set, the default menu entry boots into the specified desktop
# theme so that the graphical desktop is shown automatically.
generate_grub_cfg() {
    local desktop_default=""
    if [[ -n "$DESKTOP" ]]; then
        desktop_default="$DESKTOP"
    fi

    cat > "$GRUB_DIR/grub.cfg" <<GRUBEOF
# ZirconOS v${VERSION} GRUB Configuration (auto-generated)
set timeout=10
set timeout_style=menu
set default=0

set menu_color_normal=light-gray/black
set menu_color_highlight=white/blue

set gfxmode=auto
insmod all_video
insmod gfxterm

if loadfont unicode ; then
    terminal_output gfxterm
elif loadfont ascii ; then
    terminal_output gfxterm
else
    terminal_output console
fi

set gfxpayload=keep

insmod multiboot2
insmod part_gpt
insmod part_msdos
insmod ext2
insmod fat
insmod chain
insmod ntfs

if [ "\${grub_platform}" = "pc" ]; then
    insmod biosdisk
    insmod vbe
fi

if [ "\${grub_platform}" = "efi" ]; then
    insmod efi_gop
    insmod efi_uga
fi

GRUBEOF

    # When a desktop theme is selected, the first entry boots into desktop mode
    if [[ -n "$desktop_default" ]]; then
        cat >> "$GRUB_DIR/grub.cfg" <<GRUBEOF
# ═══ Default: Desktop Mode ($desktop_default) ═══

menuentry "ZirconOS v${VERSION} — Desktop ($desktop_default) [Default]" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=$desktop_default
    boot
}

GRUBEOF
    else
        cat >> "$GRUB_DIR/grub.cfg" <<GRUBEOF
# ═══ Default: CMD Shell ═══

GRUBEOF
    fi

    cat >> "$GRUB_DIR/grub.cfg" <<GRUBEOF
menuentry "ZirconOS v${VERSION} — CMD Shell" {
    multiboot2 /boot/kernel.elf -- console=serial,vga shell=cmd
    boot
}

menuentry "ZirconOS v${VERSION} — Normal Boot (Text)" {
    multiboot2 /boot/kernel.elf
    boot
}

# ═══ Desktop Themes ═══

menuentry "ZirconOS v${VERSION} — Classic Desktop (Win2000)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=classic
    boot
}

menuentry "ZirconOS v${VERSION} — Luna Desktop (XP)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=luna
    boot
}

menuentry "ZirconOS v${VERSION} — Aero Desktop (7)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=aero
    boot
}

menuentry "ZirconOS v${VERSION} — Modern Desktop (8)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=modern
    boot
}

menuentry "ZirconOS v${VERSION} — Fluent Desktop (10)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=fluent
    boot
}

menuentry "ZirconOS v${VERSION} — Sun Valley Desktop (11)" {
    set gfxpayload=1024x768x32
    multiboot2 /boot/kernel.elf -- desktop=sunvalley
    boot
}

# ═══ Shell / Debug Modes ═══

menuentry "ZirconOS v${VERSION} — Debug Mode (Serial + VGA)" {
    multiboot2 /boot/kernel.elf -- console=serial,vga debug=1 verbose=1
    boot
}

# ═══ Win32 Subsystem ═══

submenu "Win32 Subsystem >" {

    menuentry "CMD Shell Only" {
        multiboot2 /boot/kernel.elf -- console=serial,vga shell=cmd
        boot
    }

    menuentry "PowerShell Only" {
        multiboot2 /boot/kernel.elf -- console=serial,vga shell=powershell
        boot
    }

    menuentry "Full Demo (Phase 0-11)" {
        multiboot2 /boot/kernel.elf -- console=serial,vga debug=1 win32=full gui=full wow64=full
        boot
    }

    menuentry "Back to Main Menu" {
        configfile /boot/grub/grub.cfg
    }
}

# ═══ ZirconOS Boot Manager (ZBM) ═══

submenu "ZirconOS Boot Manager (ZBM) >" {

    if [ "\${grub_platform}" = "efi" ]; then
        menuentry "ZBM — UEFI Boot Manager" {
            chainloader /EFI/BOOT/BOOTX64.EFI
        }
    fi

    if [ "\${grub_platform}" = "pc" ]; then
        menuentry "ZBM — BIOS Boot Manager (Chainload MBR)" {
            set root=(hd0)
            chainloader +1
        }
    fi

    menuentry "Back to Main Menu" {
        configfile /boot/grub/grub.cfg
    }
}

# ═══ Advanced Boot Options ═══

submenu "Advanced Boot Options >" {

    menuentry "Serial Debug Only" {
        multiboot2 /boot/kernel.elf -- console=serial debug=1
        boot
    }

    menuentry "Safe Mode (Minimal Modules)" {
        multiboot2 /boot/kernel.elf -- safe_mode=1 debug=0 minimal=1
        boot
    }

    menuentry "Release Build (Optimized)" {
        multiboot2 /boot/kernel.elf -- debug=0 release=1
        boot
    }

    menuentry "Back to Main Menu" {
        configfile /boot/grub/grub.cfg
    }
}

menuentry "Reboot" {
    reboot
}

menuentry "Shutdown" {
    halt
}
GRUBEOF
}

build_kernel() {
    local optimize="${1:-Debug}"
    local dbg="$DEBUG"
    if [[ "$optimize" == "ReleaseSafe" || "$optimize" == "ReleaseFast" || "$optimize" == "ReleaseSmall" ]]; then
        dbg="false"
    fi

    info "Building kernel (arch=$ARCH, optimize=$optimize, debug=$dbg, idt=$ENABLE_IDT)"
    check_tool zig "https://ziglang.org"
    check_tool objcopy "apt install binutils"
    mkdir -p "$KERNEL_PREFIX" "$KERNEL_CACHE"
    cd "$ROOT_DIR"
    zig build \
        -Doptimize="$optimize" \
        -Darch="$ARCH" \
        -Ddebug="$dbg" \
        -Denable_idt="$ENABLE_IDT" \
        --cache-dir "$KERNEL_CACHE" \
        --prefix "$KERNEL_PREFIX"
    objcopy --strip-all "$KERNEL_ELF" "$KERNEL_ELF.boot"
    mv "$KERNEL_ELF.boot" "$KERNEL_ELF"
    info "Kernel built: $KERNEL_ELF"
}

build_iso() {
    check_tool grub-mkrescue "apt install grub-pc-bin grub-efi-amd64-bin"
    check_tool xorriso "apt install xorriso"
    ARCH=x86_64 build_kernel "${1:-Debug}"
    mkdir -p "$GRUB_DIR" "$RELEASE_DIR"
    cp -f "$KERNEL_ELF" "$BOOT_DIR/kernel.elf"
    generate_grub_cfg
    grub-mkrescue -o "$ISO" "$ISO_DIR"
    info "Hybrid ISO built (BIOS+UEFI): $ISO"
}

build_uefi() {
    local optimize="${1:-Debug}"
    info "Building UEFI app (arch=$ARCH, optimize=$optimize)"
    check_tool zig "https://ziglang.org"
    mkdir -p "$UEFI_PREFIX" "$UEFI_CACHE"
    cd "$ROOT_DIR"
    zig build uefi \
        -Doptimize="$optimize" \
        -Darch="$ARCH" \
        -Ddebug="$DEBUG" \
        --cache-dir "$UEFI_CACHE" \
        --prefix "$UEFI_PREFIX"
    info "UEFI app built: $UEFI_EFI"
}

build_zbm_bios() {
    info "Building ZirconOS Boot Manager (BIOS components)..."
    check_tool as "apt install binutils"
    check_tool ld "apt install binutils"
    check_tool objcopy "apt install binutils"

    local ZBM_DIR="$TMP_DIR/zbm"
    mkdir -p "$ZBM_DIR"

    as --32 -o "$ZBM_DIR/mbr.o" "$ROOT_DIR/boot/zbm/bios/mbr.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/mbr.ld" -o "$ZBM_DIR/mbr.bin" --oformat binary "$ZBM_DIR/mbr.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/mbr.o" "$ZBM_DIR/mbr.bin"
    truncate -s 512 "$ZBM_DIR/mbr.bin"
    info "MBR built: $ZBM_DIR/mbr.bin ($(stat -c%s "$ZBM_DIR/mbr.bin") bytes)"

    as --32 -o "$ZBM_DIR/vbr.o" "$ROOT_DIR/boot/zbm/bios/vbr.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/vbr.ld" -o "$ZBM_DIR/vbr.bin" --oformat binary "$ZBM_DIR/vbr.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/vbr.o" "$ZBM_DIR/vbr.bin"
    truncate -s 512 "$ZBM_DIR/vbr.bin"
    info "VBR built: $ZBM_DIR/vbr.bin ($(stat -c%s "$ZBM_DIR/vbr.bin") bytes)"

    as --32 -o "$ZBM_DIR/stage2.o" "$ROOT_DIR/boot/zbm/bios/stage2.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/zbm_bios.ld" -o "$ZBM_DIR/stage2.bin" --oformat binary "$ZBM_DIR/stage2.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/stage2.o" "$ZBM_DIR/stage2.bin"
    info "Stage2 built: $ZBM_DIR/stage2.bin ($(stat -c%s "$ZBM_DIR/stage2.bin") bytes)"

    cd "$ROOT_DIR"
    zig build zbm \
        -Doptimize=ReleaseSmall \
        -Darch=x86_64 \
        -Ddebug="$DEBUG" \
        --cache-dir "$KERNEL_CACHE" \
        --prefix "$KERNEL_PREFIX" 2>/dev/null || true
    info "ZBM common library built"
}

build_zbm_disk_image() {
    info "Building ZirconOS Boot Manager disk image..."
    check_tool qemu-img "apt install qemu-utils"

    local ZBM_DIR="$TMP_DIR/zbm"
    local DISK_MBR="$BUILD_DIR/zirconos-mbr.img"
    local DISK_GPT="$BUILD_DIR/zirconos-gpt.img"
    local DISK_SIZE_MB=128

    build_zbm_bios
    ARCH=x86_64 build_kernel "${1:-Debug}"

    info "Creating MBR disk image ($DISK_SIZE_MB MB)..."
    dd if=/dev/zero of="$DISK_MBR" bs=1M count=$DISK_SIZE_MB status=none

    dd if="$ZBM_DIR/mbr.bin" of="$DISK_MBR" bs=512 count=1 conv=notrunc status=none

    local PART_START=2048
    local PART_SECTORS=$(( (DISK_SIZE_MB * 1024 * 1024 / 512) - PART_START ))
    python3 -c "
import struct, sys
entry = struct.pack('<BBBBBBBBI I',
    0x80,       # status (active)
    0x00, 0x21, 0x00,  # CHS first (sector 1, head 0, cyl 0)
    0xFE,       # type (ZirconOS)
    0xFE, 0xFF, 0xFF,  # CHS last
    $PART_START, $PART_SECTORS)
with open('$DISK_MBR', 'r+b') as f:
    f.seek(446)
    f.write(entry)
" 2>/dev/null || info "  (partition table written via dd)"

    dd if="$ZBM_DIR/vbr.bin" of="$DISK_MBR" bs=512 seek=$PART_START count=1 conv=notrunc status=none
    dd if="$ZBM_DIR/stage2.bin" of="$DISK_MBR" bs=512 seek=$((PART_START + 1)) conv=notrunc status=none
    dd if="$KERNEL_ELF" of="$DISK_MBR" bs=512 seek=$((PART_START + 65)) conv=notrunc status=none

    info "MBR disk image built: $DISK_MBR"

    info "Creating GPT disk image ($DISK_SIZE_MB MB)..."
    if command -v sgdisk >/dev/null 2>&1; then
        dd if=/dev/zero of="$DISK_GPT" bs=1M count=$DISK_SIZE_MB status=none
        sgdisk --clear "$DISK_GPT" >/dev/null 2>&1
        sgdisk -n 1:2048:67583 -t 1:EF00 -c 1:"EFI System" "$DISK_GPT" >/dev/null 2>&1
        sgdisk -n 2:67584:0 -t 2:8300 -c 2:"ZirconOS System" "$DISK_GPT" >/dev/null 2>&1
        dd if="$ZBM_DIR/stage2.bin" of="$DISK_GPT" bs=512 seek=34 conv=notrunc status=none
        info "GPT disk image built: $DISK_GPT"
    else
        info "  sgdisk not found, skipping GPT image (apt install gdisk)"
    fi
}

build_esp() {
    check_tool mformat "apt install mtools"
    check_tool mcopy "apt install mtools"
    build_uefi "${1:-Debug}"
    local efi_name="BOOTX64.EFI"
    [[ "$ARCH" == "aarch64" ]] && efi_name="BOOTAA64.EFI"
    mkdir -p "$BUILD_DIR" "$TMP_DIR"
    dd if=/dev/zero of="$ESP_IMG" bs=1M count=64 status=none
    mformat -i "$ESP_IMG" ::
    mmd -i "$ESP_IMG" ::/EFI
    mmd -i "$ESP_IMG" ::/EFI/BOOT
    mcopy -i "$ESP_IMG" "$UEFI_EFI" "::/EFI/BOOT/$efi_name"
    ARCH=x86_64 build_kernel "${1:-Debug}" 2>/dev/null || true
    if [ -f "$KERNEL_ELF" ]; then
        mmd -i "$ESP_IMG" ::/boot 2>/dev/null || true
        mcopy -i "$ESP_IMG" "$KERNEL_ELF" "::/boot/kernel.elf" 2>/dev/null || true
    fi
    info "ESP image built: $ESP_IMG"
}

build_desktop_theme() {
    local theme="${1:-classic}"
    validate_desktop "$theme"
    info "Building desktop theme: $theme"
    check_tool zig "https://ziglang.org"
    cd "$ROOT_DIR"
    zig build "desktop-${theme}" \
        -Doptimize=Debug \
        -Dtheme="$theme" 2>/dev/null || \
    zig build desktop \
        -Dtheme="$theme"
    info "Desktop theme built: $theme"
}

run_bios() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "${1:-Debug}"
    info "Starting QEMU (x86_64 BIOS)..."
    qemu-system-x86_64 \
        -m "$QEMU_MEM" \
        -cdrom "$ISO" \
        -serial stdio \
        -display gtk \
        -no-reboot \
        -no-shutdown
}

run_bios_debug() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "Debug"
    info "Starting QEMU (x86_64 BIOS + GDB on :1234)..."
    qemu-system-x86_64 \
        -m "$QEMU_MEM" \
        -cdrom "$ISO" \
        -serial stdio \
        -display gtk \
        -no-reboot \
        -no-shutdown \
        -S -s \
        -d int,cpu_reset
}

run_uefi_x86_64() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "${1:-Debug}"
    info "Starting QEMU (x86_64 UEFI/OVMF with GRUB menu)..."
    cp -f "$OVMF_VARS" "$TMP_DIR/OVMF_VARS.fd"
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TMP_DIR/OVMF_VARS.fd" \
        -cdrom "$ISO" \
        -m "$QEMU_MEM" \
        -serial stdio \
        -display gtk \
        -net none \
        -no-reboot \
        -no-shutdown
}

run_uefi_direct_x86_64() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    ARCH=x86_64 build_esp "${1:-Debug}"
    info "Starting QEMU (x86_64 UEFI/OVMF direct, no GRUB menu)..."
    cp -f "$OVMF_VARS" "$TMP_DIR/OVMF_VARS.fd"
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TMP_DIR/OVMF_VARS.fd" \
        -drive format=raw,file="$ESP_IMG" \
        -m "$QEMU_MEM" \
        -serial stdio \
        -display gtk \
        -net none \
        -no-reboot \
        -no-shutdown
}

run_uefi_aarch64() {
    check_tool qemu-system-aarch64 "apt install qemu-system-arm"
    ARCH=aarch64 build_esp "${1:-Debug}"
    info "Starting QEMU (aarch64 UEFI/AAVMF)..."
    cp -f "$AAVMF_VARS" "$TMP_DIR/AAVMF_VARS.fd"
    qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a53 \
        -drive if=pflash,format=raw,readonly=on,file="$AAVMF_CODE" \
        -drive if=pflash,format=raw,file="$TMP_DIR/AAVMF_VARS.fd" \
        -drive format=raw,file="$ESP_IMG" \
        -m "$QEMU_MEM" \
        -nographic \
        -net none \
        -no-reboot \
        -no-shutdown
}

run_zbm_bios() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_zbm_disk_image "${1:-Debug}"
    info "Starting QEMU (ZBM BIOS/MBR Boot Manager)..."
    qemu-system-x86_64 \
        -m "$QEMU_MEM" \
        -drive format=raw,file="$BUILD_DIR/zirconos-mbr.img" \
        -serial stdio \
        -display gtk \
        -no-reboot \
        -no-shutdown
}

run_zbm_uefi() {
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    ARCH=x86_64 build_esp "${1:-Debug}"
    info "Starting QEMU (ZBM UEFI/GPT Boot Manager)..."
    cp -f "$OVMF_VARS" "$TMP_DIR/OVMF_VARS.fd"
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TMP_DIR/OVMF_VARS.fd" \
        -drive format=raw,file="$ESP_IMG" \
        -m "$QEMU_MEM" \
        -serial stdio \
        -display gtk \
        -net none \
        -no-reboot \
        -no-shutdown
}

run_desktop() {
    local opt="${1:-Debug}"
    local theme="${2:-${DESKTOP:-classic}}"
    validate_desktop "$theme"
    DESKTOP="$theme"

    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "$opt"
    info "Starting QEMU (x86_64 Desktop Mode: $theme, 1024x768x32, optimize=$opt)..."
    qemu-system-x86_64 \
        -m "${QEMU_MEM:-512M}" \
        -cdrom "$ISO" \
        -serial stdio \
        -display gtk,zoom-to-fit=on,show-cursor=on \
        -vga std \
        -no-reboot \
        -no-shutdown \
        -usb \
        -device usb-mouse \
        -device usb-kbd
}

run_desktop_uefi() {
    local theme="${2:-${DESKTOP:-classic}}"
    validate_desktop "$theme"
    DESKTOP="$theme"

    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "${1:-Debug}"
    info "Starting QEMU (x86_64 Desktop UEFI Mode: $theme)..."
    cp -f "$OVMF_VARS" "$TMP_DIR/OVMF_VARS.fd"
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TMP_DIR/OVMF_VARS.fd" \
        -cdrom "$ISO" \
        -m "${QEMU_MEM:-512M}" \
        -serial stdio \
        -display gtk,zoom-to-fit=on,show-cursor=on \
        -vga std \
        -no-reboot \
        -no-shutdown \
        -usb \
        -device usb-mouse \
        -device usb-kbd
}

run_aarch64() {
    check_tool qemu-system-aarch64 "apt install qemu-system-arm"
    ARCH=aarch64 build_kernel "Debug"
    info "Starting QEMU (aarch64 virt)..."
    qemu-system-aarch64 \
        -machine virt \
        -cpu cortex-a53 \
        -nographic \
        -kernel "$KERNEL_ELF"
}

do_clean() {
    info "Cleaning build artifacts..."
    rm -rf "$BUILD_DIR" .zig-cache zig-out
    info "Clean done"
}

usage() {
    cat <<EOF
ZirconOS v${VERSION} Build & Run Script

Usage: ./run.sh <command> [options]

Commands:
  build                       Build kernel ELF (debug)
  build-release               Build kernel ELF (release)
  build-zbm                   Build ZirconOS Boot Manager (BIOS components)
  build-zbm-disk              Build ZBM disk images (MBR + GPT)
  build-desktop [theme]       Build a desktop theme (default: classic)
  iso                         Build bootable ISO (x86_64 BIOS, GRUB)
  iso-release                 Build bootable ISO (release, GRUB)
  run                         Run in QEMU (x86_64 BIOS/GRUB, debug)
  run-release                 Run in QEMU (x86_64 BIOS/GRUB, release)
  run-debug                   Run in QEMU with GDB server
  run-desktop [theme]         Run with desktop (debug, screen+serial log)
  run-desktop-release [theme] Run with desktop (release, serial log only)
  run-desktop-uefi [theme]    Run desktop mode via UEFI
  run-zbm                     Run in QEMU (ZBM BIOS/MBR Boot Manager)
  run-zbm-uefi                Run in QEMU (ZBM UEFI/GPT Boot Manager)
  run-aarch64                 Run kernel in QEMU (aarch64 virt)
  run-uefi                    Run in QEMU (x86_64 UEFI/OVMF, with GRUB menu)
  run-uefi-direct             Run in QEMU (x86_64 UEFI/OVMF, direct EFI app)
  run-uefi-aarch64            Run in QEMU (aarch64 UEFI/AAVMF)
  clean                       Remove build artifacts
  help                        Show this message

Desktop Themes:
  classic      Windows 2000 Classic (default)
  luna         Windows XP Luna Blue
  aero         Windows Vista/7 Aero
  modern       Windows 8 Metro
  fluent       Windows 10 Fluent
  sunvalley    Windows 11 Sun Valley

Examples:
  ./run.sh run-desktop luna         # Run with Luna desktop
  ./run.sh run-desktop aero         # Run with Aero desktop
  ./run.sh run-desktop modern       # Run with Modern desktop
  DESKTOP=fluent ./run.sh run-desktop  # Via environment variable

Boot Paths:
  GRUB (Legacy):     BIOS → GRUB → Multiboot2 → kernel.elf
  GRUB (UEFI):       UEFI → GRUB → Multiboot2 → kernel.elf
  ZBM (BIOS/MBR):    BIOS → MBR → VBR → stage2 → ZBM menu → kernel.elf
  ZBM (BIOS/GPT):    BIOS → pMBR → stage2 → ZBM menu → kernel.elf
  ZBM (UEFI/GPT):    UEFI → ESP → zbmfw.efi → ZBM menu → kernel.elf

Environment Variables:
  ARCH=x86_64|aarch64|loong64|riscv64|mips64el
  DEBUG=true|false        Enable debug logging (default: true)
  ENABLE_IDT=true|false   Enable IDT/syscall (default: true)
  QEMU_MEM=256M           QEMU memory size
  DESKTOP=<theme>         Desktop theme name (overrides default)
EOF
}

case "${1:-help}" in
    build)                  build_kernel "Debug" ;;
    build-release)          build_kernel "ReleaseSafe" ;;
    build-zbm)              build_zbm_bios ;;
    build-zbm-disk)         build_zbm_disk_image "Debug" ;;
    build-desktop)          build_desktop_theme "${2:-classic}" ;;
    iso)                    build_iso "Debug" ;;
    iso-release)            build_iso "ReleaseSafe" ;;
    run)                    run_bios "Debug" ;;
    run-release)            run_bios "ReleaseSafe" ;;
    run-debug)              run_bios_debug ;;
    run-desktop)            run_desktop "Debug" "${2:-}" ;;
    run-desktop-release)    run_desktop "ReleaseSafe" "${2:-}" ;;
    run-desktop-uefi)       run_desktop_uefi "Debug" "${2:-}" ;;
    run-zbm)                run_zbm_bios "Debug" ;;
    run-zbm-uefi)           run_zbm_uefi "Debug" ;;
    run-aarch64)            run_aarch64 ;;
    run-uefi)               run_uefi_x86_64 "Debug" ;;
    run-uefi-direct)        run_uefi_direct_x86_64 "Debug" ;;
    run-uefi-aarch64)       run_uefi_aarch64 "Debug" ;;
    clean)                  do_clean ;;
    help|--help|-h)         usage ;;
    *)                      error "Unknown command: $1 (try './run.sh help')" ;;
esac
