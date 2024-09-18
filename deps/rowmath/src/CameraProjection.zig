const std = @import("std");
const Mat4 = @import("Mat4.zig");
const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Frustum = @import("Frustum.zig");
const lines = @import("lines/lines.zig");
const Ray = @import("Ray.zig");

pub const CameraProjectionType = enum {
    perspective,
    orthographic,
};

screen: Vec2 = .{ .x = 1, .y = 1 },
near_clip: f32 = 0.1,
far_clip: f32 = 50.0,
fov_y_radians: f32 = std.math.degreesToRadians(60.0),
projection_type: CameraProjectionType = .perspective,
matrix: Mat4 = Mat4.identity,

/// height of far clip
///  +--+
///  | /|
///  |/ |
///  |\ |
///  | \|
///  +--+
///  -->far
/// perspective & orthographic is same.
pub fn getHeight(self: @This()) f32 {
    return std.math.tan(self.fov_y_radians / 2) * 2 * self.far_clip;
}

pub fn getAspectRatio(self: @This()) f32 {
    return self.screen.x / self.screen.y;
}

pub fn resize(self: *@This(), size: Vec2) void {
    if (std.meta.eql(self.screen, size)) {
        return;
    }
    self.screen = size;
    self.updateProjectionMatrix();
}

pub fn updateProjectionMatrix(self: *@This()) void {
    switch (self.projection_type) {
        .perspective => {
            self.matrix = Mat4.perspective(
                self.fov_y_radians,
                self.getAspectRatio(),
                self.near_clip,
                self.far_clip,
            );
        },
        .orthographic => {
            const aspect = self.getAspectRatio();
            const height = self.getHeight();
            self.matrix = Mat4.orthographic(
                -height * aspect / 2,
                height * aspect / 2,
                -height / 2,
                height / 2,
                self.near_clip,
                self.far_clip,
            );
        },
    }
}

pub fn screenMove(self: *@This(), dx: f32, dy: f32) Vec2 {
    const x = dx / (self.screen.x);
    const y = dy / (self.screen.y);
    const t = std.math.tan(self.fov_y_radians / 2) * 2;
    return .{
        .x = -x * t,
        .y = y * t,
    };
}

/// camera local ray
pub fn getRay(self: @This(), mouse_cursor: Vec2) Ray {
    switch (self.projection_type) {
        .perspective => {
            const y = std.math.tan(self.fov_y_radians / 2);
            const x = y * self.getAspectRatio();
            const dir = Vec3{
                .x = x * mouse_cursor.x,
                .y = y * mouse_cursor.y,
                .z = -1,
            };
            return .{
                .origin = Vec3.zero,
                .direction = dir.normalize(),
            };
        },
        .orthographic => {
            const height = self.getHeight();
            const y = (height / 2) * mouse_cursor.y;
            const x = (height / 2) * self.getAspectRatio() * mouse_cursor.x;
            return .{
                .origin = .{
                    .x = x,
                    .y = y,
                    .z = 0,
                },
                .direction = .{
                    .x = 0,
                    .y = 0,
                    .z = -1,
                },
            };
        },
    }
}

pub fn perspectiveFrustum(self: @This()) Frustum {
    const y = std.math.tan(self.fov_y_radians / 2);
    const x = y * self.getAspectRatio();
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

pub fn orthographicFrustum(self: @This()) Frustum {
    const top = self.getHeight() / 2;
    const bottom = -top;
    const right = top * self.getAspectRatio();
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

pub fn getFrustum(self: @This()) Frustum {
    return switch (self.projection_type) {
        .perspective => self.perspectiveFrustum(),
        .orthographic => self.orthographicFrustum(),
    };
}
