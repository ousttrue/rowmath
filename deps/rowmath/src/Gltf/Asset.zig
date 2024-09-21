const std = @import("std");

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
    try writer.print("    version: {s}\n", .{self.version});
    try writer.print("    minVersion: {s}\n", .{if (self.minVersion) |x| x else "null"});
    try writer.print("    generator: {s}\n", .{if (self.generator) |x| x else "null"});
    try writer.print("    copyright: {s}\n", .{if (self.copyright) |x| x else "null"});
    try writer.print("  }}\n", .{});
}
