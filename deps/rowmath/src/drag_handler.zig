const std = @import("std");
const Vec2 = @import("Vec2.zig");

pub const MouseButton = enum {
    left,
    right,
    middle,
};

fn StateType(Handler: type) type {
    return @typeInfo(Handler).Fn.return_type.?;
}

fn FrameInputType(Handler: type) type {
    return @typeInfo(Handler).Fn.params[1].type.?;
}

// handler required:
//
// (StateType, FrameInputType, button_down: bool) => StateType;
//
// const FrameInputType = struct {
//   input: InputState,
//   ...: and any field,
// };

pub fn DragHandle(
    comptime button: MouseButton,
    comptime _handler: anytype,
) type {
    // const Handler = @typeInfo(@TypeOf(handler)).Pointer.child;
    const Handler = @TypeOf(_handler);
    const FrameInput = FrameInputType(Handler);
    const DragState = StateType(Handler);

    return struct {
        state: DragState,

        pub fn handler(state: DragState, input: FrameInput, _button: bool) DragState {
            return _handler(state, input, _button);
        }

        pub fn frame(self: *@This(), frame_input: FrameInput) void {
            const button_down = switch (button) {
                .left => frame_input.input.mouse_left,
                .right => frame_input.input.mouse_right,
                .middle => frame_input.input.mouse_middle,
            };
            self.state = handler(self.state, frame_input, button_down);
        }
    };
}

// for init cannot .{}
// pub fn dragHandle(
//     comptime button: MouseButton,
//     comptime handler: anytype,
//     init: anytype,
// ) DragHandle(button, handler) {
//     return DragHandle(button, handler){
//         .state = init,
//     };
// }
