const Camera = @This();
const std = @import("std");
const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
const RigidTransform = @import("RigidTransform.zig");
const Ray = @import("Ray.zig");
const InputState = @import("InputState.zig");

pub const Frustum = struct {
    near_top_left: Vec3,
    near_top_right: Vec3,
    near_bottom_left: Vec3,
    near_bottom_right: Vec3,
    far_top_left: Vec3,
    far_top_right: Vec3,
    far_bottom_left: Vec3,
    far_bottom_right: Vec3,
};

// projection
yFov: f32 = std.math.degreesToRadians(60.0),
near_clip: f32 = 0.1,
far_clip: f32 = 50.0,
projection: Mat4 = Mat4.identity,
screen: Vec2 = .{ .x = 1, .y = 1 },

// transform
pitch: f32 = 0,
yaw: f32 = 0,
shift: Vec3 = .{
    .x = 0,
    .y = 2,
    .z = 10,
},
transform: RigidTransform = .{},

pub fn aspect(self: @This()) f32 {
    return self.screen.x / self.screen.y;
}

pub fn viewProjectionMatrix(self: @This()) Mat4 {
    return self.transform.worldToLocal().mul(self.projection);
}

pub fn updateProjectionMatrix(self: *@This()) void {
    self.projection = Mat4.perspective(
        self.yFov,
        self.aspect(),
        self.near_clip,
        self.far_clip,
    );
}

pub fn updateTransform(self: *@This()) void {
    const yaw = Quat.axisAngle(.{ .x = 0, .y = 1, .z = 0 }, self.yaw);
    const pitch = Quat.axisAngle(.{ .x = 1, .y = 0, .z = 0 }, self.pitch);
    self.transform.rotation = yaw.mul(pitch); //.matrix();
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
    const dx = (input.mouse_x - prev.mouse_x) / self.screen.y;
    const dy = (input.mouse_y - prev.mouse_y) / self.screen.y;
    const t = std.math.tan(self.yFov / 2);
    self.yaw -= dx * t * ROT_SPEED;
    self.pitch -= dy * t * ROT_SPEED;
}

pub fn screenMove(self: *@This(), input: InputState, prev: InputState) void {
    const dx = (input.mouse_x - prev.mouse_x) / self.screen.y;
    const dy = (input.mouse_y - prev.mouse_y) / self.screen.y;
    const t = std.math.tan(self.yFov / 2);
    self.shift.x -= dx * t * self.shift.z;
    self.shift.y += dy * t * self.shift.z;
}

pub fn resize(self: *@This(), size: Vec2) void {
    if (std.meta.eql(self.screen, size)) {
        return;
    }
    self.screen = size;
    self.updateProjectionMatrix();
}

pub fn ray(self: @This(), mouse_cursor: Vec2) Ray {
    const y = std.math.tan(self.yFov / 2);
    const x = y * self.input_state.aspect();
    const dir = Vec3{
        .x = x * (mouse_cursor.x / self.input_state.screen_width * 2 - 1),
        .y = y * -(mouse_cursor.y / self.input_state.screen_height * 2 - 1),
        .z = -1,
    };

    const dir_cursor = self.transform.rotation.rotatePoint(dir.normalize());
    // std.debug.print("{d:.3}, {d:.3}, {d:.3}\n", .{dir_cursor.x, dir_cursor.y, dir_cursor.z});
    return .{
        .origin = self.transform.translation,
        .direction = dir_cursor,
    };
}

pub fn frustum(self: @This()) Frustum {
    const y = std.math.tan(self.yFov / 2);
    const x = y * self.input_state.aspect();
    const near_x = x * self.near_clip;
    const near_y = y * self.near_clip;
    const far_x = x * self.far_clip;
    const far_y = y * self.far_clip;
    return .{
        // near
        .near_top_left = Vec3{
            .x = -near_x,
            .y = near_y,
            .z = -self.near_clip,
        },
        .near_top_right = Vec3{
            .x = near_x,
            .y = near_y,
            .z = -self.near_clip,
        },
        .near_bottom_left = Vec3{
            .x = -near_x,
            .y = -near_y,
            .z = -self.near_clip,
        },
        .near_bottom_right = Vec3{
            .x = near_x,
            .y = -near_y,
            .z = -self.near_clip,
        },
        // far
        .far_top_left = Vec3{
            .x = -far_x,
            .y = far_y,
            .z = -self.far_clip,
        },
        .far_top_right = Vec3{
            .x = far_x,
            .y = far_y,
            .z = -self.far_clip,
        },
        .far_bottom_left = Vec3{
            .x = -far_x,
            .y = -far_y,
            .z = -self.far_clip,
        },
        .far_bottom_right = Vec3{
            .x = far_x,
            .y = -far_y,
            .z = -self.far_clip,
        },
    };
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
