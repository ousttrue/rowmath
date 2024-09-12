const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("rowmath", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/rowmath.zig"),
    });

    const tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .name = "rowmath_test",
        .root_source_file = b.path("src/rowmath.zig"),
    });
    b.installArtifact(tests);
}
