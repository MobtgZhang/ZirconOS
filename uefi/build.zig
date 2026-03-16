const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .uefi,
        .abi = .msvc,
    });

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = false,
    });

    const efi = b.addExecutable(.{
        .name = "zirconos",
        .root_module = root_mod,
    });

    b.installArtifact(efi);

    const step = b.step("uefi", "Build ZirconOS UEFI application");
    step.dependOn(&efi.step);
}

