const Rgba = @This();

r: f32,
g: f32,
b: f32,
a: f32,

pub const RED: Rgba = .{ .r = 1, .g = 0, .b = 0, .a = 1.0 };
pub const GREEN: Rgba = .{ .r = 0, .g = 1, .b = 0, .a = 1.0 };
pub const BLUE: Rgba = .{ .r = 0, .g = 0, .b = 1, .a = 1.0 };
pub const CYAN: Rgba = .{ .r = 0, .g = 0.5, .b = 0.5, .a = 1.0 };
pub const MAGENTA: Rgba = .{ .r = 0.5, .g = 0, .b = 0.5, .a = 1.0 };
pub const YELLOW: Rgba = .{ .r = 0.3, .g = 0.3, .b = 0, .a = 1.0 };
pub const GRAY: Rgba = .{ .r = 0.7, .g = 0.7, .b = 0.7, .a = 1.0 };
