pub const Example = struct {
    name: []const u8,
    src: []const u8,
    use_imgui: bool = false,
};

pub const examples = [_]Example{
    .{
        .name = "sokol_camera_simple",
        .src = "camera_simple.zig",
    },
    .{
        .name = "sokol_camera_rendertarget",
        .src = "camera_rendertarget.zig",
        .use_imgui = true,
    },
};
