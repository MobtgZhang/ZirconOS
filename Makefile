.PHONY: all build build-release build-zbm build-zbm-disk iso run run-debug run-release \
	run-zbm run-zbm-uefi run-aarch64 run-uefi run-uefi-aarch64 clean help

VERSION := 1.0.0

all: iso

help:
	@echo "ZirconOS v$(VERSION) - NT-style Hybrid Microkernel OS"
	@echo ""
	@echo "  Kernel:"
	@echo "  make build             - Build kernel ELF (debug)"
	@echo "  make build-release     - Build kernel ELF (release)"
	@echo ""
	@echo "  ZirconOS Boot Manager (ZBM):"
	@echo "  make build-zbm         - Build ZBM BIOS components (MBR/VBR/stage2)"
	@echo "  make build-zbm-disk    - Build ZBM disk images (MBR + GPT)"
	@echo ""
	@echo "  ISO (GRUB):"
	@echo "  make iso               - Build bootable ISO (x86_64 BIOS, GRUB)"
	@echo ""
	@echo "  Run in QEMU:"
	@echo "  make run               - Run via GRUB (x86_64 BIOS)"
	@echo "  make run-debug         - Run via GRUB with GDB server"
	@echo "  make run-release       - Run via GRUB (release)"
	@echo "  make run-zbm           - Run via ZBM (BIOS/MBR Boot Manager)"
	@echo "  make run-zbm-uefi      - Run via ZBM (UEFI/GPT Boot Manager)"
	@echo "  make run-uefi          - Run via GRUB (x86_64 UEFI)"
	@echo "  make run-aarch64       - Run in QEMU (aarch64 virt)"
	@echo "  make run-uefi-aarch64  - Run in QEMU (aarch64 UEFI)"
	@echo "  make clean             - Remove build artifacts"
	@echo ""
	@echo "  Boot Paths:"
	@echo "  GRUB:        BIOS/UEFI -> GRUB -> Multiboot2 -> kernel.elf"
	@echo "  ZBM (MBR):   BIOS -> MBR -> VBR -> stage2 -> ZBM -> kernel.elf"
	@echo "  ZBM (GPT):   BIOS -> pMBR -> stage2 -> ZBM -> kernel.elf"
	@echo "  ZBM (UEFI):  UEFI -> ESP -> zbmfw.efi -> ZBM -> kernel.elf"
	@echo ""
	@echo "Options: ARCH=x86_64|aarch64  DEBUG=true|false  QEMU_MEM=256M"
	@echo "See ./run.sh help for more details."

build:
	@./run.sh build

build-release:
	@./run.sh build-release

build-zbm:
	@./run.sh build-zbm

build-zbm-disk:
	@./run.sh build-zbm-disk

iso:
	@./run.sh iso

run:
	@./run.sh run

run-debug:
	@./run.sh run-debug

run-release:
	@./run.sh run-release

run-zbm:
	@./run.sh run-zbm

run-zbm-uefi:
	@./run.sh run-zbm-uefi

run-aarch64:
	@./run.sh run-aarch64

run-uefi:
	@./run.sh run-uefi

run-uefi-aarch64:
	@./run.sh run-uefi-aarch64

clean:
	@./run.sh clean
