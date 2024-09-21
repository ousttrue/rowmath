const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Buffer = @This();

byteLength: u32,
uri: ?[]const u8,

const prefixies = [_][]const u8{
    "data:application/octet-stream;base64,",
    "data:application/gltf-buffer;base64,",
};

pub fn base64FromUri(uri: []const u8) ?[]const u8 {
    for (prefixies) |prefix| {
        if (std.mem.startsWith(u8, uri, prefix)) {
            return uri[prefix.len..];
        }
    }
    return null;
}

pub fn base64DecodeSize(self: @This()) ?u32 {
    const uri = self.uri orelse {
        return null;
    };
    const base64 = base64FromUri(uri) orelse {
        return null;
    };
    const len = std.base64.standard.Decoder.calcSizeForSlice(base64) catch {
        return null;
    };
    return len;
}

pub fn format(
    self: @This(),
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("{}bytes", .{
        self.byteLength,
    });

    if (self.uri) |uri| {
        if (base64FromUri(uri)) |base64| {
            // try writer.print(" => {s} ", .{uri});
            if (std.base64.standard_no_pad.Decoder.calcSizeForSlice(base64)) |len| {
                try writer.print(" =[base64]> {}bytes", .{len});
            } else |e| {
                try writer.print(" =[base64]> {s}", .{@errorName(e)});
            }
        } else {
            try writer.print(" => {s} ", .{uri});
        }
    }
}

