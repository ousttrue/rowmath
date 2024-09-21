pub const Options = struct {
    show_null: bool = false,
};

pub fn number_field(
    writer: anytype,
    comptime indent: usize,
    key: []const u8,
    value: ?u32,
    opts: Options,
) !void {
    if (opts.show_null or value != null) {
        try writer.print("{s}", .{" " ** indent});
        try writer.print("{s}: ", .{key});
        try number_value(writer, value, .{ .show_null = true });
        try writer.print("\n", .{});
    }
}

pub fn number_value(
    writer: anytype,
    value: ?u32,
    opts: Options,
) !void {
    if (value) |x| {
        try writer.print("{}", .{x});
    } else if (opts.show_null) {
        try writer.print("null", .{});
    }
}

pub fn number4_field(
    writer: anytype,
    comptime indent: usize,
    key: []const u8,
    value: ?struct { f32, f32, f32, f32 },
    opts: Options,
) !void {
    if (opts.show_null or value != null) {
        try writer.print("{s}", .{" " ** indent});
        try writer.print("{s}: ", .{key});
        try number4_value(writer, value, .{ .show_null = true });
        try writer.print("\n", .{});
    }
}

pub fn number4_value(
    writer: anytype,
    value: ?struct { f32, f32, f32, f32 },
    opts: Options,
) !void {
    if (value) |x| {
        try writer.print("[{d},{d},{d},{d}]", .{ x[0], x[1], x[2], x[3] });
    } else if (opts.show_null) {
        try writer.print("null", .{});
    }
}

pub fn string_field(
    writer: anytype,
    comptime indent: usize,
    key: []const u8,
    value: ?[]const u8,
    opts: Options,
) !void {
    if (opts.show_null or value != null) {
        try writer.print("{s}", .{" " ** indent});
        try writer.print("{s}: ", .{key});
        try string_value(writer, value, .{ .show_null = true });
        try writer.print("\n", .{});
    }
}

pub fn string_value(
    writer: anytype,
    value: ?[]const u8,
    opts: Options,
) !void {
    if (value) |x| {
        try writer.print("\"{s}\"", .{x});
    } else if (opts.show_null) {
        try writer.print("null", .{});
    }
}
