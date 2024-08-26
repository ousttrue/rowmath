const Vec3 = @import("../Vec3.zig");
pub const BvhChannels = @import("BvhChannels.zig");
pub const BvhJoint = @This();

name: []const u8,
index: u16,
parent: u16,
localOffset: Vec3,
worldOffset: Vec3,
channels: BvhChannels,
// srht::HumanoidBones bone_ = {};
