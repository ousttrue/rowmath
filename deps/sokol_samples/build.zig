const std = @import("std");
const builtin = @import("builtin");
const emsdk_zig = @import("emsdk-zig");
const examples = @import("examples.zig").examples;
const Example = @import("examples.zig").Example;
const sokol_tool = @import("sokol_tool.zig");

const debug_flags = [_][]const u8{
    "-sASSERTIONS",
    "-g4",
};

const release_flags = [_][]const u8{};

const emcc_extra_args = [_][]const u8{
    "-sTOTAL_MEMORY=200MB",
    // default 64MB
    "-sSTACK_SIZE=256MB",
    "-sALLOW_MEMORY_GROWTH=0",
    "-sUSE_OFFSET_CONVERTER=1",
} ++ (if (builtin.mode == .Debug) debug_flags else release_flags);

const BuildExampleOptions = struct {
    utils: *std.Build.Module,
    cuber: *std.Build.Module,
    rowmath_mod: *std.Build.Module,
    cimgui_dep: *std.Build.Dependency,
    sokol_dep: *std.Build.Dependency,
    ozz_dep: *std.Build.Dependency,
    ozz_wf: *std.Build.Step.WriteFile,

    fn inject(self: @This(), compile: *std.Build.Step.Compile) void {
        compile.root_module.addImport("sokol", self.sokol_dep.module("sokol"));
        compile.root_module.addImport("rowmath", self.rowmath_mod);
        compile.root_module.addImport("cimgui", self.cimgui_dep.module("cimgui"));
        compile.root_module.addImport("utils", self.utils);
        compile.root_module.addImport("cuber", self.cuber);
    }

    fn injectWasmSysRoot(
        self: @This(),
        emsdk: *std.Build.Dependency,
        // compile: *std.Build.Step.Compile,
    ) void {
        // need to inject the Emscripten system header include path into
        // the cimgui C library otherwise the C/C++ code won't find
        // C stdlib headers
        const emsdk_incl_path = emsdk.path("upstream/emscripten/cache/sysroot/include");
        self.cimgui.artifact("cimgui_clib").addSystemIncludePath(emsdk_incl_path);

        // all C libraries need to depend on the sokol library, when building for
        // WASM this makes sure that the Emscripten SDK has been setup before
        // C compilation is attempted (since the sokol C library depends on the
        // Emscripten SDK setup step)
        self.cimgui.artifact("cimgui_clib").step.dependOn(&self.dep_sokol.artifact("sokol_clib").step);
    }
};
fn build_example(
    b: *std.Build,
    _emsdk: ?*std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    example: Example,
    opts: BuildExampleOptions,
) *std.Build.Step.Compile {
    if (_emsdk) |emsdk| {
        const lib = b.addStaticLibrary(.{
            .target = target,
            .optimize = optimize,
            .name = example.name,
            .root_source_file = b.path(example.src),
            .pic = true,
        });
        lib.addIncludePath(opts.ozz_dep.path(""));
        if (example.use_ozz) {
            lib.step.dependOn(&opts.ozz_wf.step);

            const ozz_wrap = b.addModule("ozz_wrap", .{
                .root_source_file = b.path("ozz_anim/ozz_wrap.zig"),
            });
            ozz_wrap.addImport("rowmath", opts.rowmath_mod);
            lib.root_module.addImport("ozz_wrap", ozz_wrap);
        }
        example.injectShader(b, target, lib);
        // if (example.shader) |shader| {
        //     // glsl to glsl.zig
        //     lib.step.dependOn(sokolShdc(
        //         b,
        //         target,
        //         shader,
        //     ));
        // }

        // inject dependency(must inject before emLinkStep)
        opts.inject(lib);
        // opts.injectWasmSysRoot(emsdk);

        // create a build step which invokes the Emscripten linker
        const emcc = try emsdk_zig.emLinkCommand(b, emsdk, .{
            .lib_main = lib,
            .target = target,
            .optimize = optimize,
            .use_webgl2 = true,
            .use_emmalloc = true,
            .use_filesystem = true,
            .shell_file_path = opts.sokol_dep.path("src/sokol/web/shell.html").getPath(b),
            .release_use_closure = false,
            .extra_before = &emcc_extra_args,
        });

        emcc.addArg("-o");
        const out_file = emcc.addOutputFileArg(b.fmt("{s}.html", .{lib.name}));
        if (example.use_ozz) {
            emcc.addArg("-sMAIN_MODULE=1");
            emcc.addFileArg(opts.ozz_wf.getDirectory().path(b, "web/ozz-animation.wasm"));
            emcc.addArg("-sERROR_ON_UNDEFINED_SYMBOLS=0");
        }

        // the emcc linker creates 3 output files (.html, .wasm and .js)
        const install = b.addInstallDirectory(.{
            .source_dir = out_file.dirname(),
            .install_dir = .prefix,
            .install_subdir = "web",
        });
        install.step.dependOn(&emcc.step);
        b.getInstallStep().dependOn(&install.step);

        if (_emsdk) |emsdk_dep| {
            const emsdk_incl_path = emsdk_dep.path(
                "upstream/emscripten/cache/sysroot/include",
            );
            lib.addSystemIncludePath(emsdk_incl_path);
        }

        return lib;
    } else {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = example.name,
            .root_source_file = b.path(example.src),
        });
        exe.addIncludePath(opts.ozz_dep.path(""));
        b.installArtifact(exe);

        example.injectShader(b, target, exe);

        // inject dependency
        opts.inject(exe);

        if (example.use_ozz) {
            const libdir = opts.ozz_wf.getDirectory().path(b, "lib");
            exe.addLibraryPath(libdir);
            exe.linkSystemLibrary("ozz-animation");
        }

        return exe;
    }
}

fn build_ozz_sokol_framework(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const mod = b.addModule("ozz_sokol_framework", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("ozz_sokol_framework/ozz_sokol_framework.zig"),
    });
    return mod;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rowmath_dep = b.dependency(
        "rowmath",
        .{},
    );
    const rowmath_mod = rowmath_dep.module("rowmath");

    const sokol_dep = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
    });

    const cimgui_dep = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    // inject the cimgui header search path into the sokol C library compile step
    const cimgui_root = cimgui_dep.namedWriteFiles("cimgui").getDirectory();
    sokol_dep.artifact("sokol_clib").addIncludePath(cimgui_root);

    // create a build step which invokes the Emscripten linker
    var emsdk: ?*std.Build.Dependency = null;
    if (target.result.isWasm()) {
        const _emsdk_zig = b.dependency("emsdk-zig", .{});
        const _emsdk = _emsdk_zig.builder.dependency("emsdk", .{});
        emsdk = _emsdk;

        // all C libraries need to depend on the sokol library, when building for
        // WASM this makes sure that the Emscripten SDK has been setup before
        // C compilation is attempted (since the sokol C library depends on the
        // Emscripten SDK setup step)
        // need to inject the Emscripten system header include path into
        // the cimgui C library otherwise the C/C++ code won't find
        // C stdlib headers
        const emsdk_incl_path = _emsdk.path(
            "upstream/emscripten/cache/sysroot/include",
        );
        // const emsdk_cpp_incl_path = dep_emsdk.path(
        //     "upstream/emscripten/cache/sysroot/include/c++/v1",
        // );

        const cimgui_clib_artifact = cimgui_dep.artifact("cimgui_clib");
        cimgui_clib_artifact.addSystemIncludePath(emsdk_incl_path);
        cimgui_clib_artifact.step.dependOn(&sokol_dep.artifact("sokol_clib").step);
    }

    var utils = b.addModule("utils", .{
        .root_source_file = b.path("utils/utils.zig"),
    });
    utils.addImport("rowmath", rowmath_mod);
    utils.addImport("sokol", sokol_dep.module("sokol"));
    utils.addImport("cimgui", cimgui_dep.module("cimgui"));

    var cuber = b.addModule("cuber", .{
        .root_source_file = b.path("cuber/cuber.zig"),
    });
    cuber.addImport("rowmath", rowmath_mod);
    cuber.addImport("sokol", sokol_dep.module("sokol"));

    const meson_opt: []const u8 = "--wipe";
    _ = meson_opt;
    const ozz_dep = b.dependency("ozz-animation", .{
        .target = target,
        .optimize = optimize,
        // .meson = meson_opt,
    });
    const ozz_wf = ozz_dep.namedWriteFiles("meson_build");

    b.installDirectory(.{
        .install_dir = .{ .prefix = void{} },
        .install_subdir = "",
        .source_dir = ozz_wf.getDirectory(),
    });

    _ = b.addNamedWriteFiles("ozz-animation").addCopyDirectory(ozz_wf.getDirectory(), "", .{});

    const ozz_sokol_framework = build_ozz_sokol_framework(b, target, optimize);
    ozz_sokol_framework.addImport("sokol", sokol_dep.module("sokol"));
    ozz_sokol_framework.addImport("rowmath", rowmath_mod);

    for (examples) |example| {
        const compile = build_example(
            b,
            emsdk,
            target,
            optimize,
            example,
            .{
                .utils = utils,
                .cuber = cuber,
                .rowmath_mod = rowmath_mod,
                .cimgui_dep = cimgui_dep,
                .sokol_dep = sokol_dep,
                .ozz_dep = ozz_dep,
                .ozz_wf = ozz_wf,
            },
        );

        compile.root_module.addImport("ozz_sokol_framework", ozz_sokol_framework);

        const root = b.path("");
        compile.addIncludePath(root);
        compile.linkLibCpp();
        compile.linkLibC();

        for (shaders) |glsl| {
            const shader = sokol_tool.runShdcCommand(
                b,
                target,
                b.path(glsl).getPath(b),
            );
            compile.step.dependOn(&shader.step);
        }
    }
}

// glsl to glsl.zig
const shaders: []const []const u8 = &.{
    "cuber/shader.glsl",
    "ozz_sokol_framework/bone.glsl",
    "ozz_sokol_framework/joint.glsl",
};

pub fn emrun(b: *std.Build, dep: *std.Build.Dependency) *std.Build.Step.Run {
    const emsdk_zig_dep = dep.builder.dependency("emsdk-zig", .{});
    const emsdk_dep = emsdk_zig_dep.builder.dependency("emsdk", .{});
    // ...and a special run step to start the web build output via 'emrun'
    return emsdk_zig.emRunStep(b, emsdk_dep, .{ .name = "ozz_anim" });
}
