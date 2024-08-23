const std = @import("std");
const sokol = @import("sokol");

pub const Example = struct {
    name: []const u8,
    src: []const u8,
    use_imgui: bool = false,
};

pub const examples = [_]Example{
    .{
        .name = "sokol_camera_simple",
        .src = "sokol/camera_simple.zig",
    },
    .{
        .name = "sokol_camera_rendertarget",
        .src = "sokol/camera_rendertarget.zig",
        .use_imgui = true,
    },
};

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
            .name = example.name,
            .emsdk = emsdk,
        });
        run.step.dependOn(&link_step.step);
        b.step(
            b.fmt("emrun-{s}", .{example.name}),
            b.fmt("EmRun {s}.wasm", .{example.name}),
        ).dependOn(&run.step);
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

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Module,
    dep_sokol: *std.Build.Dependency,
    _emsdk: ?*std.Build.Dependency,
) void {
    for (examples) |example| {
        build_example(b, target, optimize, rowmath, dep_sokol, _emsdk, example);
    }
}
