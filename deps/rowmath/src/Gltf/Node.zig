const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Node = @This();

name: ?[]const u8 = null,
matrix: ?[16]f32 = null,
translation: ?[3]f32 = null,
rotation: ?[4]f32 = null,
scale: ?[3]f32 = null,
children: []u32 = &.{},
mesh: ?u32 = null,
skin: ?u32 = null,

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
    try writer.print("  children: {any}\n", .{self.children});
    try format_helper.number_field(writer, 2, "mesh", self.mesh, .{});
    try format_helper.number_field(writer, 2, "skin", self.skin, .{});
    try writer.print("}}", .{});
}
