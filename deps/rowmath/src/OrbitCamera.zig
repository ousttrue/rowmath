const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
const InputState = @import("InputState.zig");
const Camera = @import("Camera.zig");
const drag_handler = @import("drag_handler.zig");
pub const OrbitCamera = @This();

pub const OrbitState = struct {
    prev_input: InputState = .{},
    start: ?Vec2 = null,
};

pub const OrbitInput = struct {
    orbit: *OrbitCamera,
    input: InputState,
};

fn bindYawPitchHandler(
    state: OrbitState,
    frame_input: OrbitInput,
    button: bool,
) OrbitState {
    if (state.start) |start| {
        if (button) {
            // drag
            frame_input.orbit.yawPitch(frame_input.input, state.prev_input);
            return .{
                .prev_input = frame_input.input,
                .start = start,
            };
        } else {
            // end
            return .{
                .prev_input = frame_input.input,
            };
        }
    } else {
        if (button) {
            // begin
            return .{
                .prev_input = frame_input.input,
                .start = frame_input.input.cursor(),
            };
        } else {
            // not drag
            return .{
                .prev_input = frame_input.input,
            };
        }
    }
}

fn bindScreenMoveHanler(
    state: OrbitState,
    frame_input: OrbitInput,
    button: bool,
) OrbitState {
    if (state.start) |start| {
        if (button) {
            // drag
            frame_input.orbit.screenMove(frame_input.input, state.prev_input);
            return .{
                .prev_input = frame_input.input,
                .start = start,
            };
        } else {
            // end
            return .{
                .prev_input = frame_input.input,
            };
        }
    } else {
        if (button) {
            // begin
            return .{
                .prev_input = frame_input.input,
                .start = frame_input.input.cursor(),
            };
        } else {
            // not drag
            return .{
                .prev_input = frame_input.input,
            };
        }
    }
}

camera: Camera = .{},
input: InputState = .{},

// transform
pitch: f32 = 0,
yaw: f32 = 0,
pivot: Vec3 = .{ .x = 0, .y = 2, .z = 0 },
shift: Vec3 = .{ .x = 0, .y = 0, .z = 10 },

drag_right: drag_handler.DragHandle(
    .right,
    bindYawPitchHandler,
) = .{ .state = .{} },
drag_middle: drag_handler.DragHandle(
    .middle,
    bindScreenMoveHanler,
) = .{ .state = .{} },

pub fn projectionMatrix(self: @This()) Mat4 {
    return self.camera.projection.matrix;
}

pub fn viewMatrix(self: @This()) Mat4 {
    return self.camera.transform.worldToLocal();
}

pub fn viewProjectionMatrix(self: @This()) Mat4 {
    return self.viewMatrix().mul(self.projectionMatrix());
}

pub fn frame(self: *@This(), input: InputState) void {
    // update projection
    self.camera.projection.resize(input.screen_size());
    self.input = input;

    // update transform
    self.drag_right.frame(.{ .orbit = self, .input = input });
    self.drag_middle.frame(.{ .orbit = self, .input = input });

    // consumed. input.mouse_wheel must be clear
    self.dolly(input.mouse_wheel);

    self.updateTransform();
}

pub fn dolly(self: *@This(), d: f32) void {
    if (d > 0) {
        self.shift.z *= 0.9;
    } else if (d < 0) {
        self.shift.z *= 1.1;
    }
}

const ROT_SPEED = 2;
pub fn yawPitch(self: *@This(), input: InputState, prev: InputState) void {
    const dx = (input.mouse_x - prev.mouse_x) / self.camera.projection.screen.y;
    const dy = (input.mouse_y - prev.mouse_y) / self.camera.projection.screen.y;
    self.yaw -= dx * ROT_SPEED;
    self.pitch -= dy * ROT_SPEED;
}

pub fn screenMove(self: *@This(), input: InputState, prev: InputState) void {
    const d = self.camera.projection.screenMove(
        input.mouse_x - prev.mouse_x,
        input.mouse_y - prev.mouse_y,
    );
    const s = switch (self.camera.projection.projection_type) {
        .perspective => self.shift.z,
        .orthographic => self.camera.projection.far_clip,
    };
    // const x_dir = self.transform.rotation.dirX().scale(d.x * s);
    // const y_dir = self.transform.rotation.dirY().scale(d.y * s);
    // self.pivot = self.pivot.add(x_dir).add(y_dir);
    self.shift = self.shift.add(.{
        .x = d.x * s,
        .y = d.y * s,
        .z = 0,
    });
}

pub fn updateTransform(self: *@This()) void {
    const yaw = Quat.axisAngle(.{ .x = 0, .y = 1, .z = 0 }, self.yaw);
    const pitch = Quat.axisAngle(.{ .x = 1, .y = 0, .z = 0 }, self.pitch);
    self.camera.transform.rotation = pitch.mul(yaw); //.matrix();
    const m = Mat4.translate(self.shift).mul(
        self.camera.transform.rotation.matrix(),
    ).mul(
        Mat4.translate(self.pivot),
    );
    self.camera.transform.translation.x = m.m[12];
    self.camera.transform.translation.y = m.m[13];
    self.camera.transform.translation.z = m.m[14];
}

pub fn target(self: @This()) Vec3 {
    return self.camera.transform.translation.add(
        self.camera.transform.rotation.dirZ().scale(-@abs(self.shift.z)),
    );
}
