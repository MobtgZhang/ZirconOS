#!/usr/bin/env python3
"""
ZirconOS Build Configuration Verification Tests

Validates that build.conf is well-formed, all referenced files exist,
the GRUB config generator works correctly, and the Makefile reads the
configuration properly.

Usage:
    python3 tests/test_build_config.py [--project-root PATH] [--output-dir DIR]
"""

import argparse
import os
import re
import subprocess
import sys
import json
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


VALID_ARCHES = {"x86_64", "aarch64", "loong64", "riscv64", "mips64el"}
VALID_BOOT_METHODS = {"mbr", "uefi"}
VALID_BOOTLOADERS = {"grub", "zbm"}
VALID_DESKTOPS = {"classic", "luna", "aero", "modern", "fluent", "sunvalley", "none"}
VALID_OPTIMIZES = {"Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall"}
VALID_GRUB_MENUS = {"minimal", "all"}


def parse_build_conf(path):
    """Parse build.conf into a dict, ignoring comments and blank lines."""
    values = {}
    if not os.path.exists(path):
        return None
    with open(path) as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            m = re.match(r"^(\w+)\s*=\s*(.+)$", line)
            if m:
                values[m.group(1)] = m.group(2).strip()
    return values


def test_build_conf_exists(project_root, result):
    """Check build.conf exists."""
    print("\n=== build.conf Existence ===")
    conf_path = os.path.join(project_root, "build.conf")
    if os.path.exists(conf_path):
        result.ok(f"build.conf exists: {conf_path}")
        return conf_path
    else:
        result.fail("build.conf not found", f"expected at {conf_path}")
        return None


def test_build_conf_parse(conf_path, result):
    """Parse build.conf and validate all keys."""
    print("\n=== build.conf Parsing ===")
    if conf_path is None:
        result.fail("Skipped: build.conf not found")
        return None

    values = parse_build_conf(conf_path)
    if values is None:
        result.fail("Failed to parse build.conf")
        return None

    result.ok(f"Parsed {len(values)} key-value pairs")

    required_keys = ["ARCH", "BOOT_METHOD", "BOOTLOADER", "DESKTOP", "OPTIMIZE"]
    for key in required_keys:
        if key in values:
            result.ok(f"Key '{key}' present: {values[key]}")
        else:
            result.fail(f"Required key '{key}' missing from build.conf")

    return values


def test_build_conf_values(values, result):
    """Validate build.conf values against allowed sets."""
    print("\n=== build.conf Value Validation ===")
    if values is None:
        result.fail("Skipped: no parsed values")
        return

    checks = [
        ("ARCH", VALID_ARCHES),
        ("BOOT_METHOD", VALID_BOOT_METHODS),
        ("BOOTLOADER", VALID_BOOTLOADERS),
        ("DESKTOP", VALID_DESKTOPS),
        ("OPTIMIZE", VALID_OPTIMIZES),
    ]

    for key, valid_set in checks:
        val = values.get(key)
        if val is None:
            continue
        if val in valid_set:
            result.ok(f"{key}={val} is valid")
        else:
            result.fail(f"{key}={val} is invalid", f"valid: {sorted(valid_set)}")

    if "GRUB_MENU" in values:
        val = values["GRUB_MENU"]
        if val in VALID_GRUB_MENUS:
            result.ok(f"GRUB_MENU={val} is valid")
        else:
            result.fail(f"GRUB_MENU={val} is invalid", f"valid: {sorted(VALID_GRUB_MENUS)}")

    if "RESOLUTION" in values:
        res = values["RESOLUTION"]
        if re.match(r"^\d+x\d+x\d+$", res):
            result.ok(f"RESOLUTION={res} format valid (WxHxBPP)")
        else:
            result.fail(f"RESOLUTION={res} invalid format", "expected WxHxBPP e.g. 1024x768x32")


def test_config_files_exist(project_root, result):
    """Check that all config files referenced by the kernel exist."""
    print("\n=== Config File Existence ===")

    config_files = [
        "config/system.conf",
        "config/boot.conf",
        "config/desktop.conf",
        "config/defaults.zig",
    ]

    for f in config_files:
        path = os.path.join(project_root, f)
        if os.path.exists(path):
            size = os.path.getsize(path)
            result.ok(f"{f} exists ({size} bytes)")
        else:
            result.fail(f"{f} not found")


def test_theme_directories(project_root, values, result):
    """Verify desktop theme directories exist for the configured DESKTOP."""
    print("\n=== Theme Directory Tests ===")

    theme_map = {
        "classic":    "3rdparty/ZirconOSClassic",
        "luna":       "3rdparty/ZirconOSLuna",
        "aero":       "3rdparty/ZirconOSAero",
        "modern":     "3rdparty/ZirconOSModern",
        "fluent":     "3rdparty/ZirconOSFluent",
        "sunvalley":  "3rdparty/ZirconOSSunValley",
    }

    desktop = values.get("DESKTOP", "sunvalley") if values else "sunvalley"

    if desktop == "none":
        result.ok("DESKTOP=none, no theme directory needed")
        return

    if desktop in theme_map:
        theme_dir = os.path.join(project_root, theme_map[desktop])
        if os.path.isdir(theme_dir):
            result.ok(f"Theme directory exists: {theme_map[desktop]}")
            src_main = os.path.join(theme_dir, "src", "main.zig")
            if os.path.exists(src_main):
                result.ok(f"Theme entry point exists: {theme_map[desktop]}/src/main.zig")
            else:
                result.fail(f"Theme entry point missing: {theme_map[desktop]}/src/main.zig")
        else:
            result.fail(f"Theme directory missing: {theme_map[desktop]}")


def test_grub_config_generator(project_root, result):
    """Test the GRUB config generator script with various inputs."""
    print("\n=== GRUB Config Generator Tests ===")

    gen_script = os.path.join(project_root, "scripts", "gen_grub_cfg.py")
    if not os.path.exists(gen_script):
        result.fail("gen_grub_cfg.py not found", gen_script)
        return

    result.ok(f"gen_grub_cfg.py exists")

    import tempfile
    tmpdir = tempfile.mkdtemp(prefix="zircon_grub_test_")

    test_cases = [
        ("minimal_sunvalley", "sunvalley", "minimal"),
        ("minimal_aero",      "aero",      "minimal"),
        ("minimal_classic",   "classic",   "minimal"),
        ("minimal_none",      "none",      "minimal"),
        ("all_sunvalley",     "sunvalley", "all"),
        ("all_fluent",        "fluent",    "all"),
    ]

    for name, desktop, menu_mode in test_cases:
        output = os.path.join(tmpdir, f"{name}.cfg")
        cmd = [
            sys.executable, gen_script,
            "--output", output,
            "--version", "1.0.0",
            "--resolution", "1024x768x32",
            "--desktop", desktop,
            "--menu-mode", menu_mode,
        ]
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            if proc.returncode == 0 and os.path.exists(output):
                with open(output) as f:
                    content = f.read()
                if f"desktop={desktop}" in content or desktop == "none":
                    result.ok(f"Generated {name}: contains desktop={desktop}")
                else:
                    result.fail(f"Generated {name}: missing desktop={desktop} in output")

                if menu_mode == "minimal" and desktop != "none":
                    other_desktops = {"classic", "luna", "aero", "modern", "fluent", "sunvalley"} - {desktop}
                    leaked = [d for d in other_desktops if f"desktop={d}" in content]
                    if not leaked:
                        result.ok(f"Minimal mode {name}: only shows {desktop}")
                    else:
                        result.fail(f"Minimal mode {name}: leaks other desktops", str(leaked))
            else:
                result.fail(f"Generator failed for {name}", proc.stderr[:200])
        except Exception as e:
            result.fail(f"Generator exception for {name}", str(e))

    import shutil
    shutil.rmtree(tmpdir, ignore_errors=True)


def test_makefile_reads_config(project_root, result):
    """Verify Makefile can parse build.conf by running 'make show-config'."""
    print("\n=== Makefile Config Integration ===")

    makefile = os.path.join(project_root, "Makefile")
    if not os.path.exists(makefile):
        result.fail("Makefile not found")
        return

    result.ok("Makefile exists")

    try:
        proc = subprocess.run(
            ["make", "-n", "show-config"],
            capture_output=True, text=True, timeout=10,
            cwd=project_root,
        )
        if proc.returncode == 0:
            result.ok("'make -n show-config' succeeds (dry run)")
        else:
            result.fail("'make -n show-config' failed", proc.stderr[:200])
    except FileNotFoundError:
        result.fail("make not installed")
    except subprocess.TimeoutExpired:
        result.fail("'make -n show-config' timed out")


def test_build_conf_combinations(result):
    """Verify that all valid (BOOT_METHOD, BOOTLOADER, DESKTOP) combos are recognized."""
    print("\n=== Valid Configuration Combinations ===")

    combos = []
    for bm in VALID_BOOT_METHODS:
        for bl in VALID_BOOTLOADERS:
            for dt in VALID_DESKTOPS:
                combos.append((bm, bl, dt))

    result.ok(f"Total valid combinations: {len(combos)} ({len(VALID_BOOT_METHODS)} x {len(VALID_BOOTLOADERS)} x {len(VALID_DESKTOPS)})")

    # Verify x86_64 specific: mbr+zbm, uefi+grub, uefi+zbm, mbr+grub are all valid
    boot_combos = {(bm, bl) for bm in VALID_BOOT_METHODS for bl in VALID_BOOTLOADERS}
    expected = {("mbr", "grub"), ("mbr", "zbm"), ("uefi", "grub"), ("uefi", "zbm")}
    if boot_combos == expected:
        result.ok(f"All 4 boot combos present: {sorted(expected)}")
    else:
        result.fail("Missing boot combos", f"got {boot_combos}, expected {expected}")


def write_results(results, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = os.path.join(output_dir, f'build_config_test_{timestamp}.json')

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
    parser = argparse.ArgumentParser(description='ZirconOS Build Configuration Tests')
    parser.add_argument('--project-root', default=None)
    parser.add_argument('--output-dir', default=RESULTS_DIR)
    args = parser.parse_args()

    if args.project_root:
        project_root = args.project_root
    else:
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print("ZirconOS Build Configuration Test Suite")
    print(f"Project: {project_root}")
    print("=" * 60)

    results = []

    r = TestResult("build_conf_exists")
    conf_path = test_build_conf_exists(project_root, r)
    results.append(r)

    r = TestResult("build_conf_parse")
    values = test_build_conf_parse(conf_path, r)
    results.append(r)

    r = TestResult("build_conf_values")
    test_build_conf_values(values, r)
    results.append(r)

    r = TestResult("config_files_exist")
    test_config_files_exist(project_root, r)
    results.append(r)

    r = TestResult("theme_directories")
    test_theme_directories(project_root, values, r)
    results.append(r)

    r = TestResult("grub_config_generator")
    test_grub_config_generator(project_root, r)
    results.append(r)

    r = TestResult("makefile_config")
    test_makefile_reads_config(project_root, r)
    results.append(r)

    r = TestResult("config_combinations")
    test_build_conf_combinations(r)
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
