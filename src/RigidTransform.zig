const RigidTransform = @This();
const Quat = @import("Quat.zig");
const Vec3 = @import("Vec3.zig");
const Mat4 = @import("Mat4.zig");

rotation: Quat = Quat.identity,
translation: Vec3 = Vec3.zero,

pub fn localToWorld(self: @This()) Mat4 {
    const r = self.rotation.matrix();
    const t = Mat4.translate(self.translation);
    return r.mul(t);
}

pub fn worldToLocal(self: @This()) Mat4 {
    const t = Mat4.translate(self.translation.negate());
    const r = self.rotation.conj().matrix();
    return t.mul(r);
}
