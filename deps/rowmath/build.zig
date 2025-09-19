const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root = b.addModule("rowmath", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/rowmath.zig"),
    });

    const tests = b.addTest(.{
        .name = "rowmath_test",
        .root_module = root,
    });
    b.installArtifact(tests);
}
