const std = @import("std");

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

    const lib = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("src/rowmath.zig") },
    );
    _ = lib;

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

    const build_sokol = (b.option(bool, "sokol", "build sokol example") orelse false);
    if (build_sokol) {
        const examples_dep = b.dependency("examples", .{});
        const artifact = examples_dep.artifact("sokol_camera");

        // run
        const run = b.addRunArtifact(artifact);
        b.step(
            b.fmt("run-{s}", .{artifact.name}),
            b.fmt("run {s}", .{artifact.name}),
        ).dependOn(&run.step);
    }

    const build_raylib = (b.option(bool, "raylib", "build raylib example") orelse false);
    if (build_raylib) {
        const examples_dep = b.dependency("examples", .{});
        const artifact = examples_dep.artifact("raylib_camera");

        // run
        const run = b.addRunArtifact(artifact);
        b.step(
            b.fmt("run-{s}", .{artifact.name}),
            b.fmt("run {s}", .{artifact.name}),
        ).dependOn(&run.step);
    }
}
