const std = @import("std");

pub fn build(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    rowmath: *std.Build.Step.Compile,
) void {
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .target = target,
        .optimize = optimize,
        .name = "example_sokol_camera",
        .root_source_file = b.path("examples/sokol/camera.zig"),
    });
    exe.root_module.addImport("sokol", dep_sokol.module("sokol"));
    exe.root_module.addImport("rowmath", &rowmath.root_module);

    // install
    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);

    // run
    const run = b.addRunArtifact(exe);
    b.step("run-sokol-camera", "run examples/sokol/camera").dependOn(&run.step);
}
