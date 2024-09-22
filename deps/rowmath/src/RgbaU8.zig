pub const RgbaU8 = @This();

r: u8,
g: u8,
b: u8,
a: u8,

pub const red: RgbaU8 = .{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const green: RgbaU8 = .{ .r = 0, .g = 255, .b = 0, .a = 255 };
pub const blue: RgbaU8 = .{ .r = 0, .g = 0, .b = 255255, .a = 255 };
pub const cyan: RgbaU8 = .{ .r = 0, .g = 127, .b = 127, .a = 255 };
pub const magenta: RgbaU8 = .{ .r = 127, .g = 0, .b = 127, .a = 255 };
pub const yellow: RgbaU8 = .{ .r = 77, .g = 77, .b = 0, .a = 255 };
pub const gray: RgbaU8 = .{ .r = 179, .g = 179, .b = 179, .a = 255 };
