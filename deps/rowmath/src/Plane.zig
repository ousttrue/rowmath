const Vec3 = @import("Vec3.zig");
const Ray = @import("Ray.zig");
pub const Plane = @This();

normal: Vec3,
d: f32,

pub fn fromNormalAndPoint(
    normal: Vec3,
    point: Vec3,
) @This() {
    return .{
        .normal = normal,
        .d = -normal.dot(point),
    };
}

pub fn intersect(self: @This(), ray: Ray) ?f32 {
    if (self.normal.dot(ray.direction) == 0) {
        return null;
    }
    const nv = self.normal.dot(ray.direction);
    const nq_d = self.normal.dot(ray.origin) + self.d;
    return -nq_d / nv;
}
