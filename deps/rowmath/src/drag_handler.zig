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

fn InputType(Handler: type) type {
    return @typeInfo(Handler).Fn.params[1].type.?;
}

// handler required:
//
// (StateType, InputType, is_pressed:bool) => StateType;

pub fn DragHandle(
    comptime button: MouseButton,
    handler: anytype,
) type {
    const Handler = @typeInfo(@TypeOf(handler)).Pointer.child;
    const DragInput = InputType(Handler);
    const DragState = StateType(Handler);

    return struct {
        fn nop(_: DragState, _: DragInput, _: bool) DragState {
            const v: DragState = undefined;
            return v;
        }

        state: DragState = undefined,
        handler: *const Handler = &nop,

        pub fn frame(self: *@This(), input: DragInput) void {
            const button_down = switch (button) {
                .left => input.mouse_left,
                .right => input.mouse_right,
                .middle => input.mouse_middle,
            };
            self.state = self.handler(self.state, input, button_down);
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
