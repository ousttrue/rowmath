const Vec4 = @This();
const Vec3 = @import("Vec3.zig");

x: f32,
y: f32,
z: f32,
w: f32,

pub const RED: Vec4 = .{ .x = 1, .y = 0, .z = 0, .w = 1.0 };
pub const GREEN: Vec4 = .{ .x = 0, .y = 1, .z = 0, .w = 1.0 };
pub const BLUE: Vec4 = .{ .x = 0, .y = 0, .z = 1, .w = 1.0 };
pub const CYAN: Vec4 = .{ .x = 0, .y = 0.5, .z = 0.5, .w = 1.0 };
pub const MAGENTA: Vec4 = .{ .x = 0.5, .y = 0, .z = 0.5, .w = 1.0 };
pub const YELLOW: Vec4 = .{ .x = 0.3, .y = 0.3, .z = 0, .w = 1.0 };
pub const GRAY: Vec4 = .{ .x = 0.7, .y = 0.7, .z = 0.7, .w = 1.0 };

pub fn fromVec3(v: Vec3, w: f32) @This() {
    return .{
        .x = v.x,
        .y = v.y,
        .z = v.z,
        .w = w,
    };
}

pub fn toVec3(self: @This()) Vec3 {
    return .{
        .x = self.x,
        .y = self.y,
        .z = self.z,
    };
}

pub fn dot(v0: Vec4, v1: Vec4) f32 {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z + v0.w * v1.w;
}
