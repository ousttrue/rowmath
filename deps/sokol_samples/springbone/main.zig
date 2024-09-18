const std = @import("std");
const builtin = @import("builtin");

const sokol = @import("sokol");
const sg = sokol.gfx;
const simgui = sokol.imgui;
const ig = @import("cimgui");

const utils = @import("utils");
const FboView = utils.FboView;
const SwapchainView = utils.SwapchainView;

const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Vec2 = rowmath.Vec2;
const Mat4 = rowmath.Mat4;
const Camera = rowmath.Camera;
const InputState = rowmath.InputState;
const Frustum = rowmath.Frustum;
const Transform = rowmath.Transform;
const Ray = rowmath.Ray;
const Plane = rowmath.Plane;
const RigidTransform = rowmath.RigidTransform;

const Joint = struct {
    name: [:0]const u8,
    transform: Transform = .{},
};

var JOINTS = [_]Joint{
    .{
        .name = "joint0",
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 3, .z = 0 } } },
    },
    .{
        .name = "joint1",
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 2, .z = 0 } } },
    },
    .{
        .name = "joint2",
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 1, .z = 0 } } },
    },
    .{
        .name = "end",
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 0, .z = 0 } } },
    },
};

const Bone = struct {
    head: u16,
    tail: u16,
};

const BONES = [_]Bone{
    .{ .head = 0, .tail = 1 },
    .{ .head = 1, .tail = 2 },
    .{ .head = 2, .tail = 3 },
};

pub fn SpringBone(comptime n: usize) type {
    return struct {
        // prev: [n]Vec3,
        // current: [n]Vec3,
        matrices: [n]Mat4,

        joints: []const Joint,
        bones: []const Bone,

        pub fn init(self: *@This(), joints: []const Joint, bones: []const Bone) void {
            self.joints = joints;
            self.bones = bones;

            for (joints, 0..) |joint, i| {
                self.matrices[i] = joint.transform.matrix();
            }
        }

        pub fn getParent(self: @This(), i: u16) ?u16 {
            for (self.bones) |bone| {
                if (bone.tail == i) {
                    return bone.head;
                }
            }
            return null;
        }

        pub fn isLeaf(self: @This(), i: u16) bool {
            for (self.bones) |bone| {
                if (bone.head == i) {
                    return false;
                }
            }
            return true;
        }

        pub fn update(self: *@This()) void {
            for (self.joints, 0..) |joint, i| {
                self.matrices[i] = joint.transform.matrix();
            }
        }
    };
}

const state = struct {
    // main camera
    var display = SwapchainView{
        .orbit = .{
            .camera = .{
                .projection = .{
                    .near_clip = 0.5,
                    .far_clip = 15,
                },
                .transform = .{
                    .translation = .{
                        .x = 0,
                        .y = 1,
                        .z = 5,
                    },
                },
            },
        },
    };

    var springbone: SpringBone(JOINTS.len) = undefined;
    var skeleton: utils.mesh.Skeleton = undefined;
    var gizmo = utils.Gizmo{};
};

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    simgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    state.display.init();
    state.springbone.init(&JOINTS, &BONES);

    state.skeleton = utils.mesh.Skeleton.init(
        std.heap.c_allocator,
        JOINTS.len,
    ) catch unreachable;
    for (JOINTS, 0..) |joint, i| {
        // const parent: u16 = parents[i];
        state.skeleton.joints[i] = .{
            .name = joint.name,
            .parent = state.springbone.getParent(@intCast(i)),
            .is_leaf = state.springbone.isLeaf(@intCast(i)),
        };
    }
    state.gizmo.init(std.heap.c_allocator);
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    state.display.frame();

    const io = ig.igGetIO();
    if (!io.*.WantCaptureMouse) {
        state.gizmo.translation.frame(.{
            .camera = state.display.orbit.camera,
            .input = state.display.orbit.input,
            .transform = &JOINTS[0].transform,
            .drawlist = &state.gizmo.drawlist,
        });
        state.springbone.update();
    }

    {
        state.display.begin();
        defer state.display.end();
        // render background
        utils.draw_lines(&rowmath.lines.Grid(5).lines);
        state.gizmo.gl_draw();

        // const matrices: [*]const Mat4 = @ptrCast(cozz.OZZ_model_matrices(state.ozz));
        state.skeleton.draw(
            state.display.orbit.viewProjectionMatrix(),
            &state.springbone.matrices,
        );
    }
    sg.commit();
}

export fn cleanup() void {
    simgui.shutdown();
    sokol.gl.shutdown();
    sg.shutdown();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    _ = simgui.handleEvent(ev.*);
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "springbone",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
