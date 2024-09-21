const std = @import("std");
pub const Asset = @import("Asset.zig");
pub const BufferView = @import("BufferView.zig");
pub const Accessor = @import("Accessor.zig");
pub const Material = @import("Material.zig");
pub const Mesh = @import("Mesh.zig");
pub const Node = @import("Node.zig");
pub const Skin = @import("Skin.zig");
pub const Gltf = @This();

asset: Asset,
bufferViews: []BufferView = &.{},
accessors: []Accessor = &.{},
materials: []Material = &.{},
meshes: []Mesh = &.{},
nodes: []Node = &.{},
skins: []Skin = &.{},

fn print_list(writer: anytype, name: []const u8, list: anytype) !void {
    if (list.len > 0) {
        try writer.print("{s}[{}]: [\n", .{ name, list.len });
        for (list, 0..) |x, i| {
            try writer.print("#{}:{any}\n", .{ i, x });
        }
        try writer.print("]\n", .{});
    }
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{{\n", .{});

    try writer.print("asset: {any}\n", .{self.asset});

    try print_list(writer, "bufferViews", self.bufferViews);
    try print_list(writer, "accessors", self.accessors);
    try print_list(writer, "materials", self.materials);
    try print_list(writer, "meshes", self.meshes);
    try print_list(writer, "nodes", self.nodes);
    try print_list(writer, "skins", self.skins);

    try writer.print("}}\n", .{});
}
