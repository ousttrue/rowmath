const std = @import("std");
pub const Tokenizer = @This();
const Result = struct {
    token: []const u8,
    next: []const u8,
};
const Delimiter = fn ([]const u8) ?usize;

fn is_space(_it: []const u8) ?usize {
    if (!std.ascii.isWhitespace(_it[0])) {
        return null;
    }

    for (_it, 0..) |c, i| {
        if (!std.ascii.isWhitespace(c)) {
            return i;
        }
    }
    return _it.len;
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
    return null;
}

pub fn expect(self: *@This(), expected: []const u8, delimiter: *const Delimiter) bool {
    if (self.token(delimiter)) |line| {
        if (std.mem.eql(u8, line, expected)) {
            return true;
        }
    }
    return false;
}

// template<typename T>
// std::optional<T> number(const Delimiter& delimiter)
// {
//   auto n = token(delimiter);
//   if (!n) {
//     return {};
//   }
//   if (auto value = to_num<T>(*n)) {
//     return *value;
//   } else {
//     return {};
//   }
// }
//

test {
    const src =
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

    var tokenizer = Tokenizer.init(src);

    try std.testing.expect(tokenizer.expect("HIERARCHY", &is_space));
}
