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
pub const Rgba = @import("Rgba.zig");

pub const RigidTransform = @import("RigidTransform.zig");
pub const Transform = @import("Transform.zig");

pub const InputState = @import("InputState.zig");
pub const Ray = @import("Ray.zig");
pub const Camera = @import("Camera.zig");
pub const DragHandle = @import("DragHandle.zig");
