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

const scale_x = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.right,
        Vec3.up,
        Vec3.forward,
        16,
        &context.MACE_POINTS,
        0,
    ),
    Rgba.red,
);
const scale_y = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.up,
        Vec3.forward,
        Vec3.right,
        16,
        &context.MACE_POINTS,
        0,
    ),
    Rgba.green,
);
const scale_z = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.forward,
        Vec3.right,
        Vec3.up,
        16,
        &context.MACE_POINTS,
        0,
    ),
    Rgba.blue,
);
fn scale_intersect(local_ray: Ray) struct { ?InteractionMode, f32 } {
    var component: ?InteractionMode = null;
    var best_t = std.math.inf(f32);
    if (scale_x.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Scale_x;
            best_t = t;
        }
    }
    if (scale_y.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Scale_y;
            best_t = t;
        }
    }
    if (scale_z.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Scale_z;
            best_t = t;
        }
    }
    return .{ component, best_t };
}

fn get(i: InteractionMode) ?geometry.MeshComponent {
    return switch (i) {
        .Scale_x => scale_x,
        .Scale_y => scale_y,
        .Scale_z => scale_z,
        .Scale_xyz => null,
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

const InteractionMode = enum {
    Scale_x,
    Scale_y,
    Scale_z,
    Scale_xyz,
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
    click_offset: Vec3,
    // Original scale of an object being manipulated with a gizmo
    original_scale: Vec3,

    fn axis_scale_dragger(
        self: @This(),
        mouse_left: bool,
        snap_scale: f32,
        ray: Ray,
        axis: Vec3,
        // Define the plane to contain the original position of the object
        plane_point: Vec3,
        uniform: bool,
    ) ?Vec3 {
        if (!mouse_left) {
            return null;
        }

        const plane_tangent = axis.cross(plane_point.sub(ray.origin));
        const plane_normal = axis.cross(plane_tangent);

        // If an intersection exists between the ray and the plane, place the object at that point
        const denom = ray.direction.dot(plane_normal);
        if (@abs(denom) == 0) return null;

        const t = plane_point.sub(ray.origin).dot(plane_normal) / denom;
        if (t < 0) return null;

        const distance = ray.point(t);
        const dist_from_click = distance.sub(self.click_offset);
        var offset_on_axis = Vec3{
            .x = dist_from_click.x * axis.x,
            .y = dist_from_click.y * axis.x,
            .z = dist_from_click.y * axis.z,
        };
        offset_on_axis = flush_to_zero(offset_on_axis);
        var new_scale = self.original_scale.add(offset_on_axis);

        new_scale = if (uniform) Vec3.scalar(std.math.clamp(distance.dot(new_scale), 0.01, 1000.0)) else Vec3{
            .x = std.math.clamp(new_scale.x, 0.01, 1000.0),
            .y = std.math.clamp(new_scale.y, 0.01, 1000.0),
            .z = std.math.clamp(new_scale.z, 0.01, 1000.0),
        };
        if (snap_scale > 0) return snap(new_scale, snap_scale);
        return new_scale;
    }
};

pub const ScalingContext = struct {
    // Flag to indicate if the gizmo is being hovered
    hover: ?InteractionMode = null,
    // Currently active component
    active: ?Drag = null,

    pub fn scale(
        self: *@This(),
        ctx: context.Context,
        drawlist: *std.ArrayList(context.Renderable),
        _p: *Transform,
        uniform: bool,
    ) !void {
        var p = Transform.trs(
            _p.rigid_transform.translation,
            _p.rigid_transform.rotation,
            Vec3.one,
        );
        const local_ray, const draw_scale = ctx.active_state.local_ray(p);
        const _component, const best_t = scale_intersect(
            local_ray.descale(draw_scale),
        );

        if (ctx.has_clicked) {
            self.active = null;
            if (_component) |component| {
                self.active = .{
                    .component = component,
                    .original_scale = _p.scale,
                    .click_offset = p.transformPoint(local_ray.point(best_t)),
                };
            }
        }

        if (ctx.has_released) {
            self.active = null;
        }

        if (self.active) |active| {
            switch (active.component) {
                .Scale_x => {
                    if (active.axis_scale_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_scale,
                        ctx.active_state.ray,
                        Vec3.right,
                        _p.rigid_transform.translation,
                        uniform,
                    )) |new_scale| {
                        _p.scale = new_scale;
                    }
                },
                .Scale_y => {
                    if (active.axis_scale_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_scale,
                        ctx.active_state.ray,
                        Vec3.up,
                        _p.rigid_transform.translation,
                        uniform,
                    )) |new_scale| {
                        _p.scale = new_scale;
                    }
                },
                .Scale_z => {
                    if (active.axis_scale_dragger(
                        ctx.active_state.mouse_left,
                        ctx.active_state.snap_scale,
                        ctx.active_state.ray,
                        Vec3.forward,
                        _p.rigid_transform.translation,
                        uniform,
                    )) |new_scale| {
                        _p.scale = new_scale;
                    }
                },
                else => unreachable,
            }
        }

        const scaleMatrix = Mat4.scaleUniform(draw_scale);
        const modelMatrix = p.matrix().mul(scaleMatrix);
        for ([_]InteractionMode{ .Scale_x, .Scale_y, .Scale_z }) |i| {
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

        // _p.* = p;
    }
};
