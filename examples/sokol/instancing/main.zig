//------------------------------------------------------------------------------
//  instancing.c
//  Demonstrate simple hardware-instancing using a static geometry buffer
//  and a dynamic instance-data buffer.
//------------------------------------------------------------------------------
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("shader.glsl.zig");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const cube = @import("cube.zig");
const MeshBuilder = @import("MeshBuilder.zig");

const MAX_PARTICLES = 4;

const Instance = struct {
    matrix: Mat4 = Mat4.identity,
    positive_face_flag: [4]f32 = .{ 1, 2, 3, 0 },
    negative_face_flag: [4]f32 = .{ 4, 5, 6, 0 },
};
const state = struct {
    var pass_action = sg.PassAction{};
    var pip = sg.Pipeline{};
    var bind = sg.Bindings{};
    var ry: f32 = 0;
    // var cur_num_particles: i32 = 0;
    var pos: [MAX_PARTICLES]Instance = undefined;
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // a pass action for the default render pass
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
    };

    var builder = MeshBuilder.init(std.heap.c_allocator, true);
    // defer builder.deinit();
    cube.buildCube(&builder) catch @panic("buildCube");

    // vertex buffer for static geometry, goes into vertex-buffer-slot 0
    // const r: f32 = 0.05;
    // const vertices = [_]f32{
    //     // positions            colors
    //     0.0, -r,  0.0, 1.0, 0.0, 0.0, 1.0,
    //     r,   0.0, r,   0.0, 1.0, 0.0, 1.0,
    //     r,   0.0, -r,  0.0, 0.0, 1.0, 1.0,
    //     -r,  0.0, -r,  1.0, 1.0, 0.0, 1.0,
    //     -r,  0.0, r,   0.0, 1.0, 1.0, 1.0,
    //     0.0, r,   0.0, 1.0, 0.0, 1.0, 1.0,
    // };
    state.bind.vertex_buffers[0] = sg.makeBuffer(.{
        .data = sg.asRange(builder.mesh.vertices.items),
        .label = "geometry-vertices",
    });

    // index buffer for static geometry
    // const indices = [_]u16{
    //     0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
    //     5, 1, 2, 5, 2, 3, 5, 3, 4, 5, 4, 1,
    // };
    state.bind.index_buffer = sg.makeBuffer(.{
        .type = .INDEXBUFFER,
        .data = sg.asRange(builder.mesh.indices.items),
        .label = "geometry-indices",
    });

    // empty, dynamic instance-data vertex buffer, goes into vertex-buffer-slot 1
    state.bind.vertex_buffers[1] = sg.makeBuffer(.{
        .size = MAX_PARTICLES * @sizeOf(Instance),
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
}

export fn frame() void {
    const frame_time: f32 = @floatCast(sokol.app.frameDuration());
    // emit new particles
    // for (0..NUM_PARTICLES_EMITTED_PER_FRAME) |_| {
    //     if (state.cur_num_particles < MAX_PARTICLES) {
    //         state.pos[@intCast(state.cur_num_particles)] = .{
    //             .x = 0.0,
    //             .y = 0.0,
    //             .z = 0.0,
    //         };
    //         state.vel[@intCast(state.cur_num_particles)] = .{
    //             .x = state.rand.random().float(f32) - 0.5,
    //             .y = state.rand.random().float(f32) * 0.5 + 2.0,
    //             .z = state.rand.random().float(f32) - 0.5,
    //         };
    //         state.cur_num_particles += 1;
    //     } else {
    //         break;
    //     }
    // }

    // update instance data
    // sg.updateBuffer(state.bind.vertex_buffers[1], .{
    //     .ptr = &state.pos[0],
    //     .size = @as(usize, @intCast(state.cur_num_particles)) * @sizeOf(Vec3),
    // });

    // model-view-projection matrix
    const proj = Mat4.perspective(
        std.math.degreesToRadians(60.0),
        sokol.app.widthf() / sokol.app.heightf(),
        0.01,
        50.0,
    );
    const view = Mat4.lookAt(
        .{ .x = 0.0, .y = 1.5, .z = 12.0 },
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .{ .x = 0.0, .y = 1.0, .z = 0.0 },
    );
    const view_proj = view.mul(proj);
    state.ry += 60.0 * frame_time;
    const vs_params = shader.VsParams{
        .VP = Mat4.rotate(
            state.ry,
            .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        ).mul(view_proj).m,
    };

    // ...and draw
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    sg.applyPipeline(state.pip);
    sg.applyBindings(state.bind);
    sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));
    sg.draw(0, 36, 4);
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        // .event_cb = dbgui.event,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .window_title = "Instancing (sokol-app)",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
