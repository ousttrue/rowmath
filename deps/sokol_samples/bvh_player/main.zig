const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const cimgui = @import("cimgui");
const rowmath = @import("rowmath");
const InputState = rowmath.InputState;
const OrbitCamera = rowmath.OrbitCamera;
const Mat4 = rowmath.Mat4;
const Vec3 = rowmath.Vec3;
const Quat = rowmath.Quat;
const bvh = rowmath.bvh;
const cozz = @import("cozz");
const Skeleton = cozz.framework.Skeleton;

// io buffers for skeleton and animation data files, we know the max file size upfront
var bvh_buffer = [1]u8{0} ** (4 * 1024 * 1024);

const state = struct {
    var input: InputState = .{};
    var orbit: OrbitCamera = .{};
    var ozz: ?*cozz.ozz_t = null;
    var pass_action = sg.PassAction{};
    var ozz_state = cozz.framework.State{};
};

export fn init() void {
    state.ozz = cozz.OZZ_init();
    state.ozz_state.time.factor = 1.0;

    // setup sokol-gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .sample_count = sokol.app.sampleCount(),
        .logger = .{ .func = sokol.log.func },
    });
    cozz.framework.gl_init();

    // setup sokol-imgui
    sokol.imgui.setup(.{ .logger = .{ .func = sokol.log.func } });

    // initialize pass action for default-pass
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.1, .b = 0.2, .a = 1.0 },
    };

    state.orbit.init();

    // setup sokol-fetch
    sokol.fetch.setup(.{
        .max_requests = 2,
        .num_channels = 1,
        .num_lanes = 2,
        .logger = .{ .func = sokol.log.func },
    });
    // start loading the skeleton and animation files
    _ = sokol.fetch.send(.{
        .path = "univrm.bvh",
        .callback = bvh_loaded,
        .buffer = sokol.fetch.asRange(&bvh_buffer),
    });
}

export fn bvh_loaded(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        std.debug.print("{}bytes\n", .{response.*.data.size});

        const p: [*]const u8 = @ptrCast(response.*.data.ptr);
        const src: []const u8 = p[0..response.*.data.size];

        // const src = bvh.BvhTokenizer.test_data;
        var bvh_fromat = bvh.BvhFormat.init(std.heap.c_allocator, src);
        defer bvh_fromat.deinit();
        if (bvh_fromat.parse() catch {
            @panic("bvh parse catched");
        }) {
            std.debug.print("{}joints\n", .{bvh_fromat.joints.items.len});
            build(&bvh_fromat);
        } else {
            @panic("bvh parse failed");
        }
    } else if (response.*.failed) {
        @panic("bvh fetch failed");
    }
}

fn create_skeleton(src: *bvh.BvhFormat) void {
    for (src.joints.items, 0..) |joint, i| {
        const path = src.jointPath(@intCast(i));
        std.debug.print("{s} => {any}\n", .{
            joint.name, path,
        });
        _ = cozz.OZZ_raw_skeleton_add_trs(
            state.ozz,
            if (path.len > 0) &path[0] else null,
            &joint.name[0],
            &joint.local_offset.x,
            &Quat.identity.x,
            &Vec3.one.x,
        );
    }
}

fn create_animation(skeleton: Skeleton, src: *bvh.BvhFormat) void {
    const kDuration = src.frame_time * @as(f32, @floatFromInt(src.frame_count));
    cozz.OZZ_raw_animation(state.ozz, kDuration, skeleton.joints.len);
    var time: f32 = 0;
    for (0..src.frame_count) |i| {
        const begin = i * src.channel_count;
        const bvh_frame = bvh.BvhFrame.init(src.frames.items[begin .. begin + src.channel_count]);
        for (src.joints.items, 0..) |joint, j| {
            const transform = bvh_frame.resolve(joint.channels);
            // cm to meter
            const pos = transform.translation.scale(0.01);
            cozz.OZZ_track_push_rotation(state.ozz, j, time, &transform.rotation.x);
            cozz.OZZ_track_push_translation(state.ozz, j, time, &pos.x);
        }
        time += src.frame_time;
    }
}

// Procedurally builds millipede skeleton and walk animation
fn build(src: *bvh.BvhFormat) void {
    // Initializes the root. The root pointer will change from a spine to the
    // next for each slice.
    create_skeleton(src);
    // const num_joints = cozz.OZZ_raw_num_joints(state.ozz);

    // Build the run time skeleton.
    if (!cozz.OZZ_raw_build(state.ozz)) {
        @panic("OZZ_raw_build");
    }
    const num_joints = cozz.OZZ_num_joints(state.ozz);
    // std.debug.print("create {}!\n", .{num_joints});
    var skeleton = Skeleton.init(std.heap.c_allocator, num_joints) catch unreachable;
    const parents = cozz.OZZ_joint_parents(state.ozz);
    const names: [*]const [*:0]const u8 = @ptrCast(cozz.OZZ_joint_names(state.ozz));
    for (0..num_joints) |i| {
        const parent: u16 = parents[i];
        skeleton.joints[i] = .{
            .name = names[i],
            .parent = if (std.math.maxInt(u16) != parent) parent else null,
            .is_leaf = cozz.OZZ_joint_is_leaf(state.ozz, i),
        };
    }
    state.ozz_state.loaded.skeleton = skeleton;

    // Build a walk animation.
    // RawAnimation raw_animation;
    create_animation(skeleton, src);
    // Build the run time animation from the raw animation.
    if (!cozz.OZZ_animation_build(state.ozz)) {
        @panic("OZZ_animation_build");
    }
    state.ozz_state.loaded.animation = true;
}

export fn frame() void {
    sokol.fetch.dowork();

    const fb_width = sokol.app.width();
    const fb_height = sokol.app.height();
    state.ozz_state.time.frame = sokol.app.frameDuration();

    // update orbit
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.orbit.frame(state.input);
    state.input.mouse_wheel = 0;

    // draw ui
    sokol.imgui.newFrame(.{
        .width = fb_width,
        .height = fb_height,
        .delta_time = state.ozz_state.time.frame,
        .dpi_scale = sokol.app.dpiScale(),
    });
    cozz.framework.draw_ui(&state.ozz_state, &state.orbit);

    // draw axis & grid
    cozz.framework.gl_begin(.{
        .view = state.orbit.camera.transform.worldToLocal(),
        .projection = state.orbit.camera.projection.matrix,
    });
    cozz.framework.draw_axis();
    cozz.framework.draw_grid(20, 1.0);
    cozz.framework.gl_end();

    // render
    {
        sg.beginPass(.{
            .action = state.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        defer sg.endPass();

        cozz.framework.gl_draw();
        if (state.ozz_state.loaded.skeleton) |skeleton| {
            if (state.ozz_state.loaded.animation) {
                const anim_ratio = state.ozz_state.update(cozz.OZZ_duration(state.ozz));
                // const anim_duration = ;
                cozz.OZZ_eval_animation(state.ozz, anim_ratio);
            }

            const matrices: [*]const Mat4 = @ptrCast(cozz.OZZ_model_matrices(state.ozz));
            skeleton.draw(
                state.orbit.viewProjectionMatrix(),
                matrices,
            );
        }

        sokol.imgui.render();
    }
    sg.commit();
}

export fn input(e: [*c]const sokol.app.Event) void {
    if (sokol.imgui.handleEvent(e.*)) {
        return;
    }
    cozz.framework.handle_camera_input(e, &state.input);
}

export fn cleanup() void {
    sokol.fetch.shutdown();
    sokol.imgui.shutdown();
    sokol.gl.shutdown();
    sg.shutdown();

    cozz.OZZ_shutdown(state.ozz);
    state.ozz = null;
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = input,
        .width = 800,
        .height = 600,
        .sample_count = 4,
        .window_title = "cozz_millipede",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
