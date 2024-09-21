const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const BufferView = @This();

name: ?[]const u8 = null,
buffer: u32,
byteLength: u32,
byteOffset: u32 = 0,
byteStride: ?u32 = null,

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    // try writer.print("{{", .{});
    // try format_helper.string_value(writer, self.name, .{});
    // try writer.print("\n", .{});
    // try writer.print("}}\n", .{});
    try writer.print("buffer#{}[{}..{}] {}bytes", .{
        self.buffer,
        self.byteOffset,
        self.byteOffset + self.byteLength,
        self.byteLength,
    });
    if (self.byteStride) |stride| {
        if (stride > 0) {
            try writer.print(" stride={}", .{stride});
        }
    }
}

