const std = @import("std");
const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Vec4 = @import("Vec4.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
const RigidTransform = @import("RigidTransform.zig");
const Ray = @import("Ray.zig");
const InputState = @import("InputState.zig");
pub const Projection = @import("CameraProjection.zig");
pub const Camera = @This();

projection: Projection = .{},
transform: RigidTransform = .{},

pub fn viewProjectionMatrix(self: @This()) Mat4 {
    return self.transform.worldToLocal().mul(self.projection.matrix);
}

pub fn getRay(self: @This(), mouse_cursor: Vec2) Ray {
    const local_ray = self.projection.getRay(mouse_cursor);
    return self.transform.transformRay(local_ray);
}

pub fn getRayClip(self: @This(), ray: Ray) struct { f32, f32 } {
    switch (self.projection.projection_type) {
        .perspective => {
            const f: f32 = -1.0 / self.transform.rotation.dirZ().dot(ray.direction);
            return .{ self.projection.near_clip * f, self.projection.far_clip * f };
        },
        .orthographic => {
            return .{ self.projection.near_clip, self.projection.far_clip };
        },
    }
}

pub fn toScreen(self: @This(), world: Vec3) Vec2 {
    const p = self.viewProjectionMatrix().transform(Vec4.fromVec3(world, 1));
    return .{
        .x = (p.x / p.w + 1.0) / 2.0 * self.projection.screen.x,
        .y = (-p.y / p.w + 1.0) / 2.0 * self.projection.screen.y,
    };
}

test "camera" {
    const cam = Camera{};
    try std.testing.expectEqual(Vec3{ .x = 1, .y = 0, .z = 0 }, cam.transform.rotation.dirX());
    try std.testing.expectEqual(Vec3{ .x = 0, .y = 1, .z = 0 }, cam.transform.rotation.dirY());
    try std.testing.expectEqual(Vec3{ .x = 0, .y = 0, .z = 1 }, cam.transform.rotation.dirZ());

    const q = Quat{ .x = 0, .y = 0, .z = 0, .w = 1 };
    const v = q.rotatePoint(.{ .x = 1, .y = 2, .z = 3 });
    try std.testing.expectEqual(Vec3{ .x = 1, .y = 2, .z = 3 }, v);
}
