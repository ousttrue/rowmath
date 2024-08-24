const std = @import("std");
const Vec2 = @import("Vec2.zig");
const InputState = @import("InputState.zig");

pub const MouseButton = enum {
    left,
    right,
    middle,
};

pub fn DragHandle(comptime button: MouseButton, DragState: type) type {
    const Handler = fn (DragState, InputState, bool) DragState;

    return struct {
        fn nop(_: DragState, _: InputState, _: bool) DragState {
            const v: DragState = undefined;
            return v;
        }

        state: DragState = undefined,
        handler: *const Handler = &nop,
        // start: ?Vec2 = null,

        pub fn frame(self: *@This(), input: InputState) void {
            const button_down = switch (button) {
                .left => input.mouse_left,
                .right => input.mouse_right,
                .middle => input.mouse_middle,
            };
            self.state = self.handler(self.state, input, button_down);
            // if (self.start) |_| {
            //     if (switch (button) {
            //         .left => input.mouse_left,
            //         .right => input.mouse_right,
            //         .middle => input.mouse_middle,
            //     }) {
            //         // drag
            //         self.state = self.handler(self.state, input);
            //     } else {
            //         // end
            //         self.start = null;
            //     }
            // } else {
            //     if (switch (button) {
            //         .left => input.mouse_left,
            //         .right => input.mouse_right,
            //         .middle => input.mouse_middle,
            //     }) {
            //         // begin
            //         self.start = input.cursor();
            //     }
            // }
        }
    };
}
