// TODO:
//
// - frustum
// - gaze cross
// - text status
// - perse ortho
//
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const ig = @import("cimgui");
const utils = @import("utils");
const CameraView = utils.CameraView;
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Camera = rowmath.Camera;

const state = struct {
    var allocator: std.mem.Allocator = undefined;
    // background. without render target
    var screen = CameraView{
        .camera = .{
            .projection = .{
                .perspective = .{
                    .near_clip = 0.5,
                    .far_clip = 15,
                },
            },
            .transform = .{
                .translation = .{
                    .x = 0,
                    .y = 1,
                    .z = 5,
                },
            },
        },
    };
    var view1_cursor: Vec2 = .{ .x = 0, .y = 0 };

    var subview = CameraView{
        .camera = .{
            .transform = .{
                .translation = .{ .x = 0, .y = 1, .z = 15 },
            },
        },
    };
};

export fn init() void {
    // initialize sokol-gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    // initialize sokol-imgui
    sokol.imgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    state.screen.init();

    // initial clear color
    state.screen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };

    state.subview.init();
}

export fn frame() void {
    // call sokol.imgui.newFrame() before any ImGui calls
    sokol.imgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });

    const input = CameraView.inputFromScreen();
    state.screen.update(input);

    //=== UI CODE STARTS HERE
    {
        ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
        ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
        _ = ig.igBegin("Hello Dear ImGui!", 0, ig.ImGuiWindowFlags_None);
        defer ig.igEnd();

        _ = ig.igColorEdit3("Background", &state.screen.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);

        // var mode: c_int = 0;
        switch (state.screen.camera.projection) {
            .perspective => |perspective| {
                if (ig.igRadioButton_Bool("perspective", true)) {}
                ig.igSameLine(0, 0);
                if (ig.igRadioButton_Bool("orthographic", false)) {
                    state.screen.camera.projection = Camera.Projection{
                        .orthographic = .{
                            .near_clip = perspective.near_clip,
                            .far_clip = perspective.far_clip,
                            .height = std.math.tan(perspective.fov_y_radians / 2) * perspective.far_clip * 2,
                        },
                    };
                    state.screen.camera.updateProjectionMatrix();
                }
            },
            .orthographic => |orthographic| {
                if (ig.igRadioButton_Bool("perspective", false)) {
                    // https://github.com/ziglang/zig/issues/19832
                    state.screen.camera.projection = Camera.Projection{
                        .perspective = .{
                            .near_clip = orthographic.near_clip,
                            .far_clip = orthographic.far_clip,
                            .fov_y_radians = std.math.atan2(orthographic.height / 2, orthographic.far_clip) * 2,
                        },
                    };
                    state.screen.camera.updateProjectionMatrix();
                }
                ig.igSameLine(0, 0);
                if (ig.igRadioButton_Bool("orthographic", true)) {}
            },
        }
    }

    {
        const io = ig.igGetIO();
        ig.igSetNextWindowPos(.{ .x = io.*.DisplaySize.x - 280, .y = 10 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
        ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
        ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });
        defer ig.igPopStyleVar(1);
        if (ig.igBegin(
            &"subview"[0],
            null,
            ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse,
        )) {
            if (state.subview.beginImageButton()) |_| {
                defer state.subview.endImageButton();

                // grid
                utils.draw_grid();
                // frustum
                utils.draw_camera_frustum(state.screen.camera, input.cursorScreenPosition());
            }
        }
        ig.igEnd();
    }

    //=== UI CODE ENDS HERE
    {
        // call sokol.imgui.render() inside a sokol-gfx pass
        state.screen.begin(null);
        defer state.screen.end(null);

        utils.draw_grid();
    }

    sg.commit();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    // forward input events to sokol-imgui
    _ = sokol.imgui.handleEvent(ev.*);
}

export fn cleanup() void {
    sokol.imgui.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "sokol-zig + Dear Imgui",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
