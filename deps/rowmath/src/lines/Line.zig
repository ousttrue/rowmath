const RgbF32 = @import("../RgbF32.zig");
const Vec3 = @import("../Vec3.zig");

start: Vec3,
end: Vec3,
color: RgbF32 = RgbF32.white,

pub fn fromTo(from: Vec3, to: Vec3, color: RgbF32) @This() {
    return .{
        .start = from,
        .end = to,
        .color = color,
    };
}
