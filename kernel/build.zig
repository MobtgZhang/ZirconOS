const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // 架构选择：支持 x86_64 / loong64 / aarch64 / riscv64 / mips64el
    const arch_opt = b.option([]const u8, "arch", "Target architecture (x86_64, loong64, aarch64, riscv64, mips64el)") orelse "x86_64";

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
        @panic("Unsupported arch value; expected one of: x86_64, loong64, aarch64, riscv64, mips64el");
    }

    const target = b.resolveTargetQuery(.{
        .cpu_arch = cpu_arch,
        .os_tag = .freestanding,
        .abi = .none,
    });

    // 各架构使用自己的 entry.zig 作为根（提供 _start）；x86_64 用 main.zig（multiboot2 直接调用）
    const root_src = if (mem.eql(u8, arch_opt, "x86_64"))
        b.path("src/main.zig")
    else if (mem.eql(u8, arch_opt, "aarch64"))
        b.path("src/arch/arm64/entry.zig")
    else if (mem.eql(u8, arch_opt, "loong64"))
        b.path("src/arch/loong64/entry.zig")
    else if (mem.eql(u8, arch_opt, "riscv64"))
        b.path("src/arch/riscv64/entry.zig")
    else if (mem.eql(u8, arch_opt, "mips64el"))
        b.path("src/arch/mips64el/entry.zig")
    else
        b.path("src/main.zig");

    const root_mod = b.createModule(.{
        .root_source_file = root_src,
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .code_model = .kernel,
        .pic = false,
        .red_zone = false,
    });

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
        .code_model = .kernel,
        .pic = false,
        .red_zone = false,
    });
    if (!mem.eql(u8, arch_opt, "x86_64")) {
        root_mod.addImport("main", main_mod);
    }

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_module = root_mod,
    });

    kernel.entry = .{ .symbol_name = if (mem.eql(u8, arch_opt, "x86_64")) "kernel_main" else "_start" };
    kernel.link_gc_sections = false;
    kernel.pie = false;
    kernel.setLinkerScript(b.path("linker.ld"));

    b.installArtifact(kernel);

    const step = b.step("kernel", "Build the kernel ELF");
    step.dependOn(&kernel.step);
}

