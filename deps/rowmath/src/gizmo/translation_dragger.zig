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

const TranslationInput = struct {
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

pub const DragState = struct {
    camera_transform: RigidTransform,
    start_transform: Transform,
    mode: translation.InteractionMode,
    cursor: Vec2,
    ray: Ray,
    hit: f32,

    pub fn getRayHitPlane(self: @This()) Plane {
        return Plane.fromNormalAndPoint(
            self.camera_transform.rotation.dirZ(),
            self.ray.point(self.hit),
        );
    }

    fn dragAxis(
        input_transform: *Transform,
        start: Vec3,
        v: Vec3,
        dir_x: Vec3,
        _dir_y: ?Vec3,
    ) void {
        const d_x = v.dot(dir_x);
        if (_dir_y) |dir_y| {
            const d_y = v.dot(dir_y);
            input_transform.rigid_transform.translation = start.add(
                dir_x.scale(d_x),
            ).add(
                dir_y.scale(d_y),
            );
        } else {
            input_transform.rigid_transform.translation = start.add(
                dir_x.scale(d_x),
            );
        }
    }

    //
    // pos = start + dir * t;
    //
    pub fn drag(self: @This(), input: TranslationInput) void {
        const start = self.ray.point(self.hit);
        const ray = input.getRay();
        switch (self.mode) {
            .Translate_x => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirZ(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.right,
                        null,
                    );
                }
            },
            .Translate_y => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirX(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.up,
                        null,
                    );
                }
            },
            .Translate_z => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirY(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.forward,
                        null,
                    );
                }
            },
            .Translate_xy => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirZ(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.right,
                        Vec3.up,
                    );
                }
            },
            .Translate_yz => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirX(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.up,
                        Vec3.forward,
                    );
                }
            },
            .Translate_zx => {
                const drag_plane = Plane.fromNormalAndPoint(
                    self.start_transform.rigid_transform.rotation.dirY(),
                    self.ray.point(self.hit),
                );
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        Vec3.forward,
                        Vec3.right,
                    );
                }
            },
            .Translate_xyz => {
                const drag_plane = self.getRayHitPlane();
                if (drag_plane.intersect(ray)) |hit| {
                    const current = ray.point(hit);
                    const v = current.sub(start);
                    dragAxis(
                        input.transform,
                        self.start_transform.rigid_transform.translation,
                        v,
                        input.camera.transform.rotation.dirX(),
                        input.camera.transform.rotation.dirY(),
                    );
                }
            },
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

pub fn translationDragHandler(
    drag_state: TranslateionState,
    drag_input: TranslationInput,
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
