const Mat4 = @This();
const std = @import("std");
const Vec4 = @import("Vec4.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");

m: [16]f32,

pub fn identity() Mat4 {
    return Mat4{
        .m = [_]f32{
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        },
    };
}

pub fn zero() Mat4 {
    return Mat4{
        .m = [_]f32{
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0,
        },
    };
}

pub fn transpose(s: Mat4) Mat4 {
    return .{
        .m = [_]f32{
            s.m[0], s.m[4], s.m[8],  s.m[12],
            s.m[1], s.m[5], s.m[9],  s.m[13],
            s.m[2], s.m[6], s.m[10], s.m[14],
            s.m[3], s.m[7], s.m[11], s.m[15],
        },
    };
}

pub fn scale(s: Vec3) Mat4 {
    return Mat4{
        .m = [_]f32{
            s.x, 0.0, 0.0, 0.0,
            0.0, s.y, 0.0, 0.0,
            0.0, 0.0, s.z, 0.0,
            0.0, 0.0, 0.0, 1.0,
        },
    };
}

pub fn scale_uniform(s: f32) Mat4 {
    return scale(.{ .x = s, .y = s, .z = s });
}

pub fn row0(self: Mat4) Vec4 {
    return .{ .x = self.m[0], .y = self.m[1], .z = self.m[2], .w = self.m[3] };
}
pub fn row1(self: Mat4) Vec4 {
    return .{ .x = self.m[4], .y = self.m[5], .z = self.m[6], .w = self.m[7] };
}
pub fn row2(self: Mat4) Vec4 {
    return .{ .x = self.m[8], .y = self.m[9], .z = self.m[10], .w = self.m[11] };
}
pub fn row3(self: Mat4) Vec4 {
    return .{ .x = self.m[12], .y = self.m[13], .z = self.m[14], .w = self.m[15] };
}
pub fn col0(self: Mat4) Vec4 {
    return .{ .x = self.m[0], .y = self.m[4], .z = self.m[8], .w = self.m[12] };
}
pub fn col1(self: Mat4) Vec4 {
    return .{ .x = self.m[1], .y = self.m[5], .z = self.m[9], .w = self.m[13] };
}
pub fn col2(self: Mat4) Vec4 {
    return .{ .x = self.m[2], .y = self.m[6], .z = self.m[10], .w = self.m[14] };
}
pub fn col3(self: Mat4) Vec4 {
    return .{ .x = self.m[3], .y = self.m[7], .z = self.m[11], .w = self.m[15] };
}

pub fn mul(left: Mat4, right: Mat4) Mat4 {
    return Mat4{
        .m = [_]f32{
            left.row0().dot(right.col0()), left.row0().dot(right.col1()), left.row0().dot(right.col2()), left.row0().dot(right.col3()),
            left.row1().dot(right.col0()), left.row1().dot(right.col1()), left.row1().dot(right.col2()), left.row1().dot(right.col3()),
            left.row2().dot(right.col0()), left.row2().dot(right.col1()), left.row2().dot(right.col2()), left.row2().dot(right.col3()),
            left.row3().dot(right.col0()), left.row3().dot(right.col1()), left.row3().dot(right.col2()), left.row3().dot(right.col3()),
        },
    };
}

pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
    var res = Mat4.identity();
    const cot = 1 / std.math.tan(fov / 2);
    res.m[0] = cot / aspect;
    res.m[5] = cot;
    res.m[11] = -1.0;
    res.m[10] = (near + far) / (near - far);
    res.m[14] = (2.0 * near * far) / (near - far);
    res.m[15] = 0.0;
    return res;
}

pub fn lookat(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
    var res = Mat4.zero();

    const f = Vec3.norm(Vec3.sub(center, eye));
    const s = Vec3.norm(Vec3.cross(f, up));
    const u = Vec3.cross(s, f);

    res.m[0] = s.x;
    res.m[1] = u.x;
    res.m[2] = -f.x;

    res.m[4] = s.y;
    res.m[5] = u.y;
    res.m[6] = -f.y;

    res.m[8] = s.z;
    res.m[9] = u.z;
    res.m[10] = -f.z;

    res.m[12] = -Vec3.dot(s, eye);
    res.m[13] = -Vec3.dot(u, eye);
    res.m[14] = Vec3.dot(f, eye);
    res.m[15] = 1.0;

    return res;
}

pub fn rotate(degree: f32, axis_unorm: Vec3) Mat4 {
    var res = Mat4.identity();

    const axis = Vec3.norm(axis_unorm);
    const sin_theta = std.math.sin(std.math.degreesToRadians(degree));
    const cos_theta = std.math.cos(std.math.degreesToRadians(degree));
    const cos_value = 1.0 - cos_theta;

    res.m[0] = (axis.x * axis.x * cos_value) + cos_theta;
    res.m[1] = (axis.x * axis.y * cos_value) + (axis.z * sin_theta);
    res.m[2] = (axis.x * axis.z * cos_value) - (axis.y * sin_theta);
    res.m[4] = (axis.y * axis.x * cos_value) - (axis.z * sin_theta);
    res.m[5] = (axis.y * axis.y * cos_value) + cos_theta;
    res.m[6] = (axis.y * axis.z * cos_value) + (axis.x * sin_theta);
    res.m[8] = (axis.z * axis.x * cos_value) + (axis.y * sin_theta);
    res.m[9] = (axis.z * axis.y * cos_value) - (axis.x * sin_theta);
    res.m[10] = (axis.z * axis.z * cos_value) + cos_theta;

    return res;
}

pub fn translate(translation: Vec3) Mat4 {
    var res = Mat4.identity();
    res.m[12] = translation.x;
    res.m[13] = translation.y;
    res.m[14] = translation.z;
    return res;
}

fn f4(v: Vec3, w: f32) [4]f32 {
    return .{ v.x, v.y, v.z, w };
}

pub fn trs(t: Vec3, r: Quat, s: Vec3) Mat4 {
    return .{
        .m = f4(r.dirX().scale(s.x), 0) ++
            f4(r.dirY().scale(s.y), 0) ++
            f4(r.dirZ().scale(s.z), 0) ++
            [4]f32{ t.x, t.y, t.z, 1 },
    };
}

pub fn transform_coord(self: @This(), coord: Vec3) Vec3 {
    const r = self.apply(Vec4.fromVec3(coord, 1));
    return .{
        .x = r.x / r.w,
        .y = r.y / r.w,
        .z = r.z / r.w,
    };
}

pub fn transform_vector(self: @This(), vector: Vec3) Vec3 {
    return self.apply(Vec4.fromVec3(vector, 0)).toVec3();
}

pub fn apply(self: @This(), v: Vec4) Vec4 {
    return .{
        .x = v.dot(self.col0()),
        .y = v.dot(self.col1()),
        .z = v.dot(self.col2()),
        .w = v.dot(self.col3()),
    };
}

test "Mat4.ident" {
    const m = Mat4.identity();
    try std.testing.expectEqual(m.m, [_]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
}

test "Mat4.mul" {
    const l = Mat4.identity();
    const r = Mat4.identity();
    const m = Mat4.mul(l, r);
    try std.testing.expectEqual(m.m, [_]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
}

fn eq(val: f32, cmp: f32) bool {
    const delta: f32 = 1e-1;
    return (val > (cmp - delta)) and (val < (cmp + delta));
}

test "Mat4.perspective" {
    const m = Mat4.perspective(std.math.degreesToRadians(60.0), 1.33333337, 0.01, 10.0);

    try std.testing.expect(eq(m.m[0], 1.73205 / 1.333));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], 0.0));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 1.73205));
    try std.testing.expect(eq(m.m[6], 0.0));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.0));
    try std.testing.expect(eq(m.m[9], 0.0));
    try std.testing.expect(eq(m.m[10], -1.00200));
    try std.testing.expect(eq(m.m[11], -1.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], -0.02002));
    try std.testing.expect(eq(m.m[15], 0.0));
}

test "Mat4.lookat" {
    const m = Mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, Vec3.ZERO, Vec3.up());

    try std.testing.expect(eq(m.m[0], 1.0));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], 0.0));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 0.97014));
    try std.testing.expect(eq(m.m[6], 0.24253));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.0));
    try std.testing.expect(eq(m.m[9], -0.24253));
    try std.testing.expect(eq(m.m[10], 0.97014));
    try std.testing.expect(eq(m.m[11], 0.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], -6.18465));
    try std.testing.expect(eq(m.m[15], 1.0));
}

test "Mat4.rotate" {
    const m = Mat4.rotate(2.0, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    try std.testing.expect(eq(m.m[0], 0.99939));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], -0.03489));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 1.0));
    try std.testing.expect(eq(m.m[6], 0.0));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.03489));
    try std.testing.expect(eq(m.m[9], 0.0));
    try std.testing.expect(eq(m.m[10], 0.99939));
    try std.testing.expect(eq(m.m[11], 0.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], 0.0));
    try std.testing.expect(eq(m.m[15], 1.0));
}
