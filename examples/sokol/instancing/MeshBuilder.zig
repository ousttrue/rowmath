const std = @import("std");
const Mesh = @import("Mesh.zig");
const Vertex = Mesh.Vertex;
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Vec4 = rowmath.Vec4;

pub const MeshBuilder = @This();
mesh: Mesh,
ccw: bool,

pub fn init(allocator: std.mem.Allocator, ccw: bool) @This() {
    return .{
        .mesh = Mesh.init(allocator),
        .ccw = ccw,
    };
}

pub fn deinit(self: *@This()) void {
    self.mesh.deinit();
}

pub fn Quad(
    self: *@This(),
    face: usize,
    p0: Vec3,
    uv0: Vec2,
    p1: Vec3,
    uv1: Vec2,
    p2: Vec3,
    uv2: Vec2,
    p3: Vec3,
    uv3: Vec2,
) !void {
    // 01   00
    //  3+-+2
    //   | |
    //  0+-+1
    // 00   10
    const v0 = Vertex{
        .position_face = .{ .x = p0.x, .y = p0.y, .z = p0.z, .w = @floatFromInt(face) },
        .uv_barycentric = .{ .x = uv0.x, .y = uv0.y, .z = 1, .w = 0 },
    };
    const v1 = Vertex{
        .position_face = .{ .x = p1.x, .y = p1.y, .z = p1.z, .w = @floatFromInt(face) },
        .uv_barycentric = .{ .x = uv1.x, .y = uv1.y, .z = 0, .w = 0 },
    };
    const v2 = Vertex{
        .position_face = .{ .x = p2.x, .y = p2.y, .z = p2.z, .w = @floatFromInt(face) },
        .uv_barycentric = .{ .x = uv2.x, .y = uv2.y, .z = 0, .w = 1 },
    };
    const v3 = Vertex{
        .position_face = .{ .x = p3.x, .y = p3.y, .z = p3.z, .w = @floatFromInt(face) },
        .uv_barycentric = .{ .x = uv3.x, .y = uv3.y, .z = 0, .w = 0 },
    };
    const index: u16 = @intCast(self.mesh.vertices.items.len);
    try self.mesh.vertices.append(v0);
    try self.mesh.vertices.append(v1);
    try self.mesh.vertices.append(v2);
    try self.mesh.vertices.append(v3);
    if (self.ccw) {
        // 0, 1, 2
        try self.mesh.indices.append(index);
        try self.mesh.indices.append(index + 1);
        try self.mesh.indices.append(index + 2);
        // 2, 3, 0
        try self.mesh.indices.append(index + 2);
        try self.mesh.indices.append(index + 3);
        try self.mesh.indices.append(index);
    } else {
        // 0, 3, 2
        try self.mesh.indices.append(index);
        try self.mesh.indices.append(index + 3);
        try self.mesh.indices.append(index + 2);
        // 2, 1, 0
        try self.mesh.indices.append(index + 2);
        try self.mesh.indices.append(index + 1);
        try self.mesh.indices.append(index);
    }
}
