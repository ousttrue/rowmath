const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const cimgui = @import("cimgui");
const rowmath = @import("rowmath");
const InputState = rowmath.InputState;
const MouseCamera = rowmath.MouseCamera;
const Mat4 = rowmath.Mat4;
const Vec3 = rowmath.Vec3;
const Quat = rowmath.Quat;
const cozz = @import("cozz");
const Skeleton = cozz.framework.Skeleton;

const slice_count_ = 26;

// The following constants are used to define the millipede skeleton and
// animation.
// Skeleton constants.
const kTransUp = Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };
const kTransDown = Vec3{ .x = 0.0, .y = 0.0, .z = 1.0 };
const kTransFoot = Vec3{ .x = 1.0, .y = 0.0, .z = 0.0 };

const kRotLeftUp =
    Quat.axisAngle(Vec3.up, -std.math.pi / 2.0);
const kRotLeftDown =
    Quat.axisAngle(Vec3.right, std.math.pi / 2.0).mul(Quat.axisAngle(Vec3.up, -std.math.pi / 2.0));
const kRotRightUp =
    Quat.axisAngle(Vec3.up, std.math.pi / 2.0);
const kRotRightDown =
    Quat.axisAngle(Vec3.right, std.math.pi / 2.0).mul(Quat.axisAngle(Vec3.up, -std.math.pi / 2.0));

// Animation constants.
const kDuration: f32 = 6.0;
const kSpinLength: f32 = 0.5;
const kWalkCycleLength: f32 = 2.0;
const kWalkCycleCount = 4;
const kSpinLoop: f32 = 2.0 * kWalkCycleCount * kWalkCycleLength / kSpinLength;

// Defines a raw translation key frame.
const TranslationKey = struct {
    // Key frame time.
    time: f32,

    // Key frame value.
    // typedef math::Float3 Value;
    value: Vec3,

    // Provides identity transformation for a translation key.
    // static math::Float3 identity() { return math::Float3::zero(); }
};

const kPrecomputedKeys = [_]TranslationKey{
    .{ .time = 0.0 * kDuration, .value = .{ .x = 0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.125 * kDuration, .value = .{ .x = -0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.145 * kDuration, .value = .{ .x = -0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.23 * kDuration, .value = .{ .x = 0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.25 * kDuration, .value = .{ .x = 0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.375 * kDuration, .value = .{ .x = -0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.395 * kDuration, .value = .{ .x = -0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.48 * kDuration, .value = .{ .x = 0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.5 * kDuration, .value = .{ .x = 0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.625 * kDuration, .value = .{ .x = -0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.645 * kDuration, .value = .{ .x = -0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.73 * kDuration, .value = .{ .x = 0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.75 * kDuration, .value = .{ .x = 0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.875 * kDuration, .value = .{ .x = -0.25 * kWalkCycleLength, .y = 0.0, .z = 0.0 } },
    .{ .time = 0.895 * kDuration, .value = .{ .x = -0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
    .{ .time = 0.98 * kDuration, .value = .{ .x = 0.17 * kWalkCycleLength, .y = 0.3, .z = 0.0 } },
};
// const kPrecomputedKeyCount = kPrecomputedKeys.len;

const state = struct {
    var input: InputState = .{};
    var camera: MouseCamera = .{};
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

    state.camera.init();

    build();
}

const JointPathPointer = [*:std.math.maxInt(u16)]const u16;
// const JointPath= [:std.math.maxInt(u16)];
const Current = struct {
    list: std.ArrayList(u16),

    fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .list = std.ArrayList(u16).init(allocator),
        };
    }

    fn set(self: *@This(), ptr: JointPathPointer) []u16 {
        self.list.clearRetainingCapacity();
        for (std.mem.span(ptr)) |i| {
            self.list.append(i) catch unreachable;
        }
        self.list.append(std.math.maxInt(u16)) catch unreachable;
        return self.list.items;
    }
};

/// A millipede slice is 2 legs and a spine.
/// Each slice is made of 7 joints, organized as follows.
///          * root
///             |
///           spine                                   spine
///         |       |                                   |
///     left_up    right_up        left_down - left_u - . - right_u - right_down
///       |           |                  |                                    |
///   left_down     right_down     left_foot         * root            right_foot
///     |               |
/// left_foot        right_foot
fn create_skeleton() void {
    const root_translation = Vec3{ .x = 0.0, .y = 1.0, .z = -slice_count_ * kSpinLength };
    const root_rotation = Quat.identity;
    const root_scale = Vec3.one;

    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var currentList = Current.init(fba.allocator());

    const _root = cozz.OZZ_raw_skeleton_add_trs(
        state.ozz,
        null,
        "root",
        &root_translation.x,
        &root_rotation.x,
        &root_scale.x,
    );
    var root = currentList.set(@ptrCast(_root));

    var number: [32]u8 = undefined;
    for (0..slice_count_) |i| {
        // Left leg.
        // RawSkeleton::Joint& lu = root->children[0];
        var lu: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "lu{}", .{i}) catch unreachable;
            const translation = kTransUp;
            const rotation = kRotLeftUp;
            const scale = Vec3.one;
            lu = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &root[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        //   lu.children.resize(1);
        //   RawSkeleton::Joint& ld = lu.children[0];
        var ld: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "ld{}", .{i}) catch unreachable;
            const translation = kTransDown;
            const rotation = kRotLeftDown;
            const scale = Vec3.one;
            ld = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &lu[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        //   ld.children.resize(1);
        //   RawSkeleton::Joint& lf = ld.children[0];
        var lf: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "lf{}", .{i}) catch unreachable;
            const translation = Vec3.right;
            const rotation = Quat.identity;
            const scale = Vec3.one;
            lf = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &ld[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        // Right leg.
        //   RawSkeleton::Joint& ru = root->children[1];
        var ru: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "ru{}", .{i}) catch unreachable;
            const translation = kTransUp;
            const rotation = kRotRightUp;
            const scale = Vec3.one;
            ru = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &root[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        //   ru.children.resize(1);
        //   RawSkeleton::Joint& rd = ru.children[0];
        var rd: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "rd{}", .{i}) catch unreachable;
            const translation = kTransDown;
            const rotation = kRotRightDown;
            const scale = Vec3.one;
            rd = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &ru[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        //   rd.children.resize(1);
        //   RawSkeleton::Joint& rf = rd.children[0];
        var rf: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "rf{}", .{i}) catch unreachable;
            const translation = Vec3.right;
            const rotation = Quat.identity;
            const scale = Vec3.one;
            rf = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &rd[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        // Spine.
        //   RawSkeleton::Joint& sp = root->children[2];
        var sp: [*:std.math.maxInt(u16)]const u16 = undefined;
        {
            const name = std.fmt.bufPrintZ(&number, "sp{}", .{i}) catch unreachable;
            const translation = Vec3{ .x = 0.0, .y = 0.0, .z = kSpinLength };
            const rotation = Quat.identity;
            const scale = Vec3.one;
            sp = @ptrCast(cozz.OZZ_raw_skeleton_add_trs(
                state.ozz,
                &root[0],
                &name[0],
                &translation.x,
                &rotation.x,
                &scale.x,
            ));
        }

        root = currentList.set(sp);
    }
}

fn create_animation(skeleton: Skeleton) void {
    cozz.OZZ_raw_animation(state.ozz, kDuration, skeleton.joints.len);

    for (skeleton.joints, 0..) |joint, i| {
        // RawAnimation::JointTrack& track = _animation->tracks[i];
        // const char* joint_name = skeleton_->joint_names()[i];

        if (std.mem.startsWith(
            u8,
            std.mem.span(joint.name),
            "ld",
        ) or std.mem.startsWith(
            u8,
            std.mem.span(joint.name),
            "rd",
        )) {
            const left = joint.name[0] == 'l'; // First letter of "ld".

            // Copy original keys while taking into consideration the spine number
            // as a phase.
            const spine_number = std.fmt.parseInt(i32, std.mem.span(joint.name)[2..], 0) catch unreachable;
            const offset = kDuration * @as(f32, @floatFromInt(slice_count_ - spine_number)) / kSpinLoop;
            const phase = std.math.mod(f32, offset, kDuration) catch unreachable;

            // Loop to find animation start.
            var i_offset: usize = 0;
            while (i_offset < kPrecomputedKeys.len and
                kPrecomputedKeys[i_offset].time < phase)
            {
                i_offset += 1;
            }

            // Push key with their corrected time.
            // track.translations.reserve(kPrecomputedKeyCount);
            for (i_offset..i_offset + kPrecomputedKeys.len) |j| {
                const rkey = kPrecomputedKeys[j % kPrecomputedKeys.len];
                var new_time = rkey.time - phase;
                if (new_time < 0.0) {
                    new_time = kDuration - phase + rkey.time;
                }

                if (left) {
                    const tkey = kTransDown.add(rkey.value);
                    cozz.OZZ_track_push_translation(state.ozz, i, new_time, &tkey.x);
                } else {
                    const tkey = Vec3{
                        .x = kTransDown.x - rkey.value.x,
                        .y = kTransDown.y + rkey.value.y,
                        .z = kTransDown.z + rkey.value.z,
                    };
                    cozz.OZZ_track_push_translation(state.ozz, i, new_time, &tkey.x);
                }
            }

            // Pushes rotation key-frame.
            if (left) {
                const rkey = kRotLeftDown;
                cozz.OZZ_track_push_rotation(state.ozz, i, 0, &rkey.x);
            } else {
                const rkey = kRotRightDown;
                cozz.OZZ_track_push_rotation(state.ozz, i, 0, &rkey.x);
            }
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "lu")) {
            const tkey = kTransUp;
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &tkey.x);
            const rkey = kRotLeftUp;
            cozz.OZZ_track_push_rotation(state.ozz, i, 0, &rkey.x);
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "ru")) {
            const tkey0 = kTransUp;
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &tkey0.x);
            const rkey0 = kRotRightUp;
            cozz.OZZ_track_push_rotation(state.ozz, i, 0, &rkey0.x);
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "lf")) {
            const tkey = kTransFoot;
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &tkey.x);
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "rf")) {
            const tkey0 = kTransFoot;
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &tkey0.x);
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "sp")) {
            const skey = Vec3{ .x = 0.0, .y = 0.0, .z = kSpinLength };
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &skey.x);
            const rkey = Quat.identity;
            cozz.OZZ_track_push_rotation(state.ozz, i, 0, &rkey.x);
        } else if (std.mem.startsWith(u8, std.mem.span(joint.name), "root")) {
            const tkey0 = Vec3{
                .x = 0.0,
                .y = 1.0,
                .z = -slice_count_ * kSpinLength,
            };
            cozz.OZZ_track_push_translation(state.ozz, i, 0, &tkey0.x);
            const tkey1 = Vec3{
                .x = 0.0,
                .y = 1.0,
                .z = kWalkCycleCount * kWalkCycleLength + tkey0.z,
            };
            cozz.OZZ_track_push_translation(state.ozz, i, kDuration, &tkey1.x);
        }
    }
}

// Procedurally builds millipede skeleton and walk animation
fn build() void {
    // Initializes the root. The root pointer will change from a spine to the
    // next for each slice.
    create_skeleton();
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
    create_animation(skeleton);
    // Build the run time animation from the raw animation.
    if (!cozz.OZZ_animation_build(state.ozz)) {
        @panic("OZZ_animation_build");
    }
    state.ozz_state.loaded.animation = true;
}

export fn frame() void {
    const fb_width = sokol.app.width();
    const fb_height = sokol.app.height();
    state.ozz_state.time.frame = sokol.app.frameDuration();

    // update camera
    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.camera.frame(state.input);
    state.input.mouse_wheel = 0;

    // draw ui
    sokol.imgui.newFrame(.{
        .width = fb_width,
        .height = fb_height,
        .delta_time = state.ozz_state.time.frame,
        .dpi_scale = sokol.app.dpiScale(),
    });
    cozz.framework.draw_ui(&state.ozz_state, &state.camera.camera);

    // draw axis & grid
    cozz.framework.gl_begin(.{
        .view = state.camera.camera.transform.worldToLocal(),
        .projection = state.camera.camera.projection_matrix,
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
                state.camera.viewProjectionMatrix(),
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
