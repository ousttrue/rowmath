const std = @import("std");
const format_helper = @import("format_helper.zig");

pub const Asset = @This();
version: []const u8,
minVersion: ?[]const u8 = null,
copyright: ?[]const u8 = null,
generator: ?[]const u8 = null,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{{\n", .{});
    try writer.print("  version: \"{s}\"\n", .{self.version});
    try format_helper.string_field(writer, 2, "minVersion", self.minVersion, .{});
    try format_helper.string_field(writer, 2, "generator", self.generator, .{});
    try format_helper.string_field(writer, 2, "copyright", self.copyright, .{});
    try writer.print("}}", .{});
}
