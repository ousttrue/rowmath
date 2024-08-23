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
    var pass_action: sg.PassAction = .{};

    var allocator: std.mem.Allocator = undefined;
    var view1 = CameraView{
        .camera = .{
            .near_clip = 0.5,
            .far_clip = 15,
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
    var view2 = CameraView{
        .camera = .{
            .transform = .{
                .translation = .{ .x = 0, .y = 1, .z = 15 },
            },
        },
    };
    var view2_cursor: Vec2 = .{ .x = 0, .y = 0 };
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

    // initial clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };

    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    state.view1.init();
    state.view2.init();
}

export fn frame() void {
    // call sokol.imgui.newFrame() before any ImGui calls
    sokol.imgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });

    const io = ig.igGetIO().*;
    if (!io.WantCaptureMouse) {
        // camera update
    }

    //=== UI CODE STARTS HERE
    // {
    //     ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
    //     ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    //     _ = ig.igBegin("Hello Dear ImGui!", 0, ig.ImGuiWindowFlags_None);
    //     _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);
    //     ig.igEnd();
    // }

    {
        ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
        ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
        ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });
        defer ig.igPopStyleVar(1);
        if (ig.igBegin(
            &"view1"[0],
            null,
            ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse,
        )) {
            if (state.view1.beginImageButton()) |render_context| {
                defer state.view1.endImageButton();
                state.view1_cursor = render_context.cursor;

                // grid
                utils.draw_grid();
            }
        }
        ig.igEnd();
    }
    {
        ig.igSetNextWindowPos(.{ .x = 310, .y = 130 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
        ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
        ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });
        defer ig.igPopStyleVar(1);
        if (ig.igBegin(
            &"view2"[0],
            null,
            ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse,
        )) {
            if (state.view2.beginImageButton()) |render_context| {
                defer state.view2.endImageButton();
                state.view2_cursor = render_context.cursor;

                // grid
                utils.draw_grid();
            }
        }
        ig.igEnd();
    }
    //=== UI CODE ENDS HERE

    // call sokol.imgui.render() inside a sokol-gfx pass
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    sokol.imgui.render();
    sg.endPass();
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
