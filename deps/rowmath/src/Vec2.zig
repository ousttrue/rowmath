const std = @import("std");
pub const Vec2 = @This();

x: f32,
y: f32,

pub const zero = Vec2{ .x = 0, .y = 0 };

pub fn dot(lhs: @This(), rhs: @This()) f32 {
    return lhs.x * rhs.x + lhs.y * rhs.y;
}

pub fn sqNorm(self: @This()) f32 {
    return self.dot(self);
}

pub fn norm(self: @This()) f32 {
    return std.math.sqrt(self.sqNorm());
}

pub fn sub(lhs: @This(), rhs: @This()) @This() {
    return .{
        .x = lhs.x - rhs.x,
        .y = lhs.y - rhs.y,
    };
}

pub fn scale(v: Vec2, s: f32) Vec2 {
    return .{
        .x = v.x * s,
        .y = v.y * s,
    };
}

test "Vec2" {
    try std.testing.expectEqual(8, @sizeOf(Vec2));

    const a = Vec2{ .x = 2, .y = 2 };
    const b = Vec2{ .x = 1, .y = 2 };
    const c = Vec2{ .x = 0, .y = 2 };
    try std.testing.expectEqual(a.sub(b), Vec2{ .x = 1, .y = 0 });
    try std.testing.expectEqual(2, c.norm());
    try std.testing.expectEqual(4, c.sqNorm());
}
