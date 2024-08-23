const Transform = @This();
const RigidTransform = @import("RigidTransform.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");

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
    return Mat4.trs(
        self.rigid_transform.translation,
        self.rigid_transform.rotation,
        self.scale,
    );
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
