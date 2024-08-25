const std = @import("std");
const sokol_tool = @import("sokol_tool.zig");

pub const Example = struct {
    name: []const u8,
    src: []const u8,
    use_imgui: bool = false,
    shader: ?[]const u8 = null,

    pub fn injectShader(
        self: @This(),
        b: *std.Build,
        target: std.Build.ResolvedTarget,
        sokol_dep: *std.Build.Dependency,
        compile: *std.Build.Step.Compile,
    ) void {
        _ = sokol_dep; // autofix
        const shader = self.shader orelse {
            return;
        };

        // glsl to glsl.zig
        const run = sokol_tool.runShdcCommand(
            b,
            target,
            shader,
        );

        // const module = std.Build.Module.create(b, .{
        //     .root_source_file = output,
        // });
        // compile.root_module.addImport(b.fmt("{s}.shader", .{self.name}), module);
        //
        // module.addImport("sokol", sokol_dep.module("sokol"));

        compile.step.dependOn(&run.step);
    }
};

pub const examples = [_]Example{
    .{
        .name = "sokol_camera_simple",
        .src = "camera_simple/main.zig",
    },
    .{
        .name = "sokol_mouse",
        .src = "mouse/main.zig",
    },
    .{
        .name = "sokol_camera_rendertarget",
        .src = "camera_rendertarget/main.zig",
        .use_imgui = true,
    },
    .{
        .name = "sokol_instancing",
        .src = "instancing/main.zig",
        .shader = "instancing/shader.glsl",
        .use_imgui = true,
    },
};
