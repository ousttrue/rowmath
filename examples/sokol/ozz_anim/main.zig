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
const MouseCamera = rowmath.MouseCamera;
const InputState = rowmath.InputState;
const sokol = @import("sokol");
const sg = sokol.gfx;
const simgui = sokol.imgui;
const ig = @import("cimgui");

const ozz_wrap = @import("ozz_wrap.zig");

const state = struct {
    var ozz: *anyopaque = undefined;
    const loaded = struct {
        var skeleton = false;
        var animation = false;
        var failed = false;
    };
    var pass_action = sg.PassAction{};
    var camera: MouseCamera = .{};
    var input: InputState = .{};
    const time = struct {
        var frame: f64 = 0;
        var absolute: f64 = 0;
        var factor: f32 = 0;
        var anim_ratio: f32 = 0;
        var anim_ratio_ui_override = false;
        var paused = false;
    };
};

// io buffers for skeleton and animation data files, we know the max file size upfront
var skel_data_buffer = [1]u8{0} ** (4 * 1024);
var anim_data_buffer = [1]u8{0} ** (32 * 1024);

export fn init() void {
    state.ozz = ozz_wrap.OZZ_init();
    state.time.factor = 1.0;

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

    // setup sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    // initialize pass action for default-pass
    state.pass_action.colors[0].load_action = .CLEAR;
    state.pass_action.colors[0].clear_value = .{ .r = 0.0, .g = 0.1, .b = 0.2, .a = 1.0 };

    // initialize camera helper
    state.camera.init();

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

export fn frame() void {
    sokol.fetch.dowork();

    state.time.frame = sokol.app.frameDuration();
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.camera.frame(state.input);
    state.input.mouse_wheel = 0;

    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = state.time.frame,
        .dpi_scale = sokol.app.dpiScale(),
    });
    draw_ui();

    if (state.loaded.skeleton and state.loaded.animation) {
        if (!state.time.paused) {
            state.time.absolute += state.time.frame * state.time.factor;
        }

        // convert current time to animation ration (0.0 .. 1.0)
        const anim_duration = ozz_wrap.OZZ_duration(state.ozz);
        if (!state.time.anim_ratio_ui_override) {
            state.time.anim_ratio = std.math.mod(
                f32,
                @as(f32, @floatCast(state.time.absolute)) / anim_duration,
                1.0,
            ) catch unreachable;
        }

        ozz_wrap.OZZ_eval_animation(state.ozz, state.time.anim_ratio);
        draw_skeleton(state.ozz);
    }

    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    sokol.gl.draw();
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
    if (simgui.handleEvent(e.*)) {
        return;
    }
    switch (e.*.type) {
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
    simgui.shutdown();
    sokol.gl.shutdown();
    sokol.fetch.shutdown();
    sg.shutdown();

    // free C++ objects early, otherwise ozz-animation complains about memory leaks
    ozz_wrap.OZZ_shutdown(state.ozz);
}

fn draw_vec(vec: Vec3) void {
    sokol.gl.v3f(vec.x, vec.y, vec.z);
}

fn draw_line(v0: Vec3, v1: Vec3) void {
    draw_vec(v0);
    draw_vec(v1);
}

// this draws a wireframe 3d rhombus between the current and parent joints
fn draw_joint(ozz: *anyopaque, joint_index: usize, parent_joint_index: u16) void {
    if (parent_joint_index == std.math.maxInt(u16)) {
        return;
    }

    const m0 = ozz_wrap.OZZ_model_matrices(ozz, joint_index).*;
    const m1 = ozz_wrap.OZZ_model_matrices(ozz, @intCast(parent_joint_index)).*;

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

fn draw_skeleton(ozz: *anyopaque) void {
    if (!state.loaded.skeleton) {
        return;
    }
    sokol.gl.defaults();
    sokol.gl.matrixModeProjection();
    sokol.gl.loadMatrix(&state.camera.projectionMatrix().m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.loadMatrix(&state.camera.viewMatrix().m[0]);

    const num_joints = ozz_wrap.OZZ_num_joints(ozz);
    const joint_parents = ozz_wrap.OZZ_joint_parents(ozz);
    sokol.gl.beginLines();

    sokol.gl.c3f(1.0, 0.0, 0.0);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(1, 0, 0);
    sokol.gl.c3f(0.0, 1.0, 0.0);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(0, 1, 0);
    sokol.gl.c3f(0.0, 0.0, 1.0);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(0, 0, 1);

    for (0..num_joints) |joint_index| {
        if (joint_index == std.math.maxInt(u16)) {
            continue;
        }
        draw_joint(ozz, joint_index, joint_parents[joint_index]);
    }
    sokol.gl.end();
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
        if (state.loaded.failed) {
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
            _ = ig.igCheckbox("Paused", &state.time.paused);
            _ = ig.igSliderFloat("Factor", &state.time.factor, 0.0, 10.0, "%.1f", 1.0);
            if (ig.igSliderFloat(
                "Ratio",
                &state.time.anim_ratio,
                0.0,
                1.0,
                null,
                0,
            )) {
                state.time.anim_ratio_ui_override = true;
            }
            if (ig.igIsItemDeactivatedAfterEdit()) {
                state.time.anim_ratio_ui_override = false;
            }
        }
    }
    ig.igEnd();
}

export fn skeleton_data_loaded(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        if (ozz_wrap.OZZ_load_skeleton(
            state.ozz,
            response.*.data.ptr,
            response.*.data.size,
        )) {
            state.loaded.skeleton = true;
        } else {
            state.loaded.failed = true;
        }
    } else if (response.*.failed) {
        state.loaded.failed = true;
    }
}

export fn animation_data_loaded(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        if (ozz_wrap.OZZ_load_animation(
            state.ozz,
            response.*.data.ptr,
            response.*.data.size,
        )) {
            state.loaded.animation = true;
        } else {
            state.loaded.failed = true;
        }
    } else if (response.*.failed) {
        state.loaded.failed = true;
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
