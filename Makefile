.PHONY: all kernel uefi iso run run-uefi run-bios clean distclean check-tools help

ROOT_DIR := $(abspath .)
VERSION := 0.0.1
ARCH ?= x86_64
KERNEL_DIR := $(ROOT_DIR)/kernel
UEFI_DIR := $(ROOT_DIR)/uefi
BUILD_DIR := $(ROOT_DIR)/build
TMP_DIR := $(BUILD_DIR)/tmp
RELEASE_DIR := $(BUILD_DIR)/release

ISO_DIR := $(TMP_DIR)/isofiles
BOOT_DIR := $(ISO_DIR)/boot
GRUB_DIR := $(BOOT_DIR)/grub
EFI_ZIRCON_DIR := $(ISO_DIR)/EFI/ZirconOS

KERNEL_PREFIX := $(TMP_DIR)/kernel-prefix
UEFI_PREFIX := $(TMP_DIR)/uefi-prefix

KERNEL_CACHE := $(TMP_DIR)/zig-cache/kernel
UEFI_CACHE := $(TMP_DIR)/zig-cache/uefi

KERNEL_ELF := $(KERNEL_PREFIX)/bin/kernel
STAGED_KERNEL := $(BOOT_DIR)/kernel.elf
UEFI_APP := $(UEFI_PREFIX)/bin/zirconos.efi
STAGED_UEFI_APP := $(EFI_ZIRCON_DIR)/zirconos.efi
GRUB_CFG := $(ROOT_DIR)/boot/grub/grub.cfg
STAGED_GRUB_CFG := $(GRUB_DIR)/grub.cfg
ISO := $(RELEASE_DIR)/zirconos-$(VERSION)-x86_64.iso

QEMU := qemu-system-x86_64
QEMU_MEM ?= 256M
OVMF_CODE ?= /usr/share/OVMF/OVMF_CODE_4M.fd

QEMU_ARM := qemu-system-aarch64
QEMU_ARM_MACHINE ?= virt
QEMU_ARM_CPU ?= cortex-a53

all: iso

help:
	@echo "Targets:"
	@echo "  make kernel                - build kernel ELF (zig, ARCH=$(ARCH))"
	@echo "  make uefi                  - build ZirconOS UEFI app (zig, x86_64)"
	@echo "  make iso                   - build hybrid ISO (BIOS + UEFI, x86_64)"
	@echo "  make run-uefi-x86_64       - run UEFI ISO in QEMU (x86_64 OVMF)"
	@echo "  make run-aarch64           - run kernel in QEMU (aarch64 virt, -nographic)"
	@echo "  make run-aarch64-uefi      - (stub) run aarch64 UEFI flow (TODO: firmware & image)"
	@echo "  make run-bios              - run ISO in QEMU (x86_64 BIOS)"
	@echo "  make run                   - alias of run-uefi-x86_64"
	@echo "  make clean        - remove build artifacts"
	@echo "  make check-tools  - check required tools exist"

check-tools:
	@command -v zig >/dev/null || (echo "missing: zig" && exit 1)
	@command -v grub-mkrescue >/dev/null || (echo "missing: grub-mkrescue (grub-pc-bin)" && exit 1)
	@command -v xorriso >/dev/null || (echo "missing: xorriso" && exit 1)
	@command -v mformat >/dev/null || (echo "missing: mformat (mtools)" && exit 1)
	@command -v $(QEMU) >/dev/null || (echo "missing: $(QEMU) (qemu-system-x86)" && exit 1)
	@echo "OK: tools found"

kernel: check-tools
	@echo "[kernel] building..."
	@mkdir -p "$(KERNEL_PREFIX)" "$(KERNEL_CACHE)"
	@cd "$(KERNEL_DIR)" && zig build -Doptimize=Debug -Darch="$(ARCH)" --cache-dir "$(KERNEL_CACHE)" --prefix "$(KERNEL_PREFIX)"

uefi: check-tools
	@echo "[uefi] building..."
	@mkdir -p "$(UEFI_PREFIX)" "$(UEFI_CACHE)"
	@cd "$(UEFI_DIR)" && zig build -Doptimize=Debug --cache-dir "$(UEFI_CACHE)" --prefix "$(UEFI_PREFIX)"

$(GRUB_DIR):
	@mkdir -p "$(GRUB_DIR)"

$(EFI_ZIRCON_DIR):
	@mkdir -p "$(EFI_ZIRCON_DIR)"

$(STAGED_KERNEL): kernel | $(GRUB_DIR)
	@cp -f "$(KERNEL_ELF)" "$(STAGED_KERNEL)"

$(STAGED_UEFI_APP): uefi | $(EFI_ZIRCON_DIR)
	@cp -f "$(UEFI_APP)" "$(STAGED_UEFI_APP)"

$(STAGED_GRUB_CFG): $(GRUB_CFG) | $(GRUB_DIR)
	@cp -f "$(GRUB_CFG)" "$(STAGED_GRUB_CFG)"

iso: ARCH=x86_64
iso: check-tools $(STAGED_UEFI_APP) $(STAGED_KERNEL) $(STAGED_GRUB_CFG)
	@echo "[iso] building hybrid ISO (BIOS + UEFI)..."
	@mkdir -p "$(RELEASE_DIR)"
	@grub-mkrescue -o "$(ISO)" "$(ISO_DIR)" >/dev/null
	@echo "OK: $(ISO)"

run: run-uefi-x86_64

run-uefi: run-uefi-x86_64

run-uefi-x86_64: iso
	@if [ ! -f "$(OVMF_CODE)" ]; then echo "missing OVMF firmware: $(OVMF_CODE) (install: ovmf)"; exit 1; fi
	@echo "[run-uefi-x86_64] starting qemu (OVMF x86_64)..."
	@$(QEMU) \
		-machine q35 \
		-drive if=pflash,format=raw,readonly=on,file="$(OVMF_CODE)" \
		-m $(QEMU_MEM) \
		-cdrom "$(ISO)" \
		-serial stdio \
		-display gtk \
		-no-reboot \
		-no-shutdown

run-aarch64: ARCH=aarch64
run-aarch64: kernel
	@echo "[run-aarch64] starting qemu-system-aarch64 (virt, -nographic)..."
	@$(QEMU_ARM) \
		-machine $(QEMU_ARM_MACHINE) \
		-cpu $(QEMU_ARM_CPU) \
		-nographic \
		-kernel "$(KERNEL_ELF)"

run-aarch64-uefi:
	@echo "run-aarch64-uefi: 需要为 aarch64 准备 UEFI 固件与启动镜像，目前作为占位目标保留，后续按实际固件路径和镜像格式补全。"
	@exit 1

run-bios: iso
	@echo "[run-bios] starting qemu (bios)..."
	@$(QEMU) \
		-m $(QEMU_MEM) \
		-cdrom "$(ISO)" \
		-serial stdio \
		-display gtk \
		-no-reboot \
		-no-shutdown

clean:
	@rm -rf "$(BUILD_DIR)"

distclean: clean

