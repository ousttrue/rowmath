const std = @import("std");
const RigidTransform = @import("RigidTransform.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
pub const Transform = @This();

// rigid_transform() {}
// rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position, const minalg::float3 & scale) : orientation(orientation), position(position), scale(scale) {}
// rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position, float scale) : orientation(orientation), position(position), scale(scale) {}
// rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position) : orientation(orientation), position(position) {}

rigid_transform: RigidTransform = .{},
// position: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
// orientation: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
scale: Vec3 = .{ .x = 1, .y = 1, .z = 1 },

pub fn trs(t: Vec3, r: Quat, s: Vec3) @This() {
    return .{
        .rigid_transform = .{ .translation = t, .rotation = r },
        .scale = s,
    };
}

pub fn uniformScale(self: @This()) bool {
    return self.scale.x == self.scale.y and self.scale.x == self.scale.z;
}
pub fn matrix(self: @This()) Mat4 {
    return Mat4.trs(.{
        .t = self.rigid_transform.translation,
        .r = self.rigid_transform.rotation,
        .s = self.scale,
    });
}

// https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Matrix.cs#L1476
pub fn fromMatrix(m: Mat4) !@This() {
    const translation = Vec3{
        .x = m.m[12],
        .y = m.m[13],
        .z = m.m[14],
    };

    const xs: f32 = if (std.math.sign(m.m[0] * m.m[1] * m.m[2] * m.m[3]) < 0) -1 else 1;
    const ys: f32 = if (std.math.sign(m.m[4] * m.m[5] * m.m[6] * m.m[7]) < 0) -1 else 1;
    const zs: f32 = if (std.math.sign(m.m[8] * m.m[9] * m.m[10] * m.m[11]) < 0) -1 else 1;

    const scale = Vec3{
        .x = xs * std.math.sqrt(m.m[0] * m.m[0] + m.m[1] * m.m[1] + m.m[2] * m.m[2]),
        .y = ys * std.math.sqrt(m.m[4] * m.m[4] + m.m[5] * m.m[5] + m.m[6] * m.m[6]),
        .z = zs * std.math.sqrt(m.m[8] * m.m[8] + m.m[9] * m.m[9] + m.m[10] * m.m[10]),
    };

    if (scale.x == 0.0 or scale.y == 0.0 or scale.z == 0.0) {
        // rotation = Quaternion.Identity;
        return error.zero;
    }

    const m1 = Mat4{
        .m = .{
            m.m[0] / scale.X, m.m[1] / scale.X, m.m[3] / scale.X,  0, //
            m.m[4] / scale.Y, m.m[5] / scale.Y, m.m[6] / scale.Y,  0,
            m.m[8] / scale.Z, m.m[9] / scale.Z, m.m[10] / scale.Z, 0,
            0,                0,                0,                 1,
        },
    };

    const rotation = try m1.toQuat();

    return trs(translation, rotation, scale);
}

pub fn transformVector(self: @This(), vec: Vec3) Vec3 {
    return self.rigid_transform.rotation.rotatePoint(.{
        .x = vec.x * self.scale.x,
        .y = vec.y * self.scale.y,
        .z = vec.z * self.scale.z,
    });
}
pub fn transformPoint(self: @This(), p: Vec3) Vec3 {
    return self.rigid_transform.translation.add(self.transformVector(p));
}
pub fn detransformPoint(self: @This(), p: Vec3) Vec3 {
    return self.detransformVector(p.sub(self.rigid_transform.translation));
}
pub fn detransformVector(self: @This(), vec: Vec3) Vec3 {
    const v = self.rigid_transform.rotation.inverse().rotatePoint(vec);
    return .{
        .x = v.x / self.scale.x,
        .y = v.y / self.scale.y,
        .z = v.z / self.scale.z,
    };
}
