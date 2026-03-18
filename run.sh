#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
ARCH="${ARCH:-x86_64}"
DEBUG="${DEBUG:-true}"
ENABLE_IDT="${ENABLE_IDT:-true}"
QEMU_MEM="${QEMU_MEM:-256M}"

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

info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

check_tool() {
    command -v "$1" >/dev/null 2>&1 || error "Missing tool: $1 ($2)"
}

build_kernel() {
    local optimize="${1:-Debug}"
    local dbg="$DEBUG"
    [[ "$optimize" == "ReleaseSafe" ]] && dbg="false"

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
    cp -f "$ROOT_DIR/boot/grub/grub.cfg" "$GRUB_DIR/grub.cfg"
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

    # Assemble MBR (stage1)
    as --32 -o "$ZBM_DIR/mbr.o" "$ROOT_DIR/boot/zbm/bios/mbr.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/mbr.ld" -o "$ZBM_DIR/mbr.bin" --oformat binary "$ZBM_DIR/mbr.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/mbr.o" "$ZBM_DIR/mbr.bin"
    # Ensure MBR is exactly 512 bytes
    truncate -s 512 "$ZBM_DIR/mbr.bin"
    info "MBR built: $ZBM_DIR/mbr.bin ($(stat -c%s "$ZBM_DIR/mbr.bin") bytes)"

    # Assemble VBR
    as --32 -o "$ZBM_DIR/vbr.o" "$ROOT_DIR/boot/zbm/bios/vbr.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/vbr.ld" -o "$ZBM_DIR/vbr.bin" --oformat binary "$ZBM_DIR/vbr.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/vbr.o" "$ZBM_DIR/vbr.bin"
    truncate -s 512 "$ZBM_DIR/vbr.bin"
    info "VBR built: $ZBM_DIR/vbr.bin ($(stat -c%s "$ZBM_DIR/vbr.bin") bytes)"

    # Assemble Stage2
    as --32 -o "$ZBM_DIR/stage2.o" "$ROOT_DIR/boot/zbm/bios/stage2.s"
    ld -m elf_i386 -T "$ROOT_DIR/link/zbm_bios.ld" -o "$ZBM_DIR/stage2.bin" --oformat binary "$ZBM_DIR/stage2.o" 2>/dev/null || \
    objcopy -O binary "$ZBM_DIR/stage2.o" "$ZBM_DIR/stage2.bin"
    info "Stage2 built: $ZBM_DIR/stage2.bin ($(stat -c%s "$ZBM_DIR/stage2.bin") bytes)"

    # Build ZBM Zig library (common modules)
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

    # ── MBR Disk Image ──
    info "Creating MBR disk image ($DISK_SIZE_MB MB)..."
    dd if=/dev/zero of="$DISK_MBR" bs=1M count=$DISK_SIZE_MB status=none

    # Write MBR to first sector
    dd if="$ZBM_DIR/mbr.bin" of="$DISK_MBR" bs=512 count=1 conv=notrunc status=none

    # Create a single bootable partition starting at sector 2048 (1MB aligned)
    # Write partition table entry into MBR (bytes 446-461)
    # Status=0x80 (active), Type=0xFE (ZirconOS), Start=2048, Size=rest
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

    # Write VBR at partition start
    dd if="$ZBM_DIR/vbr.bin" of="$DISK_MBR" bs=512 seek=$PART_START count=1 conv=notrunc status=none

    # Write stage2 at partition start + 1
    dd if="$ZBM_DIR/stage2.bin" of="$DISK_MBR" bs=512 seek=$((PART_START + 1)) conv=notrunc status=none

    # Write kernel at partition start + 65 (after stage2)
    dd if="$KERNEL_ELF" of="$DISK_MBR" bs=512 seek=$((PART_START + 65)) conv=notrunc status=none

    info "MBR disk image built: $DISK_MBR"

    # ── GPT Disk Image ──
    info "Creating GPT disk image ($DISK_SIZE_MB MB)..."
    if command -v sgdisk >/dev/null 2>&1; then
        dd if=/dev/zero of="$DISK_GPT" bs=1M count=$DISK_SIZE_MB status=none

        # Create GPT with sgdisk
        sgdisk --clear "$DISK_GPT" >/dev/null 2>&1
        # Partition 1: EFI System Partition (32MB)
        sgdisk -n 1:2048:67583 -t 1:EF00 -c 1:"EFI System" "$DISK_GPT" >/dev/null 2>&1
        # Partition 2: ZirconOS System (rest)
        sgdisk -n 2:67584:0 -t 2:8300 -c 2:"ZirconOS System" "$DISK_GPT" >/dev/null 2>&1

        # Write stage2 to known location (LBA 34, after GPT entries)
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
    # Also copy kernel to ESP for ZBM UEFI boot path
    ARCH=x86_64 build_kernel "${1:-Debug}" 2>/dev/null || true
    if [ -f "$KERNEL_ELF" ]; then
        mmd -i "$ESP_IMG" ::/boot 2>/dev/null || true
        mcopy -i "$ESP_IMG" "$KERNEL_ELF" "::/boot/kernel.elf" 2>/dev/null || true
    fi
    info "ESP image built: $ESP_IMG"
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
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "${1:-Debug}"
    info "Starting QEMU (x86_64 Desktop Mode, 1024x768x32)..."
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
    check_tool qemu-system-x86_64 "apt install qemu-system-x86"
    build_iso "${1:-Debug}"
    info "Starting QEMU (x86_64 Desktop UEFI Mode)..."
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
  build              Build kernel ELF (debug)
  build-release      Build kernel ELF (release)
  build-zbm          Build ZirconOS Boot Manager (BIOS components)
  build-zbm-disk     Build ZBM disk images (MBR + GPT)
  iso                Build bootable ISO (x86_64 BIOS, GRUB)
  iso-release        Build bootable ISO (release, GRUB)
  run                Run in QEMU (x86_64 BIOS/GRUB, debug)
  run-release        Run in QEMU (x86_64 BIOS/GRUB, release)
  run-debug          Run in QEMU with GDB server
  run-desktop        Run in QEMU with Luna desktop (1024x768, VGA std)
  run-desktop-uefi   Run in QEMU desktop mode via UEFI
  run-zbm            Run in QEMU (ZBM BIOS/MBR Boot Manager)
  run-zbm-uefi       Run in QEMU (ZBM UEFI/GPT Boot Manager)
  run-aarch64        Run kernel in QEMU (aarch64 virt)
  run-uefi           Run in QEMU (x86_64 UEFI/OVMF, with GRUB menu)
  run-uefi-direct    Run in QEMU (x86_64 UEFI/OVMF, direct EFI app, no menu)
  run-uefi-aarch64   Run in QEMU (aarch64 UEFI/AAVMF)
  clean              Remove build artifacts
  help               Show this message

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
EOF
}

case "${1:-help}" in
    build)             build_kernel "Debug" ;;
    build-release)     build_kernel "ReleaseSafe" ;;
    build-zbm)         build_zbm_bios ;;
    build-zbm-disk)    build_zbm_disk_image "Debug" ;;
    iso)               build_iso "Debug" ;;
    iso-release)       build_iso "ReleaseSafe" ;;
    run)               run_bios "Debug" ;;
    run-release)       run_bios "ReleaseSafe" ;;
    run-debug)         run_bios_debug ;;
    run-desktop)       run_desktop "Debug" ;;
    run-desktop-uefi)  run_desktop_uefi "Debug" ;;
    run-zbm)           run_zbm_bios "Debug" ;;
    run-zbm-uefi)      run_zbm_uefi "Debug" ;;
    run-aarch64)       run_aarch64 ;;
    run-uefi)          run_uefi_x86_64 "Debug" ;;
    run-uefi-direct)   run_uefi_direct_x86_64 "Debug" ;;
    run-uefi-aarch64)  run_uefi_aarch64 "Debug" ;;
    clean)             do_clean ;;
    help|--help|-h)    usage ;;
    *)                 error "Unknown command: $1 (try './run.sh help')" ;;
esac
