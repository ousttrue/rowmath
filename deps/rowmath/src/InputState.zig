const Vec2 = @import("Vec2.zig");
pub const InputState = @This();

pub const MouseButton = enum {
    left,
    right,
    middle,
};

screen_width: f32 = 0,
screen_height: f32 = 0,
mouse_x: f32 = 0,
mouse_y: f32 = 0,
mouse_left: bool = false,
mouse_right: bool = false,
mouse_middle: bool = false,
mouse_wheel: f32 = 0,

pub fn screen_size(self: @This()) Vec2 {
    return .{ .x = self.screen_width, .y = self.screen_height };
}

pub fn aspect(self: @This()) f32 {
    return self.screen_width / self.screen_height;
}

pub fn cursor(self: @This()) Vec2 {
    return .{ .x = self.mouse_x, .y = self.mouse_y };
}

/// return cursor raypoisition [-1, +1],[-1, +1]
pub fn cursorScreenPosition(self: @This()) Vec2 {
    return .{
        .x = (self.mouse_x / self.screen_width) * 2 - 1,
        .y = -((self.mouse_y / self.screen_height) * 2 - 1),
    };
}
