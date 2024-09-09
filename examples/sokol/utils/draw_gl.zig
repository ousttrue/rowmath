const sokol = @import("sokol");
const rowmath = @import("rowmath");
const Mat4 = rowmath.Mat4;
const Vec3 = rowmath.Vec3;

const CameraMatrix = struct { projection: Mat4, view: Mat4 };

const state = struct {
    var depth_test_pip = sokol.gl.Pipeline{};
};

pub fn gl_init() void {
    // a pipeline object with less-equal depth-testing
    state.depth_test_pip = sokol.gl.makePipeline(.{
        .depth = .{
            .write_enabled = true,
            .compare = .LESS_EQUAL,
        },
    });
}

pub fn gl_begin(camera: CameraMatrix) void {
    // sokol.gl.setContext(sokol.gl.defaultContext());
    sokol.gl.defaults();
    sokol.gl.pushPipeline();
    sokol.gl.loadPipeline(state.depth_test_pip);
    sokol.gl.matrixModeProjection();
    sokol.gl.multMatrix(&camera.projection.m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.multMatrix(&camera.view.m[0]);
}

pub fn gl_end() void {
    sokol.gl.popPipeline();
}

pub fn gl_draw() void {
    sokol.gl.draw();
    // sokol.gl.contextDraw(sokol.gl.defaultContext());
}

pub fn draw_axis() void {
    sokol.gl.beginLines();
    defer sokol.gl.end();

    // X axis (green).
    sokol.gl.c3f(0xff, 0, 0);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(1, 0, 0);

    // Y axis (green).
    sokol.gl.c3f(0, 0xff, 0);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(0, 1, 0);

    // Z axis (green).
    sokol.gl.c3f(0, 0, 0xff);
    sokol.gl.v3f(0, 0, 0);
    sokol.gl.v3f(0, 0, 1);
}

pub fn draw_grid(_cell_count: i32, _cell_size: f32) void {
    const extent: f32 = @as(f32, @floatFromInt(_cell_count)) * _cell_size;
    const half_extent: f32 = extent * 0.5;
    const corner = Vec3{ .x = -half_extent, .y = 0, .z = -half_extent };

    {
        sokol.gl.beginTriangleStrip();
        defer sokol.gl.end();

        sokol.gl.c4b(0x80, 0xc0, 0xd0, 0xb0);

        var v = corner;
        sokol.gl.v3f(v.x, v.y, v.z);
        v.z = corner.z + extent;
        sokol.gl.v3f(v.x, v.y, v.z);
        v.x = corner.x + extent;
        v.z = corner.z;
        sokol.gl.v3f(v.x, v.y, v.z);
        v.z = corner.z + extent;
        sokol.gl.v3f(v.x, v.y, v.z);
    }

    {
        sokol.gl.beginLines();
        defer sokol.gl.end();

        // Renders lines along X axis.
        var begin = corner;
        sokol.gl.c3b(0x54, 0x55, 0x50);
        var end = begin;
        end.x += extent;
        for (0..@intCast(_cell_count + 1)) |_| {
            sokol.gl.v3f(begin.x, begin.y, begin.z);
            sokol.gl.v3f(end.x, end.y, end.z);
            begin.z += _cell_size;
            end.z += _cell_size;
        }
        // Renders lines along Z axis.
        begin = corner;
        end = begin;
        end.z += extent;
        for (0..@intCast(_cell_count + 1)) |_| {
            sokol.gl.v3f(begin.x, begin.y, begin.z);
            sokol.gl.v3f(end.x, end.y, end.z);
            begin.x += _cell_size;
            end.x += _cell_size;
        }
    }
}
