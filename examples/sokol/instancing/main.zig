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
const utils = @import("utils");

const MAX_PARTICLES = 4;

const Instance = struct {
    matrix: Mat4 = Mat4.identity,
    positive_face_flag: [4]f32 = .{ 1, 2, 3, 0 },
    negative_face_flag: [4]f32 = .{ 4, 5, 6, 0 },
};
const state = struct {
    var pass_action = sg.PassAction{};

    var input = rowmath.InputState{};
    var camera = rowmath.Camera{};
    var drag_right = rowmath.CameraRightDragHandler{};
    var drag_middle = rowmath.CameraMiddleDragHandler{};

    var pip = sg.Pipeline{};
    var bind = sg.Bindings{};
    // var ry: f32 = 0;
    // var cur_num_particles: i32 = 0;
    var instances: [MAX_PARTICLES]Instance = undefined;

    var fs_params: shader.FsParams = undefined;
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.drag_right = rowmath.makeYawPitchHandler(.right, &state.camera);
    state.drag_middle = rowmath.makeScreenMoveHandler(.middle, &state.camera);

    // a pass action for the default render pass
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
    };

    var builder = MeshBuilder.init(std.heap.c_allocator, false);
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

export fn frame() void {
    // update projection
    state.camera.resize(state.input.screen_size());

    // update transform
    state.drag_right.frame(state.input);
    state.drag_middle.frame(state.input);
    state.camera.dolly(state.input.mouse_wheel);
    // consumed
    state.input.mouse_wheel = 0;
    state.camera.updateTransform();

    // const frame_time: f32 = @floatCast(sokol.app.frameDuration());
    // emit new particles
    // for (0..NUM_PARTICLES_EMITTED_PER_FRAME) |_| {
    //     if (state.cur_num_particles < MAX_PARTICLES) {
    //         state.instances[@intCast(state.cur_num_particles)] = .{
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
    const n = 2;
    state.instances[0] = .{ .matrix = Mat4.translate(.{ .x = -n, .y = 0, .z = -n }) };
    state.instances[1] = .{ .matrix = Mat4.translate(.{ .x = n, .y = 0, .z = -n }) };
    state.instances[2] = .{ .matrix = Mat4.translate(.{ .x = n, .y = 0, .z = n }) };
    state.instances[3] = .{ .matrix = Mat4.translate(.{ .x = -n, .y = 0, .z = n }) };
    sg.updateBuffer(state.bind.vertex_buffers[1], sg.asRange(&state.instances));

    // ...and draw
    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });

    {
        utils.gl_begin(.{
            .projection = state.camera.projection_matrix,
            .view = state.camera.transform.worldToLocal(),
        });
        utils.draw_lines(&rowmath.lines.Grid(5).lines);
        utils.gl_end();
    }

    {
        sg.applyPipeline(state.pip);
        sg.applyBindings(state.bind);
        const vs_params = shader.VsParams{
            .VP = state.camera.viewProjectionMatrix().m,
        };
        sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));
        sg.applyUniforms(.FS, shader.SLOT_fs_params, sg.asRange(&state.fs_params));
        sg.draw(0, 36, 4);
    }

    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    switch (e.*.type) {
        .RESIZED => {
            state.input.screen_width = @floatFromInt(e.*.window_width);
            state.input.screen_height = @floatFromInt(e.*.window_height);
        },
        .MOUSE_DOWN => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    state.input.mouse_left = true;
                },
                .RIGHT => {
                    state.input.mouse_right = true;
                },
                .MIDDLE => {
                    state.input.mouse_middle = true;
                },
                .INVALID => {},
            }
        },
        .MOUSE_UP => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    state.input.mouse_left = false;
                },
                .RIGHT => {
                    state.input.mouse_right = false;
                },
                .MIDDLE => {
                    state.input.mouse_middle = false;
                },
                .INVALID => {},
            }
        },
        .MOUSE_MOVE => {
            state.input.mouse_x = e.*.mouse_x;
            state.input.mouse_y = e.*.mouse_y;
        },
        .MOUSE_SCROLL => {
            state.input.mouse_wheel = e.*.scroll_y;
        },
        else => {},
    }
}

export fn cleanup() void {
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .window_title = "Instancing (sokol-app)",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
