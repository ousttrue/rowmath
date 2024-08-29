const std = @import("std");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Vec4 = rowmath.Vec4;
const MeshBuilder = @import("MeshBuilder.zig");

const s: f32 = 0.5;
const positions = [8]Vec3{
    .{ .x = s, .y = -s, .z = -s }, //
    .{ .x = s, .y = -s, .z = s }, //
    .{ .x = s, .y = s, .z = s }, //
    .{ .x = s, .y = s, .z = -s }, //
    .{ .x = -s, .y = -s, .z = -s }, //
    .{ .x = -s, .y = -s, .z = s }, //
    .{ .x = -s, .y = s, .z = s }, //
    .{ .x = -s, .y = s, .z = -s }, //
};

//   7+-+3
//   / /|
// 6+-+2|
//  |4+-+0
//  |/ /
// 5+-+1
//
//   Y
//   A
//   +-> X
//  /
// L
//
const Face = struct {
    indices: [4]usize,
    uv: [4]Vec2,
};

// CCW
const cube_faces = [6]Face{
    // x+
    .{
        .indices = .{ 2, 1, 0, 3 },
        .uv = .{ .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 1 }, .{ .x = 2, .y = 0 } },
    },
    // y+
    .{
        .indices = .{ 2, 3, 7, 6 },
        .uv = .{ .{ .x = 1, .y = 0 }, .{ .x = 1, .y = -1 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 } },
    },
    // z+
    .{
        .indices = .{ 2, 6, 5, 1 },
        .uv = .{ .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } },
    },
    // x-
    .{
        .indices = .{ 4, 5, 6, 7 },
        .uv = .{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 } },
    },
    // y-
    .{
        .indices = .{ 4, 0, 1, 5 },
        .uv = .{ .{ .x = 0, .y = 2 }, .{ .x = 1, .y = 2 }, .{ .x = 1, .y = 1 }, .{ .x = 0, .y = 1 } },
    },
    // z-
    .{
        .indices = .{ 4, 7, 3, 0 },
        .uv = .{ .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } },
    },
};

pub fn buildCube(builder: *MeshBuilder) !void {
    for (cube_faces, 0..) |face, f| {
        try builder.Quad(
            f,
            positions[face.indices[0]],
            face.uv[0],
            positions[face.indices[1]],
            face.uv[1],
            positions[face.indices[2]],
            face.uv[2],
            positions[face.indices[3]],
            face.uv[3],
        );
    }
}
