const std = @import("std");
const builtin = @import("builtin");
const ig = @import("cimgui");
const sokol = @import("sokol");
const sg = sokol.gfx;
const simgui = sokol.imgui;
const scene = @import("cube_scene.zig");
const utils = @import("utils");
const CameraView = utils.CameraView;
const linegeom = @import("linegeom.zig");
const rowmath = @import("rowmath");
const Vec3 = rowmath.Vec3;
const Vec2 = rowmath.Vec2;
const Mat4 = rowmath.Mat4;
const Camera = rowmath.Camera;
const InputState = rowmath.InputState;
const Frustum = rowmath.Frustum;
const gizmo = rowmath.gizmo;

const state = struct {
    var allocator: std.mem.Allocator = undefined;
    var display = CameraView{
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
    var offscreen = CameraView{
        .orbit = .{
            .camera = .{
                .transform = .{
                    .translation = .{ .x = 0, .y = 1, .z = 15 },
                },
            },
        },
    };
    var gizmo_ctx: gizmo.Context = .{};
    var gizmo_a: gizmo.TranslationContext = .{};
    var gizmo_b: gizmo.RotationContext = .{};
    var gizmo_c: gizmo.ScalingContext = .{};
    var drawlist: std.ArrayList(gizmo.Renderable) = undefined;

    var hover = false;
    var offscreen_cursor: Vec2 = .{ .x = 0, .y = 0 };
    var display_cursor: Vec2 = .{ .x = 0, .y = 0 };
};

export fn init() void {
    // state.allocator = std.heap.page_allocator;
    // wasm
    state.allocator = std.heap.c_allocator;

    // initialize sokol-gfx
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });

    // initialize sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    scene.setup();

    state.offscreen.init();
    state.display.init();

    state.drawlist = std.ArrayList(gizmo.Renderable).init(state.allocator);
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    const input = CameraView.inputFromScreen();
    state.display.orbit.frame(input);
    state.display_cursor = input.cursorScreenPosition();

    const io = ig.igGetIO().*;
    if (!io.WantCaptureMouse) {
        state.gizmo_ctx.update(.{
            .viewport_size = .{ .x = io.DisplaySize.x, .y = io.DisplaySize.y },
            .mouse_left = io.MouseDown[ig.ImGuiMouseButton_Left],
            .ray = state.display.orbit.camera.getRay(state.display_cursor),
            .cam_yFov = state.display.orbit.camera.projection.fov_y_radians,
            .cam_dir = state.display.orbit.camera.transform.rotation.dirZ().negate(),
        });

        state.drawlist.clearRetainingCapacity();
        state.gizmo_a.translation(
            state.gizmo_ctx,
            &state.drawlist,
            false,
            &scene.state.xform_a,
        ) catch @panic("transform a");
        state.gizmo_b.rotation(
            state.gizmo_ctx,
            &state.drawlist,
            true,
            &scene.state.xform_b,
        ) catch @panic("transform b");
        const uniform = false;
        state.gizmo_c.scale(
            state.gizmo_ctx,
            &state.drawlist,
            &scene.state.xform_c,
            uniform,
        ) catch @panic("transform b");
    }

    //=== UI CODE STARTS HERE
    show_subview("debug");
    //=== UI CODE ENDS HERE

    {
        // render background
        state.display.begin(null);
        defer state.display.end(null);

        // grid
        linegeom.grid();
        scene.draw(.{ .camera = state.display.orbit });
        draw_gizmo(state.drawlist.items);
    }
    sg.commit();
}

fn draw_gizmo(drawlist: []const gizmo.Renderable) void {
    for (drawlist) |m| {
        sokol.gl.matrixModeModelview();
        sokol.gl.pushMatrix();
        defer sokol.gl.popMatrix();
        sokol.gl.multMatrix(&m.matrix.m[0]);
        sokol.gl.beginTriangles();
        defer sokol.gl.end();
        const color = m.color();
        sokol.gl.c4f(
            color.r,
            color.g,
            color.b,
            color.a,
        );
        for (m.mesh.triangles) |triangle| {
            for (triangle) |i| {
                const p = m.mesh.vertices[i].position;
                sokol.gl.v3f(p.x, p.y, p.z);
            }
        }
    }
}

fn show_subview(name: []const u8) void {
    ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
    ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });
    defer ig.igPopStyleVar(1);
    if (ig.igBegin(
        &name[0],
        null,
        ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse,
    )) {
        if (state.offscreen.beginImageButton()) |render_context| {
            defer state.offscreen.endImageButton();
            state.hover = render_context.hover;
            state.offscreen_cursor = render_context.cursor;

            scene.draw(.{
                .camera = state.offscreen.orbit,
                .useRenderTarget = true,
            });

            utils.draw_lines(&rowmath.lines.Grid(5).lines);
            utils.draw_camera_frustum(
                state.display.orbit,
                if (state.hover)
                    null
                else
                    state.display_cursor,
            );

            draw_gizmo(state.drawlist.items);
        }
    }
    ig.igEnd();
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
        .window_title = "sokol-zig + Dear Imgui",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
