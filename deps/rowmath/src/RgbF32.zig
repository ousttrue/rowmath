pub const RgbF32 = @This();

r: f32,
g: f32,
b: f32,

pub const white = RgbF32{ .r = 1, .g = 1, .b = 1 };
pub const gray = RgbF32{ .r = 0.5, .g = 0.5, .b = 0.5 };
pub const red: RgbF32 = .{ .r = 1, .g = 0, .b = 0 };
pub const green: RgbF32 = .{ .r = 0, .g = 1, .b = 0 };
pub const blue: RgbF32 = .{ .r = 0, .g = 0, .b = 1 };

pub fn scale(self: @This(), f: f32) @This() {
    return .{
        .r = self.r * f,
        .g = self.g * f,
        .b = self.b * f,
    };
}
