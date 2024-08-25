const std = @import("std");
const Mat4 = @import("Mat4.zig");
const Vec3 = @import("Vec3.zig");
const Frustum = @import("Frustum.zig");

pub const PerspectiveProjection = struct {
    fov_y_radians: f32 = std.math.degreesToRadians(60.0),
    near_clip: f32 = 0.1,
    far_clip: f32 = 50.0,

    pub fn matrix(self: @This(), aspect: f32) Mat4 {
        return Mat4.perspective(
            self.fov_y_radians,
            aspect,
            self.near_clip,
            self.far_clip,
        );
    }

    pub fn frustum(self: @This(), aspect: f32) Frustum {
        const y = std.math.tan(self.fov_y_radians / 2);
        const x = y * aspect;
        const near_x = x * self.near_clip;
        const near_y = y * self.near_clip;
        const far_x = x * self.far_clip;
        const far_y = y * self.far_clip;
        return .{
            // near
            .near_top_left = Vec3{
                .x = -near_x,
                .y = near_y,
                .z = -self.near_clip,
            },
            .near_top_right = Vec3{
                .x = near_x,
                .y = near_y,
                .z = -self.near_clip,
            },
            .near_bottom_left = Vec3{
                .x = -near_x,
                .y = -near_y,
                .z = -self.near_clip,
            },
            .near_bottom_right = Vec3{
                .x = near_x,
                .y = -near_y,
                .z = -self.near_clip,
            },
            // far
            .far_top_left = Vec3{
                .x = -far_x,
                .y = far_y,
                .z = -self.far_clip,
            },
            .far_top_right = Vec3{
                .x = far_x,
                .y = far_y,
                .z = -self.far_clip,
            },
            .far_bottom_left = Vec3{
                .x = -far_x,
                .y = -far_y,
                .z = -self.far_clip,
            },
            .far_bottom_right = Vec3{
                .x = far_x,
                .y = -far_y,
                .z = -self.far_clip,
            },
        };
    }
};

pub const OrthographicProjection = struct {
    height: f32 = 10,
    near_clip: f32 = 0.1,
    far_clip: f32 = 50.0,
    pub fn matrix(self: @This(), aspect: f32) Mat4 {
        return Mat4.orthographic(
            -self.height * aspect / 2,
            self.height * aspect / 2,
            -self.height / 2,
            self.height / 2,
            self.near_clip,
            self.far_clip,
        );
    }

    pub fn frustum(self: @This(), aspect: f32) Frustum {
        const top = self.height / 2;
        const bottom = -top;
        const right = top * aspect;
        const left = -right;
        return .{
            .near_top_left = .{
                .x = left,
                .y = top,
                .z = -self.near_clip,
            },
            .near_top_right = .{
                .x = right,
                .y = top,
                .z = -self.near_clip,
            },
            .near_bottom_left = .{
                .x = left,
                .y = bottom,
                .z = -self.near_clip,
            },
            .near_bottom_right = .{
                .x = right,
                .y = bottom,
                .z = -self.near_clip,
            },
            .far_top_left = .{
                .x = left,
                .y = top,
                .z = -self.far_clip,
            },
            .far_top_right = .{
                .x = right,
                .y = top,
                .z = -self.far_clip,
            },
            .far_bottom_left = .{
                .x = left,
                .y = bottom,
                .z = -self.far_clip,
            },
            .far_bottom_right = .{
                .x = right,
                .y = bottom,
                .z = -self.far_clip,
            },
        };
    }
};

pub const CameraProjection = union(enum) {
    perspective: PerspectiveProjection,
    orthographic: OrthographicProjection,
};
