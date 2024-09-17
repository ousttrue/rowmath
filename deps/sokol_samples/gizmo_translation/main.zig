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
    var gizmo: rowmath.DragHandle(.left, &dragHandler) = undefined;
    // scene
    var transform = Transform{};
    var mesh = utils.mesh.Cube{};
};

const DragState = struct {
    ray: Ray,
    hit: f32,

    fn draw(self: @This()) void {
        sokol.gl.beginLines();
        defer sokol.gl.end();

        // X axis (green).
        sokol.gl.c3f(0, 0xff, 0xff);
        const o = self.ray.origin;
        sokol.gl.v3f(o.x, o.y, o.z);
        const p = self.ray.point(self.hit);
        sokol.gl.v3f(p.x, p.y, p.z);
    }
};

const GizmoState = struct {
    camera: *Camera,
    drag: ?DragState = null,
};

const DragInput = struct {
    input: InputState,
    transform: Transform,
};

// state.gizmo.ctx.update(.{
//     .viewport_size = .{ .x = io.*.DisplaySize.x, .y = io.*.DisplaySize.y },
//     .mouse_left = io.*.MouseDown[ig.ImGuiMouseButton_Left],
//     .ray = state.display.orbit.camera.getRay(state.display.cursor),
//     .cam_yFov = state.display.orbit.camera.projection.fov_y_radians,
//     .cam_dir = state.display.orbit.camera.transform.rotation.dirZ().negate(),
// });
// state.gizmo.drawlist.clearRetainingCapacity();
// state.gizmo.t.translation(
//     state.gizmo.ctx,
//     &state.gizmo.drawlist,
//     false,
//     &state.transform,
// ) catch @panic("transform a");
fn dragHandler(drag_state: GizmoState, drag_input: DragInput, button: bool) GizmoState {
    if (button) {
        if (drag_state.drag) |drag| {
            // keep
            return .{
                .camera = drag_state.camera,
                .drag = drag,
            };
        } else {
            // new ray
            const cursor = drag_input.input.cursorScreenPosition();
            const ray = drag_state.camera.getRay(cursor);
            const local_ray = detransform(drag_input.transform, ray);
            const _mode, const hit = rowmath.gizmo.translation_intersect(
                local_ray,
            );
            if (_mode) |_| {
                return .{
                    .camera = drag_state.camera,
                    .drag = DragState{
                        .ray = ray,
                        .hit = hit,
                    },
                };
            }
        }
    } else {
        const cursor = drag_input.input.cursorScreenPosition();
        const ray = drag_state.camera.getRay(cursor);
        const local_ray = detransform(drag_input.transform, ray);
        const _mode, const hit = rowmath.gizmo.translation_intersect(
            local_ray,
        );
        if (_mode) |_| {
            return .{
                .camera = drag_state.camera,
                .drag = DragState{
                    .ray = ray,
                    .hit = hit,
                },
            };
        }
    }
    return .{
        .camera = drag_state.camera,
        .drag = null,
    };
}

fn detransform(p: Transform, r: Ray) Ray {
    return .{
        .origin = p.detransformPoint(r.origin),
        .direction = p.detransformVector(r.direction),
    };
}

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
    state.gizmo = .{
        .handler = &dragHandler,
        .state = .{
            .camera = &state.display.orbit.camera,
        },
    };
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    const input = state.display.frame();

    const io = ig.igGetIO();
    if (!io.*.WantCaptureMouse) {
        state.gizmo.frame(.{
            .input = input,
            .transform = state.transform,
        });
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

            if (state.gizmo.state.drag) |drag| {
                drag.draw();
            }

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

            // drawDrag(state.drag_left.state, state.input, .{
            //     .name = "Left",
            //     .color = RgbU8.red,
            // });

            // state.gizmo.gl_draw();
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
        // state.gizmo.gl_draw();
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
