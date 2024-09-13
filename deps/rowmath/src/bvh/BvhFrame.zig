const std = @import("std");
const BvhChannels = @import("BvhChannels.zig");
const Mat4 = @import("../Mat4.zig");
const Vec3 = @import("../Vec3.zig");
const Quat = @import("../Quat.zig");

values: []f32,

pub fn init(values: []f32) @This() {
    return .{ .values = values };
}

pub const Transform = struct { translation: Vec3, rotation: Quat };

fn toRadians(degrees: f32) f32 {
    return degrees / 180.0 * std.math.pi;
}

// Transform
pub fn resolve(self: @This(), channels: BvhChannels) Transform {
    var t = Transform{
        .rotation = Quat.identity,
        .translation = channels.init,
    };
    var index = channels.startIndex;
    for (0..channels.types.len) |ch| {
        switch (channels.types[ch]) {
            .Xposition => {
                t.translation.x = self.values[index];
            },
            .Yposition => {
                t.translation.y = self.values[index];
            },
            .Zposition => {
                t.translation.z = self.values[index];
            },
            .Xrotation => {
                const r = Quat.axisAngle(Vec3.right, toRadians(self.values[index]));
                t.rotation = r.mul(t.rotation);
            },
            .Yrotation => {
                const r = Quat.axisAngle(Vec3.up, toRadians(self.values[index]));
                t.rotation = r.mul(t.rotation);
            },
            .Zrotation => {
                const r = Quat.axisAngle(Vec3.forward, toRadians(self.values[index]));
                t.rotation = r.mul(t.rotation);
            },
            .None => {},
        }
        index += 1;
    }
    return t;
}
