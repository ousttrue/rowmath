const std = @import("std");
const Vec2 = @import("../Vec2.zig");
const Vec3 = @import("../Vec3.zig");
const Rgba = @import("../RgbaF32.zig");
const Ray = @import("../Ray.zig");

const TAU = 6.28318530718;

pub const GeometryVertex = struct {
    position: Vec3 = Vec3.zero,
    normal: Vec3 = Vec3.zero,
    color: Rgba = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
};

fn make_const_mesh(_vertices: anytype, _triangles: anytype) type {
    return struct {
        const vertices = _vertices;
        const triangles = _triangles;
    };
}

fn compute_normals(vertices: []GeometryVertex, triangles: []const [3]u16) void {
    const NORMAL_EPSILON = 0.0001;
    @setEvalBranchQuota(100000);

    var uniqueVertIndices = [1]u16{0} ** vertices.len;
    for (0..vertices.len) |i| {
        if (uniqueVertIndices[i] == 0) {
            uniqueVertIndices[i] = i + 1;
            const v0 = vertices[i].position;
            for (i..vertices.len) |j| {
                const v1 = vertices[j].position;
                if (v1.sub(v0).sqNorm() < NORMAL_EPSILON) {
                    uniqueVertIndices[j] = uniqueVertIndices[i];
                }
            }
        }
    }

    // uint32_t idx0, idx1, idx2;
    for (triangles) |t| {
        const idx0 = uniqueVertIndices[t[0]] - 1;
        const idx1 = uniqueVertIndices[t[1]] - 1;
        const idx2 = uniqueVertIndices[t[2]] - 1;
        var v0 = vertices[idx0];
        var v1 = vertices[idx1];
        var v2 = vertices[idx2];
        const n = v1.position.sub(v0.position).cross(v2.position.sub(v0.position));
        v0.normal = v0.normal.add(n);
        v1.normal = v1.normal.add(n);
        v2.normal = v2.normal.add(n);
    }

    for (0..vertices.len) |i| {
        vertices[i].normal = vertices[uniqueVertIndices[i] - 1].normal;
    }
    for (vertices) |*v| {
        v.normal = v.normal.normalize();
    }
}

const Mat32 = struct {
    row0: Vec3,
    row1: Vec3,
    fn mul(a: @This(), b: Vec2) Vec3 {
        return a.row0.scale(b.x).add(a.row1.scale(b.y));
    }
};

pub fn make_lathed_geometry(
    comptime axis: Vec3,
    comptime arm1: Vec3,
    comptime arm2: Vec3,
    comptime slices: i32,
    comptime points: []const Vec2,
    comptime eps: f32,
) type {
    var vertices = [1]GeometryVertex{.{}} ** ((slices + 1) * points.len);
    var triangles = [1][3]u16{.{ 0, 0, 0 }} ** (slices * (points.len - 1) * 6);
    var v_index: usize = 0;
    var t_index: usize = 0;

    @setEvalBranchQuota(4000);
    for (0..slices + 1) |i| {
        const angle = (@as(f32, @floatFromInt(i % slices)) * TAU / slices) + (TAU / 8.0);
        const c = std.math.cos(angle);
        const s = std.math.sin(angle);
        const mat = Mat32{ .row0 = axis, .row1 = arm1.scale(c).add(arm2.scale(s)) };
        for (points) |p| {
            vertices[v_index].position = mat.mul(p).add(.{ .x = eps, .y = eps, .z = eps });
            v_index += 1;
        }

        if (i > 0) {
            for (1..points.len) |j| {
                const index0: u16 = @intCast((i - 1) * (points.len) + (j - 1));
                const index1: u16 = @intCast((i - 0) * (points.len) + (j - 1));
                const index2: u16 = @intCast((i - 0) * (points.len) + (j - 0));
                const index3: u16 = @intCast((i - 1) * (points.len) + (j - 0));
                triangles[t_index] = .{ index0, index1, index2 };
                t_index += 1;
                triangles[t_index] = .{ index0, index2, index3 };
                t_index += 1;
            }
        }
    }

    compute_normals(&vertices, &triangles);

    return make_const_mesh(vertices, triangles);
}

pub fn make_box_geometry(a: Vec3, b: Vec3) type {
    // geometry_mesh mesh;
    const vertices = [_]GeometryVertex{
        .{ .position = .{ .x = a.x, .y = a.y, .z = a.z }, .normal = .{ .x = -1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = a.y, .z = b.z }, .normal = .{ .x = -1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = b.z }, .normal = .{ .x = -1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = a.z }, .normal = .{ .x = -1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = a.z }, .normal = .{ .x = 1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = a.z }, .normal = .{ .x = 1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = b.z }, .normal = .{ .x = 1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = b.z }, .normal = .{ .x = 1, .y = 0, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = a.y, .z = a.z }, .normal = .{ .x = 0, .y = -1, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = a.z }, .normal = .{ .x = 0, .y = -1, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = b.z }, .normal = .{ .x = 0, .y = -1, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = a.y, .z = b.z }, .normal = .{ .x = 0, .y = -1, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = a.z }, .normal = .{ .x = 0, .y = 1, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = b.z }, .normal = .{ .x = 0, .y = 1, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = b.z }, .normal = .{ .x = 0, .y = 1, .z = 0 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = a.z }, .normal = .{ .x = 0, .y = 1, .z = 0 } },
        .{ .position = .{ .x = a.x, .y = a.y, .z = a.z }, .normal = .{ .x = 0, .y = 0, .z = -1 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = a.z }, .normal = .{ .x = 0, .y = 0, .z = -1 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = a.z }, .normal = .{ .x = 0, .y = 0, .z = -1 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = a.z }, .normal = .{ .x = 0, .y = 0, .z = -1 } },
        .{ .position = .{ .x = a.x, .y = a.y, .z = b.z }, .normal = .{ .x = 0, .y = 0, .z = 1 } },
        .{ .position = .{ .x = b.x, .y = a.y, .z = b.z }, .normal = .{ .x = 0, .y = 0, .z = 1 } },
        .{ .position = .{ .x = b.x, .y = b.y, .z = b.z }, .normal = .{ .x = 0, .y = 0, .z = 1 } },
        .{ .position = .{ .x = a.x, .y = b.y, .z = b.z }, .normal = .{ .x = 0, .y = 0, .z = 1 } },
    };
    const triangles = [_][3]u16{
        .{ 0, 1, 2 },    .{ 0, 2, 3 },    .{ 4, 5, 6 },    .{ 4, 6, 7 },    .{ 8, 9, 10 },
        .{ 8, 10, 11 },  .{ 12, 13, 14 }, .{ 12, 14, 15 }, .{ 16, 17, 18 }, .{ 16, 18, 19 },
        .{ 20, 21, 22 }, .{ 20, 22, 23 },
    };

    return make_const_mesh(vertices, triangles);
}

const Triangle = struct {
    v0: Vec3,
    v1: Vec3,
    v2: Vec3,

    fn intersect(self: @This(), ray: Ray) ?f32 {
        const e1 = self.v1.sub(self.v0);
        const e2 = self.v2.sub(self.v0);
        const h = ray.direction.cross(e2);
        const a = e1.dot(h);
        if (@abs(a) == 0) {
            return null;
        }

        const f = 1 / a;
        const s = ray.origin.sub(self.v0);
        const u = f * s.dot(h);
        if (u < 0 or u > 1) {
            return null;
        }

        const q = s.cross(e1);
        const v = f * ray.direction.dot(q);
        if (v < 0 or u + v > 1) {
            return null;
        }

        const t = f * e2.dot(q);
        if (t < 0) {
            return null;
        }

        return t;
    }
};

pub const GeometryMesh = struct {
    vertices: []const GeometryVertex,
    triangles: []const [3]u16,

    pub fn intersect(self: @This(), ray: Ray) ?f32 {
        var best_t = std.math.inf(f32);
        for (self.triangles) |a| {
            const triangle = Triangle{
                .v0 = self.vertices[a[0]].position,
                .v1 = self.vertices[a[1]].position,
                .v2 = self.vertices[a[2]].position,
            };
            if (triangle.intersect(ray)) |t| {
                if (t < best_t) {
                    best_t = t;
                }
            }
        }
        return if (best_t == std.math.inf(f32)) null else best_t;
    }
};

pub const MeshComponent = struct {
    mesh: GeometryMesh,
    base_color: Rgba,

    pub fn init(mesh: type, base_color: Rgba) @This() {
        return .{
            .mesh = .{
                .vertices = &mesh.vertices,
                .triangles = &mesh.triangles,
            },
            .base_color = base_color,
        };
    }
};
