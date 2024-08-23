const sokol = @import("sokol");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const Camera = rowmath.Camera;
const InputState = rowmath.InputState;
const DragHandle = rowmath.DragHandle;

pub fn gl_begin(opts: struct { projection: Mat4, view: Mat4 }) void {
    sokol.gl.setContext(sokol.gl.defaultContext());
    sokol.gl.defaults();
    sokol.gl.matrixModeProjection();
    sokol.gl.multMatrix(&opts.projection.m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.multMatrix(&opts.view.m[0]);
}

pub fn gl_end() void {
    sokol.gl.contextDraw(sokol.gl.defaultContext());
}

pub fn draw_grid() void {
    const n = 5.0;
    sokol.gl.beginLines();
    sokol.gl.c3f(1, 1, 1);
    {
        var x: f32 = -n;
        while (x <= n) : (x += 1) {
            sokol.gl.v3f(x, 0, -n);
            sokol.gl.v3f(x, 0, n);
        }
    }
    {
        var z: f32 = -n;
        while (z <= n) : (z += 1) {
            sokol.gl.v3f(-n, 0, z);
            sokol.gl.v3f(n, 0, z);
        }
    }
    sokol.gl.end();
}

pub fn draw_line(v0: Vec3, v1: Vec3) void {
    sokol.gl.v3f(v0.x, v0.y, v0.z);
    sokol.gl.v3f(v1.x, v1.y, v1.z);
}

pub fn draw_camera_frustum(camera: Camera, _cursor: ?Vec2) void {
    const frustom = camera.frustum();

    sokol.gl.pushMatrix();
    defer sokol.gl.popMatrix();
    sokol.gl.loadMatrix(&camera.transform.localToWorld().m[0]);

    sokol.gl.beginLines();
    defer sokol.gl.end();
    sokol.gl.c3f(1, 1, 1);

    draw_line(frustom.far_top_left, frustom.far_top_right);
    draw_line(frustom.far_top_right, frustom.far_bottom_right);
    draw_line(frustom.far_bottom_right, frustom.far_bottom_left);
    draw_line(frustom.far_bottom_left, frustom.far_top_left);

    draw_line(frustom.near_top_left, frustom.near_top_right);
    draw_line(frustom.near_top_right, frustom.near_bottom_right);
    draw_line(frustom.near_bottom_right, frustom.near_bottom_left);
    draw_line(frustom.near_bottom_left, frustom.near_top_left);

    draw_line(Vec3.zero, frustom.far_top_left);
    draw_line(Vec3.zero, frustom.far_top_right);
    draw_line(Vec3.zero, frustom.far_bottom_left);
    draw_line(Vec3.zero, frustom.far_bottom_right);

    if (_cursor) |cursor| {
        sokol.gl.c3f(1, 1, 0);
        draw_line(Vec3.zero, .{
            .x = frustom.far_top_right.x * cursor.x,
            .y = frustom.far_top_right.y * cursor.y,
            .z = frustom.far_top_right.z,
        });
    }
}

pub const Color = struct {
    u8,
    u8,
    u8,
};
pub const red = Color{ 0xf4, 0x43, 0x36 };
pub const green = Color{ 0x21, 0x96, 0xf3 };
pub const blue = Color{ 0x4c, 0xaf, 0x50 };
pub const yellow = Color{ 0xff, 0xeb, 0x3b };

pub fn draw_mouse_state(input: InputState, color: Color) void {
    sokol.debugtext.canvas(sokol.app.widthf(), sokol.app.heightf());
    sokol.debugtext.origin(3.0, 3.0);

    sokol.debugtext.font(0);
    sokol.debugtext.color3b(color[0], color[1], color[2]);
    sokol.debugtext.print(
        "Screen: {d:4.0} x {d:4.0}\n",
        .{ sokol.app.widthf(), sokol.app.heightf() },
    );
    sokol.debugtext.print(
        "Mouse : {d:4.0} x {d:4.0}: {d:.0}\n",
        .{ input.mouse_x, input.mouse_y, input.mouse_wheel },
    );
}

pub fn draw_button(
    name: []const u8,
    color: Color,
    button_state: ?DragHandle.DragState,
) void {
    sokol.debugtext.color3b(color[0], color[1], color[2]);
    sokol.gl.c3b(color[0], color[1], color[2]);
    if (button_state) |drag_state| {
        const delta = drag_state.delta();
        sokol.debugtext.print(
            "{s} {d:0.0}, {d:0.0} => {d:0.0}, {d:0.0}:\n",
            .{
                name,
                drag_state.start.x,
                drag_state.start.y,
                delta.x,
                delta.y,
            },
        );
        sokol.gl.v3f(drag_state.start.x, drag_state.start.y, 0);
        sokol.gl.v3f(drag_state.cursor.x, drag_state.cursor.y, 0);
    } else {
        sokol.debugtext.print(
            "{s} :\n",
            .{name},
        );
    }
}

pub fn inputEvent(e: [*c]const sokol.app.Event, input: *InputState) void {
    switch (e.*.type) {
        .MOUSE_DOWN => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    input.mouse_left = true;
                },
                .RIGHT => {
                    input.mouse_right = true;
                },
                .MIDDLE => {
                    input.mouse_middle = true;
                },
                .INVALID => {},
            }
        },
        .MOUSE_UP => {
            switch (e.*.mouse_button) {
                .LEFT => {
                    input.mouse_left = false;
                },
                .RIGHT => {
                    input.mouse_right = false;
                },
                .MIDDLE => {
                    input.mouse_middle = false;
                },
                .INVALID => {},
            }
        },
        .MOUSE_MOVE => {
            input.mouse_x = e.*.mouse_x;
            input.mouse_y = e.*.mouse_y;
        },
        .MOUSE_SCROLL => {
            input.mouse_wheel = e.*.scroll_y;
        },
        else => {},
    }
}
