const std = @import("std");
const sokol_examples = @import("examples/sokol/build.zig");
const raylib_examples = @import("examples/raylib/build.zig");

const tests = [_][]const u8{
    "src/main.zig",
    "src/Vec2.zig",
    "src/Vec3.zig",
    "src/Vec4.zig",
    "src/Quat.zig",
    "src/Mat4.zig",
    "src/RigidTransform.zig",
    "src/Transform.zig",
    "src/InputState.zig",
    "src/Ray.zig",
    "src/Camera.zig",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // tests
    const test_step = b.step("test", "rowmath tests");
    for (tests) |src| {
        const lib_unit_tests = b.addTest(.{
            .root_source_file = b.path(src),
            .target = target,
            .optimize = optimize,
        });
        const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
        test_step.dependOn(&run_lib_unit_tests.step);
    }

    // docs
    const doc_root = b.addObject(.{
        .name = "rowmath",
        .root_source_file = b.path("src/doc_root.zig"),
        .target = b.host,
        .optimize = .Debug,
    });
    // doc_root.root_module.addImport("rowmath", lib);
    // b.installArtifact(doc_root);
    const install_docs = b.addInstallDirectory(.{
        .source_dir = doc_root.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    b.getInstallStep().dependOn(&install_docs.step);
    // install_docs.step.dependOn(b.getInstallStep());
    // b.installArtifact(doc_root);
    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");
    docs_step.dependOn(&install_docs.step);

    const lib = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("src/rowmath.zig") },
    );
    const build_sokol = !target.result.isWasm() or (b.option(bool, "sokol", "build sokol example") orelse false);
    const build_raylib = !target.result.isWasm() or (b.option(bool, "raylib", "build raylib example") orelse false);
    if (build_sokol or build_raylib) {
        const dep_sokol = b.dependency("sokol", .{
            .target = target,
            .optimize = optimize,
        });

        // create a build step which invokes the Emscripten linker
        var emsdk: ?*std.Build.Dependency = null;
        if (target.result.isWasm()) {
            emsdk = dep_sokol.builder.dependency("emsdk", .{});
        }

        if (build_sokol) {
            sokol_examples.build(b, target, optimize, lib, dep_sokol, emsdk);
        }
        if (build_raylib) {
            raylib_examples.build(b, target, optimize, lib, dep_sokol, emsdk);
        }
    }
}
