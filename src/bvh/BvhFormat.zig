const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");
const is_space = Tokenizer.is_space;
const get_name = Tokenizer.get_name;
const BvhFormat = @This();
const BvhJoint = @import("BvhJoint.zig");

token: Tokenizer,
joints: std.ArrayList(BvhJoint),
//   std::vector<BvhJoint>& endsites_;
//   std::vector<float>& frames_;
//   uint32_t frame_count_ = 0;
//   BvhTime frame_time_ = {};
//   uint32_t channel_count_ = 0;
//   float max_height_ = 0;
//   std::vector<int> stack_;

pub fn init(allocator: std.mem.Allocator, src: []const u8) @This() {
    return .{
        .token = Tokenizer.init(src),
        .joints = std.ArrayList(BvhJoint).init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    self.joints.deinit();
}

pub fn parse(self: *@This()) bool {
    if (!self.token.expect("HIERARCHY", is_space)) {
        return false;
    }

    if (!self.parseJoint()) {
        return false;
    }

    //     if (!token_.expect("Frames:", is_space)) {
    //       return false;
    //     }
    //     auto frames = token_.number<int>(is_space);
    //     if (!frames) {
    //       return false;
    //     }
    //     frame_count_ = *frames;
    //
    //     if (!token_.expect("Frame", is_space)) {
    //       return false;
    //     }
    //     if (!token_.expect("Time:", is_space)) {
    //       return false;
    //     }
    //     auto frameTime = token_.number<float>(is_space);
    //     if (!frameTime) {
    //       return false;
    //     }
    //     frame_time_ = BvhTime(*frameTime);
    //
    //     // each frame
    //     channel_count_ = 0;
    //     for (auto& joint : joints_) {
    //       channel_count_ += joint.channels.size();
    //     }
    //     frames_.reserve(frame_count_ * channel_count_);
    //     for (int i = 0; i < frame_count_; ++i) {
    //       auto line = token_.token(get_eol);
    //       if (!line) {
    //         return false;
    //       }
    //
    //       Tokenizer line_token(*line);
    //       for (int j = 0; j < channel_count_; ++j) {
    //         if (auto value = line_token.number<float>(is_space)) {
    //           frames_.push_back(*value);
    //         } else {
    //           return false;
    //         }
    //       }
    //     }
    //     assert(frames_.size() == frame_count_ * channel_count_);

    return true;
}

fn parseJoint(self: *@This()) bool {
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
            _ = name;

            //         // for (size_t i = 0; i < stack_.size(); ++i) {
            //         //   std::cout << "  ";
            //         // }
            //         // std::cout << *name << std::endl;

            if (self.token.expect("{", is_space)) {
                return false;
            }

            //         auto index = joints_.size();
            //         auto offset = ParseOffset();
            //         if (!offset) {
            //           return false;
            //         }
            //         auto channels = ParseChannels();
            //         if (!channels) {
            //           return false;
            //         }
            //         channels->init = *offset;
            //         channels->startIndex = joints_.empty()
            //                                  ? 0
            //                                  : joints_.back().channels.startIndex +
            //                                      joints_.back().channels.size();
            //
            //         auto parentIndex = stack_.empty() ? -1 : stack_.back();
            //         // auto parent = stack_.empty() ? nullptr : &joints_[parentIndex];
            //         joints_.push_back(BvhJoint{
            //           .name = { name->begin(), name->end() },
            //           .index = static_cast<uint16_t>(index),
            //           .parent = static_cast<uint16_t>(parentIndex),
            //           .localOffset = *offset,
            //           .worldOffset = *offset,
            //           .channels = *channels,
            //         });
            //         if (stack_.size()) {
            //           auto& parent = joints_[stack_.back()];
            //           joints_.back().worldOffset.x += parent.worldOffset.x;
            //           joints_.back().worldOffset.y += parent.worldOffset.y;
            //           joints_.back().worldOffset.z += parent.worldOffset.z;
            //         }
            //
            //         max_height_ = std::max(max_height_, joints_.back().worldOffset.y);
            //
            //         stack_.push_back(index);
            //
            //         ParseJoint();
            //
        } else if (std.mem.eql(u8, token, "End")) {
            //         // End Site
            //         // {
            //         // OFFSET x y z
            //         // }
            //         if (!token_.expect("Site", get_name)) {
            //           return false;
            //         }
            //
            //         if (!token_.expect("{", is_space)) {
            //           return false;
            //         }
            //         auto offset = ParseOffset();
            //         if (!offset) {
            //           return false;
            //         }
            //         endsites_.push_back(BvhJoint{
            //           .name = "End Site",
            //           .parent = static_cast<uint16_t>(stack_.empty() ? -1 : stack_.back()),
            //           .localOffset = *offset,
            //         });
            //
            //         if (!token_.expect("}", is_space)) {
            //           return false;
            //         }
        } else if (std.mem.eql(u8, token, "}")) {
            //         stack_.pop_back();
            //         return true;
        } else if (std.mem.eql(u8, token, "MOTION")) {
            return true;
        } else {
            unreachable;
        }
    }

    unreachable;
}

//   std::optional<BvhOffset> ParseOffset()
//   {
//     if (!token_.expect("OFFSET", is_space)) {
//       return {};
//     }
//     auto x = token_.number<float>(is_space);
//     if (!x) {
//       return {};
//     }
//     auto y = token_.number<float>(is_space);
//     if (!y) {
//       return {};
//     }
//     auto z = token_.number<float>(is_space);
//     if (!z) {
//       return {};
//     }
//
//     return BvhOffset{ *x, *y, *z };
//   }
//
//   std::optional<BvhChannels> ParseChannels()
//   {
//     if (!token_.expect("CHANNELS", is_space)) {
//       return {};
//     }
//
//     auto n = token_.number<int>(is_space);
//     if (!n) {
//       return {};
//     }
//     auto channel_count = *n;
//     auto channels = BvhChannels{};
//     for (int i = 0; i < channel_count; ++i) {
//       if (auto channel = token_.token(is_space)) {
//         if (*channel == "Xposition") {
//           channels[i] = BvhChannelTypes::Xposition;
//         } else if (*channel == "Yposition") {
//           channels[i] = BvhChannelTypes::Yposition;
//         } else if (*channel == "Zposition") {
//           channels[i] = BvhChannelTypes::Zposition;
//         } else if (*channel == "Xrotation") {
//           channels[i] = BvhChannelTypes::Xrotation;
//         } else if (*channel == "Yrotation") {
//           channels[i] = BvhChannelTypes::Yrotation;
//         } else if (*channel == "Zrotation") {
//           channels[i] = BvhChannelTypes::Zrotation;
//         } else {
//           throw std::runtime_error("unknown");
//         }
//       }
//     }
//     return channels;
//   }

test {
    const src = Tokenizer.test_data;
    var bvh = BvhFormat.init(std.testing.allocator, src);
    try std.testing.expect(bvh.parse());
}
