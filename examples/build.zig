const std = @import("std");
const sokol_examples = @import("sokol/build.zig");
const raylib_examples = @import("raylib/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("../src/rowmath.zig") },
    );

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    // create a build step which invokes the Emscripten linker
    var emsdk: ?*std.Build.Dependency = null;
    if (target.result.isWasm()) {
        emsdk = dep_sokol.builder.dependency("emsdk", .{});
    }

    sokol_examples.build(b, target, optimize, lib, dep_sokol, emsdk);

    raylib_examples.build(b, target, optimize, lib, emsdk);
}
