const sokol = @import("sokol");
const builtin = @import("builtin");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const Camera = rowmath.Camera;
const InputState = rowmath.InputState;
const ig = @import("cimgui");
const RenderTarget = @import("RenderTarget.zig");
pub const RenderView = @This();

extern fn Custom_ButtonBehaviorMiddleRight() void;

camera: Camera = Camera{},
drag_right: rowmath.CameraRightDragHandler = undefined,
drag_middle: rowmath.CameraMiddleDragHandler = undefined,

pip: sg.Pipeline = .{},
pass_action: sg.PassAction = .{
    .colors = .{
        .{
            // initial clear color
            .load_action = .CLEAR,
            .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
        },
        .{},
        .{},
        .{},
    },
},
sgl_ctx: sokol.gl.Context = .{},
rendertarget: ?RenderTarget = null,

pub fn init(self: *@This()) void {
    // create a sokol-gl context compatible with the view1 render pass
    // (specific color pixel format, no depth-stencil-surface, no MSAA)
    self.sgl_ctx = sokol.gl.makeContext(.{
        .max_vertices = 65535,
        .max_commands = 65535,
        .color_format = .RGBA8,
        .depth_format = .DEPTH,
        .sample_count = 1,
    });
    self.drag_right = rowmath.makeYawPitchHandler(.right, &self.camera);
    self.drag_middle = rowmath.makeScreenMoveHandler(.middle, &self.camera);
}

pub const RenderTargetImageButtonContext = struct {
    hover: bool,
    cursor: Vec2,
};

fn get_or_create(self: *@This(), width: i32, height: i32) RenderTarget {
    if (self.rendertarget) |rendertarget| {
        if (rendertarget.width == width and rendertarget.height == height) {
            return rendertarget;
        }
        rendertarget.deinit();
    }

    const rendertarget = RenderTarget.init(width, height);
    self.rendertarget = rendertarget;
    return rendertarget;
}

pub fn update(self: *@This(), input: InputState) void {
    self.camera.resize(input.screen_size());
    self.drag_right.frame(input);
    self.drag_middle.frame(input);
    self.camera.dolly(input.mouse_wheel);
    self.camera.updateTransform();
}

pub fn begin(self: *@This(), _rendertarget: ?RenderTarget) void {
    if (_rendertarget) |rendertarget| {
        sg.beginPass(rendertarget.pass);
        sokol.gl.setContext(self.sgl_ctx);
    } else {
        sg.beginPass(.{
            .action = self.pass_action,
            .swapchain = sokol.glue.swapchain(),
        });
        sokol.gl.setContext(sokol.gl.defaultContext());
    }

    sokol.gl.defaults();
    sokol.gl.matrixModeProjection();
    sokol.gl.multMatrix(&self.camera.projection.m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.multMatrix(&self.camera.transform.worldToLocal().m[0]);
}

pub fn end(self: *@This(), _rendertarget: ?RenderTarget) void {
    if (_rendertarget) |_| {
        sokol.gl.contextDraw(self.sgl_ctx);
    } else {
        sokol.gl.contextDraw(sokol.gl.defaultContext());
        sokol.imgui.render();
    }
    sg.endPass();
}

fn is_contain(pos: ig.ImVec2, size: ig.ImVec2, p: ig.ImVec2) bool {
    return (p.x >= pos.x and p.x <= (pos.x + size.x)) and (p.y >= pos.y and p.y <= (pos.y + size.y));
}

pub fn inputFromScreen() InputState {
    const io = ig.igGetIO().*;
    var input = InputState{
        .screen_width = io.DisplaySize.x,
        .screen_height = io.DisplaySize.y,
        .mouse_x = io.MousePos.x,
        .mouse_y = io.MousePos.y,
    };
    if (!io.WantCaptureMouse) {
        input.mouse_left = io.MouseDown[ig.ImGuiMouseButton_Left];
        input.mouse_right = io.MouseDown[ig.ImGuiMouseButton_Right];
        input.mouse_middle = io.MouseDown[ig.ImGuiMouseButton_Middle];
        input.mouse_wheel = io.MouseWheel;
    }
    return input;
}

pub fn inputFromRendertarget(pos: ig.ImVec2, size: ig.ImVec2) InputState {
    const io = ig.igGetIO().*;
    var input = InputState{
        .screen_width = size.x,
        .screen_height = size.y,
        .mouse_x = io.MousePos.x - pos.x,
        .mouse_y = io.MousePos.y - pos.y,
    };

    if (ig.igIsItemActive()) {
        input.mouse_left = io.MouseDown[ig.ImGuiMouseButton_Left];
        input.mouse_right = io.MouseDown[ig.ImGuiMouseButton_Right];
        input.mouse_middle = io.MouseDown[ig.ImGuiMouseButton_Middle];
    } else if (ig.igIsItemHovered(0)) {
        input.mouse_wheel = io.MouseWheel;
    }

    return input;
}

pub fn beginImageButton(self: *@This()) ?RenderTargetImageButtonContext {
    const io = ig.igGetIO();
    var pos = ig.ImVec2{};
    ig.igGetCursorScreenPos(&pos);
    var size = ig.ImVec2{};
    ig.igGetContentRegionAvail(&size);
    const hover = is_contain(pos, size, io.*.MousePos);

    if (size.x <= 0 or size.y <= 0) {
        return null;
    }

    const rendertarget = self.get_or_create(
        @intFromFloat(size.x),
        @intFromFloat(size.y),
    );

    ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_FramePadding, .{ .x = 0, .y = 0 });
    defer ig.igPopStyleVar(1);
    _ = ig.igImageButton(
        "fbo",
        sokol.imgui.imtextureid(rendertarget.image),
        size,
        .{ .x = 0, .y = if (builtin.os.tag == .emscripten) 1 else 0 },
        .{ .x = 1, .y = if (builtin.os.tag == .emscripten) 0 else 1 },
        .{ .x = 1, .y = 1, .z = 1, .w = 1 },
        .{ .x = 1, .y = 1, .z = 1, .w = 1 },
    );

    Custom_ButtonBehaviorMiddleRight();
    const input = inputFromRendertarget(pos, size);
    self.update(input);

    // render offscreen
    self.begin(rendertarget);

    return .{
        .hover = hover,
        .cursor = input.cursorScreenPosition(),
    };
}

pub fn endImageButton(self: *@This()) void {
    if (self.rendertarget) |rendertarget| {
        self.end(rendertarget);
    }
}
