const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const arch_opt = b.option(
        []const u8,
        "arch",
        "Target architecture (x86_64, loong64, aarch64, riscv64, mips64el)",
    ) orelse "x86_64";
    const debug_mode = b.option(bool, "debug", "Enable debug mode (verbose klog, serial output)") orelse false;
    const enable_idt_opt = b.option(bool, "enable_idt", "Enable IDT, timer and syscall (x86_64 only)") orelse true;

    var cpu_arch: std.Target.Cpu.Arch = .x86_64;
    if (mem.eql(u8, arch_opt, "x86_64")) {
        cpu_arch = .x86_64;
    } else if (mem.eql(u8, arch_opt, "loong64")) {
        cpu_arch = .loongarch64;
    } else if (mem.eql(u8, arch_opt, "aarch64")) {
        cpu_arch = .aarch64;
    } else if (mem.eql(u8, arch_opt, "riscv64")) {
        cpu_arch = .riscv64;
    } else if (mem.eql(u8, arch_opt, "mips64el")) {
        cpu_arch = .mips64el;
    } else {
        @panic("Unsupported arch; expected: x86_64, loong64, aarch64, riscv64, mips64el");
    }

    const target = b.resolveTargetQuery(.{
        .cpu_arch = cpu_arch,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const build_opts = b.addOptions();
    build_opts.addOption(bool, "debug", debug_mode);
    build_opts.addOption(bool, "enable_idt", enable_idt_opt);

    const code_model: std.builtin.CodeModel = switch (cpu_arch) {
        .x86_64 => .kernel,
        .aarch64 => .small,
        .riscv64 => .medium,
        else => .default,
    };

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .code_model = code_model,
        .pic = false,
        .red_zone = if (cpu_arch == .x86_64) false else null,
        .strip = false,
    });
    root_mod.addOptions("build_options", build_opts);

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_module = root_mod,
    });

    kernel.entry = .{ .symbol_name = "_start" };
    kernel.link_gc_sections = false;
    kernel.pie = false;
    kernel.link_z_max_page_size = 0x1000;

    const linker_script = if (mem.eql(u8, arch_opt, "x86_64"))
        b.path("link/x86_64.ld")
    else if (mem.eql(u8, arch_opt, "aarch64"))
        b.path("link/aarch64.ld")
    else if (mem.eql(u8, arch_opt, "loong64"))
        b.path("link/loong64.ld")
    else if (mem.eql(u8, arch_opt, "riscv64"))
        b.path("link/riscv64.ld")
    else if (mem.eql(u8, arch_opt, "mips64el"))
        b.path("link/mips64el.ld")
    else
        b.path("link/x86_64.ld");

    kernel.setLinkerScript(linker_script);

    if (mem.eql(u8, arch_opt, "x86_64")) {
        kernel.addAssemblyFile(b.path("src/arch/x86_64/start.s"));
        if (enable_idt_opt) {
            kernel.addAssemblyFile(b.path("src/arch/x86_64/isr_common.s"));
            kernel.addAssemblyFile(b.path("src/arch/x86_64/syscall_entry.s"));
        }
    }

    b.installArtifact(kernel);

    const step = b.step("kernel", "Build the kernel ELF");
    step.dependOn(&kernel.step);

    buildUefi(b, cpu_arch, optimize, debug_mode);
    buildZbm(b, cpu_arch, optimize, debug_mode);
}

fn buildZbm(b: *std.Build, cpu_arch: std.Target.Cpu.Arch, optimize: std.builtin.OptimizeMode, debug_mode: bool) void {
    _ = optimize;
    if (cpu_arch != .x86_64) return;

    const zbm_opts = b.addOptions();
    zbm_opts.addOption(bool, "debug", debug_mode);

    // ZBM BIOS bootstrap components are built via run.sh using GNU as + ld
    // since they contain 16-bit real mode code not supported by Zig's backend.
    //
    // The Zig build system handles the ZBM common modules (BCD, disk, menu, loader)
    // which are compiled as freestanding x86_64 objects for use by the kernel.

    const zbm_target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // ZBM common library (BCD, disk, menu, loader)
    const zbm_mod = b.createModule(.{
        .root_source_file = b.path("boot/zbm/zbm.zig"),
        .target = zbm_target,
        .optimize = .ReleaseSmall,
        .link_libc = false,
        .code_model = .kernel,
        .pic = false,
        .red_zone = false,
        .strip = false,
    });
    zbm_mod.addOptions("build_options", zbm_opts);

    const zbm_lib = b.addLibrary(.{
        .name = "zbm",
        .linkage = .static,
        .root_module = zbm_mod,
    });

    const install_zbm = b.addInstallArtifact(zbm_lib, .{});
    const zbm_step = b.step("zbm", "Build ZirconOS Boot Manager library");
    zbm_step.dependOn(&install_zbm.step);
}

fn buildUefi(b: *std.Build, cpu_arch: std.Target.Cpu.Arch, optimize: std.builtin.OptimizeMode, debug_mode: bool) void {
    if (cpu_arch != .x86_64 and cpu_arch != .aarch64) return;

    const uefi_target = b.resolveTargetQuery(.{
        .cpu_arch = cpu_arch,
        .os_tag = .uefi,
        .abi = .none,
    });

    const uefi_opts = b.addOptions();
    uefi_opts.addOption(bool, "debug", debug_mode);

    const uefi_mod = b.createModule(.{
        .root_source_file = b.path("boot/uefi/main.zig"),
        .target = uefi_target,
        .optimize = optimize,
    });
    uefi_mod.addOptions("build_options", uefi_opts);

    const uefi_exe = b.addExecutable(.{
        .name = "zirconos",
        .root_module = uefi_mod,
    });

    const install_uefi = b.addInstallArtifact(uefi_exe, .{});

    const uefi_step = b.step("uefi", "Build UEFI boot application (.efi)");
    uefi_step.dependOn(&install_uefi.step);
}
