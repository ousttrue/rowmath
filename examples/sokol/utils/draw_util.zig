const sokol = @import("sokol");
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Vec3 = rowmath.Vec3;
const Camera = rowmath.Camera;

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
    sokol.gl.multMatrix(&camera.transform.localToWorld().m[0]);

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
