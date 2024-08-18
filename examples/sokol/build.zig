const std = @import("std");
const sokol = @import("sokol");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Module,
    dep_sokol: *std.Build.Dependency,
    _emsdk: ?*std.Build.Dependency,
) void {
    const name = "sokol_camera";
    const src = "examples/sokol/camera.zig";
    if (_emsdk) |emsdk| {
        const lib = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = name,
            .root_source_file = b.path(src),
        });

        // inject dependency(must inject before emLinkStep)
        lib.root_module.addImport("sokol", dep_sokol.module("sokol"));
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
            .shell_file_path = dep_sokol.path("src/sokol/web/shell.html").getPath(b),
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
        b.installArtifact(exe);

        // inject dependency
        exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
        exe.root_module.addImport("rowmath", rowmath);

        // run
        const run = b.addRunArtifact(exe);
        b.step(
            b.fmt("run-{s}", .{name}),
            b.fmt("run {s}", .{name}),
        ).dependOn(&run.step);
    }
}
