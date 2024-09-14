//------------------------------------------------------------------------------
//  debugtext-printf-sapp.c
//
//  Simple text rendering with sokol_debugtext.h, formatting, tabs, etc...
//------------------------------------------------------------------------------
const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const Vec2 = rowmath.Vec2;
const InputState = rowmath.InputState;
const RgbU8 = rowmath.RgbU8;
const utils = @import("utils");
const ig = @import("cimgui");

const FONT_KC854 = 0;

fn nopHandler(drag_state: ?Vec2, input: InputState, button: bool) ?Vec2 {
    if (drag_state) |pos| {
        if (button) {
            return pos;
        } else {
            return null;
        }
    } else {
        if (button) {
            return input.cursor();
        } else {
            return null;
        }
    }
}

fn NopHandler(comptime button: rowmath.MouseButton) rowmath.DragHandle(button, ?Vec2) {
    return rowmath.DragHandle(button, ?Vec2){
        .state = null,
        .handler = &nopHandler,
    };
}

const state = struct {
    var pass_action = sg.PassAction{};
    var input = InputState{};

    var drag_left = NopHandler(.left);
    var drag_right = NopHandler(.right);
    var drag_middle = NopHandler(.middle);
};

export fn init() void {
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.125, .b = 0.25, .a = 1.0 },
    };

    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    sokol.imgui.setup(.{
        .logger = .{ .func = sokol.log.func },
    });
    var sdtx_desc = sokol.debugtext.Desc{
        .logger = .{ .func = sokol.log.func },
    };
    sdtx_desc.fonts[0] = sokol.debugtext.fontKc854();
    sokol.debugtext.setup(sdtx_desc);
}

fn makeColor(r: u8, g: u8, b: u8, a: u8) u32 {
    const color = ig.ImColor_ImColor_Int(r, g, b, a);
    const p: *const ig.ImVec4 = @ptrCast(color);
    return ig.igGetColorU32_Vec4(p.*);
}

fn draw_drawlist(drawlist: [*]ig.ImDrawList) void {
    const red = makeColor(255, 0, 0, 200);

    ig.ImDrawList_AddCircle(
        drawlist,
        .{ .x = 100, .y = 100 },
        10.0,
        red,
        0,
        10 + 4,
    );
    // ig.ImDrawList_AddText_Vec2(pos, col, b, e);
}

pub fn draw_button(
    name: []const u8,
    color: RgbU8,
    _start: ?Vec2,
    input: InputState,
) void {
    // draw_drawlist(drawlist);

    sokol.debugtext.color3b(color.r, color.g, color.b);
    if (_start) |start| {
        const delta = input.cursor().sub(start);
        sokol.debugtext.print(
            "{s} {d:0.0}, {d:0.0} => {d:0.0}, {d:0.0}:\n",
            .{
                name,
                start.x,
                start.y,
                delta.x,
                delta.y,
            },
        );

        // sokol.gl.c3b(color.r, color.g, color.b);
        // sokol.gl.v3f(start.x, start.y, 0);
        // sokol.gl.v3f(input.mouse_x, input.mouse_y, 0);

        const drawlist = ig.igGetBackgroundDrawList_Nil();
        const im_color = makeColor(color.r, color.g, color.b, 255);
        const begin = ig.ImVec2{ .x = start.x, .y = start.y };
        const end = ig.ImVec2{ .x = input.mouse_x, .y = input.mouse_y };
        ig.ImDrawList_AddLine(
            drawlist,
            begin,
            end,
            im_color,
            1,
        );
        ig.ImDrawList_AddCircleFilled(drawlist, begin, 4, im_color, 14);
        ig.ImDrawList_AddCircleFilled(drawlist, end, 4, im_color, 14);

        var buf: [64]u8 = undefined;
        _ = std.fmt.bufPrintZ(&buf, "{d}:{d}", .{ start.x, start.y }) catch
            @panic("bufPrintZ");
        ig.ImDrawList_AddText_Vec2(drawlist, begin, im_color, &buf[0], null);
        _ = std.fmt.bufPrintZ(&buf, "{d}:{d}", .{ end.x, end.y }) catch
            @panic("bufPrintZ");
        ig.ImDrawList_AddText_Vec2(drawlist, end, im_color, &buf[0], null);
    } else {
        sokol.debugtext.print(
            "{s} :\n",
            .{name},
        );
    }
}

fn draw_buttons() void {
    sokol.gl.beginLines();
    defer sokol.gl.end();
    draw_button(
        "Left",
        RgbU8.red,
        state.drag_left.state,
        state.input,
    );
    draw_button(
        "Right",
        RgbU8.green,
        state.drag_right.state,
        state.input,
    );
    draw_button(
        "Middle",
        RgbU8.blue,
        state.drag_middle.state,
        state.input,
    );
    sokol.debugtext.draw();
}

export fn frame() void {
    // call sokol.imgui.newFrame() before any ImGui calls
    sokol.imgui.newFrame(.{
        .width = sokol.app.width(),
        .height = sokol.app.height(),
        .delta_time = sokol.app.frameDuration(),
        .dpi_scale = sokol.app.dpiScale(),
    });

    state.drag_left.frame(state.input);
    state.drag_right.frame(state.input);
    state.drag_middle.frame(state.input);

    // imgui
    ig.igShowDemoWindow(null);

    {
        sg.beginPass(.{
            .action = state.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        defer sg.endPass();
        utils.gl_begin(.{
            .projection = Mat4.orthographic(
                0,
                sokol.app.widthf(),
                sokol.app.heightf(),
                0,
                -1,
                1,
            ),
            .view = Mat4.identity,
        });
        defer utils.gl_end();

        utils.draw_mouse_state(state.input, RgbU8.yellow);

        draw_buttons();

        sokol.imgui.render();
    }

    sg.commit();
}

export fn event(ev: [*c]const sokol.app.Event) void {
    utils.inputEvent(ev, &state.input);
    _ = sokol.imgui.handleEvent(ev.*);
}

export fn cleanup() void {
    sokol.debugtext.shutdown();
    sokol.imgui.shutdown();
    sokol.gl.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 640,
        .height = 480,
        .window_title = "debugtext-printf-sapp",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
