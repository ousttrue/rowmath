const std = @import("std");
pub const Asset = @import("Asset.zig");
pub const Gltf = @This();

asset: Asset,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{{\n", .{});
    try writer.print("  asset: {s}", .{self.asset});
    try writer.print("}}\n", .{});
}
