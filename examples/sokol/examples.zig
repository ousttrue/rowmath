pub const Example = struct {
    name: []const u8,
    src: []const u8,
    use_imgui: bool = false,
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
};
