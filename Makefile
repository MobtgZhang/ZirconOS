# ZirconOS — NT-style Hybrid Microkernel OS
# Build system reads build.conf for default configuration.
# Override any setting via command line: make DESKTOP=aero BOOT_METHOD=uefi
#
# Requires: zig, qemu-system-x86_64, OVMF firmware, grub-mkrescue, xorriso, mtools

.PHONY: all build build-release iso run run-debug \
	build-zbm-uefi build-zbm-bios build-zbm-disk build-esp \
	build-desktop build-desktop-all build-desktop-dll \
	fetch-themes fonts resources \
	test test-kernel test-config test-boot test-all \
	clean help show-config configure

# ══════════════════════════════════════════════════════
#  Configuration: read from build.conf, allow overrides
# ══════════════════════════════════════════════════════

-include build.conf

VERSION      := 1.0.0
ARCH         ?= x86_64
BOOT_METHOD  ?= uefi
BOOTLOADER   ?= grub
DESKTOP      ?= sunvalley
OPTIMIZE     ?= Debug
RESOLUTION   ?= 1024x768x32
QEMU_MEM     ?= 512M
ENABLE_IDT   ?= true
DEBUG_LOG    ?= true
GRUB_MENU    ?= minimal

# Validate DESKTOP
VALID_DESKTOPS := classic luna aero modern fluent sunvalley none
ifeq ($(filter $(DESKTOP),$(VALID_DESKTOPS)),)
$(error Invalid DESKTOP='$(DESKTOP)'. Valid: $(VALID_DESKTOPS))
endif

# Validate BOOT_METHOD
VALID_BOOT_METHODS := mbr uefi
ifeq ($(filter $(BOOT_METHOD),$(VALID_BOOT_METHODS)),)
$(error Invalid BOOT_METHOD='$(BOOT_METHOD)'. Valid: $(VALID_BOOT_METHODS))
endif

# Validate BOOTLOADER
VALID_BOOTLOADERS := grub zbm
ifeq ($(filter $(BOOTLOADER),$(VALID_BOOTLOADERS)),)
$(error Invalid BOOTLOADER='$(BOOTLOADER)'. Valid: $(VALID_BOOTLOADERS))
endif

# ── Derived Paths ──

ROOT_DIR     := $(shell pwd)
BUILD_DIR    := $(ROOT_DIR)/build
TMP_DIR      := $(BUILD_DIR)/tmp
RELEASE_DIR  := $(BUILD_DIR)/release

KERNEL_ELF_DEBUG := $(TMP_DIR)/kernel-prefix/bin/kernel
KERNEL_ELF       := $(TMP_DIR)/kernel.elf
ISO              := $(RELEASE_DIR)/zirconos-$(VERSION)-$(ARCH).iso
TEST_RESULTS_DIR := $(BUILD_DIR)/test-results

GRUB_CFG_TMPL    := $(ROOT_DIR)/boot/grub/grub.cfg
GRUB_CFG_FULL    := $(ROOT_DIR)/boot/grub/grub-full.cfg

OVMF_CODE    ?= /usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS    ?= /usr/share/OVMF/OVMF_VARS_4M.fd

ZBM_DIR          := $(TMP_DIR)/zbm
ZBM_SRC_DIR      := $(ROOT_DIR)/boot/zbm/bios
UEFI_PREFIX      := $(TMP_DIR)/uefi-prefix
UEFI_CACHE       := $(TMP_DIR)/uefi-cache
UEFI_EFI         := $(UEFI_PREFIX)/bin/zirconos.efi
ESP_IMG          := $(BUILD_DIR)/esp-$(ARCH).img
ZBM_DISK_MBR     := $(BUILD_DIR)/zirconos-mbr.img
ZBM_DISK_GPT     := $(BUILD_DIR)/zirconos-gpt.img

THEME_DIR_MAP_classic    := $(ROOT_DIR)/3rdparty/ZirconOSClassic
THEME_DIR_MAP_luna       := $(ROOT_DIR)/3rdparty/ZirconOSLuna
THEME_DIR_MAP_aero       := $(ROOT_DIR)/3rdparty/ZirconOSAero
THEME_DIR_MAP_modern     := $(ROOT_DIR)/3rdparty/ZirconOSModern
THEME_DIR_MAP_fluent     := $(ROOT_DIR)/3rdparty/ZirconOSFluent
THEME_DIR_MAP_sunvalley  := $(ROOT_DIR)/3rdparty/ZirconOSSunValley
FONTS_DIR                := $(ROOT_DIR)/3rdparty/ZirconOSFonts

THEME_DIR := $(THEME_DIR_MAP_$(DESKTOP))

# Common QEMU flags
QEMU_COMMON := -m $(QEMU_MEM) -serial stdio -no-reboot -no-shutdown \
	-display gtk,zoom-to-fit=on,show-cursor=on -vga std \
	-usb -device usb-mouse -device usb-kbd

# ══════════════════════════════════════════════════════
#  Default target: build & run according to build.conf
# ══════════════════════════════════════════════════════

all: run

# ══════════════════════════════════════════════════════
#  show-config: display current build configuration
# ══════════════════════════════════════════════════════

show-config:
	@echo "╔══════════════════════════════════════════════╗"
	@echo "║     ZirconOS v$(VERSION) Build Configuration     ║"
	@echo "╠══════════════════════════════════════════════╣"
	@echo "║  ARCH         = $(ARCH)"
	@echo "║  BOOT_METHOD  = $(BOOT_METHOD)"
	@echo "║  BOOTLOADER   = $(BOOTLOADER)"
	@echo "║  DESKTOP      = $(DESKTOP)"
	@echo "║  OPTIMIZE     = $(OPTIMIZE)"
	@echo "║  RESOLUTION   = $(RESOLUTION)"
	@echo "║  QEMU_MEM     = $(QEMU_MEM)"
	@echo "║  GRUB_MENU    = $(GRUB_MENU)"
	@echo "║  ENABLE_IDT   = $(ENABLE_IDT)"
	@echo "║  DEBUG_LOG    = $(DEBUG_LOG)"
	@echo "╚══════════════════════════════════════════════╝"

# ══════════════════════════════════════════════════════
#  configure: interactive helper to edit build.conf
# ══════════════════════════════════════════════════════

configure:
	@python3 $(ROOT_DIR)/scripts/configure.py

# ══════════════════════════════════════════════════════
#  help
# ══════════════════════════════════════════════════════

help:
	@echo "ZirconOS v$(VERSION) — NT-style Hybrid Microkernel OS"
	@echo ""
	@echo "Configuration (edit build.conf or override via CLI):"
	@echo "  make show-config            Show current build.conf settings"
	@echo "  make configure              Interactive configuration wizard"
	@echo ""
	@echo "Build:"
	@echo "  make                        Build & run (using build.conf)"
	@echo "  make build                  Build kernel only"
	@echo "  make build-release          Build kernel (ReleaseSafe)"
	@echo "  make build-desktop          Build desktop theme (EXE + LIB + DLL)"
	@echo "  make build-desktop-all      Build all desktop themes"
	@echo "  make build-desktop-dll      Build desktop theme DLL only"
	@echo "  make iso                    Build hybrid bootable ISO"
	@echo "  make build-zbm-uefi        Build ZBM UEFI application"
	@echo "  make build-zbm-bios        Build ZBM BIOS components"
	@echo "  make build-zbm-disk        Build ZBM bootable disk images"
	@echo "  make build-esp             Build EFI System Partition image"
	@echo ""
	@echo "Run (auto-selects from build.conf):"
	@echo "  make run                    Build + run per build.conf"
	@echo "  make run-debug              Run with GDB server on :1234"
	@echo ""
	@echo "Override examples:"
	@echo "  make DESKTOP=aero                        Aero desktop"
	@echo "  make BOOT_METHOD=mbr BOOTLOADER=grub     BIOS + GRUB"
	@echo "  make BOOT_METHOD=uefi BOOTLOADER=zbm     UEFI + ZBM"
	@echo "  make DESKTOP=none                        Text/CMD mode"
	@echo ""
	@echo "Test:"
	@echo "  make test                   Run all tests"
	@echo "  make test-kernel            Kernel ELF verification tests"
	@echo "  make test-config            Build configuration tests"
	@echo "  make test-boot              Boot combination tests"
	@echo ""
	@echo "Resources:"
	@echo "  make fonts                  Fetch fonts"
	@echo "  make fetch-themes           Clone all theme repos"
	@echo "  make resources              List theme resources"
	@echo "  make clean                  Remove build artifacts"
	@echo ""
	@echo "Boot Paths:"
	@echo "  GRUB (BIOS):     BIOS -> GRUB -> Multiboot2 -> kernel.elf"
	@echo "  GRUB (UEFI):     UEFI -> GRUB -> Multiboot2 -> kernel.elf"
	@echo "  ZBM  (BIOS/MBR): BIOS -> MBR -> VBR -> Stage2 -> ZBM -> kernel"
	@echo "  ZBM  (UEFI/GPT): UEFI -> ESP -> zbmfw.efi -> ZBM -> kernel"

# ══════════════════════════════════════════════════════
#  Build kernel
# ══════════════════════════════════════════════════════

build:
	@echo "[ZirconOS] Building kernel (arch=$(ARCH), optimize=$(OPTIMIZE), desktop=$(DESKTOP))..."
	@mkdir -p $(TMP_DIR)/kernel-prefix $(TMP_DIR)/zig-cache
	cd $(ROOT_DIR) && zig build \
		-Doptimize=$(OPTIMIZE) \
		-Darch=$(ARCH) \
		-Ddebug=$(DEBUG_LOG) \
		-Denable_idt=$(ENABLE_IDT) \
		-Ddefault_desktop=$(DESKTOP) \
		--cache-dir $(TMP_DIR)/zig-cache \
		--prefix $(TMP_DIR)/kernel-prefix
	@echo "[ZirconOS] Stripping debug sections..."
	objcopy --strip-debug $(KERNEL_ELF_DEBUG) $(KERNEL_ELF)
	@echo "[ZirconOS] Kernel: $(KERNEL_ELF)"

build-release:
	@$(MAKE) build OPTIMIZE=ReleaseSafe

# ══════════════════════════════════════════════════════
#  Build desktop theme
# ══════════════════════════════════════════════════════

build-desktop:
	@echo "[ZirconOS] Building desktop theme: $(DESKTOP) (EXE + LIB + DLL)..."
	@if [ "$(DESKTOP)" = "none" ]; then \
		echo "[ZirconOS] DESKTOP=none, skipping desktop build"; \
	elif [ -d "$(THEME_DIR)" ]; then \
		cd $(THEME_DIR) && zig build -Doptimize=$(OPTIMIZE) && \
		cd $(THEME_DIR) && zig build dll -Doptimize=$(OPTIMIZE); \
	else \
		echo "[ZirconOS] Theme directory not found: $(THEME_DIR)"; \
	fi

build-desktop-all:
	@echo "[ZirconOS] Building all desktop themes (EXE + LIB + DLL)..."
	@for theme in classic luna aero modern fluent sunvalley; do \
		dir="$(ROOT_DIR)/3rdparty/ZirconOS$$(echo $$theme | python3 -c 'import sys; print(sys.stdin.read().strip().title())')"; \
		if [ -d "$$dir" ]; then \
			echo "[ZirconOS]   Building $$theme..."; \
			cd "$$dir" && zig build -Doptimize=$(OPTIMIZE) && \
			cd "$$dir" && zig build dll -Doptimize=$(OPTIMIZE); \
		else \
			echo "[ZirconOS]   Skipping $$theme (not found: $$dir)"; \
		fi; \
	done

build-desktop-dll:
	@echo "[ZirconOS] Building desktop theme DLL: $(DESKTOP)..."
	@if [ "$(DESKTOP)" = "none" ]; then \
		echo "[ZirconOS] DESKTOP=none, skipping DLL build"; \
	elif [ -d "$(THEME_DIR)" ]; then \
		cd $(THEME_DIR) && zig build dll -Doptimize=$(OPTIMIZE); \
	else \
		echo "[ZirconOS] Theme directory not found: $(THEME_DIR)"; \
	fi

# ══════════════════════════════════════════════════════
#  ZBM UEFI Boot Application
# ══════════════════════════════════════════════════════

build-zbm-uefi:
	@echo "[ZirconOS] Building ZBM UEFI boot application..."
	@mkdir -p $(UEFI_PREFIX) $(UEFI_CACHE)
	cd $(ROOT_DIR) && zig build uefi \
		-Doptimize=$(OPTIMIZE) \
		-Darch=$(ARCH) \
		-Ddesktop=$(DESKTOP) \
		--cache-dir $(UEFI_CACHE) \
		--prefix $(UEFI_PREFIX)
	@echo "[ZirconOS] UEFI app: $(UEFI_EFI)"

# ══════════════════════════════════════════════════════
#  ZBM BIOS Boot Components (MBR + VBR + Stage2)
# ══════════════════════════════════════════════════════

build-zbm-bios:
	@echo "[ZirconOS] Building ZBM BIOS components..."
	@mkdir -p $(ZBM_DIR)
	as --32 -o $(ZBM_DIR)/mbr.o $(ZBM_SRC_DIR)/mbr.s
	ld -m elf_i386 -T $(ROOT_DIR)/link/mbr.ld -o $(ZBM_DIR)/mbr.elf $(ZBM_DIR)/mbr.o 2>/dev/null || true
	objcopy -O binary $(ZBM_DIR)/mbr.o $(ZBM_DIR)/mbr.bin
	truncate -s 512 $(ZBM_DIR)/mbr.bin
	@echo "[ZirconOS] MBR: $(ZBM_DIR)/mbr.bin"
	as --32 -o $(ZBM_DIR)/vbr.o $(ZBM_SRC_DIR)/vbr.s
	ld -m elf_i386 -T $(ROOT_DIR)/link/vbr.ld -o $(ZBM_DIR)/vbr.elf $(ZBM_DIR)/vbr.o 2>/dev/null || true
	objcopy -O binary $(ZBM_DIR)/vbr.o $(ZBM_DIR)/vbr.bin
	truncate -s 512 $(ZBM_DIR)/vbr.bin
	@echo "[ZirconOS] VBR: $(ZBM_DIR)/vbr.bin"
	as --32 -o $(ZBM_DIR)/stage2.o $(ZBM_SRC_DIR)/stage2.s
	ld -m elf_i386 -T $(ROOT_DIR)/link/zbm_bios.ld -o $(ZBM_DIR)/stage2.elf $(ZBM_DIR)/stage2.o 2>/dev/null || true
	objcopy -O binary $(ZBM_DIR)/stage2.o $(ZBM_DIR)/stage2.bin
	@echo "[ZirconOS] Stage2: $(ZBM_DIR)/stage2.bin"
	cd $(ROOT_DIR) && zig build zbm \
		-Doptimize=ReleaseSmall \
		-Darch=x86_64 \
		--cache-dir $(TMP_DIR)/zig-cache \
		--prefix $(TMP_DIR)/kernel-prefix 2>/dev/null || true
	@echo "[ZirconOS] ZBM BIOS components built"

# ══════════════════════════════════════════════════════
#  ZBM Disk Images (MBR + GPT)
# ══════════════════════════════════════════════════════

build-zbm-disk: build-zbm-bios build
	@echo "[ZirconOS] Building ZBM disk images (128 MB)..."
	@mkdir -p $(BUILD_DIR)
	dd if=/dev/zero of=$(ZBM_DISK_MBR) bs=1M count=128 status=none
	dd if=$(ZBM_DIR)/mbr.bin of=$(ZBM_DISK_MBR) bs=512 count=1 conv=notrunc status=none
	@python3 -c "\
	import struct; \
	entry = struct.pack('<BBBBBBBBII', \
	    0x80, 0x00, 0x21, 0x00, \
	    0xFE, 0xFE, 0xFF, 0xFF, \
	    2048, (128*1024*1024//512)-2048); \
	f = open('$(ZBM_DISK_MBR)', 'r+b'); \
	f.seek(446); f.write(entry); f.close()" 2>/dev/null || true
	dd if=$(ZBM_DIR)/vbr.bin of=$(ZBM_DISK_MBR) bs=512 seek=2048 count=1 conv=notrunc status=none
	dd if=$(ZBM_DIR)/stage2.bin of=$(ZBM_DISK_MBR) bs=512 seek=2049 conv=notrunc status=none
	dd if=$(KERNEL_ELF) of=$(ZBM_DISK_MBR) bs=512 seek=2113 conv=notrunc status=none
	@echo "[ZirconOS] MBR disk: $(ZBM_DISK_MBR)"
	@if command -v sgdisk >/dev/null 2>&1; then \
		dd if=/dev/zero of=$(ZBM_DISK_GPT) bs=1M count=128 status=none; \
		sgdisk --clear $(ZBM_DISK_GPT) >/dev/null 2>&1; \
		sgdisk -n 1:2048:67583 -t 1:EF00 -c 1:"EFI System" $(ZBM_DISK_GPT) >/dev/null 2>&1; \
		sgdisk -n 2:67584:0 -t 2:8300 -c 2:"ZirconOS System" $(ZBM_DISK_GPT) >/dev/null 2>&1; \
		dd if=$(ZBM_DIR)/stage2.bin of=$(ZBM_DISK_GPT) bs=512 seek=34 conv=notrunc status=none; \
		echo "[ZirconOS] GPT disk: $(ZBM_DISK_GPT)"; \
	else \
		echo "[ZirconOS] sgdisk not found, skipping GPT (apt install gdisk)"; \
	fi

# ══════════════════════════════════════════════════════
#  ESP (EFI System Partition) Image
# ══════════════════════════════════════════════════════

build-esp: build-zbm-uefi build
	@echo "[ZirconOS] Building ESP image..."
	dd if=/dev/zero of=$(ESP_IMG) bs=1M count=64 status=none
	mformat -i $(ESP_IMG) ::
	mmd -i $(ESP_IMG) ::/EFI
	mmd -i $(ESP_IMG) ::/EFI/BOOT
	mcopy -i $(ESP_IMG) $(UEFI_EFI) ::/EFI/BOOT/BOOTX64.EFI
	@if [ -f "$(KERNEL_ELF)" ]; then \
		mmd -i $(ESP_IMG) ::/boot 2>/dev/null || true; \
		mcopy -i $(ESP_IMG) $(KERNEL_ELF) ::/boot/kernel.elf 2>/dev/null || true; \
	fi
	@echo "[ZirconOS] ESP image: $(ESP_IMG)"

# ══════════════════════════════════════════════════════
#  GRUB config generation (respects GRUB_MENU setting)
# ══════════════════════════════════════════════════════

_generate_grub_cfg:
	@echo "[ZirconOS] Generating GRUB config (desktop=$(DESKTOP), menu=$(GRUB_MENU))..."
	@python3 $(ROOT_DIR)/scripts/gen_grub_cfg.py \
		--template $(GRUB_CFG_FULL) \
		--output $(TMP_DIR)/isofiles/boot/grub/grub.cfg \
		--version $(VERSION) \
		--resolution $(RESOLUTION) \
		--desktop $(DESKTOP) \
		--menu-mode $(GRUB_MENU)

# ══════════════════════════════════════════════════════
#  ISO (Hybrid: BIOS + UEFI)
# ══════════════════════════════════════════════════════

iso: build
	@echo "[ZirconOS] Building hybrid ISO (BIOS + UEFI, desktop=$(DESKTOP))..."
	@mkdir -p $(TMP_DIR)/isofiles/boot/grub $(RELEASE_DIR)
	@mkdir -p $(TMP_DIR)/isofiles/EFI/BOOT
	@cp -f $(KERNEL_ELF) $(TMP_DIR)/isofiles/boot/kernel.elf
	@$(MAKE) _generate_grub_cfg
	@if command -v zig >/dev/null 2>&1; then \
		$(MAKE) build-zbm-uefi 2>/dev/null && \
		if [ -f "$(UEFI_EFI)" ]; then \
			cp -f $(UEFI_EFI) $(TMP_DIR)/isofiles/EFI/BOOT/BOOTX64.EFI; \
		fi; \
	fi
	grub-mkrescue -o $(ISO) $(TMP_DIR)/isofiles
	@echo "[ZirconOS] ISO: $(ISO)"

# ══════════════════════════════════════════════════════
#  run: unified entry point driven by build.conf
# ══════════════════════════════════════════════════════

run:
ifeq ($(BOOTLOADER),grub)
ifeq ($(BOOT_METHOD),uefi)
	@$(MAKE) _run-grub-uefi
else
	@$(MAKE) _run-grub-bios
endif
else ifeq ($(BOOTLOADER),zbm)
ifeq ($(BOOT_METHOD),uefi)
	@$(MAKE) _run-zbm-uefi
else
	@$(MAKE) _run-zbm-bios
endif
endif

# ── GRUB + UEFI ──
_run-grub-uefi: iso
	@echo "[ZirconOS] UEFI + GRUB → $(DESKTOP) Desktop ($(RESOLUTION), $(QEMU_MEM))..."
	@mkdir -p $(TMP_DIR)
	@if [ -f $(OVMF_CODE) ]; then \
		cp -f $(OVMF_VARS) $(TMP_DIR)/OVMF_VARS.fd; \
		qemu-system-x86_64 \
			-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
			-drive if=pflash,format=raw,file=$(TMP_DIR)/OVMF_VARS.fd \
			-cdrom $(ISO) \
			$(QEMU_COMMON); \
	else \
		echo "[ZirconOS] OVMF not found, falling back to BIOS"; \
		$(MAKE) _run-grub-bios; \
	fi

# ── GRUB + BIOS ──
_run-grub-bios: iso
	@echo "[ZirconOS] BIOS + GRUB → $(DESKTOP) Desktop ($(RESOLUTION))..."
	qemu-system-x86_64 \
		-cdrom $(ISO) \
		$(QEMU_COMMON)

# ── ZBM + BIOS ──
_run-zbm-bios: build-zbm-disk
	@echo "[ZirconOS] BIOS + ZBM → $(DESKTOP) Desktop ($(QEMU_MEM))..."
	qemu-system-x86_64 \
		-drive format=raw,file=$(ZBM_DISK_MBR) \
		$(QEMU_COMMON)

# ── ZBM + UEFI ──
_run-zbm-uefi: build-esp
	@echo "[ZirconOS] UEFI + ZBM → $(DESKTOP) Desktop ($(QEMU_MEM))..."
	@mkdir -p $(TMP_DIR)
	@cp -f $(OVMF_VARS) $(TMP_DIR)/OVMF_VARS.fd
	qemu-system-x86_64 \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(TMP_DIR)/OVMF_VARS.fd \
		-drive format=raw,file=$(ESP_IMG) \
		$(QEMU_COMMON)

# ── Debug mode (GDB) ──
run-debug: iso
	@echo "[ZirconOS] Debug mode (GDB on :1234)..."
	qemu-system-x86_64 \
		-cdrom $(ISO) \
		$(QEMU_COMMON) \
		-s -S

# ══════════════════════════════════════════════════════
#  Resources / Fonts / Themes
# ══════════════════════════════════════════════════════

fonts:
	@if [ -x $(FONTS_DIR)/fetch-fonts.sh ]; then \
		cd $(FONTS_DIR) && ./fetch-fonts.sh; \
	else \
		echo "[ZirconOS] $(FONTS_DIR)/fetch-fonts.sh not found"; \
	fi

resources:
	@echo "[ZirconOS] Resources for $(DESKTOP) theme:"
	@if [ -n "$(THEME_DIR)" ] && [ -d "$(THEME_DIR)/resources" ]; then \
		echo "  Wallpapers:"; \
		ls -1 $(THEME_DIR)/resources/wallpapers/*.svg 2>/dev/null | sed 's/.*\//    /' || echo "    (none)"; \
		echo "  Icons:"; \
		ls -1 $(THEME_DIR)/resources/icons/*.svg 2>/dev/null | sed 's/.*\//    /' || echo "    (none)"; \
		echo "  Cursors:"; \
		ls -1 $(THEME_DIR)/resources/cursors/*.svg 2>/dev/null | sed 's/.*\//    /' || echo "    (none)"; \
		echo "  Themes:"; \
		ls -1 $(THEME_DIR)/resources/themes/*.theme 2>/dev/null | sed 's/.*\//    /' || echo "    (none)"; \
	else \
		echo "  (theme directory not found)"; \
	fi

fetch-themes:
	@if [ -x $(ROOT_DIR)/3rdparty/fetch-themes.sh ]; then \
		$(ROOT_DIR)/3rdparty/fetch-themes.sh; \
	else \
		echo "[ZirconOS] fetch-themes.sh not found"; \
	fi

# ══════════════════════════════════════════════════════
#  Tests
# ══════════════════════════════════════════════════════

test: test-kernel test-config test-boot
	@echo "[ZirconOS] All tests complete."

test-kernel: build
	@echo "[ZirconOS] Running kernel verification tests..."
	@mkdir -p $(TEST_RESULTS_DIR)
	python3 $(ROOT_DIR)/tests/run_all.py \
		--kernel $(KERNEL_ELF) \
		--output-dir $(TEST_RESULTS_DIR)

test-config:
	@echo "[ZirconOS] Running build configuration tests..."
	@mkdir -p $(TEST_RESULTS_DIR)
	python3 $(ROOT_DIR)/tests/test_build_config.py \
		--project-root $(ROOT_DIR) \
		--output-dir $(TEST_RESULTS_DIR)

test-boot:
	@echo "[ZirconOS] Running boot combination tests..."
	@mkdir -p $(TEST_RESULTS_DIR)
	python3 $(ROOT_DIR)/tests/test_boot_combinations.py \
		--project-root $(ROOT_DIR) \
		--output-dir $(TEST_RESULTS_DIR)

# ══════════════════════════════════════════════════════
#  Clean
# ══════════════════════════════════════════════════════

clean:
	@echo "[ZirconOS] Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -rf $(ROOT_DIR)/.zig-cache $(ROOT_DIR)/zig-out
	@for theme in classic luna aero modern fluent sunvalley; do \
		dir="$(ROOT_DIR)/3rdparty/ZirconOS$$(echo $$theme | sed 's/.*/\u&/')"; \
		[ -d "$$dir" ] && rm -rf "$$dir/.zig-cache" "$$dir/zig-out" 2>/dev/null; \
	done || true
	@echo "[ZirconOS] Clean done"
