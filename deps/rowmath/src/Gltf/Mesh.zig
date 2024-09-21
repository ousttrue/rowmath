const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Mesh = @This();

const Attributes = struct {
    POSITION: u32,
    NORMAL: ?u32,

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        // if (self.POSITION) |POSITION| {
        try writer.print("[POS=>#{}]", .{self.POSITION});
        // }
        if (self.NORMAL) |NORMAL| {
            try writer.print("[NOM=>#{}]", .{NORMAL});
        }
    }
};

const Primitive = struct {
    attributes: Attributes,
    material: ?u32 = null,
    indices: ?u32 = null,
};

name: ?[]const u8 = null,
primitives: []Primitive,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try format_helper.string_value(writer, self.name, .{});
    try writer.print("{{\n", .{});

    try writer.print("  primitives[{}]:[\n", .{self.primitives.len});
    // attributes
    for (self.primitives, 0..) |primitive, i| {
        try writer.print("    #{}:{{", .{i});
        if (primitive.material) |material| {
            try writer.print(" => material#{}", .{material});
        }
        try writer.print("\n", .{});
        try writer.print("      {any}\n", .{primitive.attributes});
        if (primitive.indices) |indices| {
            try writer.print("      [indices=>#{}]\n", .{indices});
        } else {
            unreachable;
        }
        try writer.print("    }}\n", .{});
    }
    try writer.print("  ]\n", .{});
    try writer.print("}}", .{});
}
