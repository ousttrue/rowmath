const std = @import("std");
const Vec2 = @import("../Vec2.zig");
const Vec3 = @import("../Vec3.zig");
const Vec4 = @import("../Vec4.zig");
const Rgba = @import("../RgbaF32.zig");
const Quat = @import("../Quat.zig");
const Mat4 = @import("../Mat4.zig");
const Ray = @import("../Ray.zig");
const Transform = @import("../Transform.zig");
const geometry = @import("geometry.zig");
const context = @import("context.zig");

const rotate_x = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.right,
        Vec3.up,
        Vec3.forward,
        32,
        &context.RING_POINTS,
        0.003,
    ),
    Rgba.red,
);
const rotate_y = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.up,
        Vec3.forward,
        Vec3.right,
        32,
        &context.RING_POINTS,
        -0.003,
    ),
    Rgba.green,
);
const rotate_z = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.forward,
        Vec3.right,
        Vec3.up,
        32,
        &context.RING_POINTS,
        0,
    ),
    Rgba.blue,
);
fn rotation_intersect(local_ray: Ray) struct { ?InteractionMode, f32 } {
    var component: ?InteractionMode = null;
    var best_t = std.math.inf(f32);

    if (rotate_x.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Rotate_x;
            best_t = t;
        }
    }
    if (rotate_y.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Rotate_y;
            best_t = t;
        }
    }
    if (rotate_z.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Rotate_z;
            best_t = t;
        }
    }
    return .{ component, best_t };
}

fn get(i: InteractionMode) ?geometry.MeshComponent {
    return switch (i) {
        .Rotate_x => rotate_x,
        .Rotate_y => rotate_y,
        .Rotate_z => rotate_z,
    };
}

fn snap(value: Vec3, f: f32) ?Vec3 {
    if (f > 0.0) {
        return .{
            .x = std.math.floor(value.x / f) * f,
            .y = std.math.floor(value.y / f) * f,
            .z = std.math.floor(value.z / f) * f,
        };
    }
    return null;
}

pub const ApplicationState = struct {
    // 3d viewport used to render the view
    viewport_size: Vec2,
    // Used for constructing inverse view projection for raycasting onto gizmo geometry
    cam_dir: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
    cam_yFov: f32 = 0,
    // world-space ray (from camera position to mouse cursor)
    ray: Ray = .{
        .origin = .{ .x = 0, .y = 0, .z = 0 },
        .direction = .{ .x = 0, .y = 0, .z = 0 },
    },
    // mouse
    mouse_left: bool = false,
    // If > 0.f, the gizmos are drawn scale-invariant with a screenspace value defined here
    screenspace_scale: f32 = 0,
    // World-scale units used for snapping translation
    snap_translation: f32 = 0,
    // World-scale units used for snapping scale
    snap_scale: f32 = 0,
    // Radians used for snapping rotation quaternions (i.e. PI/8 or PI/16)
    snap_rotation: f32 = 0,

    fn scale_screenspace(self: @This(), position: Vec3, pixel_scale: f32) f32 {
        const dist = position.sub(self.ray.origin).len();
        return std.math.tan(self.cam_yFov) * dist * (pixel_scale / self.viewport_size.y);
    }

    fn draw_scale(self: @This(), p: Transform) f32 {
        if (self.screenspace_scale > 0.0) {
            return self.scale_screenspace(
                p.rigid_transform.translation,
                self.screenspace_scale,
            );
        } else {
            return 1.0;
        }
    }

    fn local_ray(self: @This(), p: Transform) struct { Ray, f32 } {
        return .{
            detransform(p, self.ray),
            self.draw_scale(p),
        };
    }
};

// 32 bit Fowler–Noll–Vo Hash
const fnv1aBase32: u32 = 0x811C9DC5;
const fnv1aPrime32: u32 = 0x01000193;
fn hash_fnv1a(str: []const u8) u32 {
    var result = fnv1aBase32;
    for (str) |ch| {
        result ^= @as(u32, ch);
        result *%= fnv1aPrime32;
    }
    return result;
}

fn detransform(p: Transform, r: Ray) Ray {
    return .{
        .origin = p.detransform_point(r.origin),
        .direction = p.detransform_vector(r.direction),
    };
}

const InteractionMode = enum {
    Rotate_x,
    Rotate_y,
    Rotate_z,
};

fn flush_to_zero(f: Vec3) Vec3 {
    return .{
        .x = if (@abs(f.x) < 0.02) 0 else f.x,
        .y = if (@abs(f.y) < 0.02) 0 else f.y,
        .z = if (@abs(f.z) < 0.02) 0 else f.z,
    };
}

const Drag = struct {
    component: InteractionMode,
    // Offset from position of grabbed object to coordinates of clicked point
    local_click: Vec3,
    // Original position of an object being manipulated with a gizmo
    original_position: Vec3,
    // Original orientation of an object being manipulated with a gizmo
    original_orientation: Quat,
    active_axis: Vec3,

    fn axis_rotation_dragger(
        self: @This(),
        mouse_left: bool,
        snap_rotation: f32,
        r: Ray,
        axis: Vec3,
        start_orientation: Quat,
    ) ?Quat {
        if (!mouse_left) {
            return null;
        }
        const original_pose = Transform.fromTrs(
            self.original_position,
            start_orientation,
            Vec3.one,
        );
        const the_axis = original_pose.transformVector(axis);
        const the_plane = Vec4{
            .x = the_axis.x,
            .y = the_axis.y,
            .z = the_axis.z,
            .w = -the_axis.dot(self.local_click),
        };

        if (intersect_ray_plane(r, the_plane)) |t| {
            const center_of_rotation = self.original_position.add(the_axis.scale(the_axis.dot(self.local_click.sub(self.original_position))));
            const arm1 = self.local_click.sub(center_of_rotation).normalize();
            const arm2 = r.point(t).sub(center_of_rotation).normalize();

            const d = arm1.dot(arm2);
            if (d > 0.999) {
                return null;
            }

            const angle = std.math.acos(d);
            if (angle < 0.001) {
                return null;
            }

            if (snap_rotation > 0) {
                const snapped = make_rotation_quat_between_vectors_snapped(arm1, arm2, snap_rotation);
                return snapped.mul(start_orientation);
            } else {
                const a = arm1.cross(arm2).normalize();
                return Quat.fromAxisAngle(a, angle).mul(start_orientation);
            }
        }

        return null;
    }
};

fn intersect_ray_plane(ray: Ray, plane: Vec4) ?f32 {
    const denom = (Vec3{ .x = plane.x, .y = plane.y, .z = plane.z }).dot(ray.direction);
    if (@abs(denom) == 0) return null;
    return -plane.dot(Vec4.fromVec3(ray.origin, 1)) / denom;
}

fn make_rotation_quat_between_vectors_snapped(
    from: Vec3,
    to: Vec3,
    angle: f32,
) Quat {
    const a = from.normalize();
    const b = to.normalize();
    const snappedAcos = std.math.floor(std.math.acos(a.dot(b)) / angle) * angle;
    return make_rotation_quat_axis_angle(a.cross(b).normalize(), snappedAcos);
}

fn make_rotation_quat_axis_angle(axis: Vec3, angle: f32) Quat {
    const s = std.math.sin(angle / 2);
    const c = std.math.cos(angle / 2);
    return .{
        .x = axis.x * s,
        .y = axis.y * s,
        .z = axis.z * s,
        .w = c,
    };
}

pub const RotationContext = struct {
    // Flag to indicate if the gizmo is being hovered
    hover: ?InteractionMode = null,
    // Currently active component
    drag: ?Drag = null,

    pub fn rotation(
        self: *@This(),
        ctx: context.Context,
        drawlist: *std.ArrayList(context.Renderable),
        local_toggle: bool,
        _p: *Transform,
    ) !void {
        std.debug.assert(_p.rigid_transform.rotation.sqNorm() > 1e-6);

        var p = Transform.fromTrs(
            _p.rigid_transform.translation,
            if (local_toggle) _p.rigid_transform.rotation else Quat.identity,
            Vec3.one,
        );
        const local_ray, const draw_scale = ctx.active_state.local_ray(p);
        const _component, const best_t = rotation_intersect(
            local_ray.descale(draw_scale),
        );
        if (ctx.has_clicked) {
            self.drag = null;
            if (_component) |component| {
                var scale_local_ray = ctx.active_state.ray;
                scale_local_ray.scale(draw_scale);
                const local_click = scale_local_ray.point(best_t);
                std.debug.print("{}\n", .{local_click});
                self.drag = .{
                    .component = component,
                    .original_position = _p.rigid_transform.translation,
                    .original_orientation = _p.rigid_transform.rotation,
                    .local_click = local_click,
                    .active_axis = switch (component) {
                        .Rotate_x => Vec3.right,
                        .Rotate_y => Vec3.up,
                        .Rotate_z => Vec3.forward,
                    },
                };
            }
        }

        if (self.drag) |*drag| {
            switch (drag.component) {
                .Rotate_x => {
                    if (drag.axis_rotation_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_rotation,
                        ctx.active_state.ray,
                        Vec3.right,
                        drag.original_orientation,
                    )) |rot| {
                        p.rigid_transform.rotation = rot;
                    }
                },
                .Rotate_y => {
                    if (drag.axis_rotation_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_rotation,
                        ctx.active_state.ray,
                        Vec3.up,
                        drag.original_orientation,
                    )) |rot| {
                        p.rigid_transform.rotation = rot;
                    }
                },
                .Rotate_z => {
                    if (drag.axis_rotation_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_rotation,
                        ctx.active_state.ray,
                        Vec3.forward,
                        drag.original_orientation,
                    )) |rot| {
                        p.rigid_transform.rotation = rot;
                    }
                },
            }
        }

        if (ctx.has_released) {
            self.drag = null;
        }

        const scaleMatrix = Mat4.makeScale(.{
            .x = draw_scale,
            .y = draw_scale,
            .z = draw_scale,
        });
        const modelMatrix = p.matrix().mul(scaleMatrix);

        // if (!local_toggle and self.drag != null) {
        //     // draw_interactions = { g.interaction_mode };
        // } else {
        for ([_]InteractionMode{ .Rotate_x, .Rotate_y, .Rotate_z }) |i| {
            if (get(i)) |c| {
                try drawlist.append(.{
                    .mesh = c.mesh,
                    .base_color = c.base_color,
                    .matrix = modelMatrix,
                    .hover = i == _component,
                    .active = false,
                });
            }
        }
        // }

        // For non-local transformations, we only present one rotation ring
        // and draw an arrow from the center of the gizmo to indicate the degree of rotation
        // if (g.local_toggle == false && g.gizmos[id].interaction_mode != interact::none)
        // {
        //     interaction_state & interaction = g.gizmos[id];
        //
        //     // Create orthonormal basis for drawing the arrow
        //     float3 a = qrot(p.orientation, interaction.local_click - interaction.original_position);
        //     float3 zDir = normalize(activeAxis), xDir = normalize(cross(a, zDir)), yDir = cross(zDir, xDir);
        //
        //     // Ad-hoc geometry
        //     std::initializer_list<float2> arrow_points = { { 0.0f, 0.f },{ 0.0f, 0.05f },{ 0.8f, 0.05f },{ 0.9f, 0.10f },{ 1.0f, 0 } };
        //     auto geo = make_lathed_geometry(yDir, xDir, zDir, 32, arrow_points);
        //
        //     gizmo_renderable r;
        //     r.mesh = geo;
        //     r.color = float4(1);
        //     for (auto & v : r.mesh.vertices)
        //     {
        //         v.position = transform_coord(modelMatrix, v.position);
        //         v.normal = transform_vector(modelMatrix, v.normal);
        //     }
        //     g.drawlist.push_back(r);
        //
        //     orientation = qmul(p.orientation, interaction.original_orientation);
        // }
        // else if (g.local_toggle == true && g.gizmos[id].interaction_mode != interact::none) orientation = p.orientation;
        //

        if (ctx.active_state.mouse_left) {
            _p.* = p;
        }
    }
};
