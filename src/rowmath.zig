//------------------------------------------------------------------------------
// row-major linear math
//
// * memory layout
// mat4: [00,01,02,03,10,11,12,13,20,21,22,23,30,31,32,33]
//
// * mul order
// [vec4][model][view][projection]
//
// * trs
// [vec4][s][r][t]
//------------------------------------------------------------------------------
const std = @import("std");

fn radians(deg: f32) f32 {
    return deg * (std.math.pi / 180.0);
}

pub const Vec2 = extern struct {
    x: f32,
    y: f32,

    pub fn zero() Vec2 {
        return Vec2{ .x = 0.0, .y = 0.0 };
    }

    pub fn new(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }
};

pub const Vec3 = extern struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{{{d:.2},{d:.2},{d:.2}}}", .{
            self.x,
            self.y,
            self.z,
        });
    }

    pub const ONE = Vec3{ .x = 1, .y = 1, .z = 1 };
    pub const ZERO = Vec3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    pub const RIGHT: Vec3 = .{ .x = 1, .y = 0, .z = 0 };
    pub const UP: Vec3 = .{ .x = 0, .y = 1, .z = 0 };
    pub const FORWARD: Vec3 = .{ .x = 0, .y = 0, .z = 1 };

    pub fn scalar(f: f32) Vec3 {
        return .{
            .x = f,
            .y = f,
            .z = f,
        };
    }

    pub fn new(x: f32, y: f32, z: f32) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn up() Vec3 {
        return Vec3{ .x = 0.0, .y = 1.0, .z = 0.0 };
    }

    pub fn negate(self: @This()) @This() {
        return .{ .x = -self.x, .y = -self.y, .z = -self.z };
    }

    pub fn len2(v: Vec3) f32 {
        return Vec3.dot(v, v);
    }

    pub fn len(v: Vec3) f32 {
        return std.math.sqrt(v.len2());
    }

    pub fn add(left: Vec3, right: Vec3) Vec3 {
        return Vec3{ .x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z };
    }

    pub fn sub(left: Vec3, right: Vec3) Vec3 {
        return Vec3{ .x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z };
    }

    pub fn scale(v: Vec3, s: f32) Vec3 {
        return Vec3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
    }

    pub fn norm(v: Vec3) Vec3 {
        const l = Vec3.len(v);
        if (l != 0.0) {
            return Vec3{ .x = v.x / l, .y = v.y / l, .z = v.z / l };
        } else {
            return Vec3.ZERO;
        }
    }

    pub fn mul_each(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{
            .x = v0.x * v1.x,
            .y = v0.y * v1.y,
            .z = v0.z * v1.z,
        };
    }

    pub fn cross(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{ .x = (v0.y * v1.z) - (v0.z * v1.y), .y = (v0.z * v1.x) - (v0.x * v1.z), .z = (v0.x * v1.y) - (v0.y * v1.x) };
    }

    pub fn dot(v0: Vec3, v1: Vec3) f32 {
        return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
    }
};

pub const Vec4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const RED: Vec4 = .{ .x = 1, .y = 0, .z = 0, .w = 1.0 };
    pub const GREEN: Vec4 = .{ .x = 0, .y = 1, .z = 0, .w = 1.0 };
    pub const BLUE: Vec4 = .{ .x = 0, .y = 0, .z = 1, .w = 1.0 };
    pub const CYAN: Vec4 = .{ .x = 0, .y = 0.5, .z = 0.5, .w = 1.0 };
    pub const MAGENTA: Vec4 = .{ .x = 0.5, .y = 0, .z = 0.5, .w = 1.0 };
    pub const YELLOW: Vec4 = .{ .x = 0.3, .y = 0.3, .z = 0, .w = 1.0 };
    pub const GRAY: Vec4 = .{ .x = 0.7, .y = 0.7, .z = 0.7, .w = 1.0 };

    pub fn fromVec3(v: Vec3, w: f32) @This() {
        return .{
            .x = v.x,
            .y = v.y,
            .z = v.z,
            .w = w,
        };
    }

    pub fn toVec3(self: @This()) Vec3 {
        return .{
            .x = self.x,
            .y = self.y,
            .z = self.z,
        };
    }

    pub fn dot(v0: Vec4, v1: Vec4) f32 {
        return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z + v0.w * v1.w;
    }
};

pub const Mat4 = extern struct {
    m: [16]f32,

    pub fn identity() Mat4 {
        return Mat4{
            .m = [_]f32{
                1.0, 0.0, 0.0, 0.0,
                0.0, 1.0, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0,
            },
        };
    }

    pub fn zero() Mat4 {
        return Mat4{
            .m = [_]f32{
                0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0,
            },
        };
    }

    pub fn transpose(s: Mat4) Mat4 {
        return .{
            .m = [_]f32{
                s.m[0], s.m[4], s.m[8],  s.m[12],
                s.m[1], s.m[5], s.m[9],  s.m[13],
                s.m[2], s.m[6], s.m[10], s.m[14],
                s.m[3], s.m[7], s.m[11], s.m[15],
            },
        };
    }

    pub fn scale(s: Vec3) Mat4 {
        return Mat4{
            .m = [_]f32{
                s.x, 0.0, 0.0, 0.0,
                0.0, s.y, 0.0, 0.0,
                0.0, 0.0, s.z, 0.0,
                0.0, 0.0, 0.0, 1.0,
            },
        };
    }

    pub fn scale_uniform(s: f32) Mat4 {
        return scale(.{ .x = s, .y = s, .z = s });
    }

    pub fn row0(self: Mat4) Vec4 {
        return .{ .x = self.m[0], .y = self.m[1], .z = self.m[2], .w = self.m[3] };
    }
    pub fn row1(self: Mat4) Vec4 {
        return .{ .x = self.m[4], .y = self.m[5], .z = self.m[6], .w = self.m[7] };
    }
    pub fn row2(self: Mat4) Vec4 {
        return .{ .x = self.m[8], .y = self.m[9], .z = self.m[10], .w = self.m[11] };
    }
    pub fn row3(self: Mat4) Vec4 {
        return .{ .x = self.m[12], .y = self.m[13], .z = self.m[14], .w = self.m[15] };
    }
    pub fn col0(self: Mat4) Vec4 {
        return .{ .x = self.m[0], .y = self.m[4], .z = self.m[8], .w = self.m[12] };
    }
    pub fn col1(self: Mat4) Vec4 {
        return .{ .x = self.m[1], .y = self.m[5], .z = self.m[9], .w = self.m[13] };
    }
    pub fn col2(self: Mat4) Vec4 {
        return .{ .x = self.m[2], .y = self.m[6], .z = self.m[10], .w = self.m[14] };
    }
    pub fn col3(self: Mat4) Vec4 {
        return .{ .x = self.m[3], .y = self.m[7], .z = self.m[11], .w = self.m[15] };
    }

    pub fn mul(left: Mat4, right: Mat4) Mat4 {
        return Mat4{
            .m = [_]f32{
                left.row0().dot(right.col0()), left.row0().dot(right.col1()), left.row0().dot(right.col2()), left.row0().dot(right.col3()),
                left.row1().dot(right.col0()), left.row1().dot(right.col1()), left.row1().dot(right.col2()), left.row1().dot(right.col3()),
                left.row2().dot(right.col0()), left.row2().dot(right.col1()), left.row2().dot(right.col2()), left.row2().dot(right.col3()),
                left.row3().dot(right.col0()), left.row3().dot(right.col1()), left.row3().dot(right.col2()), left.row3().dot(right.col3()),
            },
        };
    }

    pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
        var res = Mat4.identity();
        const t = std.math.tan(fov / 2);
        res.m[0] = 1.0 / t / aspect;
        res.m[5] = 1 / t;
        res.m[11] = -1.0;
        res.m[10] = (near + far) / (near - far);
        res.m[14] = (2.0 * near * far) / (near - far);
        res.m[15] = 0.0;
        return res;
    }

    pub fn lookat(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
        var res = Mat4.zero();

        const f = Vec3.norm(Vec3.sub(center, eye));
        const s = Vec3.norm(Vec3.cross(f, up));
        const u = Vec3.cross(s, f);

        res.m[0] = s.x;
        res.m[1] = u.x;
        res.m[2] = -f.x;

        res.m[4] = s.y;
        res.m[5] = u.y;
        res.m[6] = -f.y;

        res.m[8] = s.z;
        res.m[9] = u.z;
        res.m[10] = -f.z;

        res.m[12] = -Vec3.dot(s, eye);
        res.m[13] = -Vec3.dot(u, eye);
        res.m[14] = Vec3.dot(f, eye);
        res.m[15] = 1.0;

        return res;
    }

    pub fn rotate(angle: f32, axis_unorm: Vec3) Mat4 {
        var res = Mat4.identity();

        const axis = Vec3.norm(axis_unorm);
        const sin_theta = std.math.sin(radians(angle));
        const cos_theta = std.math.cos(radians(angle));
        const cos_value = 1.0 - cos_theta;

        res.m[0] = (axis.x * axis.x * cos_value) + cos_theta;
        res.m[1] = (axis.x * axis.y * cos_value) + (axis.z * sin_theta);
        res.m[2] = (axis.x * axis.z * cos_value) - (axis.y * sin_theta);
        res.m[4] = (axis.y * axis.x * cos_value) - (axis.z * sin_theta);
        res.m[5] = (axis.y * axis.y * cos_value) + cos_theta;
        res.m[6] = (axis.y * axis.z * cos_value) + (axis.x * sin_theta);
        res.m[8] = (axis.z * axis.x * cos_value) + (axis.y * sin_theta);
        res.m[9] = (axis.z * axis.y * cos_value) - (axis.x * sin_theta);
        res.m[10] = (axis.z * axis.z * cos_value) + cos_theta;

        return res;
    }

    pub fn translate(translation: Vec3) Mat4 {
        var res = Mat4.identity();
        res.m[12] = translation.x;
        res.m[13] = translation.y;
        res.m[14] = translation.z;
        return res;
    }

    pub fn trs(t: Vec3, r: Quat, s: Vec3) Mat4 {
        return .{
            .m = f4(r.dirX().scale(s.x), 0) ++
                f4(r.dirY().scale(s.y), 0) ++
                f4(r.dirZ().scale(s.z), 0) ++
                [4]f32{ t.x, t.y, t.z, 1 },
        };
    }

    pub fn transform_coord(self: @This(), coord: Vec3) Vec3 {
        const r = self.apply(Vec4.fromVec3(coord, 1));
        return .{
            .x = r.x / r.w,
            .y = r.y / r.w,
            .z = r.z / r.w,
        };
    }

    pub fn transform_vector(self: @This(), vector: Vec3) Vec3 {
        return self.apply(Vec4.fromVec3(vector, 0)).toVec3();
    }

    pub fn apply(self: @This(), v: Vec4) Vec4 {
        return .{
            .x = v.dot(self.col0()),
            .y = v.dot(self.col1()),
            .z = v.dot(self.col2()),
            .w = v.dot(self.col3()),
        };
    }
};

test "Vec3.zero" {
    const v = Vec3.zero();
    try std.testing.expect(v.x == 0.0 and v.y == 0.0 and v.z == 0.0);
}

test "Vec3.new" {
    const v = Vec3.new(1.0, 2.0, 3.0);
    try std.testing.expect(v.x == 1.0 and v.y == 2.0 and v.z == 3.0);
}

test "Mat4.ident" {
    const m = Mat4.identity();
    try std.testing.expectEqual(m.m, [_]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
}

test "Mat4.mul" {
    const l = Mat4.identity();
    const r = Mat4.identity();
    const m = Mat4.mul(l, r);
    try std.testing.expectEqual(m.m, [_]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    });
}

fn eq(val: f32, cmp: f32) bool {
    const delta: f32 = 0.00001;
    return (val > (cmp - delta)) and (val < (cmp + delta));
}

test "Mat4.persp" {
    const m = Mat4.persp(60.0, 1.33333337, 0.01, 10.0);

    try std.testing.expect(eq(m.m[0], 1.73205));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], 0.0));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 2.30940));
    try std.testing.expect(eq(m.m[6], 0.0));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.0));
    try std.testing.expect(eq(m.m[9], 0.0));
    try std.testing.expect(eq(m.m[10], -1.00200));
    try std.testing.expect(eq(m.m[11], -1.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], -0.02002));
    try std.testing.expect(eq(m.m[15], 0.0));
}

test "Mat4.lookat" {
    const m = Mat4.lookat(.{ .x = 0.0, .y = 1.5, .z = 6.0 }, Vec3.zero(), Vec3.up());

    try std.testing.expect(eq(m.m[0], 1.0));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], 0.0));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 0.97014));
    try std.testing.expect(eq(m.m[6], 0.24253));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.0));
    try std.testing.expect(eq(m.m[9], -0.24253));
    try std.testing.expect(eq(m.m[10], 0.97014));
    try std.testing.expect(eq(m.m[11], 0.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], -6.18465));
    try std.testing.expect(eq(m.m[15], 1.0));
}

test "Mat4.rotate" {
    const m = Mat4.rotate(2.0, .{ .x = 0.0, .y = 1.0, .z = 0.0 });

    try std.testing.expect(eq(m.m[0], 0.99939));
    try std.testing.expect(eq(m.m[1], 0.0));
    try std.testing.expect(eq(m.m[2], -0.03489));
    try std.testing.expect(eq(m.m[3], 0.0));

    try std.testing.expect(eq(m.m[4], 0.0));
    try std.testing.expect(eq(m.m[5], 1.0));
    try std.testing.expect(eq(m.m[6], 0.0));
    try std.testing.expect(eq(m.m[7], 0.0));

    try std.testing.expect(eq(m.m[8], 0.03489));
    try std.testing.expect(eq(m.m[9], 0.0));
    try std.testing.expect(eq(m.m[10], 0.99939));
    try std.testing.expect(eq(m.m[11], 0.0));

    try std.testing.expect(eq(m.m[12], 0.0));
    try std.testing.expect(eq(m.m[13], 0.0));
    try std.testing.expect(eq(m.m[14], 0.0));
    try std.testing.expect(eq(m.m[15], 1.0));
}

fn f4(v: Vec3, w: f32) [4]f32 {
    return .{ v.x, v.y, v.z, w };
}

pub const Quat = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const IDENTITY: Quat = .{
        .x = 0,
        .y = 0,
        .z = 0,
        .w = 1,
    };

    pub fn axisAngle(axis: Vec3, angle: f32) Quat {
        const s = std.math.sin(angle / 2);
        return .{
            .x = axis.x * s,
            .y = axis.y * s,
            .z = axis.z * s,
            .w = std.math.cos(angle / 2),
        };
    }

    pub fn conj(q: @This()) @This() {
        return .{
            .x = -q.x,
            .y = -q.y,
            .z = -q.z,
            .w = q.w,
        };
    }

    pub fn length2(q: @This()) f32 {
        return q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
    }

    pub fn inverse(q: @This()) @This() {
        const sqlen = q.length2();
        const c = q.conj();
        return .{
            .x = c.x / sqlen,
            .y = c.y / sqlen,
            .z = c.z / sqlen,
            .w = c.w / sqlen,
        };
    }

    pub fn mul(a: @This(), b: @This()) @This() {
        return .{
            .x = a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
            .y = a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
            .z = a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
            .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
        };
    }

    pub fn dirX(q: @This()) Vec3 {
        return .{
            .x = q.w * q.w + q.x * q.x - q.y * q.y - q.z * q.z,
            .y = (q.x * q.y + q.z * q.w) * 2,
            .z = (q.z * q.x - q.y * q.w) * 2,
        };
    }

    pub fn dirY(q: @This()) Vec3 {
        return .{
            .x = (q.x * q.y - q.z * q.w) * 2,
            .y = q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z,
            .z = (q.y * q.z + q.x * q.w) * 2,
        };
    }

    pub fn dirZ(q: @This()) Vec3 {
        return .{
            .x = (q.z * q.x + q.y * q.w) * 2,
            .y = (q.y * q.z - q.x * q.w) * 2,
            .z = q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z,
        };
    }

    pub fn matrix(q: @This()) Mat4 {
        return .{
            .m = f4(q.dirX(), 0) ++
                f4(q.dirY(), 0) ++
                f4(q.dirZ(), 0) ++
                [4]f32{ 0, 0, 0, 1 },
        };
    }

    pub fn qrot(q: @This(), v: Vec3) Vec3 {
        return (q.dirX().scale(v.x)).add(q.dirY().scale(v.y)).add(q.dirZ().scale(v.z));
    }
};

pub const RigidTransform = struct {
    rotation: Quat = Quat.IDENTITY,
    translation: Vec3 = Vec3.ZERO,

    pub fn localToWorld(self: @This()) Mat4 {
        const r = self.rotation.matrix();
        const t = Mat4.translate(self.translation);
        return r.mul(t);
    }

    pub fn worldToLocal(self: @This()) Mat4 {
        const t = Mat4.translate(self.translation.negate());
        const r = self.rotation.conj().matrix();
        return t.mul(r);
    }
};

pub const Transform = struct {
    // rigid_transform() {}
    // rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position, const minalg::float3 & scale) : orientation(orientation), position(position), scale(scale) {}
    // rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position, float scale) : orientation(orientation), position(position), scale(scale) {}
    // rigid_transform(const minalg::float4 & orientation, const minalg::float3 & position) : orientation(orientation), position(position) {}

    rigid_transform: RigidTransform = .{},
    // position: Vec3 = .{ .x = 0, .y = 0, .z = 0 },
    // orientation: Quat = .{ .x = 0, .y = 0, .z = 0, .w = 1 },
    scale: Vec3 = .{ .x = 1, .y = 1, .z = 1 },

    pub fn trs(t: Vec3, r: Quat, s: Vec3) @This() {
        return .{
            .rigid_transform = .{ .translation = t, .rotation = r },
            .scale = s,
        };
    }

    pub fn uniform_scale(self: @This()) bool {
        return self.scale.x == self.scale.y and self.scale.x == self.scale.z;
    }
    pub fn matrix(self: @This()) Mat4 {
        return Mat4.trs(
            self.rigid_transform.translation,
            self.rigid_transform.rotation,
            self.scale,
        );
    }

    pub fn transform_vector(self: @This(), vec: Vec3) Vec3 {
        return self.rigid_transform.rotation.qrot(.{
            .x = vec.x * self.scale.x,
            .y = vec.y * self.scale.y,
            .z = vec.z * self.scale.z,
        });
    }
    pub fn transform_point(self: @This(), p: Vec3) Vec3 {
        return self.rigid_transform.translation.add(self.transform_vector(p));
    }
    pub fn detransform_point(self: @This(), p: Vec3) Vec3 {
        return self.detransform_vector(p.sub(self.rigid_transform.translation));
    }
    pub fn detransform_vector(self: @This(), vec: Vec3) Vec3 {
        const v = self.rigid_transform.rotation.inverse().qrot(vec);
        return .{
            .x = v.x / self.scale.x,
            .y = v.y / self.scale.y,
            .z = v.z / self.scale.z,
        };
    }
};

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn point(self: @This(), t: f32) Vec3 {
        return self.origin.add(self.direction.scale(t));
    }

    pub fn scale(self: *@This(), f: f32) void {
        self.origin = self.origin.scale(f);
        self.direction = self.direction.scale(f);
    }

    pub fn descale(self: @This(), f: f32) Ray {
        return .{
            .origin = .{
                .x = self.origin.x / f,
                .y = self.origin.y / f,
                .z = self.origin.z / f,
            },
            .direction = .{
                .x = self.direction.x / f,
                .y = self.direction.y / f,
                .z = self.direction.z / f,
            },
        };
    }
};
