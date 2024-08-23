//------------------------------------------------------------------------------
//  debugtext-printf-sapp.c
//
//  Simple text rendering with sokol_debugtext.h, formatting, tabs, etc...
//------------------------------------------------------------------------------
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const sg = sokol.gfx;

const FONT_KC854 = 0;

const Color = struct {
    u8,
    u8,
    u8,
};

const state = struct {
    var pass_action = sg.PassAction{};
    var palette = Color{ 0xf4, 0x43, 0x36 };
    var input = rowmath.InputState{};
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
    var sdtx_desc = sokol.debugtext.Desc{
        .logger = .{ .func = sokol.log.func },
    };
    sdtx_desc.fonts[0] = sokol.debugtext.fontKc854();
    sokol.debugtext.setup(sdtx_desc);
}

export fn frame() void {
    sokol.debugtext.canvas(sokol.app.widthf() * 0.5, sokol.app.heightf() * 0.5);
    sokol.debugtext.origin(3.0, 3.0);

    const color = state.palette;
    sokol.debugtext.font(0);
    sokol.debugtext.color3b(color[0], color[1], color[2]);
    sokol.debugtext.print(
        "Screen: {d:4.0} x {d:4.0}\n",
        .{ sokol.app.widthf(), sokol.app.heightf() },
    );
    sokol.debugtext.print(
        "Mouse : {d:4.0} x {d:4.0}: {d:.0}\n",
        .{ state.input.mouse_x, state.input.mouse_y, state.input.mouse_wheel },
    );
    sokol.debugtext.print(
        "Left  : {}\n",
        .{state.input.mouse_left},
    );
    sokol.debugtext.print(
        "Right : {}\n",
        .{state.input.mouse_right},
    );
    sokol.debugtext.print(
        "Middle: {}\n",
        .{state.input.mouse_middle},
    );

    sg.beginPass(.{
        .action = state.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
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
    sokol.debugtext.shutdown();
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
