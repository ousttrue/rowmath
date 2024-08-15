const std = @import("std");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Step.Compile,
) void {
    const dep_raylib = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = dep_raylib.artifact("raylib");

    const exe = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = "example_raylib_camera",
        .root_source_file = b.path("examples/raylib/camera.zig"),
    });
    for (dep_raylib.builder.modules.keys()) |key| {
        std.debug.print("key:{s}\n", .{key});
    }
    exe.root_module.linkLibrary(raylib);
    exe.root_module.addImport("rowmath", &rowmath.root_module);

    // install
    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);

    // run
    const run = b.addRunArtifact(exe);
    b.step("run-raylib-camera", "run examples/raylib/camera").dependOn(&run.step);
}
