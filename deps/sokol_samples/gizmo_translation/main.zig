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
    // gizmo
    var gizmo: rowmath.DragHandle(.left, &rowmath.gizmo.translationDragHandler) = undefined;
    var drawlist: std.ArrayList(rowmath.gizmo.Renderable) = undefined;
    // scene
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
    state.gizmo = .{
        .handler = &rowmath.gizmo.translationDragHandler,
        .state = .{
            .camera = &state.display.orbit.camera,
        },
    };
    state.drawlist = std.ArrayList(rowmath.gizmo.Renderable).init(std.heap.c_allocator);
}

export fn frame() void {
    simgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });
    const input = state.display.frame();

    const io = ig.igGetIO();
    if (!io.*.WantCaptureMouse) {
        state.gizmo.frame(.{
            .input = input,
            .transform = state.transform,
            .drawlist = &state.drawlist,
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
        // show_subview("debug");
        var pos: ig.ImVec2 = undefined;
        if (state.offscreen.beginButton("debug", &pos)) {
            defer state.offscreen.endButton();

            state.mesh.draw(
                state.transform,
                state.offscreen.orbit.camera.viewProjectionMatrix(),
                .{ .useRenderTarget = true },
            );
            utils.draw_lines(&rowmath.lines.Grid(5).lines);
            utils.draw_camera_frustum(
                state.display.orbit,
                if (state.offscreen.hover)
                    null
                else
                    state.display.cursor,
            );

            draw_gizmo_mesh(state.offscreen.orbit.camera);

            if (state.gizmo.state.drag) |drag| {
                draw_debug(
                    state.offscreen.orbit.camera,
                    drag,
                    ig.igGetWindowDrawList(),
                    pos,
                );
            }
        }
        ig.igEnd();
    }

    {
        // render background
        state.display.begin();
        defer state.display.end();

        utils.draw_lines(&rowmath.lines.Grid(5).lines);
        state.mesh.draw(
            state.transform,
            state.display.orbit.viewProjectionMatrix(),
            .{ .useRenderTarget = false },
        );

        draw_gizmo_mesh(state.display.orbit.camera);
    }
    sg.commit();
}

fn draw_gizmo_mesh(camera: Camera) void {
    _ = camera;
    for (state.drawlist.items) |m| {
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

fn draw_debug(
    camera: Camera,
    drag: rowmath.gizmo.DragState,
    drawlist: *ig.ImDrawList,
    pos: ig.ImVec2,
) void {
    sokol.gl.beginLines();
    defer sokol.gl.end();

    sokol.gl.c3f(0, 0xff, 0xff);
    const o = drag.ray.origin;
    sokol.gl.v3f(o.x, o.y, o.z);
    const p = drag.ray.point(drag.hit);
    sokol.gl.v3f(p.x, p.y, p.z);

    switch (drag.mode) {
        .Translate_x => {
            var buf: [64]u8 = undefined;

            const im_color = utils.imColor(0, 255, 255, 255);
            {
                const begin = camera.toScreen(drag.start.rigid_transform.translation);
                // y = a * x + d
                ig.ImDrawList_AddCircleFilled(
                    drawlist,
                    .{ .x = pos.x + begin.x, .y = pos.y + begin.y },
                    4,
                    im_color,
                    14,
                );
                // ig.ImDrawList_AddCircleFilled(drawlist, end, 4, im_color, 14);
                _ = std.fmt.bufPrintZ(&buf, "{d:.0}:{d:.0}", .{ begin.x, begin.y }) catch
                    @panic("bufPrintZ");

                ig.ImDrawList_AddText_Vec2(
                    drawlist,
                    .{ .x = pos.x + begin.x, .y = pos.y + begin.y },
                    im_color,
                    &buf[0],
                    null,
                );
            }
            {
                const end = camera.toScreen(drag.ray.point(drag.hit));
                // y = a * x + d
                ig.ImDrawList_AddCircleFilled(
                    drawlist,
                    .{ .x = pos.x + end.x, .y = pos.y + end.y },
                    4,
                    im_color,
                    14,
                );
                // ig.ImDrawList_AddCircleFilled(drawlist, end, 4, im_color, 14);
                _ = std.fmt.bufPrintZ(&buf, "{d:.0}:{d:.0}", .{ end.x, end.y }) catch
                    @panic("bufPrintZ");

                ig.ImDrawList_AddText_Vec2(
                    drawlist,
                    .{ .x = pos.x + end.x, .y = pos.y + end.y },
                    im_color,
                    &buf[0],
                    null,
                );
            }
        },
        .Translate_y => {},
        .Translate_z => {},
        .Translate_yz => {},
        .Translate_zx => {},
        .Translate_xy => {},
        .Translate_xyz => {},
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
