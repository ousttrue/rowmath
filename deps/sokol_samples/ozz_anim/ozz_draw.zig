const std = @import("std");
const sokol = @import("sokol");
const ozz_wrap = @import("ozz_wrap.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;

fn draw_vec(vec: Vec3) void {
    sokol.gl.v3f(vec.x, vec.y, vec.z);
}

fn draw_line(v0: Vec3, v1: Vec3) void {
    draw_vec(v0);
    draw_vec(v1);
}

// this draws a wireframe 3d rhombus between the current and parent joints
fn draw_joint(
    matrices: [*]const Mat4,
    joint_index: usize,
    parent_joint_index: u16,
) void {
    if (parent_joint_index == std.math.maxInt(u16)) {
        return;
    }

    const m0 = matrices[joint_index];
    const m1 = matrices[parent_joint_index];

    const p0 = m0.row3().toVec3();
    const p1 = m1.row3().toVec3();
    const ny = m1.row1().toVec3();
    const nz = m1.row2().toVec3();

    const len = p1.sub(p0).norm() * 0.1;
    const pmid = p0.add((p1.sub(p0)).scale(0.66));
    const p2 = pmid.add(ny.scale(len));
    const p3 = pmid.add(nz.scale(len));
    const p4 = pmid.sub(ny.scale(len));
    const p5 = pmid.sub(nz.scale(len));

    sokol.gl.c3f(1.0, 1.0, 0.0);
    draw_line(p0, p2);
    draw_line(p0, p3);
    draw_line(p0, p4);
    draw_line(p0, p5);
    draw_line(p1, p2);
    draw_line(p1, p3);
    draw_line(p1, p4);
    draw_line(p1, p5);
    draw_line(p2, p3);
    draw_line(p3, p4);
    draw_line(p4, p5);
    draw_line(p5, p2);
}

pub fn draw_skeleton(
    ozz: ?*ozz_wrap.ozz_t,
) void {
    const num_joints = ozz_wrap.OZZ_num_joints(ozz);
    const joint_parents = ozz_wrap.OZZ_joint_parents(ozz);
    const matrices: [*]const Mat4 = @ptrCast(ozz_wrap.OZZ_model_matrices(ozz));

    {
        sokol.gl.beginLines();
        defer sokol.gl.end();
        for (0..num_joints) |joint_index| {
            if (joint_index == std.math.maxInt(u16)) {
                continue;
            }
            draw_joint(matrices, joint_index, joint_parents[joint_index]);
        }
    }
}
