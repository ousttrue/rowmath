const std = @import("std");
const sokol = @import("sokol");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Module,
    _emsdk: ?*std.Build.Dependency,
) void {
    if (_emsdk) |emsdk| {
        b.sysroot = emsdk.path("upstream/emscripten").getPath(b);
    } else {}
    var dep_raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = dep_raylib.artifact("raylib");

    const name = "raylib_camera";
    const src = "examples/raylib/camera.zig";
    if (_emsdk) |emsdk| {
        const lib = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(src),
        });
        const emsdk_incl_path = emsdk.path(
            "upstream/emscripten/cache/sysroot/include",
        );
        lib.addSystemIncludePath(emsdk_incl_path);

        // inject dependency(must inject before emLinkStep)
        lib.root_module.linkLibrary(raylib);
        lib.root_module.addImport("rowmath", rowmath);

        // link emscripten
        const link_step = try sokol.emLinkStep(b, .{
            .lib_main = lib,
            .target = target,
            .optimize = optimize,
            .emsdk = emsdk,
            .use_webgl2 = true,
            .use_emmalloc = true,
            .use_filesystem = false,
            // .shell_file_path = dep_raylib.path("src/minshell.html").getPath(b),
            .shell_file_path = b.path("examples/raylib/minshell.html").getPath(b),
            .extra_args = &.{
                "-sUSE_GLFW=3",
                "-sASYNCIFY",
            },
            .release_use_closure = false,
        });

        // emrun
        const run = sokol.emRunStep(b, .{
            .name = name,
            .emsdk = emsdk,
        });
        run.step.dependOn(&link_step.step);
        b.step(
            b.fmt("emrun-{s}", .{name}),
            b.fmt("EmRun {s}.wasm", .{name}),
        ).dependOn(&run.step);
    } else {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(src),
        });

        // inject dependency
        exe.addIncludePath(dep_raylib.path("src"));
        exe.root_module.linkLibrary(raylib);
        exe.root_module.addImport("rowmath", rowmath);

        // run
        const run = b.addRunArtifact(exe);
        b.step(
            b.fmt("run-{s}", .{name}),
            b.fmt("run {s}", .{name}),
        ).dependOn(&run.step);
    }
}
