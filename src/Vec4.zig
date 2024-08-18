const Vec4 = @This();
const Vec3 = @import("Vec3.zig");

x: f32,
y: f32,
z: f32,
w: f32,

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
