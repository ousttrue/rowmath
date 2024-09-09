const std = @import("std");
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const Bone = @import("Bone.zig");
const Joint = @import("Joint.zig");

pub const SkeletonJoint = struct {
    name: [*:0]const u8,
    is_leaf: bool,
    parent: ?u16,
};

const Skeleton = @This();

allocator: std.mem.Allocator,
joints: []SkeletonJoint,
bone: Bone = .{},
joint: Joint = .{},

pub fn init(allocator: std.mem.Allocator, size: usize) !@This() {
    var list = std.ArrayList(SkeletonJoint).init(allocator);
    try list.resize(size);
    var skeleton = Skeleton{
        .allocator = allocator,
        .joints = try list.toOwnedSlice(),
    };
    list.deinit();
    skeleton.bone.init();
    skeleton.joint.init();
    return skeleton;
}

pub fn deinit(self: *@This()) void {
    self.allocator.free(self.joints);
}

pub fn draw(
    self: @This(),
    viewProjection: Mat4,
    matrices: [*]const Mat4,
) void {
    for (self.joints, 0..) |joint, i| {
        // Root isn't rendered.
        if (joint.parent) |parent_id| {

            // Selects joint matrices.
            const parent = matrices[@intCast(parent_id)];
            const current = matrices[i];

            // Copy parent joint's raw matrix, to render a bone between the parent
            // and current matrix.
            var uniform = parent;

            // Set bone direction (bone_dir). The shader expects to find it at index
            const bone_dir = current.row3().sub(parent.row3());
            // [3,7,11] of the matrix.
            // Index 15 is used to store whether a bone should be rendered,
            // otherwise it's a leaf.
            uniform.m[3] = bone_dir.x;
            uniform.m[7] = bone_dir.y;
            uniform.m[11] = bone_dir.z;
            uniform.m[15] = 1.0; // Enables bone rendering.

            self.joint.draw(.{
                .camera = viewProjection,
                .joint = uniform,
            });

            self.bone.draw(.{
                .camera = viewProjection,
                .joint = uniform,
            });

            // Only the joint is rendered for leaves, the bone model isn't.
            if (joint.is_leaf) {
                // Copy current joint's raw matrix.
                uniform = current;

                // Re-use bone_dir to fix the size of the leaf (same as previous bone).
                // The shader expects to find it at index [3,7,11] of the matrix.
                uniform.m[3] = bone_dir.x;
                uniform.m[7] = bone_dir.y;
                uniform.m[11] = bone_dir.z;
                // uniform.m[15] = 0.0; // Disables bone rendering.

                self.joint.draw(.{
                    .camera = viewProjection,
                    .joint = uniform,
                });
            }
        }
    }
}
