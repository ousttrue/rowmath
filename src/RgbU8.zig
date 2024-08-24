pub const RgbU8 = @This();
r: u8,
g: u8,
b: u8,

pub const red = RgbU8{ .r = 0xf4, .g = 0x43, .b = 0x36 };
pub const blue = RgbU8{ .r = 0x21, .g = 0x96, .b = 0xf3 };
pub const green = RgbU8{ .r = 0x4c, .g = 0xaf, .b = 0x50 };
pub const yellow = RgbU8{ .r = 0xff, .g = 0xeb, .b = 0x3b };
