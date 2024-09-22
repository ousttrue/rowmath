const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("bone.glsl.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;

pub const Bone = @This();

pip: sg.Pipeline = .{},
bind: sg.Bindings = .{},
pass_action: sg.PassAction = .{},
draw_count: u32 = 0,

// A vertex made of positions and normals.
const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const VertexPNC = struct {
    pos: Vec3,
    normal: Vec3,
    color: Color,
};

const kInter: f32 = 0.2;
// Prepares joint mesh.
const kNumSlices = 20;
const kNumPointsPerCircle = kNumSlices + 1;
const kNumPointsYZ = kNumPointsPerCircle;
const kNumPointsXY = kNumPointsPerCircle + kNumPointsPerCircle / 4;
const kNumPointsXZ = kNumPointsPerCircle;
const kNumPoints = kNumPointsXY + kNumPointsXZ + kNumPointsYZ;
const kRadius = kInter; // Radius multiplier.
const red = Color{ .r = 0xff, .g = 0xc0, .b = 0xc0, .a = 0xff };
const green = Color{ .r = 0xc0, .g = 0xff, .b = 0xc0, .a = 0xff };
const blue = Color{ .r = 0xc0, .g = 0xc0, .b = 0xff, .a = 0xff };

pub fn makeBoneVertices() [24]VertexPNC {

    // Prepares bone mesh.
    const pos = [6]Vec3{
        .{ .x = 1.0, .y = 0.0, .z = 0.0 },
        .{ .x = kInter, .y = 0.1, .z = 0.1 },
        .{ .x = kInter, .y = 0.1, .z = -0.1 },
        .{ .x = kInter, .y = -0.1, .z = -0.1 },
        .{ .x = kInter, .y = -0.1, .z = 0.1 },
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
    };

    const normals = [8]Vec3{
        (pos[2].sub(pos[1])).cross(pos[2].sub(pos[0])).normalize(),
        (pos[1].sub(pos[2])).cross(pos[1].sub(pos[5])).normalize(),
        (pos[3].sub(pos[2])).cross(pos[3].sub(pos[0])).normalize(),
        (pos[2].sub(pos[3])).cross(pos[2].sub(pos[5])).normalize(),
        (pos[4].sub(pos[3])).cross(pos[4].sub(pos[0])).normalize(),
        (pos[3].sub(pos[4])).cross(pos[3].sub(pos[5])).normalize(),
        (pos[1].sub(pos[4])).cross(pos[1].sub(pos[0])).normalize(),
        (pos[4].sub(pos[1])).cross(pos[4].sub(pos[5])).normalize(),
    };
    const white = Color{ .r = 0xff, .g = 0xff, .b = 0xff, .a = 0xff };
    const bones = [24]VertexPNC{
        .{ .pos = pos[0], .normal = normals[0], .color = white },
        .{ .pos = pos[2], .normal = normals[0], .color = white },
        .{ .pos = pos[1], .normal = normals[0], .color = white },
        .{ .pos = pos[5], .normal = normals[1], .color = white },
        .{ .pos = pos[1], .normal = normals[1], .color = white },
        .{ .pos = pos[2], .normal = normals[1], .color = white },
        .{ .pos = pos[0], .normal = normals[2], .color = white },
        .{ .pos = pos[3], .normal = normals[2], .color = white },
        .{ .pos = pos[2], .normal = normals[2], .color = white },
        .{ .pos = pos[5], .normal = normals[3], .color = white },
        .{ .pos = pos[2], .normal = normals[3], .color = white },
        .{ .pos = pos[3], .normal = normals[3], .color = white },
        .{ .pos = pos[0], .normal = normals[4], .color = white },
        .{ .pos = pos[4], .normal = normals[4], .color = white },
        .{ .pos = pos[3], .normal = normals[4], .color = white },
        .{ .pos = pos[5], .normal = normals[5], .color = white },
        .{ .pos = pos[3], .normal = normals[5], .color = white },
        .{ .pos = pos[4], .normal = normals[5], .color = white },
        .{ .pos = pos[0], .normal = normals[6], .color = white },
        .{ .pos = pos[1], .normal = normals[6], .color = white },
        .{ .pos = pos[4], .normal = normals[6], .color = white },
        .{ .pos = pos[5], .normal = normals[7], .color = white },
        .{ .pos = pos[4], .normal = normals[7], .color = white },
        .{ .pos = pos[1], .normal = normals[7], .color = white },
    };

    return bones;
}

pub fn init(state: *@This()) void {
    const vertices = makeBoneVertices();
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&vertices),
        .label = "bone-vertices",
    });
    state.draw_count = vertices.len;

    // create shader
    const shd = sg.makeShader(shader.boneShaderDesc(sg.queryBackend()));

    // create pipeline object
    var pip_desc = sg.PipelineDesc{
        .shader = shd,
        .cull_mode = .BACK,
        .depth = .{
            .write_enabled = true,
            .compare = .LESS_EQUAL,
        },
        .label = "bone-pipeline",
    };
    pip_desc.layout.buffers[0].stride = 28;
    pip_desc.layout.attrs[shader.ATTR_vs_a_position].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_a_normal].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_a_color].format = .UBYTE4N;
    state.pip = sg.makePipeline(pip_desc);
}

pub const DrawOpts = struct {
    camera: Mat4,
    joint: Mat4,
};

pub fn draw(state: @This(), opts: DrawOpts) void {
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    const vs_params = shader.VsParams{
        .joint = opts.joint.m,
        .u_mvp = opts.camera.m,
    };
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));
    sg.draw(0, state.draw_count, 1);
}
