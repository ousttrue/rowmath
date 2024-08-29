const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("src/rowmath.zig") },
    );

    // tests
    const test_step = b.step("test", "rowmath tests");
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/rowmath.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_step.dependOn(&b.addRunArtifact(lib_unit_tests).step);

    // docs
    const doc_root = b.addObject(.{
        .name = "rowmath",
        .root_source_file = b.path("src/doc_root.zig"),
        .target = b.host,
        .optimize = .Debug,
    });
    doc_root.linkLibC();
    doc_root.linkLibCpp();
    const install_docs = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = doc_root.getEmittedDocs(),
    });
    b.step(
        "docs",
        "Copy documentation artifacts to prefix path",
    ).dependOn(&install_docs.step);

    // examples sokol
    const build_sokol = if (b.option(bool, "sokol", "build sokol examples")) |enable|
        enable
    else
        false;
    if (build_sokol) {
        const d = b.dependency("examples_sokol", .{
            .target = target,
            .optimize = optimize,
        });

        // const ozz_wf = d.namedWriteFiles("ozz-animation");
        // const ozz_install = b.addInstallDirectory(.{
        //     .install_dir = .{ .prefix = void{} },
        //     .install_subdir = "",
        //     .source_dir = ozz_wf.getDirectory(),
        // });
        // b.default_step.dependOn(&ozz_install.step);

        for (d.builder.install_tls.step.dependencies.items) |dep_step| {
            if (target.result.isWasm()) {
                if (dep_step.cast(std.Build.Step.InstallDir)) |dir| {
                    b.installDirectory(.{
                        .source_dir = dir.options.source_dir,
                        .install_dir = .prefix,
                        .install_subdir = dir.options.install_subdir,
                    });
                }
            } else {
                const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
                const root = b.step(
                    b.fmt("run-{s}", .{inst.artifact.name}),
                    b.fmt("Run {s}", .{inst.artifact.name}),
                );

                const run = b.addRunArtifact(inst.artifact);
                run.setCwd(b.path("zig-out/bin"));
                root.dependOn(&run.step);

                const install = b.addInstallArtifact(inst.artifact, .{});
                run.step.dependOn(&install.step);
                // run.step.dependOn(&ozz_install.step);
            }
        }
    }

    // examples raylib
    const build_raylib = if (b.option(bool, "raylib", "build raylib examples")) |enable|
        enable
    else
        false;
    if (build_raylib) {
        const d = b.dependency("examples_raylib", .{
            .target = target,
            .optimize = optimize,
        });
        for (d.builder.install_tls.step.dependencies.items) |dep_step| {
            if (target.result.isWasm()) {
                if (dep_step.cast(std.Build.Step.InstallDir)) |dir| {
                    // b.installDirectory();
                    b.installDirectory(.{
                        .source_dir = dir.options.source_dir,
                        .install_dir = .prefix,
                        .install_subdir = "web",
                    });
                }
            } else {
                const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
                const install = b.addInstallArtifact(inst.artifact, .{});
                b.getInstallStep().dependOn(&install.step);
                // run exe
                const run = b.addRunArtifact(inst.artifact);
                run.step.dependOn(&install.step);
                b.step(
                    b.fmt("run-{s}", .{inst.artifact.name}),
                    b.fmt("Run {s}", .{inst.artifact.name}),
                ).dependOn(&run.step);
            }
        }
    }
}
