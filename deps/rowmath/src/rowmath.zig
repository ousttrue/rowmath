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
pub const Vec2 = @import("Vec2.zig");
pub const Vec3 = @import("Vec3.zig");
pub const Vec4 = @import("Vec4.zig");
pub const Mat4 = @import("Mat4.zig");
pub const Quat = @import("Quat.zig");
pub const RgbF32 = @import("RgbF32.zig");
pub const RgbaF32 = @import("RgbaF32.zig");
pub const RgbU8 = @import("RgbU8.zig");
pub const RgbaU8 = @import("RgbaU8.zig");

pub const RigidTransform = @import("RigidTransform.zig");
pub const Transform = @import("Transform.zig");

pub const InputState = @import("InputState.zig");
pub const Ray = @import("Ray.zig");
pub const Plane = @import("Plane.zig");
pub const Camera = @import("Camera.zig");
pub const OrbitCamera = @import("OrbitCamera.zig");
pub usingnamespace @import("drag_handler.zig");

pub const lines = @import("lines/lines.zig");
pub const Frustum = @import("Frustum.zig");

pub const bvh = @import("bvh/bvh.zig");
pub const gizmo = @import("gizmo/gizmo.zig");

pub const Gltf = @import("Gltf/Gltf.zig");
pub const GltfBuffer = @import("GltfBuffer.zig");

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
