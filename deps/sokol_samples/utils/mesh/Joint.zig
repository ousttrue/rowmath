const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("joint.glsl.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;

pub const Joint = @This();

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

pub fn makeJointVertices() [kNumPoints]VertexPNC {
    var joints: [kNumPoints]VertexPNC = undefined;

    // Fills vertices.
    var index: usize = 0;
    for (0..kNumPointsYZ) |j| { // YZ plan.
        const angle = @as(f32, @floatFromInt(j)) * std.math.pi * 2 / kNumSlices;
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);
        var vertex = &joints[index];
        index += 1;
        vertex.pos = Vec3{ .x = 0.0, .y = c * kRadius, .z = s * kRadius };
        vertex.normal = Vec3{ .x = 0.0, .y = c, .z = s };
        vertex.color = red;
    }
    for (0..kNumPointsXY) |j| { // XY plan.
        const angle = @as(f32, @floatFromInt(j)) * std.math.pi * 2 / kNumSlices;
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);
        var vertex = &joints[index];
        index += 1;
        vertex.pos = Vec3{ .x = s * kRadius, .y = c * kRadius, .z = 0.0 };
        vertex.normal = Vec3{ .x = s, .y = c, .z = 0.0 };
        vertex.color = blue;
    }
    for (0..kNumPointsXZ) |j| { // XZ plan.
        const angle = @as(f32, @floatFromInt(j)) * std.math.pi * 2 / kNumSlices;
        const s = std.math.sin(angle);
        const c = std.math.cos(angle);
        var vertex = &joints[index];
        index += 1;
        vertex.pos = Vec3{ .x = c * kRadius, .y = 0.0, .z = -s * kRadius };
        vertex.normal = Vec3{ .x = c, .y = 0.0, .z = -s };
        vertex.color = green;
    }
    std.debug.assert(index == kNumPoints);

    return joints;
}

pub fn init(state: *@This()) void {
    const vertices = makeJointVertices();
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&vertices),
        .label = "joint-vertices",
    });
    state.draw_count = vertices.len;

    // create shader
    const shd = sg.makeShader(shader.jointShaderDesc(sg.queryBackend()));

    // create pipeline object
    var pip_desc = sg.PipelineDesc{
        .shader = shd,
        .cull_mode = .BACK,
        .depth = .{
            .write_enabled = true,
            .compare = .LESS_EQUAL,
        },
        .label = "joint-pipeline",
        .primitive_type = .LINE_STRIP,
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
