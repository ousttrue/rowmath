const std = @import("std");
const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const RigidTransform = @import("RigidTransform.zig");
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

pub fn toLines(self: @This()) [15]Line {
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

pub const Quad = struct {
    tl: Vec3,
    bl: Vec3,
    br: Vec3,
    tr: Vec3,

    pub fn toLines(self: @This()) [4]Line {
        return [_]Line{
            Line.fromTo(self.tl, self.bl, RgbF32.white.scale(0.5)),
            Line.fromTo(self.bl, self.br, RgbF32.white.scale(0.5)),
            Line.fromTo(self.br, self.tr, RgbF32.white.scale(0.5)),
            Line.fromTo(self.tr, self.tl, RgbF32.white.scale(0.5)),
        };
    }

    pub fn crossLines(self: @This(), cursor: Vec2) [2]Line {
        const x = (cursor.x + 1) / 2;
        const t = self.tl.add(self.tr.sub(self.tl).scale(x));
        const b = self.bl.add(self.br.sub(self.bl).scale(x));

        const y = (-cursor.y + 1) / 2;
        const l = self.tl.add(self.bl.sub(self.tl).scale(y));
        const r = self.tr.add(self.br.sub(self.tr).scale(y));

        return [_]Line{
            Line.fromTo(
                l,
                r,
                RgbF32.red.scale(0.5),
            ),
            Line.fromTo(
                t,
                b,
                RgbF32.green.scale(0.5),
            ),
        };
    }
};

pub fn getPyramidBase(
    fov: f32,
    aspect: f32,
    depth: f32,
) Quad {
    const v = std.math.tan(fov / 2);
    const h = v * aspect;
    const x = Vec3.left.scale(h);
    const y = Vec3.down.scale(v);
    const z = Vec3.forward;
    return .{
        .tl = y.add(x.negate()).add(z).scale(depth),
        .bl = y.negate().add(x.negate()).add(z).scale(depth),
        .br = y.negate().add(x).add(z).scale(depth),
        .tr = y.add(x).add(z).scale(depth),
    };
}
