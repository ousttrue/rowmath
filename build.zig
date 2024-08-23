const std = @import("std");
const emsdk_zig = @import("emsdk-zig");

const tests = [_][]const u8{
    "src/rowmath.zig",
    "src/Vec2.zig",
    "src/Vec3.zig",
    "src/Vec4.zig",
    "src/Quat.zig",
    "src/Rgba.zig",
    "src/Mat4.zig",
    "src/RigidTransform.zig",
    "src/Transform.zig",
    "src/InputState.zig",
    "src/Ray.zig",
    "src/Camera.zig",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("src/rowmath.zig") },
    );

    // tests
    const test_step = b.step("test", "rowmath tests");
    for (tests) |src| {
        const lib_unit_tests = b.addTest(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        test_step.dependOn(&b.addRunArtifact(lib_unit_tests).step);
    }

    // docs
    const doc_root = b.addObject(.{
        .name = "rowmath",
        .root_source_file = b.path("src/doc_root.zig"),
        .target = b.host,
        .optimize = .Debug,
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = doc_root.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    b.step(
        "docs",
        "Copy documentation artifacts to prefix path",
    ).dependOn(&install_docs.step);

    // examples sokol
    const build_sokol = if (b.option(bool, "sokol", "build sokol examples")) |enable|
        enable
    else
        false;
    if (build_sokol) {
        const d = b.dependency("examples_sokol", .{
            .target = target,
            .optimize = optimize,
        });
        for (d.builder.install_tls.step.dependencies.items) |dep_step| {
            if (target.result.isWasm()) {
                if (dep_step.cast(std.Build.Step.InstallDir)) |dir| {
                    // b.installDirectory();
                    b.installDirectory(.{
                        .source_dir = dir.options.source_dir,
                        .install_dir = .prefix,
                        .install_subdir = "web",
                    });
                }
            } else {
                const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
                b.installArtifact(inst.artifact);
                // run exe
                const run = b.addRunArtifact(inst.artifact);
                b.step(
                    b.fmt("run-{s}", .{inst.artifact.name}),
                    b.fmt("Run {s}", .{inst.artifact.name}),
                ).dependOn(&run.step);
            }
        }
    }

    // examples raylib
    const build_raylib = if (b.option(bool, "raylib", "build raylib examples")) |enable|
        enable
    else
        false;
    if (build_raylib) {
        const d = b.dependency("examples_raylib", .{
            .target = target,
            .optimize = optimize,
        });
        for (d.builder.install_tls.step.dependencies.items) |dep_step| {
            if (target.result.isWasm()) {
                if (dep_step.cast(std.Build.Step.InstallDir)) |dir| {
                    // b.installDirectory();
                    b.installDirectory(.{
                        .source_dir = dir.options.source_dir,
                        .install_dir = .prefix,
                        .install_subdir = "web",
                    });
                }
            } else {
                const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
                const install = b.addInstallArtifact(inst.artifact, .{});
                b.getInstallStep().dependOn(&install.step);
                // run exe
                const run = b.addRunArtifact(inst.artifact);
                run.step.dependOn(&install.step);
                b.step(
                    b.fmt("run-{s}", .{inst.artifact.name}),
                    b.fmt("Run {s}", .{inst.artifact.name}),
                ).dependOn(&run.step);
            }
        }
    }
}
