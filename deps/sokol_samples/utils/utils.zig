pub usingnamespace @import("draw_util.zig");
pub const Fbo = @import("Fbo.zig");
pub const FboView = @import("FboView.zig");
pub const SwapchainView = @import("SwapchainView.zig");
pub const mesh = @import("mesh/mesh.zig");
pub const Gizmo = @import("Gizmo.zig");
const ig = @import("cimgui");

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

pub fn imColor(r: u8, g: u8, b: u8, a: u8) u32 {
    const color = ig.ImColor_ImColor_Int(r, g, b, a);
    const p: *const ig.ImVec4 = @ptrCast(color);
    return ig.igGetColorU32_Vec4(p.*);
}
