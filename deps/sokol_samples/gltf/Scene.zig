const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const shader = @import("gltf.glsl.zig");
const rowmath = @import("rowmath");
const zigltf = @import("zigltf");

pub const Vertex = struct {
    position: [3]f32,
    normal: [3]f32,
};

pub const Mesh = struct {
    bind: sg.Bindings = undefined,
    draw_count: u32 = 0,

    pub fn init(
        self: *@This(),
        vertices: []Vertex,
        indices: []u16,
    ) void {
        self.bind.vertex_buffers[0] = sg.makeBuffer(.{
            .data = sg.asRange(vertices),
            .label = "gltf-vertices",
        });
        self.bind.index_buffer = sg.makeBuffer(.{
            .type = .INDEXBUFFER,
            .data = sg.asRange(indices),
            .label = "gltf-indices",
        });
        self.draw_count = @intCast(indices.len);
    }

    pub fn draw(self: *const @This()) void {
        sg.applyBindings(self.bind);
        sg.draw(0, self.draw_count, 1);
    }
};

pub const Scene = @This();
allocator: std.mem.Allocator = undefined,
meshes: []Mesh = &.{},
pip: sg.Pipeline = undefined,

pub fn init(self: *@This(), allocator: std.mem.Allocator) void {
    self.allocator = allocator;

    // create pipeline object
    var pip_desc = sg.PipelineDesc{
        .shader = sg.makeShader(shader.gltfShaderDesc(sg.queryBackend())),
        .index_type = .UINT16,
        .cull_mode = .BACK,
        .face_winding = .CCW,
        .depth = .{
            .write_enabled = true,
            .compare = .LESS_EQUAL,
        },
        .label = "cube-pipeline",
    };
    // test to provide buffer stride, but no attr offsets
    // pip_desc.layout.buffers[0].stride = 28;
    pip_desc.layout.attrs[shader.ATTR_vs_position].format = .FLOAT3;
    pip_desc.layout.attrs[shader.ATTR_vs_normal].format = .FLOAT3;
    self.pip = sg.makePipeline(pip_desc);
}

pub fn deinit(self: *@This()) void {
    self.allocator.free(self.meshes);
}

pub fn load(
    self: *@This(),
    gltf: zigltf.Gltf,
    bin: []const u8,
) !void {
    var meshes = std.ArrayList(Mesh).init(self.allocator);
    defer meshes.deinit();
    var mesh_vertices = std.ArrayList(Vertex).init(self.allocator);
    defer mesh_vertices.deinit();
    var mesh_indices = std.ArrayList(u16).init(self.allocator);
    defer mesh_indices.deinit();

    var gltf_buffer = zigltf.GltfBuffer.init(
        self.allocator,
        gltf,
        bin,
    );
    defer gltf_buffer.deinit();

    for (gltf.meshes) |gltf_mesh| {
        var vertex_count: u32 = 0;
        var index_count: u32 = 0;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];
            const index_accessor = gltf.accessors[primitive.indices.?];
            vertex_count += pos_accessor.count;
            index_count += index_accessor.count;
        }
        try mesh_vertices.resize(vertex_count);
        try mesh_indices.resize(index_count);

        vertex_count = 0;
        index_count = 0;
        for (gltf_mesh.primitives) |primitive| {
            const pos_accessor = gltf.accessors[primitive.attributes.POSITION];
            const index_accessor = gltf.accessors[primitive.indices.?];

            {
                // position
                const positions = try gltf_buffer.getAccessorBytes(
                    [3]f32,
                    primitive.attributes.POSITION,
                );
                for (positions, 0..) |pos, i| {
                    mesh_vertices.items[vertex_count + i].position = pos;
                }
            }
            if (primitive.attributes.NORMAL) |normal_accessor_index| {
                // normal
                const normals = try gltf_buffer.getAccessorBytes(
                    [3]f32,
                    normal_accessor_index,
                );
                for (normals, 0..) |normal, i| {
                    mesh_vertices.items[vertex_count + i].normal = normal;
                }
            }

            if (primitive.indices) |indices_accessor_index| {
                // indies
                const indices = try gltf_buffer.getAccessorBytes(
                    u16,
                    indices_accessor_index,
                );
                for (indices, 0..) |index, i| {
                    mesh_indices.items[index_count + i] = index + @as(u16, @intCast(vertex_count));
                }
            } else {
                unreachable;
            }

            vertex_count += pos_accessor.count;
            index_count += index_accessor.count;
        }

        var mesh = Mesh{};
        mesh.init(mesh_vertices.items, mesh_indices.items);
        try meshes.append(mesh);
    }
    self.meshes = try meshes.toOwnedSlice();
}

pub fn draw(self: *@This(), camera: rowmath.Camera) void {
    const vs_params = shader.VsParams{
        .mvp = camera.viewProjectionMatrix().m,
    };

    sg.applyPipeline(self.pip);
    for (self.meshes) |mesh| {
        sg.applyUniforms(.VS, shader.SLOT_vs_params, sg.asRange(&vs_params));
        mesh.draw();
    }
}
