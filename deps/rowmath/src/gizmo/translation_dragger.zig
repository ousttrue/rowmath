const std = @import("std");
const Camera = @import("../Camera.zig");
const InputState = @import("../InputState.zig");
const Transform = @import("../Transform.zig");
const Ray = @import("../Ray.zig");
const Mat4 = @import("../Mat4.zig");
const geometry = @import("geometry.zig");
const translation = @import("translation.zig");
const Renderable = @import("context.zig").Renderable;

pub const DragState = struct {
    start: Transform,
    mode: translation.InteractionMode,
    ray: Ray,
    hit: f32,
};

pub const TranslateionState = union(enum) {
    none: void,
    hover: DragState,
    drag: DragState,
};

const DragInput = struct {
    camera: Camera,
    input: InputState,
    transform: Transform,
    drawlist: *std.ArrayList(Renderable),
};

pub fn make_drawlist(
    drawlist: *std.ArrayList(Renderable),
    m: Mat4,
    mode: ?translation.InteractionMode,
) void {
    drawlist.clearRetainingCapacity();
    for (translation.draw_interactions) |_c| {
        if (translation.get(_c)) |c| {
            drawlist.append(.{
                .mesh = c.mesh,
                .base_color = c.base_color,
                .matrix = m,
                .hover = _c == mode,
                .active = false,
            }) catch @panic("append");
        }
    }
}

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
pub fn translationDragHandler(
    drag_state: TranslateionState,
    drag_input: DragInput,
    button: bool,
) TranslateionState {
    var next_state = TranslateionState{ .none = void{} };

    switch (drag_state) {
        .none => {
            // new hover
            const cursor = drag_input.input.cursorScreenPosition();
            const ray = drag_input.camera.getRay(cursor);
            const local_ray = detransform(drag_input.transform, ray);
            const _mode, const hit = translation.translation_intersect(
                local_ray,
            );
            if (_mode) |mode| {
                // new hover
                next_state = .{
                    .hover = .{
                        .start = drag_input.transform,
                        .mode = mode,
                        .ray = ray,
                        .hit = hit,
                    },
                };
            }
        },
        .hover => |hover| {
            if (button) {
                // begin drag
                next_state = .{
                    .drag = hover,
                };
            } else {
                const cursor = drag_input.input.cursorScreenPosition();
                const ray = drag_input.camera.getRay(cursor);
                const local_ray = detransform(drag_input.transform, ray);
                const _mode, const hit = translation.translation_intersect(
                    local_ray,
                );
                if (_mode) |mode| {
                    // new hover
                    next_state = .{
                        .hover = .{
                            .start = drag_input.transform,
                            .mode = mode,
                            .ray = ray,
                            .hit = hit,
                        },
                    };
                }
            }
        },
        .drag => |drag| {
            if (button) {
                // continue drag
                next_state = .{ .drag = drag };
            } else {
                // end drag
            }
        },
    }

    make_drawlist(drag_input.drawlist, drag_input.transform.matrix(), switch (drag_state) {
        .none => null,
        .hover => |hover| hover.mode,
        .drag => |drag| drag.mode,
    });

    return next_state;
}

fn detransform(p: Transform, r: Ray) Ray {
    return .{
        .origin = p.detransformPoint(r.origin),
        .direction = p.detransformVector(r.direction),
    };
}
