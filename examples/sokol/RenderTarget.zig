const sokol = @import("sokol");
const sg = sokol.gfx;

pub const RenderTarget = @This();

width: i32,
height: i32,
attachments_desc: sg.AttachmentsDesc,
attachments: sg.Attachments,
pass: sg.Pass,
image: sokol.imgui.Image,

pub fn init(width: i32, height: i32) @This() {
    const color_img = sg.makeImage(.{
        .render_target = true,
        .width = width,
        .height = height,
        .pixel_format = .RGBA8,
        // required
        .sample_count = 1,
        .label = "color-image",
    });
    const depth_img = sg.makeImage(.{
        .render_target = true,
        .width = width,
        .height = height,
        .pixel_format = .DEPTH,
        // required
        .sample_count = 1,
        .label = "depth-image",
    });
    var attachments_desc = sg.AttachmentsDesc{
        .depth_stencil = .{ .image = depth_img },
        .label = "offscreen-attachments",
    };
    attachments_desc.colors[0] = .{ .image = color_img };
    const attachments = sg.makeAttachments(attachments_desc);

    return .{
        .width = width,
        .height = height,
        .attachments_desc = attachments_desc,
        .attachments = attachments,
        .pass = sg.Pass{
            .attachments = attachments,
            .action = .{
                .colors = .{
                    .{
                        .load_action = .CLEAR,
                        .clear_value = .{ .r = 0.25, .g = 0.25, .b = 0.25, .a = 1.0 },
                    },
                    .{},
                    .{},
                    .{},
                },
            },
            .label = "offscreen-pass",
        },
        .image = sokol.imgui.makeImage(.{
            .image = color_img,
        }),
    };
}

pub fn deinit(self: @This()) void {
    sokol.imgui.destroyImage(self.image);
    sg.destroyAttachments(self.attachments);
    sg.destroyImage(self.attachments_desc.colors[0].image);
    sg.destroyImage(self.attachments_desc.depth_stencil.image);
}
