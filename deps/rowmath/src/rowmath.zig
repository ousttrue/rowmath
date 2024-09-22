//------------------------------------------------------------------------------
// row-major linear math
//
// * memory layout
// mat4: [00,01,02,03,10,11,12,13,20,21,22,23,30,31,32,33]
//
// * mul order
// [vec4][model][view][projection]
//
// * trs
// [vec4][s][r][t]
//------------------------------------------------------------------------------
pub usingnamespace @import("Vec2.zig");
pub usingnamespace @import("Vec3.zig");
pub usingnamespace @import("Vec4.zig");
pub usingnamespace @import("Mat4.zig");
pub usingnamespace @import("Quat.zig");
pub usingnamespace @import("RgbF32.zig");
pub usingnamespace @import("RgbaF32.zig");
pub usingnamespace @import("RgbU8.zig");
pub usingnamespace @import("RgbaU8.zig");
pub usingnamespace @import("RigidTransform.zig");
pub usingnamespace @import("Transform.zig");
pub usingnamespace @import("InputState.zig");
pub usingnamespace @import("Ray.zig");
pub usingnamespace @import("Plane.zig");
pub usingnamespace @import("Camera.zig");
pub usingnamespace @import("OrbitCamera.zig");
pub usingnamespace @import("drag_handler.zig");

pub const lines = @import("lines/lines.zig");
pub usingnamespace @import("Frustum.zig");

pub const bvh = @import("bvh/bvh.zig");
pub const gizmo = @import("gizmo/gizmo.zig");

test {
    // const std = @import("std");
    // std.testing.refAllDecls(@This());
    _ = @import("Vec2.zig");
    _ = @import("Vec3.zig");
    _ = @import("Vec4.zig");
    _ = @import("Quat.zig");
    _ = @import("RgbaF32.zig");
    _ = @import("Mat4.zig");
    _ = @import("RigidTransform.zig");
    _ = @import("Transform.zig");
    _ = @import("InputState.zig");
    _ = @import("Ray.zig");
    _ = @import("Camera.zig");
    _ = @import("bvh/BvhTokenizer.zig");
    _ = @import("bvh/BvhFormat.zig");
}
