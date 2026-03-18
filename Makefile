.PHONY: all kernel kernel-release iso uefi uefi-release esp \
	run run-bios run-bios-debug run-bios-release run-aarch64 \
	run-uefi-x86_64 run-uefi-debug run-uefi-release run-uefi-aarch64 \
	clean distclean check-tools check-uefi-tools help

# ── Configuration ────────────────────────────────────────────────────
ROOT_DIR  := $(abspath .)
VERSION   := 1.0.0
ARCH      ?= x86_64
BUILD_DIR := $(ROOT_DIR)/build
TMP_DIR   := $(BUILD_DIR)/tmp
RELEASE_DIR := $(BUILD_DIR)/release

# ── Kernel build paths ──────────────────────────────────────────────
ISO_DIR        := $(TMP_DIR)/isofiles
BOOT_DIR       := $(ISO_DIR)/boot
GRUB_DIR       := $(BOOT_DIR)/grub
KERNEL_PREFIX  := $(TMP_DIR)/kernel-prefix
KERNEL_CACHE   := $(TMP_DIR)/zig-cache
KERNEL_ELF     := $(KERNEL_PREFIX)/bin/kernel
STAGED_KERNEL  := $(BOOT_DIR)/kernel.elf
GRUB_CFG       := $(ROOT_DIR)/boot/grub/grub.cfg
STAGED_GRUB_CFG := $(GRUB_DIR)/grub.cfg
ISO            := $(RELEASE_DIR)/zirconos-$(VERSION)-$(ARCH).iso

# ── UEFI build paths ───────────────────────────────────────────────
UEFI_PREFIX := $(TMP_DIR)/uefi-prefix
UEFI_CACHE  := $(TMP_DIR)/uefi-cache
UEFI_EFI    := $(UEFI_PREFIX)/bin/zirconos.efi
ESP_IMG      = $(BUILD_DIR)/esp-$(ARCH).img

# ── QEMU ────────────────────────────────────────────────────────────
QEMU           := qemu-system-x86_64
QEMU_MEM       ?= 256M
QEMU_ARM       := qemu-system-aarch64
QEMU_ARM_MACHINE ?= virt
QEMU_ARM_CPU   ?= cortex-a53

# ── UEFI firmware ──────────────────────────────────────────────────
OVMF_CODE  ?= /usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS  ?= /usr/share/OVMF/OVMF_VARS_4M.fd
AAVMF_CODE ?= /usr/share/AAVMF/AAVMF_CODE.fd
AAVMF_VARS ?= /usr/share/AAVMF/AAVMF_VARS.fd

# ── Build options ──────────────────────────────────────────────────
DEBUG      ?= true
ENABLE_IDT ?= true
EFI_BOOT_NAME ?= BOOTX64.EFI

# ── Default ─────────────────────────────────────────────────────────
all: iso

# ── Help ────────────────────────────────────────────────────────────
help:
	@echo "ZirconOS v$(VERSION) Build System (Phase 0-11)"
	@echo ""
	@echo "Kernel & ISO:"
	@echo "  make kernel            - Build kernel ELF (debug, ARCH=$(ARCH))"
	@echo "  make kernel-release    - Build kernel ELF (release, ARCH=$(ARCH))"
	@echo "  make iso               - Build bootable ISO (x86_64, GRUB/BIOS)"
	@echo ""
	@echo "BIOS boot:"
	@echo "  make run-bios          - Run ISO in QEMU (x86_64 BIOS, debug)"
	@echo "  make run-bios-debug    - Run ISO in QEMU (BIOS + GDB debug server)"
	@echo "  make run-bios-release  - Run ISO in QEMU (x86_64 BIOS, release)"
	@echo "  make run-aarch64       - Run kernel in QEMU (aarch64 virt)"
	@echo ""
	@echo "UEFI boot:"
	@echo "  make run-uefi-x86_64   - Run UEFI app in QEMU+OVMF (debug)"
	@echo "  make run-uefi-debug    - Run UEFI app in QEMU+OVMF (debug + GDB)"
	@echo "  make run-uefi-release  - Run UEFI app in QEMU+OVMF (release)"
	@echo "  make run-uefi-aarch64  - Run UEFI app in QEMU+AAVMF"
	@echo "  make uefi ARCH=x86_64  - Build UEFI .efi only"
	@echo "  make esp  ARCH=x86_64  - Build ESP FAT image"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean             - Remove build artifacts"
	@echo "  make check-tools       - Check required tools (kernel/ISO)"
	@echo "  make check-uefi-tools  - Check required tools (UEFI)"
	@echo ""
	@echo "Options:"
	@echo "  DEBUG=true/false        - Enable debug logging (default: true)"
	@echo "  ENABLE_IDT=true/false   - Enable IDT/syscall x86_64 (default: true)"
	@echo "  ARCH=x86_64|aarch64|loong64|riscv64|mips64el"
	@echo ""
	@echo "Modules (Phase 0-11):"
	@echo "  ke(sched/timer/intr/sync) mm(frame/vm/heap)"
	@echo "  ob(object/handle/namespace) ps(process/server/smss)"
	@echo "  se(token/access) io(device/driver/irp) lpc(ipc/port)"
	@echo "  fs(vfs/fat32/ntfs) loader(pe32/pe32+/elf)"
	@echo "  win32(ntdll/kernel32/console/cmd/powershell)"
	@echo "  csrss(subsystem/window_station) exec(win32_app_engine)"
	@echo "  user32(window/message/input) gdi32(dc/draw/font/bitmap)"
	@echo "  wow64(thunk/pe32/32bit_compat)"
	@echo ""
	@echo "Boot modes:"
	@echo "  BIOS: Normal, Debug, Serial Debug, Safe Mode"
	@echo "  UEFI: Normal, Debug (GDB), Release"
	@echo "  Win32: Full Demo, CMD Only, PowerShell Only"
	@echo "  GUI: user32/gdi32 Demo"
	@echo "  WOW64: 32-bit Compatibility Demo"
	@echo "  Recovery: Recovery Console, Last Known Good"

# ── Tool checks ────────────────────────────────────────────────────
check-tools:
	@command -v zig >/dev/null || (echo "missing: zig" && exit 1)
	@command -v grub-mkrescue >/dev/null || (echo "missing: grub-mkrescue (grub-pc-bin)" && exit 1)
	@command -v xorriso >/dev/null || (echo "missing: xorriso" && exit 1)
	@command -v $(QEMU) >/dev/null || (echo "missing: $(QEMU)" && exit 1)
	@echo "OK: kernel/ISO tools found"

check-uefi-tools:
	@command -v zig >/dev/null || (echo "missing: zig" && exit 1)
	@command -v mformat >/dev/null || (echo "missing: mformat (install mtools)" && exit 1)
	@command -v mcopy >/dev/null || (echo "missing: mcopy (install mtools)" && exit 1)
	@command -v dd >/dev/null || (echo "missing: dd (coreutils)" && exit 1)
	@echo "OK: UEFI tools found"

# ═══════════════════════════════════════════════════════════════════
#  Kernel build
# ═══════════════════════════════════════════════════════════════════
kernel: check-tools
	@echo "[kernel] building... (arch=$(ARCH), debug=$(DEBUG), idt=$(ENABLE_IDT))"
	@mkdir -p "$(KERNEL_PREFIX)" "$(KERNEL_CACHE)"
	@cd "$(ROOT_DIR)" && zig build \
		-Doptimize=Debug \
		-Darch="$(ARCH)" \
		-Ddebug=$(DEBUG) \
		-Denable_idt=$(ENABLE_IDT) \
		--cache-dir "$(KERNEL_CACHE)" \
		--prefix "$(KERNEL_PREFIX)"

kernel-release: check-tools
	@echo "[kernel-release] building... (arch=$(ARCH), debug=false, idt=$(ENABLE_IDT))"
	@mkdir -p "$(KERNEL_PREFIX)" "$(KERNEL_CACHE)"
	@cd "$(ROOT_DIR)" && zig build \
		-Doptimize=ReleaseSafe \
		-Darch="$(ARCH)" \
		-Ddebug=false \
		-Denable_idt=$(ENABLE_IDT) \
		--cache-dir "$(KERNEL_CACHE)" \
		--prefix "$(KERNEL_PREFIX)"

# ═══════════════════════════════════════════════════════════════════
#  GRUB ISO (x86_64 BIOS)
# ═══════════════════════════════════════════════════════════════════
$(GRUB_DIR):
	@mkdir -p "$(GRUB_DIR)"

$(STAGED_KERNEL): kernel | $(GRUB_DIR)
	@cp -f "$(KERNEL_ELF)" "$(STAGED_KERNEL)"

$(STAGED_GRUB_CFG): $(GRUB_CFG) | $(GRUB_DIR)
	@cp -f "$(GRUB_CFG)" "$(STAGED_GRUB_CFG)"

iso: ARCH=x86_64
iso: check-tools $(STAGED_KERNEL) $(STAGED_GRUB_CFG)
	@echo "[iso] building ISO..."
	@mkdir -p "$(RELEASE_DIR)"
	@grub-mkrescue -o "$(ISO)" "$(ISO_DIR)" 2>/dev/null
	@echo "OK: $(ISO)"

# ═══════════════════════════════════════════════════════════════════
#  UEFI application build
# ═══════════════════════════════════════════════════════════════════
uefi: check-uefi-tools
	@echo "[uefi] building UEFI app (arch=$(ARCH), debug=$(DEBUG))..."
	@mkdir -p "$(UEFI_PREFIX)" "$(UEFI_CACHE)"
	@cd "$(ROOT_DIR)" && zig build uefi \
		-Doptimize=Debug \
		-Darch="$(ARCH)" \
		-Ddebug=$(DEBUG) \
		--cache-dir "$(UEFI_CACHE)" \
		--prefix "$(UEFI_PREFIX)"
	@echo "OK: $(UEFI_EFI)"

uefi-release: check-uefi-tools
	@echo "[uefi-release] building UEFI app (arch=$(ARCH), release)..."
	@mkdir -p "$(UEFI_PREFIX)" "$(UEFI_CACHE)"
	@cd "$(ROOT_DIR)" && zig build uefi \
		-Doptimize=ReleaseSafe \
		-Darch="$(ARCH)" \
		-Ddebug=false \
		--cache-dir "$(UEFI_CACHE)" \
		--prefix "$(UEFI_PREFIX)"
	@echo "OK: $(UEFI_EFI)"

# ═══════════════════════════════════════════════════════════════════
#  ESP (EFI System Partition) image
# ═══════════════════════════════════════════════════════════════════
esp: uefi
	@echo "[esp] creating FAT ESP image ($(ARCH), boot=$(EFI_BOOT_NAME))..."
	@mkdir -p "$(BUILD_DIR)" "$(TMP_DIR)"
	@dd if=/dev/zero of="$(ESP_IMG)" bs=1M count=64 status=none
	@mformat -i "$(ESP_IMG)" ::
	@mmd -i "$(ESP_IMG)" ::/EFI
	@mmd -i "$(ESP_IMG)" ::/EFI/BOOT
	@mcopy -i "$(ESP_IMG)" "$(UEFI_EFI)" "::/EFI/BOOT/$(EFI_BOOT_NAME)"
	@echo "OK: $(ESP_IMG)"

# ═══════════════════════════════════════════════════════════════════
#  Run targets – BIOS
# ═══════════════════════════════════════════════════════════════════
run: run-bios

run-bios: iso
	@echo "[run-bios] starting QEMU (x86_64 BIOS, debug=$(DEBUG))..."
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-cdrom "$(ISO)" \
		-serial stdio \
		-display gtk \
		-no-reboot \
		-no-shutdown

run-bios-debug: iso
	@echo "[run-bios-debug] starting QEMU (x86_64 BIOS, debug mode + GDB)..."
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-cdrom "$(ISO)" \
		-serial stdio \
		-display gtk \
		-no-reboot \
		-no-shutdown \
		-S -s \
		-d int,cpu_reset

run-bios-release: DEBUG=false
run-bios-release: iso
	@echo "[run-bios-release] starting QEMU (x86_64 BIOS, release)..."
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-cdrom "$(ISO)" \
		-serial stdio \
		-display gtk \
		-no-reboot \
		-no-shutdown

run-aarch64: ARCH=aarch64
run-aarch64: kernel
	@echo "[run-aarch64] starting qemu-system-aarch64..."
	@$(QEMU_ARM) \
		-machine $(QEMU_ARM_MACHINE) \
		-cpu $(QEMU_ARM_CPU) \
		-nographic \
		-kernel "$(KERNEL_ELF)"

# ═══════════════════════════════════════════════════════════════════
#  Run targets – UEFI
# ═══════════════════════════════════════════════════════════════════

# --- x86_64 UEFI (OVMF) ---
run-uefi-x86_64: ARCH = x86_64
run-uefi-x86_64: EFI_BOOT_NAME = BOOTX64.EFI
run-uefi-x86_64: esp
	@echo "[run-uefi-x86_64] starting QEMU with OVMF (debug=$(DEBUG))..."
	@cp -f "$(OVMF_VARS)" "$(TMP_DIR)/OVMF_VARS.fd"
	@$(QEMU) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file="$(TMP_DIR)/OVMF_VARS.fd" \
		-drive format=raw,file="$(ESP_IMG)" \
		-m $(QEMU_MEM) \
		-serial stdio \
		-display gtk \
		-net none \
		-no-reboot \
		-no-shutdown

run-uefi-debug: ARCH = x86_64
run-uefi-debug: EFI_BOOT_NAME = BOOTX64.EFI
run-uefi-debug: esp
	@echo "[run-uefi-debug] starting QEMU with OVMF (debug + GDB)..."
	@cp -f "$(OVMF_VARS)" "$(TMP_DIR)/OVMF_VARS.fd"
	@$(QEMU) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file="$(TMP_DIR)/OVMF_VARS.fd" \
		-drive format=raw,file="$(ESP_IMG)" \
		-m $(QEMU_MEM) \
		-serial stdio \
		-display gtk \
		-net none \
		-no-reboot \
		-no-shutdown \
		-S -s \
		-d int,cpu_reset

run-uefi-release: ARCH = x86_64
run-uefi-release: DEBUG = false
run-uefi-release: EFI_BOOT_NAME = BOOTX64.EFI
run-uefi-release: esp
	@echo "[run-uefi-release] starting QEMU with OVMF (release)..."
	@cp -f "$(OVMF_VARS)" "$(TMP_DIR)/OVMF_VARS.fd"
	@$(QEMU) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file="$(TMP_DIR)/OVMF_VARS.fd" \
		-drive format=raw,file="$(ESP_IMG)" \
		-m $(QEMU_MEM) \
		-serial stdio \
		-display gtk \
		-net none \
		-no-reboot \
		-no-shutdown

# --- aarch64 UEFI (AAVMF) ---
run-uefi-aarch64: ARCH = aarch64
run-uefi-aarch64: EFI_BOOT_NAME = BOOTAA64.EFI
run-uefi-aarch64: esp
	@echo "[run-uefi-aarch64] starting QEMU with AAVMF..."
	@cp -f "$(AAVMF_VARS)" "$(TMP_DIR)/AAVMF_VARS.fd"
	@$(QEMU_ARM) \
		-machine $(QEMU_ARM_MACHINE) \
		-cpu $(QEMU_ARM_CPU) \
		-drive if=pflash,format=raw,readonly=on,file=$(AAVMF_CODE) \
		-drive if=pflash,format=raw,file="$(TMP_DIR)/AAVMF_VARS.fd" \
		-drive format=raw,file="$(ESP_IMG)" \
		-m $(QEMU_MEM) \
		-nographic \
		-net none \
		-no-reboot \
		-no-shutdown

# ═══════════════════════════════════════════════════════════════════
#  Clean
# ═══════════════════════════════════════════════════════════════════
clean:
	@rm -rf "$(BUILD_DIR)" .zig-cache zig-out

distclean: clean
