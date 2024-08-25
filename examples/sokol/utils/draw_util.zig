const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Mat4 = rowmath.Mat4;
const RgbU8 = rowmath.RgbU8;
const RgbF32 = rowmath.RgbF32;
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

pub fn draw_lines(lines: []const rowmath.lines.Line) void {
    sokol.gl.beginLines();
    defer sokol.gl.end();

    var current: ?RgbF32 = null;

    for (lines) |line| {
        if (!(if (current) |color| std.meta.eql(color, line.color) else false)) {
            current = line.color;
            sokol.gl.c3f(line.color.r, line.color.g, line.color.b);
        }
        sokol.gl.v3f(line.start.x, line.start.y, line.start.z);
        sokol.gl.v3f(line.end.x, line.end.y, line.end.z);
    }
}

pub fn draw_line(v0: Vec3, v1: Vec3) void {
    sokol.gl.v3f(v0.x, v0.y, v0.z);
    sokol.gl.v3f(v1.x, v1.y, v1.z);
}

pub fn draw_camera_frustum(camera: Camera, _cursor: ?Vec2) void {
    sokol.gl.pushMatrix();
    defer sokol.gl.popMatrix();
    sokol.gl.multMatrix(&camera.transform.localToWorld().m[0]);

    draw_lines(&camera.frustum_lines);

    // cursor
    if (_cursor) |cursor| {
        sokol.gl.beginLines();
        defer sokol.gl.end();

        sokol.gl.c3f(1, 1, 0);
        switch (camera.projection) {
            .perspective => |perspective| {
                const frustum = perspective.frustum(camera.getAspect());
                draw_line(Vec3.zero, .{
                    .x = frustum.far_top_right.x * cursor.x,
                    .y = frustum.far_top_right.y * cursor.y,
                    .z = frustum.far_top_right.z,
                });
            },
            .orthographic => |orthographic| {
                const frustum = orthographic.frustum(camera.getAspect());
                draw_line(
                    .{
                        .x = frustum.near_top_right.x * cursor.x,
                        .y = frustum.near_top_right.y * cursor.y,
                        .z = frustum.near_top_right.z,
                    },
                    .{
                        .x = frustum.far_top_right.x * cursor.x,
                        .y = frustum.far_top_right.y * cursor.y,
                        .z = frustum.far_top_right.z,
                    },
                );
            },
        }
    }

    // gaze
}

pub fn draw_mouse_state(input: InputState, color: RgbU8) void {
    sokol.debugtext.canvas(sokol.app.widthf(), sokol.app.heightf());
    sokol.debugtext.origin(3.0, 3.0);

    sokol.debugtext.font(0);
    sokol.debugtext.color3b(color.r, color.g, color.b);
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
    color: RgbU8,
    _start: ?Vec2,
    input: InputState,
) void {
    sokol.debugtext.color3b(color.r, color.g, color.b);
    sokol.gl.c3b(color.r, color.g, color.b);
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
        sokol.gl.v3f(start.x, start.y, 0);
        sokol.gl.v3f(input.mouse_x, input.mouse_y, 0);
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
