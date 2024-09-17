const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const gizmo = rowmath.gizmo;
const ig = @import("cimgui");
pub const Gizmo = @This();

allocator: std.mem.Allocator = undefined,
ctx: gizmo.Context = .{},
drawlist: std.ArrayList(gizmo.Renderable) = undefined,
t: rowmath.gizmo.TranslationContext = .{},

pub fn init(self: *@This(), allocator: std.mem.Allocator) void {
    self.drawlist = std.ArrayList(gizmo.Renderable).init(allocator);
}

pub fn gl_draw(self: @This()) void {
    for (self.drawlist.items) |m| {
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
