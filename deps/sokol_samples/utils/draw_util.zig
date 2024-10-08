const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Quat = rowmath.Quat;
const Mat4 = rowmath.Mat4;
const RgbU8 = rowmath.RgbU8;
const RgbF32 = rowmath.RgbF32;
const OrbitCamera = rowmath.OrbitCamera;
const InputState = rowmath.InputState;
const DragHandle = rowmath.DragHandle;
const Frustum = rowmath.Frustum;
const Ray = rowmath.Ray;

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

pub fn draw_camera_frustum(
    orbit: OrbitCamera,
) void {
    {
        sokol.gl.pushMatrix();
        defer sokol.gl.popMatrix();
        sokol.gl.multMatrix(&orbit.camera.transform.localToWorld().m[0]);
        const frustum = orbit.camera.projection.getFrustum();
        const frustum_lines = frustum.toLines();
        draw_lines(&frustum_lines);
    }

    // cursor
    const cursor = orbit.input.cursorScreenPosition();
    const ray = orbit.camera.getRay(cursor);
    const min, const max = orbit.camera.getRayClip(ray);
    draw_ray(ray, min, max);

    // pivot
    {
        sokol.gl.beginLines();
        defer sokol.gl.end();
        sokol.gl.c3f(1, 1, 0);
        draw_line(orbit.camera.transform.translation, orbit.pivot);
    }
}

pub fn draw_camera_frustum_gizmo(
    orbit: OrbitCamera,
    translation_state: rowmath.gizmo.TranslateionState,
) void {
    switch (translation_state) {
        .none => {},
        .hover, .drag => |drag_state| {
            // drag plane
            {
                const hit = drag_state.ray.point(drag_state.hit);
                const v = hit.sub(orbit.camera.transform.translation);
                const drag_clip = v.dot(orbit.camera.transform.rotation.dirZ());
                const quad = Frustum.getPyramidBase(
                    orbit.camera.projection.fov_y_radians,
                    orbit.camera.projection.getAspectRatio(),
                    drag_clip,
                );
                const quad_lines = quad.toLines();
                draw_lines(&quad_lines);
                const cross_lines = quad.crossLines(drag_state.cursor);
                draw_lines(&cross_lines);
            }
        },
    }
}

pub fn draw_ray(ray: Ray, min: f32, max: f32) void {
    sokol.gl.beginLines();
    defer sokol.gl.end();

    {
        const v0 = ray.point(min);
        sokol.gl.c3f(1, 1, 0);
        sokol.gl.v3f(v0.x, v0.y, v0.z);
    }
    {
        const v1 = ray.point(max);
        sokol.gl.c3f(1, 0, 0);
        sokol.gl.v3f(v1.x, v1.y, v1.z);
    }
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
