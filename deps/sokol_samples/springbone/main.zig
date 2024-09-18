const std = @import("std");
const builtin = @import("builtin");

const sokol = @import("sokol");
const sg = sokol.gfx;
const simgui = sokol.imgui;
const ig = @import("cimgui");

const utils = @import("utils");
const FboView = utils.FboView;
const SwapchainView = utils.SwapchainView;

const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Vec2 = rowmath.Vec2;
const Mat4 = rowmath.Mat4;
const Camera = rowmath.Camera;
const InputState = rowmath.InputState;
const Frustum = rowmath.Frustum;
const Transform = rowmath.Transform;
const Ray = rowmath.Ray;
const Plane = rowmath.Plane;

const state = struct {
    // main camera
    var display = SwapchainView{
        .orbit = .{
            .camera = .{
                .projection = .{
                    .near_clip = 0.5,
                    .far_clip = 15,
                },
                .transform = .{
                    .translation = .{
                        .x = 0,
                        .y = 1,
                        .z = 5,
                    },
                },
            },
        },
    };
    // sub camera
    var offscreen = FboView{
        .orbit = .{
            .camera = .{
                .transform = .{
                    .translation = .{ .x = 0, .y = 1, .z = 15 },
                },
            },
        },
    };
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    simgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    state.offscreen.init();
    state.display.init();
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    state.display.frame();

    {
        state.display.begin();
        defer state.display.end();
        // render background
        utils.draw_lines(&rowmath.lines.Grid(5).lines);
    }
    sg.commit();
}

export fn cleanup() void {
    simgui.shutdown();
    sokol.gl.shutdown();
    sg.shutdown();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    _ = simgui.handleEvent(ev.*);
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "springbone",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
