pub usingnamespace @import("draw_util.zig");
pub const Fbo = @import("Fbo.zig");
pub const CameraView = @import("CameraView.zig");
pub const SwapchainView = @import("SwapchainView.zig");
pub const mesh = @import("mesh/mesh.zig");

const sokol = @import("sokol");
const rowmath = @import("rowmath");
pub fn handle_camera_input(
    e: [*c]const sokol.app.Event,
    input: *rowmath.InputState,
) void {
    switch (e.*.type) {
        .RESIZED => {
            input.screen_width = @floatFromInt(e.*.window_width);
            input.screen_height = @floatFromInt(e.*.window_height);
        },
        .MOUSE_DOWN => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    input.mouse_left = true;
                },
                .RIGHT => {
                    input.mouse_right = true;
                },
                .MIDDLE => {
                    input.mouse_middle = true;
                },
                .INVALID => {},
            }
        },
        .MOUSE_UP => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    input.mouse_left = false;
                },
                .RIGHT => {
                    input.mouse_right = false;
                },
                .MIDDLE => {
                    input.mouse_middle = false;
                },
                .INVALID => {},
            }
        },
        .MOUSE_MOVE => {
            input.mouse_x = e.*.mouse_x;
            input.mouse_y = e.*.mouse_y;
        },
        .MOUSE_SCROLL => {
            input.mouse_wheel = e.*.scroll_y;
        },
        else => {},
    }
}
