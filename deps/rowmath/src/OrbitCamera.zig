const Vec2 = @import("Vec2.zig");
const Vec3 = @import("Vec3.zig");
const Quat = @import("Quat.zig");
const Mat4 = @import("Mat4.zig");
const InputState = @import("InputState.zig");
const Camera = @import("Camera.zig");
const drag_handler = @import("drag_handler.zig");
pub const OrbitCamera = @This();

pub const DragState = struct {
    orbit: *OrbitCamera = undefined,
    input: InputState = .{},
    start: ?Vec2 = null,
};

fn bindYawPitchHandler(
    state: DragState,
    input: InputState,
    button: bool,
) DragState {
    if (state.start) |start| {
        if (button) {
            // drag
            state.orbit.yawPitch(input, state.input);
            return DragState{
                .orbit = state.orbit,
                .input = input,
                .start = start,
            };
        } else {
            // end
            return DragState{
                .orbit = state.orbit,
                .input = input,
            };
        }
    } else {
        if (button) {
            // begin
            return DragState{
                .orbit = state.orbit,
                .input = input,
                .start = input.cursor(),
            };
        } else {
            // not drag
            return DragState{
                .orbit = state.orbit,
                .input = input,
            };
        }
    }
}

pub fn makeYawPitchHandler(
    comptime button: drag_handler.MouseButton,
    orbit: *OrbitCamera,
) drag_handler.DragHandle(button, &bindYawPitchHandler) {
    return drag_handler.dragHandle(
        button,
        &bindYawPitchHandler,
        .{ .orbit = orbit },
    );
}

fn bindScreenMoveHanler(
    state: DragState,
    input: InputState,
    button: bool,
) DragState {
    if (state.start) |start| {
        if (button) {
            // drag
            state.orbit.screenMove(input, state.input);
            return DragState{
                .orbit = state.orbit,
                .input = input,
                .start = start,
            };
        } else {
            // end
            return DragState{
                .orbit = state.orbit,
                .input = input,
            };
        }
    } else {
        if (button) {
            // begin
            return DragState{
                .orbit = state.orbit,
                .input = input,
                .start = input.cursor(),
            };
        } else {
            // not drag
            return DragState{
                .orbit = state.orbit,
                .input = input,
            };
        }
    }
}

pub fn makeScreenMoveHandler(
    comptime button: drag_handler.MouseButton,
    orbit: *OrbitCamera,
) drag_handler.DragHandle(button, &bindScreenMoveHanler) {
    return drag_handler.dragHandle(
        button,
        &bindScreenMoveHanler,
        .{ .orbit = orbit },
    );
}

pub const CameraRightDragHandler = drag_handler.DragHandle(.right, &bindYawPitchHandler);
pub const CameraMiddleDragHandler = drag_handler.DragHandle(.middle, &bindScreenMoveHanler);
camera: Camera = .{},

// transform
pitch: f32 = 0,
yaw: f32 = 0,
pivot: Vec3 = .{ .x = 0, .y = 2, .z = 0 },
shift: Vec3 = .{ .x = 0, .y = 0, .z = 10 },

drag_right: CameraRightDragHandler = .{},
drag_middle: CameraMiddleDragHandler = .{},

pub fn init(state: *@This()) void {
    state.drag_right = makeYawPitchHandler(.right, state);
    state.drag_middle = makeScreenMoveHandler(.middle, state);
}

pub fn projectionMatrix(self: @This()) Mat4 {
    return self.camera.projection.matrix;
}

pub fn viewMatrix(self: @This()) Mat4 {
    return self.camera.transform.worldToLocal();
}

pub fn viewProjectionMatrix(self: @This()) Mat4 {
    return self.viewMatrix().mul(self.projectionMatrix());
}

pub fn frame(state: *@This(), input: InputState) void {
    // update projection
    state.camera.projection.resize(input.screen_size());

    // update transform
    state.drag_right.frame(input);
    state.drag_middle.frame(input);

    // consumed. input.mouse_wheel must be clear
    state.dolly(input.mouse_wheel);

    state.updateTransform();
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
