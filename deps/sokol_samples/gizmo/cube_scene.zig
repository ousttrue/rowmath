const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const Transform = rowmath.Transform;
const InputState = rowmath.InputState;
const OrbitCamera = rowmath.OrbitCamera;
const shader = @import("cube.glsl.zig");

pub const state = struct {
    var pass_action: sg.PassAction = .{};
    var pip: sg.Pipeline = .{};
    var offscreen_pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};

    pub var xform_a = Transform{};
    pub var xform_b = Transform{};
    pub var xform_c = Transform{};
};

const points = [_]f32{
    // positions        colors
    -1.0, -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
    1.0,  -1.0, -1.0, 1.0, 0.0, 0.0, 1.0,
    1.0,  1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,
    -1.0, 1.0,  -1.0, 1.0, 0.0, 0.0, 1.0,

    -1.0, -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
    1.0,  -1.0, 1.0,  0.0, 1.0, 0.0, 1.0,
    1.0,  1.0,  1.0,  0.0, 1.0, 0.0, 1.0,
    -1.0, 1.0,  1.0,  0.0, 1.0, 0.0, 1.0,

    -1.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0,
    -1.0, 1.0,  -1.0, 0.0, 0.0, 1.0, 1.0,
    -1.0, 1.0,  1.0,  0.0, 0.0, 1.0, 1.0,
    -1.0, -1.0, 1.0,  0.0, 0.0, 1.0, 1.0,

    1.0,  -1.0, -1.0, 1.0, 0.5, 0.0, 1.0,
    1.0,  1.0,  -1.0, 1.0, 0.5, 0.0, 1.0,
    1.0,  1.0,  1.0,  1.0, 0.5, 0.0, 1.0,
    1.0,  -1.0, 1.0,  1.0, 0.5, 0.0, 1.0,

    -1.0, -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,
    -1.0, -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
    1.0,  -1.0, 1.0,  0.0, 0.5, 1.0, 1.0,
    1.0,  -1.0, -1.0, 0.0, 0.5, 1.0, 1.0,

    -1.0, 1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
    -1.0, 1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
    1.0,  1.0,  1.0,  1.0, 0.0, 0.5, 1.0,
    1.0,  1.0,  -1.0, 1.0, 0.0, 0.5, 1.0,
};

const indices = [_]u16{
    0,  1,  2,  0,  2,  3,
    6,  5,  4,  7,  6,  4,
    8,  9,  10, 8,  10, 11,
    14, 13, 12, 15, 14, 12,
    16, 17, 18, 16, 18, 19,
    22, 21, 20, 23, 22, 20,
};

pub fn setup() void {
    state.xform_a.rigid_transform.translation.x = -2;
    state.xform_b.rigid_transform.translation.x = 2;
    state.xform_c.rigid_transform.translation.z = -2;

    // cube vertex buffer
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&points),
    });

    // cube index buffer
    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(&indices),
    });

    // shader and pipeline object
    var pip_desc: sg.PipelineDesc = .{
        .shader = sg.makeShader(shader.cubeShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .depth = .{
            .compare = .LESS_EQUAL,
            .write_enabled = true,
        },
        .cull_mode = .BACK,
    };
    pip_desc.layout.attrs[shader.ATTR_vs_position].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_color0].format = .FLOAT4;
    state.pip = sg.makePipeline(pip_desc);

    // offscreen_pip
    pip_desc.colors[0].pixel_format = .RGBA8;
    pip_desc.sample_count = 1;
    pip_desc.depth = .{
        .pixel_format = .DEPTH,
        .compare = .LESS_EQUAL,
        .write_enabled = true,
    };
    state.offscreen_pip = sg.makePipeline(pip_desc);
}

fn mat4_to_array(m: *const Mat4) *const [16]f32 {
    return @ptrCast(m);
}

pub fn draw(opts: struct { camera: OrbitCamera, useRenderTarget: bool = false }) void {
    const viewProj = opts.camera.viewProjectionMatrix();

    // teapot
    if (opts.useRenderTarget) {
        sg.applyPipeline(state.offscreen_pip);
    } else {
        sg.applyPipeline(state.pip);
    }
    sg.applyBindings(state.bind);

    draw_cube(state.xform_a, viewProj);
    draw_cube(state.xform_b, viewProj);
    draw_cube(state.xform_c, viewProj);
}

fn draw_cube(
    t: Transform,
    viewProj: Mat4,
) void {
    const vsParams = shader.VsParams{
        .mvp = t.matrix().mul(viewProj).m,
    };
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vsParams));
    sg.draw(0, 36, 1);
}
