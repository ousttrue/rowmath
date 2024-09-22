const Quat = @import("Quat.zig");
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");
const Ray = @import("Ray.zig");
pub const RigidTransform = @This();

rotation: Quat = Quat.identity,
translation: Vec3 = Vec3.zero,

pub fn localToWorld(self: @This()) Mat4 {
    const r = self.rotation.matrix();
    const t = Mat4.translate(self.translation);
    return r.mul(t);
}

pub fn worldToLocal(self: @This()) Mat4 {
    const t = Mat4.translate(self.translation.negate());
    const r = self.rotation.conjugate().matrix();
    return t.mul(r);
}

pub fn transformVector(self: @This(), vec: Vec3) Vec3 {
    return self.rotation.rotatePoint(.{
        .x = vec.x,
        .y = vec.y,
        .z = vec.z,
    });
}

pub fn transformPoint(self: @This(), p: Vec3) Vec3 {
    return self.translation.add(self.transformVector(p));
}

pub fn transformRay(self: @This(), ray: Ray) Ray {
    return .{
        .origin = self.transformPoint(ray.origin),
        .direction = self.transformVector(ray.direction),
    };
    // // world
    // const dir_cursor = self.transform.rotation.rotatePoint(dir.normalize());
    // return .{
    //     .origin = self.transform.translation,
    //     .direction = dir_cursor,
    // };
    // world
    // const dir_cursor = self.transform.rotation.rotatePoint(dir);
    // const origin_offset = self.transform.rotation.rotatePoint(Vec3{
    //     .x = x,
    //     .y = y,
    //     .z = 0,
    // });
    // return .{
    //     .origin = self.transform.translation.add(origin_offset),
    //     .direction = dir_cursor,
    // };
    // switch (self.projection.projection_type) {
    //     .perspective =>  {
    //         // local
    //         const y = std.math.tan(self.projection.fov_y_radians / 2);
    //         const x = y * self.projection.getAspect();
    //         const dir = Vec3{
    //             .x = x * mouse_cursor.x,
    //             .y = y * mouse_cursor.y,
    //             .z = -1,
    //         };
    //         // world
    //         const dir_cursor = self.transform.rotation.rotatePoint(dir.normalize());
    //         return .{
    //             .origin = self.transform.translation,
    //             .direction = dir_cursor,
    //         };
    //     },
    //     .orthographic => |orthographic| {
    //         const dir = Vec3{
    //             .x = 0,
    //             .y = 0,
    //             .z = -1,
    //         };
    //         const y = (orthographic.height / 2) * mouse_cursor.y;
    //         const x = (orthographic.height / 2) * self.getAspect() * mouse_cursor.x;
    //         // world
    //         const dir_cursor = self.transform.rotation.rotatePoint(dir);
    //         const origin_offset = self.transform.rotation.rotatePoint(Vec3{
    //             .x = x,
    //             .y = y,
    //             .z = 0,
    //         });
    //         return .{
    //             .origin = self.transform.translation.add(origin_offset),
    //             .direction = dir_cursor,
    // };
    // },
    // }

}
