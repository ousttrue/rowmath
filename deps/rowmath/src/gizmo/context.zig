const std = @import("std");
// const rowmath = @import("rowmath");
const Vec2 = @import("../Vec2.zig");
const Vec3 = @import("../Vec3.zig");
const Rgba = @import("../RgbaF32.zig");
const Mat4 = @import("../Mat4.zig");
const Transform = @import("../Transform.zig");
const Ray = @import("../Ray.zig");
const geometry = @import("geometry.zig");

pub const ARROW_POINTS = [_]Vec2{
    .{ .x = 0.25, .y = 0 },
    .{ .x = 0.25, .y = 0.05 },
    .{ .x = 1, .y = 0.05 },
    .{ .x = 1, .y = 0.10 },
    .{ .x = 1.2, .y = 0 },
};
pub const MACE_POINTS = [_]Vec2{
    .{ .x = 0.25, .y = 0 },
    .{ .x = 0.25, .y = 0.05 },
    .{ .x = 1, .y = 0.05 },
    .{ .x = 1, .y = 0.1 },
    .{ .x = 1.25, .y = 0.1 },
    .{ .x = 1.25, .y = 0 },
};
pub const RING_POINTS = [_]Vec2{
    .{ .x = 0.025, .y = 1 },
    .{ .x = -0.025, .y = 1 },
    .{ .x = -0.025, .y = 1 },
    .{ .x = -0.025, .y = 1.1 },
    .{ .x = -0.025, .y = 1.1 },
    .{ .x = 0.025, .y = 1.1 },
    .{ .x = 0.025, .y = 1.1 },
    .{ .x = 0.025, .y = 1 },
};

fn detransform(p: Transform, r: Ray) Ray {
    return .{
        .origin = p.detransformPoint(r.origin),
        .direction = p.detransformVector(r.direction),
    };
}

// 32 bit Fowler–Noll–Vo Hash
const fnv1aBase32: u32 = 0x811C9DC5;
const fnv1aPrime32: u32 = 0x01000193;
fn hash_fnv1a(str: []const u8) u32 {
    var result = fnv1aBase32;
    for (str) |ch| {
        result ^= @as(u32, ch);
        result *%= fnv1aPrime32;
    }
    return result;
}

pub const ApplicationState = struct {
    // 3d viewport used to render the view
    viewport_size: Vec2,
    // Used for constructing inverse view projection for raycasting onto gizmo geometry
    cam_dir: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
    cam_yFov: f32 = 0,
    // world-space ray (from camera position to mouse cursor)
    ray: Ray = .{
        .origin = .{ .x = 0, .y = 0, .z = 0 },
        .direction = .{ .x = 0, .y = 0, .z = 0 },
    },
    // mouse
    mouse_left: bool = false,
    // If > 0.f, the gizmos are drawn scale-invariant with a screenspace value defined here
    screenspace_scale: f32 = 0,
    // World-scale units used for snapping translation
    snap_translation: f32 = 0,
    // World-scale units used for snapping scale
    snap_scale: f32 = 0,
    // Radians used for snapping rotation quaternions (i.e. PI/8 or PI/16)
    snap_rotation: f32 = 0,

    fn scale_screenspace(self: @This(), position: Vec3, pixel_scale: f32) f32 {
        const dist = position.sub(self.ray.origin).norm();
        return std.math.tan(self.cam_yFov) * dist * (pixel_scale / self.viewport_size.y);
    }

    fn draw_scale(self: @This(), p: Transform) f32 {
        if (self.screenspace_scale > 0.0) {
            return self.scale_screenspace(
                p.rigid_transform.translation,
                self.screenspace_scale,
            );
        } else {
            return 1.0;
        }
    }

    pub fn local_ray(self: @This(), p: Transform) struct { Ray, f32 } {
        return .{
            detransform(p, self.ray),
            self.draw_scale(p),
        };
    }
};

pub const Context = struct {
    active_state: ApplicationState = .{ .viewport_size = .{ .x = 0, .y = 0 } },
    last_state: ApplicationState = .{ .viewport_size = .{ .x = 0, .y = 0 } },
    // State to describe if the user has pressed the left mouse button during the last frame
    has_clicked: bool = false,
    // State to describe if the user has released the left mouse button during the last frame
    has_released: bool = false,

    pub fn update(self: *@This(), state: ApplicationState) void {
        self.last_state = self.active_state;
        self.active_state = state;
        // self.local_toggle = if (!self.last_state.hotkey_local and self.active_state.hotkey_local and self.active_state.hotkey_ctrl) !self.local_toggle else self.local_toggle;
        self.has_clicked = !self.last_state.mouse_left and self.active_state.mouse_left;
        self.has_released = self.last_state.mouse_left and !self.active_state.mouse_left;
    }
};

pub const Renderable = struct {
    mesh: geometry.GeometryMesh,
    base_color: Rgba,
    matrix: Mat4,
    hover: bool,
    active: bool,

    pub fn color(self: @This()) Rgba {
        if (self.hover) {
            return .{
                .r = std.math.lerp(self.base_color.r, 1, 0.5),
                .g = std.math.lerp(self.base_color.g, 1, 0.5),
                .b = std.math.lerp(self.base_color.b, 1, 0.5),
                .a = std.math.lerp(self.base_color.a, 1, 0.5),
            };
        } else {
            return self.base_color;
        }
    }
};


