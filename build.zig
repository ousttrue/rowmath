const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rowmath_dep = b.dependency("rowmath", .{
        .target = target,
        .optimize = optimize,
    });
    const rowmath_mod = rowmath_dep.module("rowmath");
    b.modules.put("rowmath", rowmath_mod) catch unreachable;

    {
        // tests
        const rowmath_test = rowmath_dep.artifact("rowmath_test");
        const test_run = b.addRunArtifact(rowmath_test);
        b.step("test", "rowmath tests").dependOn(&test_run.step);

        // docs
        const install_docs = b.addInstallDirectory(.{
            .install_dir = .prefix,
            .install_subdir = "docs",
            .source_dir = rowmath_test.getEmittedDocs(),
        });
        b.step(
            "docs",
            "Copy documentation artifacts to prefix path",
        ).dependOn(&install_docs.step);
    }

    // examples sokol
    if (b.option(bool, "sokol", "build sokol examples") orelse false) {
        const sokol_dep = b.dependency("sokol_samples", .{
            .target = target,
            .optimize = optimize,
        });

        const wf = sokol_dep.namedWriteFiles("build");

        const install_wf = b.addInstallDirectory(.{
            .source_dir = wf.getDirectory(),
            .install_dir = .{ .prefix = void{} },
            .install_subdir = "",
        });

        if (target.result.isWasm()) {
            b.getInstallStep().dependOn(&install_wf.step);
        } else {
            for (sokol_dep.builder.install_tls.step.dependencies.items) |dep_step| {
                // }

                if (dep_step.cast(std.Build.Step.InstallArtifact)) |install_artifact| {
                    // exe
                    const run = b.addRunArtifact(install_artifact.artifact);
                    run.setCwd(b.path("zig-out/bin"));
                    run.step.dependOn(&install_artifact.step);
                    run.step.dependOn(&install_wf.step);

                    b.step(
                        b.fmt("run-{s}", .{install_artifact.artifact.name}),
                        b.fmt("Run {s}", .{install_artifact.artifact.name}),
                    ).dependOn(&run.step);

                    const install = b.addInstallArtifact(install_artifact.artifact, .{});
                    b.getInstallStep().dependOn(&install.step);
                    install.step.dependOn(&install_artifact.step);
                    run.step.dependOn(&install.step);
                }
            }
        }

        const sokol_build = @import("sokol_samples");
        const run = sokol_build.emrun(b, sokol_dep);
        b.step("emrun", "run emrun").dependOn(&run.step);
    }

    // examples raylib
    if (b.option(bool, "raylib", "build raylib examples") orelse false) {
        const raylib_dep = b.dependency("raylib_samples", .{
            .target = target,
            .optimize = optimize,
        });
        for (raylib_dep.builder.install_tls.step.dependencies.items) |dep_step| {
            if (target.result.isWasm()) {
                if (dep_step.cast(std.Build.Step.InstallDir)) |dir| {
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
