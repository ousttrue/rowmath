const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Line = @import("lines/Line.zig");
const RgbF32 = @import("RgbF32.zig");

pub const Frustum = @This();
near_top_left: Vec3,
near_top_right: Vec3,
near_bottom_left: Vec3,
near_bottom_right: Vec3,
far_top_left: Vec3,
far_top_right: Vec3,
far_bottom_left: Vec3,
far_bottom_right: Vec3,

pub const line_num = 15;

pub fn toLines(self: @This()) [line_num]Line {
    return [_]Line{
        Line.fromTo(self.far_top_left, self.far_top_right, RgbF32.white),
        Line.fromTo(self.far_top_right, self.far_bottom_right, RgbF32.white),
        Line.fromTo(self.far_bottom_right, self.far_bottom_left, RgbF32.white),
        Line.fromTo(self.far_bottom_left, self.far_top_left, RgbF32.white),

        Line.fromTo(self.near_top_left, self.near_top_right, RgbF32.white),
        Line.fromTo(self.near_top_right, self.near_bottom_right, RgbF32.white),
        Line.fromTo(self.near_bottom_right, self.near_bottom_left, RgbF32.white),
        Line.fromTo(self.near_bottom_left, self.near_top_left, RgbF32.white),

        Line.fromTo(self.near_top_left, self.far_top_left, RgbF32.white),
        Line.fromTo(self.near_top_right, self.far_top_right, RgbF32.white),
        Line.fromTo(self.near_bottom_left, self.far_bottom_left, RgbF32.white),
        Line.fromTo(self.near_bottom_right, self.far_bottom_right, RgbF32.white),

        // xyz
        Line.fromTo(
            self.far_top_left.add(self.far_bottom_left).scale(0.5),
            self.far_top_right.add(self.far_bottom_right).scale(0.5),
            RgbF32.red,
        ),
        Line.fromTo(
            self.far_top_left.add(self.far_top_right).scale(0.5),
            self.far_bottom_left.add(self.far_bottom_right).scale(0.5),
            RgbF32.green,
        ),
        Line.fromTo(
            Vec3.zero,
            self.far_top_left.add(
                self.far_top_right,
            ).add(
                self.far_bottom_right,
            ).add(
                self.far_bottom_left,
            ).scale(0.25),
            RgbF32.blue,
        ),
    };
}
