const Quat = @This();
const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");

fn f4(v: Vec3, w: f32) [4]f32 {
    return .{ v.x, v.y, v.z, w };
}

x: f32,
y: f32,
z: f32,
w: f32,

pub const identity: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 };

pub fn axisAngle(axis: Vec3, angle: f32) Quat {
    const s = std.math.sin(angle / 2);
    return .{
        .x = axis.x * s,
        .y = axis.y * s,
        .z = axis.z * s,
        .w = std.math.cos(angle / 2),
    };
}

pub fn conjugate(q: @This()) @This() {
    return .{
        .x = -q.x,
        .y = -q.y,
        .z = -q.z,
        .w = q.w,
    };
}

pub fn sqNorm(q: @This()) f32 {
    return q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
}

pub fn inverse(q: @This()) @This() {
    const sqlen = q.length2();
    const c = q.conj();
    return .{
        .x = c.x / sqlen,
        .y = c.y / sqlen,
        .z = c.z / sqlen,
        .w = c.w / sqlen,
    };
}

pub fn mul(a: @This(), b: @This()) @This() {
    return .{
        .x = a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
        .y = a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
        .z = a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
        .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    };
}

pub fn dirX(q: @This()) Vec3 {
    return .{
        .x = q.w * q.w + q.x * q.x - q.y * q.y - q.z * q.z,
        .y = (q.x * q.y + q.z * q.w) * 2,
        .z = (q.z * q.x - q.y * q.w) * 2,
    };
}

pub fn dirY(q: @This()) Vec3 {
    return .{
        .x = (q.x * q.y - q.z * q.w) * 2,
        .y = q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z,
        .z = (q.y * q.z + q.x * q.w) * 2,
    };
}

pub fn dirZ(q: @This()) Vec3 {
    return .{
        .x = (q.z * q.x + q.y * q.w) * 2,
        .y = (q.y * q.z - q.x * q.w) * 2,
        .z = q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z,
    };
}

pub fn matrix(q: @This()) Mat4 {
    return .{
        .m = f4(q.dirX(), 0) ++
            f4(q.dirY(), 0) ++
            f4(q.dirZ(), 0) ++
            [4]f32{ 0, 0, 0, 1 },
    };
}

pub fn rotatePoint(q: @This(), v: Vec3) Vec3 {
    return (q.dirX().scale(v.x)).add(q.dirY().scale(v.y)).add(q.dirZ().scale(v.z));
}
