const std = @import("std");
pub const Tokenizer = @This();
const Result = struct {
    token: []const u8,
    next: []const u8,
};
const Delimiter = fn ([]const u8) ?usize;

pub fn is_space(str: []const u8) ?usize {
    if (!std.ascii.isWhitespace(str[0])) {
        return null;
    }

    for (str, 0..) |c, i| {
        if (!std.ascii.isWhitespace(c)) {
            return i;
        }
    }

    return str.len;
}

pub fn get_name(str: []const u8) ?usize {
    if (str[0] != '\n') {
        return null;
    }
    // head space
    for (str, 0..) |c, i| {
        if (!std.ascii.isWhitespace(c)) {
            return i;
        }
    }

    return str.len;
}

data: []const u8,
remain: []const u8,

pub fn init(data: []const u8) @This() {
    return .{
        .data = data,
        .remain = data,
    };
}

/// get token and skip until next head
pub fn token(self: *@This(), delimiter: *const Delimiter) ?[]const u8 {
    for (self.remain, 0..) |_, i| {
        if (delimiter(self.remain[i..self.remain.len])) |found| {
            defer self.remain = self.remain[i + found .. self.remain.len];
            return self.remain[0..i];
        }
    }

    defer self.remain = self.remain[self.remain.len..self.remain.len];
    return self.remain;
}

pub fn expect(self: *@This(), expected: []const u8, delimiter: *const Delimiter) bool {
    if (self.token(delimiter)) |line| {
        if (std.mem.eql(u8, line, expected)) {
            return true;
        }
    }
    return false;
}

pub fn number(self: *@This(), T: type, delimiter: *const Delimiter) ?T {
    const n = self.token(delimiter) orelse {
        return null;
    };

    return switch (T) {
        f32 => std.fmt.parseFloat(T, n) catch null,
        i32 => std.fmt.parseInt(T, n, 10) catch null,
        else => unreachable,
    };
}

pub const test_data =
    \\HIERARCHY
    \\ROOT Hips
    \\{
    \\  OFFSET 0.000000 0.000000 0.000000
    \\  CHANNELS 6 Xposition Yposition Zposition Yrotation Xrotation Zrotation
    \\  JOINT Chest
    \\  {
    \\    OFFSET 0.000000 10.678932 0.006280
    \\    CHANNELS 3 Yrotation Xrotation Zrotation
    \\    End Site
    \\    {
    \\      OFFSET 0.000000 16.966594 -0.014170
    \\    }
    \\  }
    \\}
;

test {
    // https://qiita.com/matchyy/items/ee99fb28110e4614323f
    const src = test_data;

    var t = Tokenizer.init(src);

    try std.testing.expect(t.expect("HIERARCHY", &is_space));
    try std.testing.expect(t.expect("ROOT", &is_space));
    try std.testing.expect(t.expect("Hips", &get_name));
    try std.testing.expect(t.expect("{", &is_space));
    try std.testing.expect(t.expect("OFFSET", &is_space));
    try std.testing.expectEqual(0, t.number(f32, &is_space).?);
    try std.testing.expectEqual(0, t.number(f32, &is_space).?);
    try std.testing.expectEqual(0, t.number(f32, &is_space).?);
    try std.testing.expect(t.expect("CHANNELS", &is_space));
    try std.testing.expectEqual(6, t.number(i32, &is_space).?);
    try std.testing.expect(t.expect("Xposition", &is_space));
    try std.testing.expect(t.expect("Yposition", &is_space));
    try std.testing.expect(t.expect("Zposition", &is_space));
    try std.testing.expect(t.expect("Yrotation", &is_space));
    try std.testing.expect(t.expect("Xrotation", &is_space));
    try std.testing.expect(t.expect("Zrotation", &is_space));
    try std.testing.expect(t.expect("JOINT", &is_space));
    try std.testing.expect(t.expect("Chest", &get_name));
    try std.testing.expect(t.expect("{", &is_space));
    try std.testing.expect(t.expect("OFFSET", &is_space));
    try std.testing.expectEqual(0, t.number(f32, &is_space).?);
    try std.testing.expectEqual(10.678932, t.number(f32, &is_space).?);
    try std.testing.expectEqual(0.0062800, t.number(f32, &is_space).?);
    try std.testing.expect(t.expect("CHANNELS", &is_space));
    try std.testing.expectEqual(3, t.number(i32, &is_space).?);
    try std.testing.expect(t.expect("Yrotation", &is_space));
    try std.testing.expect(t.expect("Xrotation", &is_space));
    try std.testing.expect(t.expect("Zrotation", &is_space));
    try std.testing.expect(t.expect("End", &is_space));
    try std.testing.expect(t.expect("Site", &get_name));
    try std.testing.expect(t.expect("{", &is_space));
    try std.testing.expect(t.expect("OFFSET", &is_space));
    try std.testing.expectEqual(0, t.number(f32, &is_space).?);
    try std.testing.expectEqual(16.966594, t.number(f32, &is_space).?);
    try std.testing.expectEqual(-0.014170, t.number(f32, &is_space).?);
    try std.testing.expect(t.expect("}", &is_space));
    try std.testing.expect(t.expect("}", &is_space));
    try std.testing.expect(t.expect("}", &is_space));
    try std.testing.expectEqual(0, t.remain.len);
}
