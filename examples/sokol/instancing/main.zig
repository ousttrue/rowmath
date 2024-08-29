//------------------------------------------------------------------------------
//  instancing.c
//  Demonstrate simple hardware-instancing using a static geometry buffer
//  and a dynamic instance-data buffer.
//------------------------------------------------------------------------------
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const utils = @import("utils");

const cuber = @import("cuber");
const Cuber = cuber.Cuber(4);

const state = struct {
    var pass_action = sg.PassAction{};

    var input = rowmath.InputState{};
    var camera = rowmath.MouseCamera{};

    var cuber = Cuber{};
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // a pass action for the default render pass
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
    };

    state.camera.init();
    state.cuber.init();
}

export fn frame() void {
    // update camera
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.camera.frame(state.input);
    state.input.mouse_wheel = 0;

    // update instance data
    const n = 2;
    state.cuber.instances[0] = .{ .matrix = Mat4.translate(.{ .x = -n, .y = 0, .z = -n }) };
    state.cuber.instances[1] = .{ .matrix = Mat4.translate(.{ .x = n, .y = 0, .z = -n }) };
    state.cuber.instances[2] = .{ .matrix = Mat4.translate(.{ .x = n, .y = 0, .z = n }) };
    state.cuber.instances[3] = .{ .matrix = Mat4.translate(.{ .x = -n, .y = 0, .z = n }) };
    state.cuber.upload();

    // ...and draw
    {
        sg.beginPass(.{
            .action = state.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        defer sg.endPass();

        {
            // grid
            utils.gl_begin(.{
                .projection = state.camera.projectionMatrix(),
                .view = state.camera.viewMatrix(),
            });
            defer utils.gl_end();

            utils.draw_lines(&rowmath.lines.Grid(5).lines);
        }

        state.cuber.draw(state.camera.viewProjectionMatrix());
    }
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    utils.handle_camera_input(e, &state.input);
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .window_title = "Instancing (sokol-app)",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
