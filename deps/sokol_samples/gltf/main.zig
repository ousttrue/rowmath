const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const utils = @import("utils");

const state = struct {
    var pass_action = sg.PassAction{};
    var input = rowmath.InputState{};
    var orbit = rowmath.OrbitCamera{};
    var status: [:0]const u8 = "loading...";
};

var fetch_buffer: [1024 * 1024]u8 = undefined;
var status_buffer: [1024]u8 = undefined;

export fn init() void {
    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    sokol.gl.setup(.{
        .logger = .{ .func = sokol.log.func },
    });

    var debugtext_desc = sokol.debugtext.Desc{
        .logger = .{ .func = sokol.log.func },
    };
    debugtext_desc.fonts[0] = sokol.debugtext.fontOric();
    sokol.debugtext.setup(debugtext_desc);

    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 },
    };

    // setup sokol-fetch with 2 channels and 6 lanes per channel,
    // we'll use one channel for mesh data and the other for textures
    sokol.fetch.setup(.{
        .max_requests = 2,
        .num_channels = 1,
        .num_lanes = 2,
        .logger = .{ .func = sokol.log.func },
    });
    // start loading the base gltf file...
    _ = sokol.fetch.send(.{
        .path = "Box.gltf",
        .callback = gltf_fetch_callback,
        .buffer = sokol.fetch.asRange(&fetch_buffer),
    });
}

export fn gltf_fetch_callback(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        state.status = std.fmt.bufPrintZ(
            &status_buffer,
            "{}bytes\n",
            .{response.*.data.size},
        ) catch @panic("bufPrintZ");
    } else if (response.*.failed) {
        state.status = "fetch fail";
    }
}

export fn frame() void {
    sokol.fetch.dowork();

    state.input.screen_width = sokol.app.widthf();
    state.input.screen_height = sokol.app.heightf();
    state.orbit.frame(state.input);
    state.input.mouse_wheel = 0;

    sokol.debugtext.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
    sokol.debugtext.pos(0.5, 0.5);
    sokol.debugtext.puts(state.status);

    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    utils.gl_begin(.{
        .projection = state.orbit.projectionMatrix(),
        .view = state.orbit.viewMatrix(),
    });
    utils.draw_lines(&rowmath.lines.Grid(5).lines);
    utils.gl_end();

    sokol.debugtext.draw();
    sg.endPass();
    sg.commit();
}

export fn event(e: [*c]const sokol.app.Event) void {
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
    sg.shutdown();
}

pub fn main() void {
    sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 800,
        .height = 600,
        .window_title = "rowmath: examples/sokol/camera_simple",
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    });
}
