const Line = @import("Line.zig");

fn MakeType(comptime _value: anytype) type {
    return struct {
        pub const lines = _value;
    };
}

pub fn Grid(comptime _n: u16) type {
    const n: f32 = @floatFromInt(_n); //5.0;

    var lines: [(_n * 2 + 1) * 2]Line = undefined;

    var i: usize = 0;
    {
        var x: f32 = -n;
        while (x <= n) : (x += 1) {
            lines[i] = Line{
                .start = .{ .x = x, .y = 0, .z = -n },
                .end = .{ .x = x, .y = 0, .z = n },
            };
            i += 1;
        }
    }
    {
        var z: f32 = -n;
        while (z <= n) : (z += 1) {
            lines[i] = Line{
                .start = .{ .x = -n, .y = 0, .z = z },
                .end = .{ .x = n, .y = 0, .z = z },
            };
            i += 1;
        }
    }
    return MakeType(lines);
}
