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
    // gizmo
    var gizmo = utils.Gizmo{};
    // scene
    var transform = Transform{};
    var mesh = utils.mesh.Cube{};
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
    state.mesh.init();
    // page_allocator crash wasm
    state.gizmo.init(std.heap.c_allocator);
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    state.display.frame();

    const io = ig.igGetIO();
    if (!io.*.WantCaptureMouse) {
        state.gizmo.ctx.update(.{
            .viewport_size = .{ .x = io.*.DisplaySize.x, .y = io.*.DisplaySize.y },
            .mouse_left = io.*.MouseDown[ig.ImGuiMouseButton_Left],
            .ray = state.display.orbit.camera.getRay(state.display.cursor),
            .cam_yFov = state.display.orbit.camera.projection.fov_y_radians,
            .cam_dir = state.display.orbit.camera.transform.rotation.dirZ().negate(),
        });
        state.gizmo.drawlist.clearRetainingCapacity();
        state.gizmo.t.translation(
            state.gizmo.ctx,
            &state.gizmo.drawlist,
            false,
            &state.transform,
        ) catch @panic("transform a");
    }

    {
        // imgui widgets
        ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
        const w = io.*.DisplaySize.x;
        ig.igSetNextWindowPos(
            .{ .x = w - 256 - 10, .y = 10 },
            ig.ImGuiCond_Once,
            .{ .x = 0, .y = 0 },
        );
        // show_subview("debug");
        if (state.offscreen.beginButton("debug")) {
            defer state.offscreen.endButton();

            // draw_scene(state.offscreen.orbit.camera.viewProjectionMatrix(), true);
            state.mesh.draw(
                state.transform,
                state.offscreen.orbit.camera.viewProjectionMatrix(),
                .{ .useRenderTarget = true },
            );
            utils.draw_lines(&rowmath.lines.Grid(5).lines);
            utils.draw_camera_frustum(
                state.display.orbit,
                if (state.offscreen.hover)
                    null
                else
                    state.display.cursor,
            );

            state.gizmo.gl_draw();
        }
        ig.igEnd();
    }

    {
        // render background
        state.display.begin();
        defer state.display.end();

        utils.draw_lines(&rowmath.lines.Grid(5).lines);
        state.mesh.draw(
            state.transform,
            state.display.orbit.viewProjectionMatrix(),
            .{ .useRenderTarget = false },
        );
        state.gizmo.gl_draw();
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
        .window_title = "sokol-zig + Dear Imgui",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
