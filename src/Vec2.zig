const Vec2 = @This();
const std = @import("std");

x: f32,
y: f32,

test "Vec2" {
    try std.testing.expectEqual(8, @sizeOf(Vec2));
}

// pub fn zero() Vec2 {
//     return Vec2{ .x = 0.0, .y = 0.0 };
// }
//
// pub fn new(x: f32, y: f32) Vec2 {
//     return Vec2{ .x = x, .y = y };
// }
