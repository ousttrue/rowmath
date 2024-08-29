const std = @import("std");
const emsdk_zig = @import("emsdk-zig");
const examples = @import("examples.zig").examples;
const Example = @import("examples.zig").Example;

const emcc_extra_args = [_][]const u8{
    "-sTOTAL_MEMORY=200MB",
    "-sUSE_OFFSET_CONVERTER=1",
};

const BuildExampleOptions = struct {
    rowmath: *std.Build.Module,
    cimgui: *std.Build.Dependency,
    utils: *std.Build.Module,
    cuber: *std.Build.Module,
    dep_sokol: *std.Build.Dependency,
    ozz_wf: *std.Build.Step.WriteFile,

    fn inject(self: @This(), compile: *std.Build.Step.Compile) void {
        compile.root_module.addImport("sokol", self.dep_sokol.module("sokol"));
        compile.root_module.addImport("rowmath", self.rowmath);
        compile.root_module.addImport("cimgui", self.cimgui.module("cimgui"));
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
        if (example.use_ozz) {
            lib.step.dependOn(&opts.ozz_wf.step);

            const ozz_wrap = b.addModule("ozz_wrap", .{
                .root_source_file = b.path("ozz_anim/ozz_wrap.zig"),
            });
            ozz_wrap.addImport("rowmath", opts.rowmath);
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
            .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html").getPath(b),
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

        return lib;
    } else {
        const exe = b.addExecutable(.{
            .target = target,
            .optimize = optimize,
            .name = example.name,
            .root_source_file = b.path(example.src),
        });
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

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rowmath = b.addModule(
        "rowmath",
        .{ .root_source_file = b.path("../../src/rowmath.zig") },
    );

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
    });

    const cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });
    // inject the cimgui header search path into the sokol C library compile step
    const cimgui_root = cimgui.namedWriteFiles("cimgui").getDirectory();
    dep_sokol.artifact("sokol_clib").addIncludePath(cimgui_root);

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

        const cimgui_clib_artifact = cimgui.artifact("cimgui_clib");
        cimgui_clib_artifact.addSystemIncludePath(emsdk_incl_path);
        cimgui_clib_artifact.step.dependOn(&dep_sokol.artifact("sokol_clib").step);
    }

    var utils = b.addModule("utils", .{
        .root_source_file = b.path("utils/utils.zig"),
    });
    utils.addImport("rowmath", rowmath);
    utils.addImport("sokol", dep_sokol.module("sokol"));
    utils.addImport("cimgui", cimgui.module("cimgui"));

    var cuber = b.addModule("cuber", .{
        .root_source_file = b.path("cuber/cuber.zig"),
    });
    cuber.addImport("rowmath", rowmath);
    cuber.addImport("sokol", dep_sokol.module("sokol"));
    // glsl to glsl.zig
    const sokol_tool = @import("sokol_tool.zig");
    const cuber_shader = sokol_tool.runShdcCommand(
        b,
        target,
        b.path("cuber/shader.glsl").getPath(b),
    );

    const ozz_dep = b.dependency("ozz-animation", .{
        .target = target,
        .optimize = optimize,
    });
    const ozz_wf = ozz_dep.namedWriteFiles("meson_build");

    b.installDirectory(.{
        .install_dir = .{ .prefix = void{} },
        .install_subdir = "",
        .source_dir = ozz_wf.getDirectory(),
    });

    _ = b.addNamedWriteFiles("ozz-animation").addCopyDirectory(ozz_wf.getDirectory(), "", .{});

    for (examples) |example| {
        const compile = build_example(
            b,
            emsdk,
            target,
            optimize,
            example,
            .{
                .rowmath = rowmath,
                .cimgui = cimgui,
                .utils = utils,
                .cuber = cuber,
                .dep_sokol = dep_sokol,
                .ozz_wf = ozz_wf,
            },
        );
        compile.step.dependOn(&cuber_shader.step);
    }
}
