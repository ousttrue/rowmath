//------------------------------------------------------------------------------
//  ozz-anim-sapp.cc
//
//  https://guillaumeblanc.github.io/ozz-animation/
//
//  Port of the ozz-animation "Animation Playback" sample. Use sokol-gl
//  for debug-rendering the animated character skeleton (no skinning).
//------------------------------------------------------------------------------
const std = @import("std");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const Quat = rowmath.Quat;
const MouseCamera = rowmath.MouseCamera;
const InputState = rowmath.InputState;
const sokol = @import("sokol");
const sg = sokol.gfx;
const simgui = sokol.imgui;
const ig = @import("cimgui");
const cuber = @import("cuber");
const Cuber = cuber.Cuber;
const utils = @import("utils");
const ozz_draw = @import("ozz_draw.zig");
const c = @import("ozz_wrap.zig");
const framework = @import("ozz_sokol_framework");
const Skeleton = framework.Skeleton;

const state = struct {
    var input: InputState = .{};
    var camera: MouseCamera = .{};
    var pass_action = sg.PassAction{};
    var cuber = Cuber(512){};
    var ozz: ?*c.ozz_t = null;
    var ozz_state = framework.State{};
};

// io buffers for skeleton and animation data files, we know the max file size upfront
var skel_data_buffer = [1]u8{0} ** (4 * 1024);
var anim_data_buffer = [1]u8{0} ** (32 * 1024);

const Header = struct {
    unaligned: *anyopaque,
    size: usize,
};

fn calc_align(_address: usize, _alignment: usize) usize {
    return (_address + _alignment - 1) & @subWithOverflow(0, _alignment)[0];
}

export fn Allocate(_size: usize, _alignment: usize) ?*anyopaque {
    // Allocates enough memory to store the header + required alignment space.
    const to_allocate: usize = _size + @sizeOf(Header) + _alignment - 1;
    std.debug.print("{} => {}", .{ _size, to_allocate });
    const unaligned = std.c.malloc(to_allocate) orelse {
        return null;
    };
    const addr: usize = calc_align(@intFromPtr(unaligned) + @sizeOf(Header), _alignment);
    const aligned: *anyopaque = @ptrFromInt(addr);
    // std.debug.assert(aligned + _size <= unaligned + to_allocate);  // Don't overrun.
    // Set the header
    const header: *Header = @ptrFromInt(addr - @sizeOf(Header));
    // assert(reinterpret_cast<char*>(header) >= unaligned);
    header.unaligned = unaligned;
    header.size = _size;
    // Allocation's succeeded.
    // ++allocation_count_;
    return aligned;
}

export fn Deallocate(_block: ?*anyopaque) void {
    if (_block != null) {
        const addr = @intFromPtr(_block) - @sizeOf(Header);
        const header: *Header = @ptrFromInt(addr);
        std.c.free(header.unaligned);
    }
}

export fn init() void {
    state.ozz = c.OZZ_init();
    state.ozz_state.time.factor = 1.0;
    // c.OZZ_set_allocator(&c.my_aligned_alloc, &c.my_free);
    c.OZZ_set_allocator(&Allocate, &Deallocate);

    // setup sokol-gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // setup sokol-fetch
    sokol.fetch.setup(.{
        .max_requests = 2,
        .num_channels = 1,
        .num_lanes = 2,
        .logger = .{ .func = sokol.log.func },
    });

    // setup sokol-gl
    sokol.gl.setup(.{
        .sample_count = sokol.app.sampleCount(),
        .logger = .{ .func = sokol.log.func },
    });
    framework.gl_init();

    // setup sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // initialize pass action for default-pass
    state.pass_action.colors[0].load_action = .CLEAR;
    state.pass_action.colors[0].clear_value = .{ .r = 0.0, .g = 0.1, .b = 0.2, .a = 1.0 };

    // initialize camera helper
    state.camera.init();
    state.cuber.init();

    // start loading the skeleton and animation files
    _ = sokol.fetch.send(.{
        .path = "pab_skeleton.ozz",
        .callback = skeleton_data_loaded,
        .buffer = sokol.fetch.asRange(&skel_data_buffer),
    });

    _ = sokol.fetch.send(.{
        .path = "pab_crossarms.ozz",
        .callback = animation_data_loaded,
        .buffer = sokol.fetch.asRange(&anim_data_buffer),
    });
}

const TRS = struct {
    t: Vec3 = undefined,
    r: Quat = undefined,
    s: Vec3 = undefined,
};

fn makeShape(i: usize, j: usize) Mat4 {
    var head: TRS = undefined;
    c.OZZ_skeleton_trs(state.ozz, i, &head.t.x, &head.r.x, &head.s.x);
    var tail: TRS = undefined;
    c.OZZ_skeleton_trs(state.ozz, j, &tail.t.x, &tail.r.x, &tail.s.x);

    const n = 0.03;

    const center = Mat4.translate(.{ .x = 0.5, .y = 0, .z = 0 });

    const size = Mat4.scale(.{
        .x = tail.t.x,
        .y = n,
        .z = n,
    });

    // const r = head.r.inverse().matrix();

    return center.mul(size);
}

export fn frame() void {
    sokol.fetch.dowork();

    state.ozz_state.time.frame = sokol.app.frameDuration();

    // update camera
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.camera.frame(state.input);
    state.input.mouse_wheel = 0;

    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = state.ozz_state.time.frame,
        .dpi_scale = sokol.app.dpiScale(),
    });
    draw_ui();

    // if (state.loaded.skeleton and state.loaded.animation) {
    //     // update skeleton
    //     if (!state.time.paused) {
    //         state.time.absolute += state.time.frame * state.time.factor;
    //     }
    //
    //     // convert current time to animation ration (0.0 .. 1.0)
    //     const anim_duration = c.OZZ_duration(state.ozz);
    //     if (!state.time.anim_ratio_ui_override) {
    //         state.time.anim_ratio = std.math.mod(
    //             f32,
    //             @as(f32, @floatCast(state.time.absolute)) / anim_duration,
    //             1.0,
    //         ) catch unreachable;
    //     }
    //
    //     c.OZZ_eval_animation(state.ozz, state.time.anim_ratio);
    //
    //     const num_joints = c.OZZ_num_joints(state.ozz);
    //     const joint_parents = c.OZZ_joint_parents(state.ozz);
    //     const matrices: [*]const Mat4 = @ptrCast(c.OZZ_model_matrices(state.ozz));
    //     for (0..num_joints) |i| {
    //         for (joint_parents[0..num_joints], 0..) |parent, j| {
    //             if (@as(usize, @intCast(parent)) == i) {
    //                 const shape = makeShape(i, j);
    //                 state.cuber.instances[i] = .{ .matrix = shape.mul(matrices[i]) };
    //                 break;
    //             }
    //         }
    //     }
    //     state.cuber.upload(@intCast(num_joints));
    // }

    // draw axis & grid
    framework.gl_begin(.{
        .view = state.camera.camera.transform.worldToLocal(),
        .projection = state.camera.camera.projection_matrix,
    });
    framework.draw_axis();
    framework.draw_grid(20, 1.0);
    framework.gl_end();

    {
        sg.beginPass(.{
            .action = state.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        defer sg.endPass();

        {
            // utils.gl_begin(.{
            //     .projection = state.camera.projectionMatrix(),
            //     .view = state.camera.viewMatrix(),
            // });
            // defer utils.gl_end();
            //
            // // grid
            // utils.draw_lines(&rowmath.lines.Grid(5).lines);
            // skeleton
            // if (state.loaded.skeleton) {
            //     ozz_draw.draw_skeleton(state.ozz);
            // }
            framework.gl_draw();
            if (state.ozz_state.loaded.skeleton) |skeleton| {
                if (state.ozz_state.loaded.animation) {
                    const anim_ratio = state.ozz_state.update(c.OZZ_duration(state.ozz));
                    // const anim_duration = ;
                    c.OZZ_eval_animation(state.ozz, anim_ratio);
                }

                const matrices: [*]const Mat4 = @ptrCast(c.OZZ_model_matrices(state.ozz));
                skeleton.draw(
                    state.camera.viewProjectionMatrix(),
                    matrices,
                );
            }
        }

        sokol.gl.draw();
        simgui.render();
        state.cuber.draw(state.camera.viewProjectionMatrix());
    }
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    if (simgui.handleEvent(e.*)) {
        return;
    }
    utils.handle_camera_input(e, &state.input);
}

export fn cleanup() void {
    simgui.shutdown();
    sokol.gl.shutdown();
    sokol.fetch.shutdown();
    sg.shutdown();

    // free C++ objects early, otherwise ozz-animation complains about memory leaks
    c.OZZ_shutdown(state.ozz);
}

fn draw_ui() void {
    ig.igSetNextWindowPos(.{ .x = 20, .y = 20 }, ig.ImGuiCond_Once, .{ .x = 0, .y = 0 });
    ig.igSetNextWindowSize(.{ .x = 220, .y = 150 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowBgAlpha(0.35);
    if (ig.igBegin(
        "Controls",
        null,
        ig.ImGuiWindowFlags_NoDecoration | ig.ImGuiWindowFlags_AlwaysAutoResize,
    )) {
        if (state.ozz_state.loaded.failed) {
            ig.igText("Failed loading character data!");
        } else {
            ig.igText("Camera Controls:");
            ig.igText("  LMB + Mouse Move: Look");
            ig.igText("  Mouse Wheel: Zoom");
            // ig.igSliderFloat(
            //     "Distance",
            //     &state.camera.distance,
            //     state.camera.min_dist,
            //     state.camera.max_dist,
            //     "%.1f",
            //     1.0,
            // );
            // ig.igSliderFloat(
            //     "Latitude",
            //     &state.camera.latitude,
            //     state.camera.min_lat,
            //     state.camera.max_lat,
            //     "%.1f",
            //     1.0,
            // );
            // ig.igSliderFloat(
            //     "Longitude",
            //     &state.camera.longitude,
            //     0.0,
            //     360.0,
            //     "%.1f",
            //     1.0,
            // );
            ig.igSeparator();
            ig.igText("Time Controls:");
            _ = ig.igCheckbox("Paused", &state.ozz_state.time.paused);
            _ = ig.igSliderFloat("Factor", &state.ozz_state.time.factor, 0.0, 10.0, "%.1f", 1.0);
            if (ig.igSliderFloat(
                "Ratio",
                &state.ozz_state.time.anim_ratio,
                0.0,
                1.0,
                null,
                0,
            )) {
                state.ozz_state.time.anim_ratio_ui_override = true;
            }
            if (ig.igIsItemDeactivatedAfterEdit()) {
                state.ozz_state.time.anim_ratio_ui_override = false;
            }
        }
    }
    ig.igEnd();
}

export fn skeleton_data_loaded(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        if (c.OZZ_load_skeleton(state.ozz, response.*.data.ptr, response.*.data.size)) {
            const num_joints = c.OZZ_num_joints(state.ozz);
            var skeleton = Skeleton.init(std.heap.c_allocator, num_joints) catch unreachable;
            const parents = c.OZZ_joint_parents(state.ozz);
            const names: [*]const [*:0]const u8 = @ptrCast(c.OZZ_joint_names(state.ozz));
            for (0..num_joints) |i| {
                const parent: u16 = parents[i];
                skeleton.joints[i] = .{
                    .name = names[i],
                    .parent = if (std.math.maxInt(u16) != parent) parent else null,
                    .is_leaf = c.OZZ_joint_is_leaf(state.ozz, i),
                };
            }
            state.ozz_state.loaded.skeleton = skeleton;
        } else {
            state.ozz_state.loaded.failed = true;
        }
    } else if (response.*.failed) {
        state.ozz_state.loaded.failed = true;
    }
}

export fn animation_data_loaded(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        if (c.OZZ_load_animation(state.ozz, response.*.data.ptr, response.*.data.size)) {
            state.ozz_state.loaded.animation = true;
        } else {
            state.ozz_state.loaded.failed = true;
        }
    } else if (response.*.failed) {
        state.ozz_state.loaded.failed = true;
    }
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
        .window_title = "ozz-anim-sapp.cc",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
