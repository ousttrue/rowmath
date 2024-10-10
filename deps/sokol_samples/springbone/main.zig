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

const MoveType = enum {
    kinematic,
    particle,
};

const Joint = struct {
    name: [:0]const u8,
    type: MoveType,
    transform: Transform = .{},
    drag_force: f32 = 0.5,
};

var JOINTS = [_]Joint{
    .{
        .name = "joint0",
        .type = .kinematic,
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 3, .z = 0 } } },
    },
    .{
        .name = "joint1",
        .type = .particle,
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 2, .z = 0 } } },
    },
    .{
        .name = "joint2",
        .type = .particle,
        .transform = .{ .rigid_transform = .{ .translation = .{ .x = 0, .y = 1, .z = 0 } } },
    },
    .{
        .name = "end",
        .type = .particle,
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

const Node = struct {
    joint_index: u16,
    children: std.ArrayList(u16),
    parent_index: ?u16 = null,
    // springbone
    length_from_parent: f32 = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        joint_index: u16,
    ) !@This() {
        return Node{
            .joint_index = joint_index,
            .children = std.ArrayList(u16).init(allocator),
        };
    }
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.children.deinit();
        allocator.free(self);
    }
    pub fn addChild(self: *@This(), child: *@This()) !void {
        try self.children.append(child.joint_index);
        std.debug.assert(child.parent_index == null);
        child.parent_index = self.joint_index;
    }
};

pub fn ParticleSimulation(comptime n: usize) type {
    return struct {
        buffer: [3][n]Vec3 = undefined,
        phase: usize = 0,
        matrices: [n]Mat4 = undefined,

        pub fn prev(self: *const @This()) []const Vec3 {
            return &self.buffer[@mod(self.phase, 3)];
        }
        pub fn current(self: *const @This()) []const Vec3 {
            return &self.buffer[@mod(self.phase + 1, 3)];
        }
        pub fn next(self: *@This()) []Vec3 {
            return &self.buffer[@mod(self.phase + 2, 3)];
        }

        pub fn init(self: *@This(), joints: []const Joint) void {
            for (joints, &self.buffer[0], &self.buffer[1], &self.buffer[2]) |joint, *b0, *b1, *b2| {
                b0.* = joint.transform.rigid_transform.translation;
                b1.* = joint.transform.rigid_transform.translation;
                b2.* = joint.transform.rigid_transform.translation;
            }
        }

        pub fn currentToMatrixFlip(self: *@This()) void {
            for (&self.matrices, self.current()) |*m, *b| {
                m.* = Mat4.makeTranslation(b.*);
            }
            self.phase += 1;
        }
    };
}
const SIMULATION = ParticleSimulation(JOINTS.len);

pub const SpringBone = struct {
    nodes: std.ArrayList(Node),

    pub fn init(
        self: *@This(),
        allocator: std.mem.Allocator,
        joints: []const Joint,
        bones: []const Bone,
    ) !void {
        self.nodes = std.ArrayList(Node).init(allocator);
        // make nodes
        for (0..joints.len) |i| {
            try self.nodes.append(try Node.init(allocator, @intCast(i)));
        }
        // build hierarchy.
        // bones[0] must root
        for (bones) |bone| {
            const child = &self.nodes.items[bone.tail];
            try self.nodes.items[bone.head].addChild(child);

            const parent_pos = joints[bone.head].transform.rigid_transform.translation;
            const child_pos = joints[bone.tail].transform.rigid_transform.translation;
            child.length_from_parent = child_pos.sub(parent_pos).norm();
        }
    }

    pub fn update(
        self: *@This(),
        joints: []const Joint,
        simuation: *SIMULATION,
    ) void {
        // verlet
        for (joints, simuation.current(), simuation.prev(), simuation.next()) |joint, current, prev, *next| {
            next.* = switch (joint.type) {
                .kinematic => block: {
                    break :block joint.transform.rigid_transform.translation;
                },
                .particle => block: {
                    const position = current.add(current.sub(prev).scale(1.0 - joint.drag_force))
                    // + parentRotation * LocalRotation * BoneAxis * settings.StiffnessForce * deltaTime * scalingFactor // 親の回転による子ボーンの移動目標
                    //// 外力による移動量
                    // + settings.GravityDir * (settings.GravityPower * deltaTime) * scalingFactor;
                    ;
                    break :block position;
                },
            };
        }

        // constraint
        self.constraintRecursive(0, simuation.next());
    }

    pub fn constraintRecursive(
        self: @This(),
        joint_index: usize,
        next: []Vec3,
    ) void {
        const node = self.nodes.items[joint_index];
        if (node.parent_index) |parent_index| {
            const joint_pos = next[joint_index];
            const parent_pos = next[parent_index];
            next[joint_index] = parent_pos.add(
                joint_pos.sub(parent_pos).normalize().scale(node.length_from_parent),
            );
        }

        for (node.children.items) |child| {
            self.constraintRecursive(child, next);
        }
    }
};

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

    var springbone: SpringBone = undefined;
    var skeleton: utils.mesh.Skeleton = undefined;
    var gizmo = utils.Gizmo{};

    var simulation = ParticleSimulation(JOINTS.len){};
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
    state.springbone.init(
        std.heap.c_allocator,
        &JOINTS,
        &BONES,
    ) catch @panic("SpringBone.init");

    state.skeleton = utils.mesh.Skeleton.init(
        std.heap.c_allocator,
        JOINTS.len,
    ) catch unreachable;
    for (JOINTS, 0..) |joint, i| {
        state.skeleton.joints[i] = .{
            .name = joint.name,
            .parent = state.springbone.nodes.items[i].parent_index,
            .is_leaf = state.springbone.nodes.items[i].children.items.len == 0,
        };
    }
    state.simulation.init(&JOINTS);
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
        state.springbone.update(&JOINTS, &state.simulation);
        state.simulation.currentToMatrixFlip();
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
            &state.simulation.matrices,
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
