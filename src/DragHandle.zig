const Vec2 = @import("Vec2.zig");
pub const DragHandle = @This();
pub const DragState = struct {
    start: Vec2,
    cursor: Vec2,

    pub fn delta(self: @This()) Vec2 {
        return self.cursor.sub(self.start);
    }
};

state: ?DragState = null,

pub fn frame(self: *@This(), cursor: Vec2, button: bool) void {
    if (self.state) |state| {
        if (button) {
            self.drag(state.start, cursor);
        } else {
            self.end();
        }
    } else {
        if (button) {
            self.begin(cursor);
        }
    }
}

fn begin(self: *@This(), cursor: Vec2) void {
    self.state = .{
        .start = cursor,
        .cursor = cursor,
    };
}

fn end(self: *@This()) void {
    self.state = null;
}

fn drag(self: *@This(), start: Vec2, cursor: Vec2) void {
    self.state = .{
        .start = start,
        .cursor = cursor,
    };
}
