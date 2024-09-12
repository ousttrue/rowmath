const std = @import("std");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Vec4 = rowmath.Vec4;

pub const Vertex = struct {
    position_face: Vec4,
    uv_barycentric: Vec4,
};

pub const Mesh = @This();
vertices: std.ArrayList(Vertex),
indices: std.ArrayList(u16),

pub fn init(allocator: std.mem.Allocator) @This() {
    return .{
        .vertices = std.ArrayList(Vertex).init(allocator),
        .indices = std.ArrayList(u16).init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    self.vertices.deinit();
    self.indices.deinit();
}
