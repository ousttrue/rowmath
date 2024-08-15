const InputState = @This();

screen_width: f32 = 0,
screen_height: f32 = 0,
mouse_x: f32 = 0,
mouse_y: f32 = 0,
mouse_left: bool = false,
mouse_right: bool = false,
mouse_middle: bool = false,
mouse_wheel: f32 = 0,

pub fn aspect(self: @This()) f32 {
    return self.screen_width / self.screen_height;
}
