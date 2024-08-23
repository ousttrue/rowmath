const std = @import("std");
const sokol = @import("sokol");
const emsdk_zig = @import("emsdk-zig");
const examples = @import("examples.zig").examples;
const Example = @import("examples.zig").Example;

fn build_example(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Module,
    dep_sokol: *std.Build.Dependency,
    _emsdk: ?*std.Build.Dependency,
    example: Example,
) void {
    if (_emsdk) |emsdk| {
        const lib = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = example.name,
            .root_source_file = b.path(example.src),
        });
        b.installArtifact(lib);

        // inject dependency(must inject before emLinkStep)
        lib.root_module.addImport("sokol", dep_sokol.module("sokol"));
        lib.root_module.addImport("rowmath", rowmath);

        // link emscripten
        const link_step = try emsdk_zig.emLinkStep(b, emsdk, .{
            .lib_main = lib,
            .target = target,
            .optimize = optimize,
            .use_webgl2 = true,
            .use_emmalloc = true,
            .use_filesystem = false,
            .shell_file_path = dep_sokol.path("src/sokol/web/shell.html").getPath(b),
            .release_use_closure = false,
        });
        b.getInstallStep().dependOn(&link_step.step);
    } else {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = example.name,
            .root_source_file = b.path(example.src),
        });
        b.installArtifact(exe);

        // inject dependency
        exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
        exe.root_module.addImport("rowmath", rowmath);
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rowmath = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("../../src/rowmath.zig") },
    );

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    // create a build step which invokes the Emscripten linker
    var emsdk: ?*std.Build.Dependency = null;
    if (target.result.isWasm()) {
        emsdk = b.dependency("emsdk-zig", .{}).builder.dependency("emsdk", .{});
    }

    for (examples) |example| {
        build_example(
            b,
            target,
            optimize,
            rowmath,
            dep_sokol,
            emsdk,
            example,
        );
    }
}
