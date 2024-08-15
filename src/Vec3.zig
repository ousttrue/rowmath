const Vec3 = @This();
const std = @import("std");

x: f32,
y: f32,
z: f32,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("{{{d:.2},{d:.2},{d:.2}}}", .{
        self.x,
        self.y,
        self.z,
    });
}

pub const ONE = Vec3{ .x = 1, .y = 1, .z = 1 };
pub const ZERO = Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };
pub const RIGHT: Vec3 = .{ .x = 1, .y = 0, .z = 0 };
pub const UP: Vec3 = .{ .x = 0, .y = 1, .z = 0 };
pub const FORWARD: Vec3 = .{ .x = 0, .y = 0, .z = 1 };

pub fn scalar(f: f32) Vec3 {
    return .{
        .x = f,
        .y = f,
        .z = f,
    };
}

pub fn new(x: f32, y: f32, z: f32) Vec3 {
    return Vec3{ .x = x, .y = y, .z = z };
}

pub fn up() Vec3 {
    return Vec3{ .x = 0.0, .y = 1.0, .z = 0.0 };
}

pub fn negate(self: @This()) @This() {
    return .{ .x = -self.x, .y = -self.y, .z = -self.z };
}

pub fn len2(v: Vec3) f32 {
    return Vec3.dot(v, v);
}

pub fn len(v: Vec3) f32 {
    return std.math.sqrt(v.len2());
}

pub fn add(left: Vec3, right: Vec3) Vec3 {
    return Vec3{ .x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z };
}

pub fn sub(left: Vec3, right: Vec3) Vec3 {
    return Vec3{ .x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z };
}

pub fn scale(v: Vec3, s: f32) Vec3 {
    return Vec3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

pub fn norm(v: Vec3) Vec3 {
    const l = Vec3.len(v);
    if (l != 0.0) {
        return Vec3{ .x = v.x / l, .y = v.y / l, .z = v.z / l };
    } else {
        return Vec3.ZERO;
    }
}

pub fn mul_each(v0: Vec3, v1: Vec3) Vec3 {
    return Vec3{
        .x = v0.x * v1.x,
        .y = v0.y * v1.y,
        .z = v0.z * v1.z,
    };
}

pub fn cross(v0: Vec3, v1: Vec3) Vec3 {
    return Vec3{ .x = (v0.y * v1.z) - (v0.z * v1.y), .y = (v0.z * v1.x) - (v0.x * v1.z), .z = (v0.x * v1.y) - (v0.y * v1.x) };
}

pub fn dot(v0: Vec3, v1: Vec3) f32 {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
}

test "Vec3.zero" {
    const v = Vec3.ZERO;
    try std.testing.expect(v.x == 0.0 and v.y == 0.0 and v.z == 0.0);
}

test "Vec3.new" {
    const v = Vec3.new(1.0, 2.0, 3.0);
    try std.testing.expect(v.x == 1.0 and v.y == 2.0 and v.z == 3.0);
}
