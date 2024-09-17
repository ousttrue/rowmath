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
    handler: anytype,
) type {
    const Handler = @typeInfo(@TypeOf(handler)).Pointer.child;
    const FrameInput = FrameInputType(Handler);
    const DragState = StateType(Handler);

    return struct {
        fn nop(_: DragState, _: FrameInput, _: bool) DragState {
            const v: DragState = undefined;
            return v;
        }

        state: DragState = undefined,
        handler: *const Handler = &nop,

        pub fn frame(self: *@This(), frame_input: FrameInput) void {
            const button_down = switch (button) {
                .left => frame_input.input.mouse_left,
                .right => frame_input.input.mouse_right,
                .middle => frame_input.input.mouse_middle,
            };
            self.state = self.handler(self.state, frame_input, button_down);
        }
    };
}

pub fn dragHandle(
    comptime button: MouseButton,
    comptime handler: anytype,
    init: anytype,
) DragHandle(button, handler) {
    return DragHandle(button, handler){
        .handler = handler,
        .state = init,
    };
}
