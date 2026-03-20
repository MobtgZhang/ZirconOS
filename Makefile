.PHONY: all build build-release build-zbm build-zbm-disk iso iso-release run run-debug run-release \
	run-zbm run-zbm-uefi run-aarch64 run-uefi run-uefi-aarch64 \
	run-desktop run-desktop-release run-desktop-uefi \
	run-desktop-classic run-desktop-luna run-desktop-aero \
	run-desktop-modern run-desktop-fluent run-desktop-sunvalley \
	desktop desktop-all build-desktop fetch-themes clean help

VERSION := 1.0.0

# Default desktop theme (overridable: make run-desktop DESKTOP=aero)
DESKTOP ?= classic

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
	@echo "  Desktop Themes:"
	@echo "  make fetch-themes      - Clone desktop theme repos into 3rdparty/"
	@echo "  make build-desktop     - Build desktop theme (DESKTOP=classic)"
	@echo "  make desktop           - Build default desktop theme (classic)"
	@echo "  make desktop-all       - Build all desktop themes"
	@echo ""
	@echo "  Run with Desktop (select theme):"
	@echo "  make run-desktop                  - Run with desktop (debug, screen+serial log)"
	@echo "  make run-desktop-release          - Run with desktop (release, serial log only)"
	@echo "  make run-desktop DESKTOP=<theme>  - Run with selected desktop"
	@echo "  make run-desktop-classic          - Run with Classic (Win2000)"
	@echo "  make run-desktop-luna             - Run with Luna (WinXP)"
	@echo "  make run-desktop-aero            - Run with Aero (Win7)"
	@echo "  make run-desktop-modern           - Run with Modern (Win8)"
	@echo "  make run-desktop-fluent           - Run with Fluent (Win10)"
	@echo "  make run-desktop-sunvalley        - Run with Sun Valley (Win11)"
	@echo "  make run-desktop-uefi             - Run desktop mode via UEFI"
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
	@echo "  Available Desktops: classic, luna, aero, modern, fluent, sunvalley"
	@echo ""
	@echo "Options: ARCH=x86_64|aarch64  DEBUG=true|false  QEMU_MEM=256M  DESKTOP=<theme>"
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

# ── Desktop theme targets ──

run-desktop:
	@DESKTOP=$(DESKTOP) ./run.sh run-desktop Debug $(DESKTOP)

run-desktop-release:
	@DESKTOP=$(DESKTOP) ./run.sh run-desktop-release $(DESKTOP)

run-desktop-uefi:
	@DESKTOP=$(DESKTOP) ./run.sh run-desktop-uefi Debug $(DESKTOP)

run-desktop-classic:
	@DESKTOP=classic ./run.sh run-desktop Debug classic

run-desktop-luna:
	@DESKTOP=luna ./run.sh run-desktop Debug luna

run-desktop-aero:
	@DESKTOP=aero ./run.sh run-desktop Debug aero

run-desktop-modern:
	@DESKTOP=modern ./run.sh run-desktop Debug modern

run-desktop-fluent:
	@DESKTOP=fluent ./run.sh run-desktop Debug fluent

run-desktop-sunvalley:
	@DESKTOP=sunvalley ./run.sh run-desktop Debug sunvalley

fetch-themes:
	@./3rdparty/fetch-themes.sh

build-desktop:
	@./run.sh build-desktop $(DESKTOP)

desktop:
	@echo "Building desktop theme: $(DESKTOP)"
	@zig build desktop -Dtheme=$(DESKTOP)

desktop-all:
	@echo "Building all desktop themes..."
	@zig build desktop-all

clean:
	@./run.sh clean
