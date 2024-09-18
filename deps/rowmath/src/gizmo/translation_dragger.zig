const std = @import("std");
const Camera = @import("../Camera.zig");
const InputState = @import("../InputState.zig");
const Transform = @import("../Transform.zig");
const RigidTransform = @import("../RigidTransform.zig");
const Vec2 = @import("../Vec2.zig");
const Vec3 = @import("../Vec3.zig");
const Ray = @import("../Ray.zig");
const Mat4 = @import("../Mat4.zig");
const Plane = @import("../Plane.zig");
const geometry = @import("geometry.zig");
const translation = @import("translation.zig");
const Renderable = @import("context.zig").Renderable;

const DragInput = struct {
    camera: Camera,
    input: InputState,
    transform: *Transform,
    drawlist: *std.ArrayList(Renderable),

    pub fn getRay(self: @This()) Ray {
        return self.camera.getRay(self.input.cursorScreenPosition());
    }
};

const DragAxis = union(enum) {
    mono: Vec3,
    di: struct { Vec3, Vec3 },
};

pub fn getDir(t: Transform, mode: translation.InteractionMode, camera: Camera) DragAxis {
    _ = t;
    return switch (mode) {
        .Translate_x => DragAxis{ .mono = Vec3.right },
        .Translate_y => DragAxis{ .mono = Vec3.up },
        .Translate_z => DragAxis{ .mono = Vec3.forward },
        .Translate_yz => DragAxis{ .di = .{ Vec3.up, Vec3.forward } },
        .Translate_zx => DragAxis{ .di = .{ Vec3.forward, Vec3.right } },
        .Translate_xy => DragAxis{ .di = .{ Vec3.right, Vec3.up } },
        .Translate_xyz => DragAxis{ .di = .{
            camera.transform.rotation.dirX(),
            camera.transform.rotation.dirY(),
        } },
    };
}

pub const DragState = struct {
    camera_transform: RigidTransform,
    start_transform: Transform,
    mode: translation.InteractionMode,
    cursor: Vec2,
    ray: Ray,
    hit: f32,

    pub fn getPlane(self: @This()) Plane {
        return Plane.fromNormalAndPoint(
            self.camera_transform.rotation.dirZ(),
            self.ray.point(self.hit),
        );
    }

    //
    // pos = start + dir * t;
    //
    pub fn drag(self: @This(), input: DragInput) void {
        const drag_plane = self.getPlane();
        const ray = input.getRay();
        if (drag_plane.intersect(ray)) |hit| {
            const current = ray.point(hit);
            const start = self.ray.point(self.hit);
            switch (getDir(self.start_transform, self.mode, input.camera)) {
                .mono => |dir| {
                    const d = dir.dot(current.sub(start));

                    input.transform.rigid_transform.translation = self.start_transform.rigid_transform.translation.add(
                        dir.scale(d),
                    );
                },
                .di => |x_y| {
                    const dir_x, const dir_y = x_y;
                    const v = current.sub(start);
                    const d_x = dir_x.dot(v);
                    const d_y = dir_y.dot(v);
                    input.transform.rigid_transform.translation = self.start_transform.rigid_transform.translation.add(
                        dir_x.scale(d_x),
                    ).add(
                        dir_y.scale(d_y),
                    );
                },
            }
        }
    }
};

pub const TranslateionState = union(enum) {
    none: void,
    hover: DragState,
    drag: DragState,
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
            const local_ray = detransform(drag_input.transform.*, ray);
            const _mode, const hit = translation.translation_intersect(
                local_ray,
            );
            if (_mode) |mode| {
                // new hover
                next_state = .{
                    .hover = .{
                        .camera_transform = drag_input.camera.transform,
                        .start_transform = drag_input.transform.*,
                        .mode = mode,
                        .cursor = drag_input.input.cursorScreenPosition(),
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
                const local_ray = detransform(drag_input.transform.*, ray);
                const _mode, const hit = translation.translation_intersect(
                    local_ray,
                );
                if (_mode) |mode| {
                    // new hover
                    next_state = .{
                        .hover = .{
                            .camera_transform = drag_input.camera.transform,
                            .start_transform = drag_input.transform.*,
                            .mode = mode,
                            .cursor = drag_input.input.cursorScreenPosition(),
                            .ray = ray,
                            .hit = hit,
                        },
                    };
                }
            }
        },
        .drag => |drag| {
            if (button) {
                drag.drag(drag_input);

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
