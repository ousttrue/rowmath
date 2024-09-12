const std = @import("std");
const emsdk_zig = @import("emsdk-zig");

const name = "raylib_camera";
const src = "camera.zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rowmath_dep = b.dependency("rowmath", .{
        .target = target,
        .optimize = optimize,
    });
    const rowmath_mod = rowmath_dep.module("rowmath");

    // create a build step which invokes the Emscripten linker
    var _emsdk: ?*std.Build.Dependency = null;
    if (target.result.isWasm()) {
        const emsdk = b.dependency("emsdk-zig", .{}).builder.dependency("emsdk", .{});
        b.sysroot = emsdk.path("upstream/emscripten").getPath(b);
        _emsdk = emsdk;
    }

    var raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib_lib = raylib_dep.artifact("raylib");

    if (_emsdk) |emsdk| {
        const lib = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(src),
        });
        b.installArtifact(lib);
        const emsdk_incl_path = emsdk.path(
            "upstream/emscripten/cache/sysroot/include",
        );
        lib.addSystemIncludePath(emsdk_incl_path);

        // inject dependency(must inject before emLinkStep)
        lib.root_module.linkLibrary(raylib_lib);
        lib.root_module.addImport("rowmath", rowmath_mod);

        // link emscripten
        const link_step = try emsdk_zig.emLinkStep(b, emsdk, .{
            .lib_main = lib,
            .target = target,
            .optimize = optimize,
            .use_webgl2 = true,
            .use_emmalloc = true,
            .use_filesystem = false,
            // .shell_file_path = dep_raylib.path("src/minshell.html").getPath(b),
            .shell_file_path = b.path("minshell.html").getPath(b),
            .extra_before = &.{
                "-sUSE_GLFW=3",
                "-sASYNCIFY",
            },
            .release_use_closure = false,
        });
        b.getInstallStep().dependOn(&link_step.step);
    } else {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(src),
        });
        b.installArtifact(exe);

        // inject dependency
        exe.addIncludePath(raylib_dep.path("src"));
        exe.root_module.linkLibrary(raylib_lib);
        exe.root_module.addImport("rowmath", rowmath_mod);
    }
}
