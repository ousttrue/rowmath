const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;

pub extern fn OZZ_init() *anyopaque;
pub extern fn OZZ_shutdown(p: *anyopaque) void;
pub extern fn OZZ_load_skeleton(p: *anyopaque, buf: ?*const anyopaque, size: usize) bool;
pub extern fn OZZ_load_animation(p: *anyopaque, buf: ?*const anyopaque, size: usize) bool;
pub extern fn OZZ_load_mesh(
    p: *anyopaque,
    // input
    buf: ?*const anyopaque,
    size: usize,
    // output
    vertices: **anyopaque,
    num_vertices: *u32,
    indices: **anyopaque,
    num_triangle_indices: *u32,
) bool;

pub extern fn OZZ_eval_animation(ozz: *anyopaque, anim_ratio: f32) void;
pub extern fn OZZ_duration(ozz: *anyopaque) f32;
pub extern fn OZZ_num_joints(ozz: *anyopaque) usize;
pub extern fn OZZ_joint_parents(ozz: *anyopaque) [*]u16;
pub extern fn OZZ_model_matrices(ozz: *anyopaque, joint_index: usize) *const Mat4;
pub extern fn OZZ_skeleton_matrices(ozz: *anyopaque, joint_index: usize) *const Mat4;

pub extern fn OZZ_update_joints(
    ozz: *anyopaque,
    num_instances: u32,
    abs_time_sec: f32,
    joint_upload_buffer: *f32,
    max_joints: c_int,
) void;
pub extern fn OZZ_free(p: *anyopaque) void;
