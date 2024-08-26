const std = @import("std");
const Vec3 = @import("../Vec3.zig");
pub const BvhChannelTypes = enum {
    None,
    Xposition,
    Yposition,
    Zposition,
    Xrotation,
    Yrotation,
    Zrotation,
};

pub const BvhChannels = @This();

init: Vec3 = Vec3.zero,
startIndex: usize = 0,
types: [6]BvhChannelTypes = .{ .None, .None, .None, .None, .None, .None },

pub fn size(self: @This()) usize {
    for (self.types, 0..) |t, i| {
        if (t == .None) {
            return i;
        }
    }
    return 6;
}
