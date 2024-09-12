const Vec3 = @import("../Vec3.zig");
pub const BvhChannels = @import("BvhChannels.zig");
pub const BvhJoint = @This();

name: []const u8,
index: usize = 0,
parent: ?usize,
local_offset: Vec3,
world_offset: Vec3 = Vec3.zero,
channels: BvhChannels = undefined,
// srht::HumanoidBones bone_ = {};
