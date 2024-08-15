const std = @import("std");

const tests = [_][]const u8{
    "src/main.zig",
    "src/Vec2.zig",
    "src/Vec3.zig",
    "src/Vec4.zig",
    "src/Quat.zig",
    "src/Mat4.zig",
    "src/RigidTransform.zig",
    "src/Transform.zig",
    "src/InputState.zig",
    "src/Ray.zig",
    "src/_Camera.zig",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("src/main.zig") },
    );

    const lib = b.addStaticLibrary(.{
        .name = "rowmath",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.linkLibrary(lib);

    const test_step = b.step("test", "Run unit tests");
    for (tests) |src| {
        const lib_unit_tests = b.addTest(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
        test_step.dependOn(&run_lib_unit_tests.step);
    }
}
