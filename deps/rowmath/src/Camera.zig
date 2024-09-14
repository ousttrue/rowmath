const Camera = @This();
const std = @import("std");
const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
const RigidTransform = @import("RigidTransform.zig");
const Ray = @import("Ray.zig");
const InputState = @import("InputState.zig");
pub const Projection = @import("CameraProjection.zig");

// projection
projection: Projection = .{},

// transform
pitch: f32 = 0,
yaw: f32 = 0,
shift: Vec3 = .{
    .x = 0,
    .y = 2,
    .z = 10,
},
transform: RigidTransform = .{},

pub fn viewProjectionMatrix(self: @This()) Mat4 {
    return self.transform.worldToLocal().mul(self.projection_matrix);
}

pub fn updateTransform(self: *@This()) void {
    const yaw = Quat.axisAngle(.{ .x = 0, .y = 1, .z = 0 }, self.yaw);
    const pitch = Quat.axisAngle(.{ .x = 1, .y = 0, .z = 0 }, self.pitch);
    self.transform.rotation = pitch.mul(yaw); //.matrix();
    const m = Mat4.translate(self.shift).mul(self.transform.rotation.matrix());
    self.transform.translation.x = m.m[12];
    self.transform.translation.y = m.m[13];
    self.transform.translation.z = m.m[14];
}

pub fn dolly(self: *@This(), d: f32) void {
    if (d > 0) {
        self.shift.z *= 0.9;
    } else if (d < 0) {
        self.shift.z *= 1.1;
    }
}

const ROT_SPEED = 2;
pub fn yawPitch(self: *@This(), input: InputState, prev: InputState) void {
    const dx = (input.mouse_x - prev.mouse_x) / self.projection.screen.y;
    const dy = (input.mouse_y - prev.mouse_y) / self.projection.screen.y;
    self.yaw -= dx * ROT_SPEED;
    self.pitch -= dy * ROT_SPEED;
}

pub fn screenMove(self: *@This(), input: InputState, prev: InputState) void {
    const d = self.projection.screenMove(
        input.mouse_x - prev.mouse_x,
        input.mouse_y - prev.mouse_y,
    );
    self.shift = self.shift.add(.{
        .x = d.x * self.shift.z,
        .y = d.y * self.shift.z,
        .z = 0,
    });
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

pub fn target(self: @This()) Vec3 {
    return self.transform.translation.add(self.transform.rotation.dirZ().scale(-@abs(self.shift.z)));
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
