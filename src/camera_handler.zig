const drag_handler = @import("drag_handler.zig");
const MouseButton = drag_handler.MouseButton;
const DragHandle = drag_handler.DragHandle;
const Camera = @import("Camera.zig");
const InputState = @import("InputState.zig");
const Vec2 = @import("Vec2.zig");

pub const DragState = struct {
    camera: *Camera = undefined,
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
            state.camera.yawPitch(input, state.input);
            return DragState{
                .camera = state.camera,
                .input = input,
                .start = start,
            };
        } else {
            // end
            return DragState{
                .camera = state.camera,
                .input = input,
            };
        }
    } else {
        if (button) {
            // begin
            return DragState{
                .camera = state.camera,
                .input = input,
                .start = input.cursor(),
            };
        } else {
            // not drag
            return DragState{
                .camera = state.camera,
                .input = input,
            };
        }
    }
}

pub fn makeYawPitchHandler(
    comptime button: MouseButton,
    camera: *Camera,
) DragHandle(button, DragState) {
    return DragHandle(button, DragState){
        .state = .{ .camera = camera },
        .handler = &bindYawPitchHandler,
    };
}

fn bindScreenMoveHanler(
    state: DragState,
    input: InputState,
    button: bool,
) DragState {
    if (state.start) |start| {
        if (button) {
            // drag
            state.camera.screenMove(input, state.input);
            return DragState{
                .camera = state.camera,
                .input = input,
                .start = start,
            };
        } else {
            // end
            return DragState{
                .camera = state.camera,
                .input = input,
            };
        }
    } else {
        if (button) {
            // begin
            return DragState{
                .camera = state.camera,
                .input = input,
                .start = input.cursor(),
            };
        } else {
            // not drag
            return DragState{
                .camera = state.camera,
                .input = input,
            };
        }
    }
}

pub fn makeScreenMoveHandler(
    comptime button: MouseButton,
    camera: *Camera,
) DragHandle(button, DragState) {
    return DragHandle(button, DragState){
        .state = .{ .camera = camera },
        .handler = &bindScreenMoveHanler,
    };
}

pub const CameraLeftDragHandler = DragHandle(.left, DragState);
pub const CameraRightDragHandler = DragHandle(.right, DragState);
pub const CameraMiddleDragHandler = DragHandle(.middle, DragState);
