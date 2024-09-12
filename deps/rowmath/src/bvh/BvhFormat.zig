const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");
const is_space = Tokenizer.is_space;
const get_eol = Tokenizer.get_eol;
const get_name = Tokenizer.get_name;
const BvhFormat = @This();
const BvhJoint = @import("BvhJoint.zig");
const BvhChannels = @import("BvhChannels.zig");
const Vec3 = @import("../Vec3.zig");

token: Tokenizer,
joints: std.ArrayList(BvhJoint),
endsites: std.ArrayList(BvhJoint),
frames: std.ArrayList(f32),
frame_count: u32 = 0,
frame_time: f32 = 0,
channel_count: usize = 0,
max_height: f32 = 0,
stack: std.ArrayList(usize),

pub fn init(allocator: std.mem.Allocator, src: []const u8) @This() {
    return .{
        .token = Tokenizer.init(src),
        .joints = std.ArrayList(BvhJoint).init(allocator),
        .endsites = std.ArrayList(BvhJoint).init(allocator),
        .frames = std.ArrayList(f32).init(allocator),
        .stack = std.ArrayList(usize).init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    self.stack.deinit();
    self.frames.deinit();
    self.endsites.deinit();
    self.joints.deinit();
}

pub fn parse(self: *@This()) !bool {
    if (!self.token.expect("HIERARCHY", is_space)) {
        return false;
    }

    if (!(try self.parseJoint())) {
        return false;
    }

    if (!self.token.expect("Frames:", is_space)) {
        return false;
    }
    const frames = self.token.number(u32, is_space) orelse {
        return false;
    };
    self.frame_count = frames;

    if (!self.token.expect("Frame", is_space)) {
        return false;
    }
    if (!self.token.expect("Time:", is_space)) {
        return false;
    }
    const frameTime = self.token.number(f32, is_space) orelse {
        return false;
    };
    self.frame_time = frameTime;

    // each frame
    self.channel_count = 0;
    for (self.joints.items) |joint| {
        self.channel_count += joint.channels.size();
    }
    //     frames_.reserve(frame_count_ * channel_count_);
    for (0..self.frame_count) |_| {
        const line = self.token.token(get_eol) orelse {
            return false;
        };

        var line_token = Tokenizer.init(line);
        for (0..self.channel_count) |_| {
            if (line_token.number(f32, is_space)) |value| {
                try self.frames.append(value);
            } else {
                return false;
            }
        }
    }
    std.debug.assert(self.frames.items.len == self.frame_count * self.channel_count);

    return true;
}

fn parseJoint(self: *@This()) !bool {
    while (true) {
        const token = self.token.token(is_space) orelse {
            return false;
        };

        if (std.mem.eql(u8, token, "ROOT") or std.mem.eql(u8, token, "JOINT")) {
            // name
            // {
            // OFFSET x y z
            // CHANNELS 6
            // X {
            // }
            // }
            const name = self.token.token(get_name) orelse {
                return false;
            };

            // std.debug.print("\n", .{});
            // for (0..self.stack.items.len) |_| {
            //     std.debug.print("  ", .{});
            // }

            if (!self.token.expect("{", is_space)) {
                return false;
            }

            const index = self.joints.items.len;
            const offset = self.parseOffset() orelse {
                return false;
            };
            var channels = self.parseChannels() orelse {
                return false;
            };
            channels.init = offset;
            channels.startIndex = if (self.joints.items.len == 0)
                0
            else
                self.joints.items[self.joints.items.len - 1].channels.startIndex +
                    self.joints.items[self.joints.items.len - 1].channels.size();

            const parentIndex: ?usize = if (self.stack.items.len == 0) null else self.stack.items[self.stack.items.len - 1];
            // auto parent = stack_.empty() ? nullptr : &joints_[parentIndex];
            try self.joints.append(BvhJoint{
                .name = name,
                .index = index,
                .parent = parentIndex,
                .local_offset = offset,
                .world_offset = offset,
                .channels = channels,
            });
            if (self.stack.items.len > 0) {
                const parent = &self.joints.items[self.stack.getLast()];
                self.joints.items[self.joints.items.len - 1].world_offset.x += parent.world_offset.x;
                self.joints.items[self.joints.items.len - 1].world_offset.y += parent.world_offset.y;
                self.joints.items[self.joints.items.len - 1].world_offset.z += parent.world_offset.z;
            }

            self.max_height = @max(self.max_height, self.joints.getLast().world_offset.y);

            try self.stack.append(index);

            _ = try self.parseJoint();
        } else if (std.mem.eql(u8, token, "End")) {
            // End Site
            // {
            // OFFSET x y z
            // }
            if (!self.token.expect("Site", get_name)) {
                return false;
            }

            if (!self.token.expect("{", is_space)) {
                return false;
            }
            const offset = self.parseOffset() orelse {
                return false;
            };
            try self.endsites.append(BvhJoint{
                .name = "End Site",
                .parent = self.stack.getLastOrNull(),
                .local_offset = offset,
            });

            if (!self.token.expect("}", is_space)) {
                return false;
            }
        } else if (std.mem.eql(u8, token, "}")) {
            _ = self.stack.pop();
            return true;
        } else if (std.mem.eql(u8, token, "MOTION")) {
            return true;
        } else {
            unreachable;
        }
    }

    unreachable;
}

fn parseOffset(self: *@This()) ?Vec3 {
    if (!self.token.expect("OFFSET", is_space)) {
        return null;
    }
    const x = self.token.number(f32, is_space) orelse {
        return null;
    };
    const y = self.token.number(f32, is_space) orelse {
        return null;
    };
    const z = self.token.number(f32, is_space) orelse {
        return null;
    };
    return .{ .x = x, .y = y, .z = z };
}

fn parseChannels(self: *@This()) ?BvhChannels {
    if (!self.token.expect("CHANNELS", is_space)) {
        return null;
    }

    const channel_count = self.token.number(usize, is_space) orelse {
        return null;
    };
    var channels = BvhChannels{};
    for (0..channel_count) |i| {
        if (self.token.token(is_space)) |channel| {
            if (std.mem.eql(u8, channel, "Xposition")) {
                channels.types[i] = .Xposition;
            } else if (std.mem.eql(u8, channel, "Yposition")) {
                channels.types[i] = .Yposition;
            } else if (std.mem.eql(u8, channel, "Zposition")) {
                channels.types[i] = .Zposition;
            } else if (std.mem.eql(u8, channel, "Xrotation")) {
                channels.types[i] = .Xrotation;
            } else if (std.mem.eql(u8, channel, "Yrotation")) {
                channels.types[i] = .Yrotation;
            } else if (std.mem.eql(u8, channel, "Zrotation")) {
                channels.types[i] = .Zrotation;
            } else {
                unreachable;
            }
        }
    }
    return channels;
}

test {
    const src = Tokenizer.test_data;
    var bvh = BvhFormat.init(std.testing.allocator, src);
    defer bvh.deinit();
    try std.testing.expect(try bvh.parse());
}
