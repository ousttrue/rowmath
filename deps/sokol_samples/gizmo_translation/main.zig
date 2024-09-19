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
    // sub camera
    var offscreen = FboView{
        .orbit = .{
            .camera = .{
                .transform = .{
                    .translation = .{ .x = 0, .y = 1, .z = 15 },
                },
            },
        },
    };

    var gizmo = utils.Gizmo{};
    var transform = Transform{};
    var mesh = utils.mesh.Cube{};
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

    state.offscreen.init();
    state.display.init();
    state.mesh.init();
    // page_allocator crash wasm
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
            .transform = &state.transform,
            .drawlist = &state.gizmo.drawlist,
        });
    }

    {
        // imgui widgets
        ig.igSetNextWindowSize(.{ .x = 256, .y = 256 }, ig.ImGuiCond_Once);
        const w = io.*.DisplaySize.x;
        ig.igSetNextWindowPos(
            .{ .x = w - 256 - 10, .y = 10 },
            ig.ImGuiCond_Once,
            .{ .x = 0, .y = 0 },
        );
        var screen_pos: ig.ImVec2 = undefined;
        if (state.offscreen.beginButton("debug", &screen_pos)) {
            defer state.offscreen.endButton();
            // render subview
            state.mesh.draw(
                state.transform,
                state.offscreen.orbit.camera.viewProjectionMatrix(),
                .{ .useRenderTarget = true },
            );
            utils.draw_lines(&rowmath.lines.Grid(5).lines);
            state.gizmo.gl_draw();
            draw_debug(
                state.offscreen.orbit.camera,
                screen_pos,
                ig.igGetWindowDrawList(),
                true,
            );
        }
        ig.igEnd();
    }

    {
        state.display.begin();
        defer state.display.end();
        // render background
        state.mesh.draw(
            state.transform,
            state.display.orbit.viewProjectionMatrix(),
            .{ .useRenderTarget = false },
        );
        utils.draw_lines(&rowmath.lines.Grid(5).lines);
        state.gizmo.gl_draw();
        draw_debug(
            state.display.orbit.camera,
            .{ .x = 0, .y = 0 },
            ig.igGetBackgroundDrawList_Nil(),
            false,
        );
    }
    sg.commit();
}

fn draw_debug(
    camera: Camera,
    o: ig.ImVec2,
    drawlist: *ig.ImDrawList,
    draw_frustum: bool,
) void {
    if (draw_frustum) {
        utils.draw_camera_frustum(
            state.display.orbit,
        );
        utils.draw_camera_frustum_gizmo(
            state.display.orbit,
            state.gizmo.translation.state,
        );
    }

    const drag = switch (state.gizmo.translation.state) {
        .none => return,
        .hover => |hover| hover,
        .drag => |drag| drag,
    };
    const ray = state.display.orbit.getRay();
    sokol.gl.beginLines();
    defer sokol.gl.end();

    {
        sokol.gl.c3f(0, 0xff, 0xff);
        const origin = drag.ray.origin;
        sokol.gl.v3f(origin.x, origin.y, origin.z);
        const point = drag.ray.point(drag.hit);
        sokol.gl.v3f(point.x, point.y, point.z);
    }

    // drag plane & current ray intersection
    const drag_plane = drag.getRayHitPlane();
    if (drag_plane.intersect(ray)) |hit| {
        const start = drag.ray.point(drag.hit);
        sokol.gl.v3f(start.x, start.y, start.z);
        const current = ray.point(hit);
        sokol.gl.v3f(current.x, current.y, current.z);
    }

    var buf: [64]u8 = undefined;

    // {
    //     const im_color = utils.imColor(0, 255, 255, 255);
    //     const pos = camera.toScreen(drag.start.rigid_transform.translation);
    //     ig.ImDrawList_AddCircleFilled(
    //         drawlist,
    //         .{ .x = o.x + pos.x, .y = o.y + pos.y },
    //         4,
    //         im_color,
    //         14,
    //     );
    //     _ = std.fmt.bufPrintZ(&buf, "{d:.0}:{d:.0}", .{ pos.x, pos.y }) catch
    //         @panic("bufPrintZ");
    //     ig.ImDrawList_AddText_Vec2(
    //         drawlist,
    //         .{ .x = o.x + pos.x, .y = o.y + pos.y },
    //         im_color,
    //         &buf[0],
    //         null,
    //     );
    // }

    {
        const im_color = utils.imColor(0, 255, 255, 255);
        const pos = camera.toScreen(drag.ray.point(drag.hit));
        ig.ImDrawList_AddCircleFilled(
            drawlist,
            .{ .x = o.x + pos.x, .y = o.y + pos.y },
            4,
            im_color,
            14,
        );
        _ = std.fmt.bufPrintZ(&buf, "{d:.0}:{d:.0}", .{ pos.x, pos.y }) catch
            @panic("bufPrintZ");
        ig.ImDrawList_AddText_Vec2(
            drawlist,
            .{ .x = o.x + pos.x, .y = o.y + pos.y },
            im_color,
            &buf[0],
            null,
        );
    }

    {
        const im_color = utils.imColor(255, 0, 0, 255);
        if (drag_plane.intersect(ray)) |hit| {
            const world = ray.point(hit);
            const pos = camera.toScreen(world);
            ig.ImDrawList_AddCircleFilled(
                drawlist,
                .{ .x = o.x + pos.x, .y = o.y + pos.y },
                4,
                im_color,
                14,
            );
            _ = std.fmt.bufPrintZ(&buf, "{d:.0}:{d:.0}", .{ pos.x, pos.y }) catch
                @panic("bufPrintZ");
            ig.ImDrawList_AddText_Vec2(
                drawlist,
                .{ .x = o.x + pos.x, .y = o.y + pos.y },
                im_color,
                &buf[0],
                null,
            );
        }
    }
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
