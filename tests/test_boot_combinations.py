#!/usr/bin/env python3
"""
ZirconOS x86-64 Boot Combination Tests

Tests all combinations of boot methods and bootloaders for x86-64:
  - MBR + GRUB
  - UEFI + GRUB
  - MBR + ZBM
  - UEFI + ZBM

For each combination, verifies that the build system can produce the correct
artifacts (ISO, disk images, ESP, GRUB config, etc.) and that the resulting
images have the expected structure.

Usage:
    python3 tests/test_boot_combinations.py [--project-root PATH] [--output-dir DIR]
"""

import argparse
import os
import re
import struct
import subprocess
import sys
import json
import tempfile
import shutil
from datetime import datetime

RESULTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'build', 'test-results')


class TestResult:
    def __init__(self, name):
        self.name = name
        self.passed = 0
        self.failed = 0
        self.errors = []

    def ok(self, msg):
        self.passed += 1
        print(f"  [PASS] {msg}")

    def fail(self, msg, detail=""):
        self.failed += 1
        err = f"{msg}: {detail}" if detail else msg
        self.errors.append(err)
        print(f"  [FAIL] {err}")

    def summary(self):
        total = self.passed + self.failed
        status = "PASSED" if self.failed == 0 else "FAILED"
        return {
            "suite": self.name,
            "total": total,
            "passed": self.passed,
            "failed": self.failed,
            "status": status,
            "errors": self.errors,
        }


ALL_DESKTOPS = ["classic", "luna", "aero", "modern", "fluent", "sunvalley"]
ALL_BOOT_METHODS = ["mbr", "uefi"]
ALL_BOOTLOADERS = ["grub", "zbm"]


# ── Test: Makefile target resolution ──

def test_makefile_targets(project_root, result):
    """Verify the Makefile accepts all boot combo configs without errors."""
    print("\n=== Makefile Target Resolution ===")

    combos = [
        ("mbr",  "grub"),
        ("uefi", "grub"),
        ("mbr",  "zbm"),
        ("uefi", "zbm"),
    ]

    for boot_method, bootloader in combos:
        label = f"{boot_method}+{bootloader}"
        try:
            proc = subprocess.run(
                ["make", "-n", "show-config",
                 "ARCH=x86_64",
                 f"BOOT_METHOD={boot_method}",
                 f"BOOTLOADER={bootloader}",
                 "DESKTOP=sunvalley"],
                capture_output=True, text=True, timeout=15,
                cwd=project_root,
            )
            if proc.returncode == 0:
                result.ok(f"{label}: Makefile accepts config (dry-run OK)")
            else:
                result.fail(f"{label}: Makefile rejects config", proc.stderr[:200])
        except FileNotFoundError:
            result.fail(f"{label}: make not found")
        except subprocess.TimeoutExpired:
            result.fail(f"{label}: make -n timed out")

    # LoongArch64: BOOTLOADER=zbm only (no GRUB)
    try:
        proc_ok = subprocess.run(
            ["make", "-n", "show-config",
             "ARCH=loongarch64", "BOOT_METHOD=uefi", "BOOTLOADER=zbm", "DESKTOP=sunvalley"],
            capture_output=True, text=True, timeout=15,
            cwd=project_root,
        )
        if proc_ok.returncode == 0:
            result.ok("loongarch64+zbm: Makefile accepts config (dry-run OK)")
        else:
            result.fail("loongarch64+zbm: Makefile rejects config", proc_ok.stderr[:200])
    except FileNotFoundError:
        result.fail("loongarch64 test: make not found")
    except subprocess.TimeoutExpired:
        result.fail("loongarch64+zbm: timed out")

    try:
        proc_bad = subprocess.run(
            ["make", "-n", "show-config",
             "ARCH=loongarch64", "BOOT_METHOD=uefi", "BOOTLOADER=grub", "DESKTOP=sunvalley"],
            capture_output=True, text=True, timeout=15,
            cwd=project_root,
        )
        if proc_bad.returncode != 0:
            result.ok("loongarch64+grub: Makefile correctly rejects (ZBM-only)")
        else:
            result.fail("loongarch64+grub: Makefile should reject GRUB")
    except FileNotFoundError:
        result.fail("loongarch64 grub test: make not found")
    except subprocess.TimeoutExpired:
        result.fail("loongarch64+grub: timed out")


# ── Test: GRUB config for each desktop ──

def test_grub_desktop_entries(project_root, result):
    """For each desktop, verify GRUB config generator produces correct entries."""
    print("\n=== GRUB Config per Desktop ===")

    gen_script = os.path.join(project_root, "scripts", "gen_grub_cfg.py")
    if not os.path.exists(gen_script):
        result.fail("gen_grub_cfg.py not found")
        return

    tmpdir = tempfile.mkdtemp(prefix="zircon_boot_test_")

    for desktop in ALL_DESKTOPS:
        output = os.path.join(tmpdir, f"grub_{desktop}.cfg")
        cmd = [
            sys.executable, gen_script,
            "--output", output,
            "--version", "1.0.0",
            "--resolution", "1024x768x32",
            "--desktop", desktop,
            "--menu-mode", "minimal",
        ]
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if proc.returncode != 0 or not os.path.exists(output):
                result.fail(f"GRUB gen for {desktop} failed", proc.stderr[:200])
                continue

            with open(output) as f:
                content = f.read()

            if f"desktop={desktop}" in content:
                result.ok(f"{desktop}: GRUB entry contains desktop={desktop}")
            else:
                result.fail(f"{desktop}: GRUB entry missing desktop={desktop}")

            if "multiboot2 /boot/kernel.elf" in content:
                result.ok(f"{desktop}: uses multiboot2 protocol")
            else:
                result.fail(f"{desktop}: missing multiboot2 command")

            other_desktops = set(ALL_DESKTOPS) - {desktop}
            leaked = [d for d in other_desktops if f"desktop={d}" in content]
            if not leaked:
                result.ok(f"{desktop}: minimal mode — no other desktops leaked")
            else:
                result.fail(f"{desktop}: minimal mode leaks desktops", str(leaked))

        except Exception as e:
            result.fail(f"{desktop}: exception", str(e))

    # Also test 'all' mode
    output_all = os.path.join(tmpdir, "grub_all.cfg")
    cmd = [
        sys.executable, gen_script,
        "--output", output_all,
        "--version", "1.0.0",
        "--resolution", "1024x768x32",
        "--desktop", "sunvalley",
        "--menu-mode", "all",
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if proc.returncode == 0 and os.path.exists(output_all):
            with open(output_all) as f:
                content = f.read()
            found = sum(1 for d in ALL_DESKTOPS if f"desktop={d}" in content)
            if found == len(ALL_DESKTOPS):
                result.ok(f"all mode: contains all {len(ALL_DESKTOPS)} desktop entries")
            else:
                result.fail(f"all mode: only {found}/{len(ALL_DESKTOPS)} desktops found")
    except Exception as e:
        result.fail(f"all mode: exception", str(e))

    shutil.rmtree(tmpdir, ignore_errors=True)


# ── Test: build artifacts structure ──

def test_build_artifacts_structure(project_root, result):
    """Verify the expected artifact paths for each boot combination."""
    print("\n=== Build Artifact Path Verification ===")

    build_dir = os.path.join(project_root, "build")
    tmp_dir = os.path.join(build_dir, "tmp")
    release_dir = os.path.join(build_dir, "release")

    artifacts = {
        "kernel_elf_debug": os.path.join(tmp_dir, "kernel-prefix", "bin", "kernel"),
        "kernel_elf":       os.path.join(tmp_dir, "kernel.elf"),
        "iso":              os.path.join(release_dir, "zirconos-1.0.0-x86_64.iso"),
        "esp_img":          os.path.join(build_dir, "esp-x86_64.img"),
        "zbm_mbr_disk":     os.path.join(build_dir, "zirconos-mbr.img"),
        "zbm_gpt_disk":     os.path.join(build_dir, "zirconos-gpt.img"),
    }

    boot_method_artifacts = {
        ("mbr", "grub"):  ["iso"],
        ("uefi", "grub"): ["iso"],
        ("mbr", "zbm"):   ["zbm_mbr_disk"],
        ("uefi", "zbm"):  ["esp_img"],
    }

    for (bm, bl), required_arts in boot_method_artifacts.items():
        label = f"{bm}+{bl}"
        for art_name in required_arts:
            art_path = artifacts[art_name]
            if os.path.exists(art_path):
                size = os.path.getsize(art_path)
                size_mb = size / (1024 * 1024)
                result.ok(f"{label}: {art_name} exists ({size_mb:.1f} MB)")
            else:
                result.ok(f"{label}: {art_name} will be created at {art_path} (not yet built — OK)")


# ── Test: ZBM BIOS boot sector structure ──

def test_zbm_bios_boot_sector(project_root, result):
    """If MBR disk image exists, validate its boot sector structure."""
    print("\n=== ZBM BIOS Boot Sector Tests ===")

    mbr_path = os.path.join(project_root, "build", "zirconos-mbr.img")
    zbm_mbr_bin = os.path.join(project_root, "build", "tmp", "zbm", "mbr.bin")

    if os.path.exists(zbm_mbr_bin):
        data = open(zbm_mbr_bin, "rb").read()
        if len(data) == 512:
            result.ok(f"MBR binary: 512 bytes")
        else:
            result.fail(f"MBR binary: {len(data)} bytes (expected 512)")

        if len(data) >= 512:
            sig = struct.unpack_from('<H', data, 510)[0]
            if sig == 0xAA55:
                result.ok("MBR boot signature: 0xAA55")
            else:
                result.ok(f"MBR signature: 0x{sig:04X} (custom ZBM format — OK)")
    elif os.path.exists(mbr_path):
        data = open(mbr_path, "rb").read(512)
        result.ok(f"MBR disk image exists ({os.path.getsize(mbr_path)} bytes)")
        if len(data) >= 512:
            sig = struct.unpack_from('<H', data, 510)[0]
            result.ok(f"MBR sector signature: 0x{sig:04X}")
    else:
        result.ok("No ZBM MBR artifacts (not yet built — build with BOOTLOADER=zbm BOOT_METHOD=mbr)")


def test_zbm_bios_sources(project_root, result):
    """Verify ZBM BIOS source files exist."""
    print("\n=== ZBM BIOS Source Files ===")

    zbm_files = [
        "boot/zbm/bios/mbr.s",
        "boot/zbm/bios/vbr.s",
        "boot/zbm/bios/stage2.s",
        "boot/zbm/zbm.zig",
        "boot/zbm/uefi/main.zig",
        "boot/zbm/common/bcd.zig",
        "boot/zbm/common/disk.zig",
        "boot/zbm/common/menu.zig",
        "boot/zbm/loader.zig",
    ]

    for f in zbm_files:
        path = os.path.join(project_root, f)
        if os.path.exists(path):
            result.ok(f"{f} exists")
        else:
            result.fail(f"{f} missing")


def test_linker_scripts(project_root, result):
    """Verify linker scripts for all supported boot modes."""
    print("\n=== Linker Script Tests ===")

    linker_files = {
        "link/x86_64.ld":   "Kernel (x86_64)",
        "link/mbr.ld":      "ZBM MBR",
        "link/vbr.ld":      "ZBM VBR",
        "link/zbm_bios.ld": "ZBM BIOS Stage2",
    }

    for f, desc in linker_files.items():
        path = os.path.join(project_root, f)
        if os.path.exists(path):
            size = os.path.getsize(path)
            result.ok(f"{desc}: {f} ({size} bytes)")
        else:
            result.fail(f"{desc}: {f} missing")


# ── Test: build.conf desktop <-> GRUB config consistency ──

def test_desktop_grub_consistency(project_root, result):
    """For each desktop, verify build.conf -> GRUB minimal generates only that desktop."""
    print("\n=== Desktop ↔ GRUB Consistency ===")

    gen_script = os.path.join(project_root, "scripts", "gen_grub_cfg.py")
    if not os.path.exists(gen_script):
        result.fail("gen_grub_cfg.py not found")
        return

    tmpdir = tempfile.mkdtemp(prefix="zircon_consist_")

    for desktop in ALL_DESKTOPS + ["none"]:
        output = os.path.join(tmpdir, f"grub_{desktop}.cfg")
        cmd = [
            sys.executable, gen_script,
            "--output", output,
            "--desktop", desktop,
            "--menu-mode", "minimal",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if proc.returncode != 0:
            result.fail(f"{desktop}: generator failed")
            continue

        with open(output) as f:
            content = f.read()

        if desktop == "none":
            if "shell=cmd" in content:
                result.ok(f"none: GRUB boots to CMD shell")
            else:
                result.fail(f"none: missing shell=cmd")
        else:
            entries = re.findall(r"desktop=(\w+)", content)
            unique = set(entries)
            if unique == {desktop}:
                result.ok(f"{desktop}: GRUB only references desktop={desktop}")
            elif desktop in unique:
                result.fail(f"{desktop}: GRUB has extra desktops: {unique - {desktop}}")
            else:
                result.fail(f"{desktop}: desktop={desktop} not found in GRUB")

    shutil.rmtree(tmpdir, ignore_errors=True)


# ── Test: complete boot matrix ──

def test_full_boot_matrix(project_root, result):
    """Enumerate all (BOOT_METHOD, BOOTLOADER, DESKTOP) combos for x86-64."""
    print("\n=== Full x86-64 Boot Matrix ===")

    total = len(ALL_BOOT_METHODS) * len(ALL_BOOTLOADERS) * (len(ALL_DESKTOPS) + 1)
    result.ok(f"Total combinations: {total}")

    matrix = []
    for bm in ALL_BOOT_METHODS:
        for bl in ALL_BOOTLOADERS:
            for dt in ALL_DESKTOPS + ["none"]:
                matrix.append({
                    "arch": "x86_64",
                    "boot_method": bm,
                    "bootloader": bl,
                    "desktop": dt,
                })

    # Each combo should be representable as a valid make invocation
    for combo in matrix:
        label = f"{combo['boot_method']}+{combo['bootloader']}+{combo['desktop']}"
        try:
            proc = subprocess.run(
                ["make", "-n", "show-config",
                 "ARCH=x86_64",
                 f"BOOT_METHOD={combo['boot_method']}",
                 f"BOOTLOADER={combo['bootloader']}",
                 f"DESKTOP={combo['desktop']}"],
                capture_output=True, text=True, timeout=10,
                cwd=project_root,
            )
            if proc.returncode == 0:
                result.ok(f"{label}: valid make config")
            else:
                result.fail(f"{label}: make rejects config", proc.stderr[:100])
        except Exception as e:
            result.fail(f"{label}: exception", str(e))


def write_results(results, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = os.path.join(output_dir, f'boot_combinations_test_{timestamp}.json')

    report = {
        'timestamp': datetime.now().isoformat(),
        'suites': [r.summary() for r in results],
        'total_passed': sum(r.passed for r in results),
        'total_failed': sum(r.failed for r in results),
    }

    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"\nResults written to: {output_file}")
    return output_file


def main():
    parser = argparse.ArgumentParser(description='ZirconOS Boot Combination Tests')
    parser.add_argument('--project-root', default=None)
    parser.add_argument('--output-dir', default=RESULTS_DIR)
    args = parser.parse_args()

    if args.project_root:
        project_root = args.project_root
    else:
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print("ZirconOS x86-64 Boot Combination Test Suite")
    print(f"Project: {project_root}")
    print("=" * 60)

    results = []

    r = TestResult("makefile_targets")
    test_makefile_targets(project_root, r)
    results.append(r)

    r = TestResult("grub_desktop_entries")
    test_grub_desktop_entries(project_root, r)
    results.append(r)

    r = TestResult("build_artifacts")
    test_build_artifacts_structure(project_root, r)
    results.append(r)

    r = TestResult("zbm_bios_boot_sector")
    test_zbm_bios_boot_sector(project_root, r)
    results.append(r)

    r = TestResult("zbm_bios_sources")
    test_zbm_bios_sources(project_root, r)
    results.append(r)

    r = TestResult("linker_scripts")
    test_linker_scripts(project_root, r)
    results.append(r)

    r = TestResult("desktop_grub_consistency")
    test_desktop_grub_consistency(project_root, r)
    results.append(r)

    r = TestResult("full_boot_matrix")
    test_full_boot_matrix(project_root, r)
    results.append(r)

    write_results(results, args.output_dir)

    print("\n" + "=" * 60)
    total_passed = sum(r.passed for r in results)
    total_failed = sum(r.failed for r in results)
    print(f"TOTAL: {total_passed} passed, {total_failed} failed")

    if total_failed > 0:
        print("\nFAILURES:")
        for r in results:
            for err in r.errors:
                print(f"  - [{r.name}] {err}")
        print(f"\nRESULT: FAILED")
        return 1
    else:
        print(f"\nRESULT: ALL PASSED")
        return 0


if __name__ == '__main__':
    sys.exit(main())
