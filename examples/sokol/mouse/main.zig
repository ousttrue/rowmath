//------------------------------------------------------------------------------
//  debugtext-printf-sapp.c
//
//  Simple text rendering with sokol_debugtext.h, formatting, tabs, etc...
//------------------------------------------------------------------------------
const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const InputState = rowmath.InputState;
const DragHandle = rowmath.DragHandle;
const utils = @import("utils");

const FONT_KC854 = 0;

const state = struct {
    var pass_action = sg.PassAction{};
    var input = InputState{};

    var drag_left = DragHandle{};
    var drag_right = DragHandle{};
    var drag_middle = DragHandle{};
};

export fn init() void {
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.125, .b = 0.25, .a = 1.0 },
    };

    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    var sdtx_desc = sokol.debugtext.Desc{
        .logger = .{ .func = sokol.log.func },
    };
    sdtx_desc.fonts[0] = sokol.debugtext.fontKc854();
    sokol.debugtext.setup(sdtx_desc);
}

export fn frame() void {
    state.drag_left.frame(
        .{ .x = state.input.mouse_x, .y = state.input.mouse_y },
        state.input.mouse_left,
    );
    state.drag_right.frame(
        .{ .x = state.input.mouse_x, .y = state.input.mouse_y },
        state.input.mouse_right,
    );
    state.drag_middle.frame(
        .{ .x = state.input.mouse_x, .y = state.input.mouse_y },
        state.input.mouse_middle,
    );

    {
        sg.beginPass(.{
            .action = state.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        defer sg.endPass();
        utils.gl_begin(.{
            .projection = Mat4.orthographic(
                0,
                sokol.app.widthf(),
                sokol.app.heightf(),
                0,
                -1,
                1,
            ),
            .view = Mat4.identity,
        });
        defer utils.gl_end();

        utils.draw_mouse_state(state.input, utils.yellow);

        {
            sokol.gl.beginLines();
            defer sokol.gl.end();
            utils.draw_button("Left", utils.red, state.drag_left.state);
            utils.draw_button("Right", utils.green, state.drag_right.state);
            utils.draw_button("Middle", utils.blue, state.drag_middle.state);
            sokol.debugtext.draw();
        }
    }
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    utils.inputEvent(e, &state.input);
}

export fn cleanup() void {
    sokol.debugtext.shutdown();
    sokol.gl.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 640,
        .height = 480,
        .window_title = "debugtext-printf-sapp",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
