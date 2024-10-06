const Line = @import("Line.zig");
const MakeType = @import("MakeType.zig").MakeType;
const Vec3 = @import("../Vec3.zig");
const RgbF32 = @import("../RgbF32.zig");

pub fn Axis(comptime _n: u16) type {
    var lines: [3]Line = undefined;

    lines[0] = .{
        .start = Vec3.zero.scale(_n),
        .end = Vec3.right.scale(_n),
        .color = RgbF32.red,
    };
    lines[1] = .{
        .start = Vec3.zero.scale(_n),
        .end = Vec3.up.scale(_n),
        .color = RgbF32.green,
    };
    lines[2] = .{
        .start = Vec3.zero.scale(_n),
        .end = Vec3.forward.scale(_n),
        .color = RgbF32.blue,
    };

    return MakeType(lines);
}
