//
// CUBE insance Renderer
//
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
pub usingnamespace @import("cube.zig");
pub const MeshBuilder = @import("MeshBuilder.zig");
pub const shader = @import("shader.glsl.zig");
pub const cube = @import("cube.zig");
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;

fn calc_shape() Mat4 {
    // auto Y = Float3(tail->joint_.localOffset.x * scaling,
    //                 tail->joint_.localOffset.y * scaling,
    //                 tail->joint_.localOffset.z * scaling);
    //
    // auto length = Float3Len(Y);
    // // std::cout << name_ << "=>" << tail->name_ << "=" << length << std::endl;
    // Y = DirectX::XMVector3Normalize(Y);
    // auto Z = Float3(0, 0, 1);
    // auto X = DirectX::XMVector3Cross(Y, Z);
    // Z = DirectX::XMVector3Cross(X, Y);
    //
    // auto center = DirectX::XMMatrixTranslation(0, 0.5f, 0);
    // auto scale = DirectX::XMMatrixScaling(DEFAULT_SIZE, length, DEFAULT_SIZE);
    // auto r = DirectX::XMMATRIX(X, Y, Z, Float4(0, 0, 0, 1));
    //
    // auto shape = center * scale * r;
    // DirectX::XMStoreFloat4x4((DirectX::XMFLOAT4X4*)&shape_, shape);
    unreachable;
}

const Instance = struct {
    matrix: Mat4 = Mat4.identity,
    positive_face_flag: [4]f32 = .{ 1, 2, 3, 0 },
    negative_face_flag: [4]f32 = .{ 4, 5, 6, 0 },
};
pub fn Cuber(comptime N: usize) type {
    return struct {
        bind: sg.Bindings = .{},
        pip: sg.Pipeline = .{},
        instances: [N]Instance = undefined,
        shapes: [N]Mat4 = undefined,
        fs_params: shader.FsParams = std.mem.zeroes(shader.FsParams),
        draw_count: u32 = 0,

        pub fn init(state: *@This()) void {
            var builder = MeshBuilder.init(std.heap.c_allocator, false);
            defer builder.deinit();
            cube.buildCube(&builder) catch @panic("buildCube");

            // vertex buffer for static geometry, goes into vertex-buffer-slot 0
            state.bind.vertex_buffers[0] = sg.makeBuffer(.{
                .data = sg.asRange(builder.mesh.vertices.items),
                .label = "geometry-vertices",
            });

            // index buffer for static geometry
            state.bind.index_buffer = sg.makeBuffer(.{
                .type = .INDEXBUFFER,
                .data = sg.asRange(builder.mesh.indices.items),
                .label = "geometry-indices",
            });

            // empty, dynamic instance-data vertex buffer, goes into vertex-buffer-slot 1
            state.bind.vertex_buffers[1] = sg.makeBuffer(.{
                .size = N * @sizeOf(Instance),
                .usage = .STREAM,
                .label = "instance-data",
            });

            // a shader
            const shd = sg.makeShader(shader.instancingShaderDesc(sg.queryBackend()));

            // a pipeline object
            var pip_desc = sg.PipelineDesc{
                .shader = shd,
                .index_type = .UINT16,
                .cull_mode = .BACK,
                .depth = .{
                    .compare = .LESS_EQUAL,
                    .write_enabled = true,
                },
                .label = "instancing-pipeline",
            };
            // vertex buffer at slot 1 must step per instance
            pip_desc.layout.buffers[1].step_func = .PER_INSTANCE;
            pip_desc.layout.attrs[shader.ATTR_vs_vPosFace] = .{ .format = .FLOAT4, .buffer_index = 0 };
            pip_desc.layout.attrs[shader.ATTR_vs_vUvBarycentric] = .{ .format = .FLOAT4, .buffer_index = 0 };
            pip_desc.layout.attrs[shader.ATTR_vs_iRow0] = .{ .format = .FLOAT4, .buffer_index = 1 };
            pip_desc.layout.attrs[shader.ATTR_vs_iRow1] = .{ .format = .FLOAT4, .buffer_index = 1 };
            pip_desc.layout.attrs[shader.ATTR_vs_iRow2] = .{ .format = .FLOAT4, .buffer_index = 1 };
            pip_desc.layout.attrs[shader.ATTR_vs_iRow3] = .{ .format = .FLOAT4, .buffer_index = 1 };
            pip_desc.layout.attrs[shader.ATTR_vs_iPositive_xyz_flag] = .{ .format = .FLOAT4, .buffer_index = 1 };
            pip_desc.layout.attrs[shader.ATTR_vs_iNegative_xyz_flag] = .{ .format = .FLOAT4, .buffer_index = 1 };
            state.pip = sg.makePipeline(pip_desc);

            const Red = [4]f32{ 1, 0, 0, 1 };
            const Green = [4]f32{ 0, 1, 0, 1 };
            const Blue = [4]f32{ 0, 0, 1, 1 };
            const DarkRed = [4]f32{ 0.5, 0, 0, 1 };
            const DarkGreen = [4]f32{ 0, 0.5, 0, 1 };
            const DarkBlue = [4]f32{ 0, 0, 0.5, 1 };
            const Magenta = [4]f32{ 1, 0, 1, 1 };
            const White = [4]f32{ 0.8, 0.8, 0.9, 1 };
            const Black = [4]f32{ 0, 0, 0, 1 };
            state.fs_params.colors[0] = Magenta;
            state.fs_params.colors[1] = Red;
            state.fs_params.colors[2] = Green;
            state.fs_params.colors[3] = Blue;
            state.fs_params.colors[4] = DarkRed;
            state.fs_params.colors[5] = DarkGreen;
            state.fs_params.colors[6] = DarkBlue;
            state.fs_params.colors[7] = White;
            state.fs_params.colors[8] = Black;
            state.fs_params.textures[0] = .{ -1, -1, -1, -1 };
            state.fs_params.textures[1] = .{ -1, -1, -1, -1 }; // Red
            state.fs_params.textures[2] = .{ -1, -1, -1, -1 }; // Green
            state.fs_params.textures[3] = .{ -1, -1, -1, -1 }; // Blue
            state.fs_params.textures[4] = .{ -1, -1, -1, -1 }; // DarkRed
            state.fs_params.textures[5] = .{ -1, -1, -1, -1 }; // DarkGreen
            state.fs_params.textures[6] = .{ -1, -1, -1, -1 }; // DarkBlue
            state.fs_params.textures[7] = .{ -1, -1, -1, -1 }; // White
            state.fs_params.textures[8] = .{ -1, -1, -1, -1 }; // Black

        }

        pub fn upload(state: *@This(), draw_count: u32) void {
            sg.updateBuffer(
                state.bind.vertex_buffers[1],
                sg.asRange(state.instances[0..draw_count]),
            );
            state.draw_count = draw_count;
        }

        pub fn draw(state: @This(), viewProjection: Mat4) void {
            sg.applyPipeline(state.pip);
            sg.applyBindings(state.bind);

            const vs_params = shader.VsParams{
                .VP = viewProjection.m,
            };
            sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));

            // WASM: require on stack ?
            const fs_params = state.fs_params;//std.mem.zeroes(shader.FsParams);
            sg.applyUniforms(.FS, shader.SLOT_fs_params, .{
                .ptr = &fs_params,
                .size = @sizeOf(@TypeOf(fs_params)),
            });

            sg.draw(0, 36, state.draw_count);
        }
    };
}
