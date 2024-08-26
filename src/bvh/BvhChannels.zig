const Vec3 = @import("../Vec3.zig");
pub const BvhChannelTypes = enum {
    Xposition,
    Yposition,
    Zposition,
    Xrotation,
    Yrotation,
    Zrotation,
};

pub const BvhChannels = @This();

init: Vec3,
startIndex: usize,
types: []BvhChannelTypes,
