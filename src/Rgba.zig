const Rgba = @This();

r: f32,
g: f32,
b: f32,
a: f32,

pub const red: Rgba = .{ .r = 1, .g = 0, .b = 0, .a = 1.0 };
pub const green: Rgba = .{ .r = 0, .g = 1, .b = 0, .a = 1.0 };
pub const blue: Rgba = .{ .r = 0, .g = 0, .b = 1, .a = 1.0 };
pub const cyan: Rgba = .{ .r = 0, .g = 0.5, .b = 0.5, .a = 1.0 };
pub const magenta: Rgba = .{ .r = 0.5, .g = 0, .b = 0.5, .a = 1.0 };
pub const yellow: Rgba = .{ .r = 0.3, .g = 0.3, .b = 0, .a = 1.0 };
pub const gray: Rgba = .{ .r = 0.7, .g = 0.7, .b = 0.7, .a = 1.0 };
