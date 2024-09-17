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

pub const translate_x = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.right,
        Vec3.up,
        Vec3.forward,
        16,
        &context.ARROW_POINTS,
        0,
    ),
    Rgba.red,
);
pub const translate_y = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.up,
        Vec3.forward,
        Vec3.right,
        16,
        &context.ARROW_POINTS,
        0,
    ),
    Rgba.green,
);
pub const translate_z = geometry.MeshComponent.init(
    geometry.make_lathed_geometry(
        Vec3.forward,
        Vec3.right,
        Vec3.up,
        16,
        &context.ARROW_POINTS,
        0,
    ),
    Rgba.blue,
);
pub const translate_yz = geometry.MeshComponent.init(
    geometry.make_box_geometry(
        .{ .x = -0.01, .y = 0.25, .z = 0.25 },
        .{ .x = 0.01, .y = 0.75, .z = 0.75 },
    ),
    Rgba.cyan,
);
pub const translate_zx = geometry.MeshComponent.init(
    geometry.make_box_geometry(
        .{ .x = 0.25, .y = -0.01, .z = 0.25 },
        .{ .x = 0.75, .y = 0.01, .z = 0.75 },
    ),
    Rgba.magenta,
);
pub const translate_xy = geometry.MeshComponent.init(
    geometry.make_box_geometry(
        .{ .x = 0.25, .y = 0.25, .z = -0.01 },
        .{ .x = 0.75, .y = 0.75, .z = 0.01 },
    ),
    Rgba.yellow,
);
pub const translate_xyz = geometry.MeshComponent.init(
    geometry.make_box_geometry(
        .{ .x = -0.05, .y = -0.05, .z = -0.05 },
        .{ .x = 0.05, .y = 0.05, .z = 0.05 },
    ),
    Rgba.gray,
);
pub fn translation_intersect(local_ray: Ray) struct { ?InteractionMode, f32 } {
    var component: ?InteractionMode = null;
    var best_t = std.math.inf(f32);

    if (translate_x.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_x;
            best_t = t;
        }
    }
    if (translate_y.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_y;
            best_t = t;
        }
    }
    if (translate_z.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_z;
            best_t = t;
        }
    }
    if (translate_yz.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_yz;
            best_t = t;
        }
    }
    if (translate_zx.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_zx;
            best_t = t;
        }
    }
    if (translate_xy.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_xy;
            best_t = t;
        }
    }
    if (translate_xyz.mesh.intersect(local_ray)) |t| {
        if (t < best_t) {
            component = .Translate_xyz;
            best_t = t;
        }
    }

    return .{ component, best_t };
}

pub fn get(i: InteractionMode) ?geometry.MeshComponent {
    return switch (i) {
        .Translate_x => translate_x,
        .Translate_y => translate_y,
        .Translate_z => translate_z,
        .Translate_yz => translate_yz,
        .Translate_zx => translate_zx,
        .Translate_xy => translate_xy,
        .Translate_xyz => translate_xyz,
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

pub const InteractionMode = enum {
    Translate_x,
    Translate_y,
    Translate_z,
    Translate_yz,
    Translate_zx,
    Translate_xy,
    Translate_xyz,
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
    click_offset: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
    // Original position of an object being manipulated with a gizmo
    original_position: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
    // Original orientation of an object being manipulated with a gizmo
    original_orientation: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
    // Original scale of an object being manipulated with a gizmo
    original_scale: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
};

fn intersect_ray_plane(ray: Ray, plane: Vec4) ?f32 {
    const denom = (Vec3{ .x = plane.x, .y = plane.y, .z = plane.z }).dot(ray.direction);
    if (@abs(denom) == 0) return null;
    return -plane.dot(Vec4.fromVec3(ray.origin, 1)) / denom;
}

fn plane_translation_dragger(
    ctx: context.Context,
    active: *Drag,
    plane_normal: Vec3,
    point: Vec3,
) ?Vec3 {
    // Mouse clicked
    if (ctx.has_clicked) {
        active.original_position = point;
    }

    // Define the plane to contain the original position of the object
    const plane_point = active.original_position;

    // If an intersection exists between the ray and the plane, place the object at that point
    const denom = ctx.active_state.ray.direction.dot(plane_normal);
    if (@abs(denom) == 0) {
        return null;
    }

    const t = plane_point.sub(ctx.active_state.ray.origin).dot(plane_normal) / denom;
    if (t < 0) {
        return null;
    }

    var result = ctx.active_state.ray.point(t);
    if (snap(result, ctx.active_state.snap_translation)) |new_position| {
        result = new_position;
    }
    return result;
}

fn axis_translation_dragger(
    ctx: context.Context,
    active: *Drag,
    axis: Vec3,
    point: Vec3,
) ?Vec3 {
    // First apply a plane translation dragger with a plane that contains the desired axis and is oriented to face the camera
    const plane_tangent = axis.cross(point.sub(ctx.active_state.ray.origin));
    const plane_normal = axis.cross(plane_tangent);
    const new_point = plane_translation_dragger(ctx, active, plane_normal, point) orelse {
        return null;
    };
    // Constrain object motion to be along the desired axis
    const delta = new_point.sub(active.original_position);
    return active.original_position.add(axis.scale(delta.dot(axis)));
}

pub const draw_interactions = [_]InteractionMode{
    .Translate_x,
    .Translate_y,
    .Translate_z,
    .Translate_yz,
    .Translate_zx,
    .Translate_xy,
    .Translate_xyz,
};

pub const TranslationContext = struct {
    // Flag to indicate if the gizmo is being hovered
    hover: ?InteractionMode = null,
    // Currently active component
    active: ?Drag = null,

    pub fn translation(
        self: *@This(),
        ctx: context.Context,
        drawlist: *std.ArrayList(context.Renderable),
        local_toggle: bool,
        _p: *Transform,
    ) !void {
        var p = Transform.trs(
            _p.rigid_transform.translation,
            if (local_toggle) _p.rigid_transform.rotation else Quat.identity,
            Vec3.one,
        );
        const local_ray, const draw_scale = ctx.active_state.local_ray(p);
        const _component, const best_t = translation_intersect(
            local_ray.descale(draw_scale),
        );

        if (ctx.has_clicked) {
            self.active = null;
            if (_component) |component| {
                const point = local_ray.point(best_t);
                const active = Drag{
                    .component = component,
                    .click_offset = if (local_toggle) p.transformPoint(point) else point,
                };
                self.active = active;
            }
        }

        const axes = if (local_toggle) [3]Vec3{
            p.rigid_transform.rotation.dirX(),
            p.rigid_transform.rotation.dirY(),
            p.rigid_transform.rotation.dirZ(),
        } else [3]Vec3{
            .{ .x = 1, .y = 0, .z = 0 },
            .{ .x = 0, .y = 1, .z = 0 },
            .{ .x = 0, .y = 0, .z = 1 },
        };

        if (self.active) |*active| {
            if (ctx.active_state.mouse_left) {
                var position = p.rigid_transform.translation.add(active.click_offset);
                if (switch (active.component) {
                    .Translate_x => axis_translation_dragger(ctx, active, axes[0], position),
                    .Translate_y => axis_translation_dragger(ctx, active, axes[1], position),
                    .Translate_z => axis_translation_dragger(ctx, active, axes[2], position),
                    .Translate_yz => plane_translation_dragger(ctx, active, axes[0], position),
                    .Translate_zx => plane_translation_dragger(ctx, active, axes[1], position),
                    .Translate_xy => plane_translation_dragger(ctx, active, axes[2], position),
                    .Translate_xyz => plane_translation_dragger(
                        ctx,
                        active,
                        ctx.active_state.cam_dir, //.orientation.dirZ().negate(),
                        position,
                    ),
                }) |new_position| {
                    position = new_position;
                }
                p.rigid_transform.translation = position.sub(active.click_offset);
            }
        }

        if (ctx.has_released) {
            self.active = null;
        }

        const scaleMatrix = Mat4.scale(.{
            .x = draw_scale,
            .y = draw_scale,
            .z = draw_scale,
        });
        const modelMatrix = p.matrix().mul(scaleMatrix);

        for (draw_interactions) |i| {
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

        _p.* = p;
    }
};
