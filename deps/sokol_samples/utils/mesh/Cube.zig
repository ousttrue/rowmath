const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("cube.glsl.zig");
const rowmath = @import("rowmath");
const Transform = rowmath.Transform;
const Mat4 = rowmath.Mat4;
pub const Cube = @This();

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

bind: sg.Bindings = .{},
pip: sg.Pipeline = .{},
offscreen_pip: sg.Pipeline = .{},

pub fn init(self: *@This()) void {
    // cube vertex buffer
    self.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(&points),
    });

    // cube index buffer
    self.bind.index_buffer = sg.makeBuffer(.{
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
    self.pip = sg.makePipeline(pip_desc);

    // offscreen_pip
    pip_desc.colors[0].pixel_format = .RGBA8;
    pip_desc.sample_count = 1;
    pip_desc.depth = .{
        .pixel_format = .DEPTH,
        .compare = .LESS_EQUAL,
        .write_enabled = true,
    };
    self.offscreen_pip = sg.makePipeline(pip_desc);
}

pub fn draw(
    self: @This(),
    t: Transform,
    viewProj: Mat4,
    opts: struct {
        useRenderTarget: bool = false,
    },
) void {
    if (opts.useRenderTarget) {
        sg.applyPipeline(self.offscreen_pip);
    } else {
        sg.applyPipeline(self.pip);
    }
    sg.applyBindings(self.bind);

    const vsParams = shader.VsParams{
        .mvp = t.matrix().mul(viewProj).m,
    };
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vsParams));
    sg.draw(0, 36, 1);
}
