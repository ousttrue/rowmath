//------------------------------------------------------------------------------
//  debugtext-printf-sapp.c
//
//  Simple text rendering with sokol_debugtext.h, formatting, tabs, etc...
//------------------------------------------------------------------------------
const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const Vec2 = rowmath.Vec2;
const InputState = rowmath.InputState;
const RgbU8 = rowmath.RgbU8;
const utils = @import("utils");

const FONT_KC854 = 0;

fn nopHandler(drag_state: ?Vec2, input: InputState, button: bool) ?Vec2 {
    if (drag_state) |pos| {
        if (button) {
            return pos;
        } else {
            return null;
        }
    } else {
        if (button) {
            return input.cursor();
        } else {
            return null;
        }
    }
}

fn NopHandler(comptime button: rowmath.MouseButton) rowmath.DragHandle(button, ?Vec2) {
    return rowmath.DragHandle(button, ?Vec2){
        .state = null,
        .handler = &nopHandler,
    };
}

const state = struct {
    var pass_action = sg.PassAction{};
    var input = InputState{};

    var drag_left = NopHandler(.left);
    var drag_right = NopHandler(.right);
    var drag_middle = NopHandler(.middle);
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
    state.drag_left.frame(state.input);
    state.drag_right.frame(state.input);
    state.drag_middle.frame(state.input);

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

        utils.draw_mouse_state(state.input, RgbU8.yellow);

        {
            sokol.gl.beginLines();
            defer sokol.gl.end();
            utils.draw_button(
                "Left",
                RgbU8.red,
                state.drag_left.state,
                state.input,
            );
            utils.draw_button(
                "Right",
                RgbU8.green,
                state.drag_right.state,
                state.input,
            );
            utils.draw_button(
                "Middle",
                RgbU8.blue,
                state.drag_middle.state,
                state.input,
            );
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
