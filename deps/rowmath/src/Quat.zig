const std = @import("std");
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");
pub const Quat = @This();

x: f32,
y: f32,
z: f32,
w: f32,

pub const identity: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 };

pub fn fromAxisAngle(axis: Vec3, angle: f32) Quat {
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
    const sqlen = q.sqNorm();
    const c = q.conjugate();
    return .{
        .x = c.x / sqlen,
        .y = c.y / sqlen,
        .z = c.z / sqlen,
        .w = c.w / sqlen,
    };
}

pub fn mul(a: @This(), b: @This()) @This() {
    // return .{
    //     .x = a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
    //     .y = a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
    //     .z = a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
    //     .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    // };
    return .{
        .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        .x = a.w * b.x + a.x * b.w + a.z * b.y - a.y * b.z,
        .y = a.w * b.y + a.y * b.w + a.x * b.z - a.z * b.x,
        .z = a.w * b.z + a.z * b.w + a.y * b.x - a.x * b.y,
    };
}

pub fn dot(a: @This(), b: @This()) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
}

pub fn slerp(a: @This(), _b: @This(), t: f32) @This() {
    var cos_omega = a.dot(_b);
    const b = if (cos_omega < 0) blk: {
        cos_omega = -cos_omega;
        break :blk Quat{
            .x = -_b.x,
            .y = -_b.y,
            .z = -_b.z,
            .w = -_b.w,
        };
    } else _b;

    var k0: f32 = undefined;
    var k1: f32 = undefined;
    if (cos_omega > 0.9999) {
        k0 = 1 - t;
        k1 = t;
    } else {
        const sin_omega = std.math.sqrt(1 - cos_omega * cos_omega);
        const omega = std.math.atan2(sin_omega, cos_omega);
        const one_over_sin_omega = 1 / sin_omega;
        k0 = std.math.sin((1 - t) * omega) * one_over_sin_omega;
        k1 = std.math.sin(t * omega) * one_over_sin_omega;
    }

    return .{
        .x = a.x * k0 + b.x * k1,
        .y = a.y * k0 + b.y * k1,
        .z = a.z * k0 + b.z * k1,
        .w = a.w * k0 + b.w * k1,
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

fn f4(v: Vec3, w: f32) [4]f32 {
    return .{ v.x, v.y, v.z, w };
}

pub fn toMatrix(q: @This()) Mat4 {
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
