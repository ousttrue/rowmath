pub const RgbaF32 = @This();

r: f32,
g: f32,
b: f32,
a: f32,

pub const red: RgbaF32 = .{ .r = 1, .g = 0, .b = 0, .a = 1.0 };
pub const green: RgbaF32 = .{ .r = 0, .g = 1, .b = 0, .a = 1.0 };
pub const blue: RgbaF32 = .{ .r = 0, .g = 0, .b = 1, .a = 1.0 };
pub const cyan: RgbaF32 = .{ .r = 0, .g = 0.5, .b = 0.5, .a = 1.0 };
pub const magenta: RgbaF32 = .{ .r = 0.5, .g = 0, .b = 0.5, .a = 1.0 };
pub const yellow: RgbaF32 = .{ .r = 0.3, .g = 0.3, .b = 0, .a = 1.0 };
pub const gray: RgbaF32 = .{ .r = 0.7, .g = 0.7, .b = 0.7, .a = 1.0 };
