const Ray = @This();
const Vec3 = @import("Vec3.zig");

origin: Vec3,
direction: Vec3,

pub fn point(self: @This(), t: f32) Vec3 {
    return self.origin.add(self.direction.scale(t));
}

pub fn scale(self: *@This(), f: f32) void {
    self.origin = self.origin.scale(f);
    self.direction = self.direction.scale(f);
}

pub fn descale(self: @This(), f: f32) Ray {
    return .{
        .origin = .{
            .x = self.origin.x / f,
            .y = self.origin.y / f,
            .z = self.origin.z / f,
        },
        .direction = .{
            .x = self.direction.x / f,
            .y = self.direction.y / f,
            .z = self.direction.z / f,
        },
    };
}
