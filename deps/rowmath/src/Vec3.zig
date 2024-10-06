const std = @import("std");
pub const Vec3 = @This();

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

pub const one = Vec3{ .x = 1, .y = 1, .z = 1 };
pub const zero = Vec3{ .x = 0, .y = 0, .z = 0 };
pub const right: Vec3 = .{ .x = 1, .y = 0, .z = 0 };
pub const up: Vec3 = .{ .x = 0, .y = 1, .z = 0 };
pub const forward: Vec3 = .{ .x = 0, .y = 0, .z = 1 };

pub const left: Vec3 = .{ .x = -1, .y = 0, .z = 0 };
pub const down: Vec3 = .{ .x = 0, .y = -1, .z = 0 };
pub const backward: Vec3 = .{ .x = 0, .y = 0, .z = -1 };

pub fn fromScalar(f: f32) Vec3 {
    return .{
        .x = f,
        .y = f,
        .z = f,
    };
}

pub fn new(x: f32, y: f32, z: f32) Vec3 {
    return Vec3{ .x = x, .y = y, .z = z };
}

pub fn negate(self: @This()) @This() {
    return .{ .x = -self.x, .y = -self.y, .z = -self.z };
}

pub fn sqNorm(v: Vec3) f32 {
    return Vec3.dot(v, v);
}

pub fn norm(v: Vec3) f32 {
    return std.math.sqrt(v.sqNorm());
}

pub fn add(lhs: Vec3, rhs: Vec3) Vec3 {
    return Vec3{ .x = lhs.x + rhs.x, .y = lhs.y + rhs.y, .z = lhs.z + rhs.z };
}

pub fn sub(lhs: Vec3, rhs: Vec3) Vec3 {
    return Vec3{ .x = lhs.x - rhs.x, .y = lhs.y - rhs.y, .z = lhs.z - rhs.z };
}

pub fn scale(v: Vec3, s: f32) Vec3 {
    return Vec3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
}

pub fn normalize(v: Vec3) Vec3 {
    const l = Vec3.norm(v);
    if (l != 0.0) {
        return Vec3{ .x = v.x / l, .y = v.y / l, .z = v.z / l };
    } else {
        return Vec3.zero;
    }
}

// pub fn mul_each(v0: Vec3, v1: Vec3) Vec3 {
//     return Vec3{
//         .x = v0.x * v1.x,
//         .y = v0.y * v1.y,
//         .z = v0.z * v1.z,
//     };
// }

pub fn cross(v0: Vec3, v1: Vec3) Vec3 {
    return Vec3{ .x = (v0.y * v1.z) - (v0.z * v1.y), .y = (v0.z * v1.x) - (v0.x * v1.z), .z = (v0.x * v1.y) - (v0.y * v1.x) };
}

pub fn dot(v0: Vec3, v1: Vec3) f32 {
    return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
}

test "Vec3.zero" {
    const v = Vec3.zero;
    try std.testing.expect(v.x == 0.0 and v.y == 0.0 and v.z == 0.0);
}

test "Vec3.new" {
    const v = Vec3.new(1.0, 2.0, 3.0);
    try std.testing.expect(v.x == 1.0 and v.y == 2.0 and v.z == 3.0);
}
