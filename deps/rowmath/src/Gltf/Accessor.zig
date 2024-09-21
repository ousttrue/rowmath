const std = @import("std");
const format_helper = @import("format_helper.zig");
pub const Accessor = @This();

name: ?[]const u8 = null,
componentType: u32,
type: []const u8,
count: u32,
bufferView: ?u32,
byteOffset: ?u32,

fn componentTypeToStr(componentType: u32) []const u8 {
    return switch (componentType) {
        5120 => "sbyte",
        5121 => "byte",
        5122 => "short",
        5123 => "ushort",
        5125 => "uint",
        5126 => "float",
        else => "unknown",
    };
}

fn typeToSuffix(type_: []const u8) []const u8 {
    if (std.mem.eql(u8, "SCALAR", type_)) {
        return "";
    } else if (std.mem.eql(u8, "VEC2", type_)) {
        return "2";
    } else if (std.mem.eql(u8, "VEC3", type_)) {
        return "3";
    } else if (std.mem.eql(u8, "VEC4", type_)) {
        return "4";
    } else if (std.mem.eql(u8, "MAT2", type_)) {
        return "4";
    } else if (std.mem.eql(u8, "MAT3", type_)) {
        return "9";
    } else if (std.mem.eql(u8, "MAT4", type_)) {
        return "16";
    } else {
        return type_;
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
    if (self.name) |name| {
        try writer.print("{s}:", .{name});
    }
    try writer.print("{s}{s}[{}]", .{
        componentTypeToStr(self.componentType),
        typeToSuffix(self.type),
        self.count,
    });
    if (self.bufferView) |bufferView| {
        try writer.print(" => bufferView#{}", .{bufferView});
        if (self.byteOffset) |byteOffset| {
            if (byteOffset > 0) {
                try writer.print("+{}", .{byteOffset});
            }
        }
    }
}
