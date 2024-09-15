const std = @import("std");
const sokol_tool = @import("sokol_tool.zig");

pub const Example = struct {
    name: []const u8,
    src: []const u8,
    shader: ?[]const u8 = null,
    use_imgui: bool = false,

    pub fn injectShader(
        self: @This(),
        b: *std.Build,
        target: std.Build.ResolvedTarget,
        compile: *std.Build.Step.Compile,
    ) void {
        const shader = self.shader orelse {
            return;
        };

        // glsl to glsl.zig
        const run = sokol_tool.runShdcCommand(
            b,
            target,
            shader,
        );
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
        .use_imgui = true,
    },
    .{
        .name = "sokol_camera_rendertarget",
        .src = "camera_rendertarget/main.zig",
        .use_imgui = true,
    },
    .{
        .name = "sokol_instancing",
        .src = "instancing/main.zig",
        .use_imgui = true,
    },
};
