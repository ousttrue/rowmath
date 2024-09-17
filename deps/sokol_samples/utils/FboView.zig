const sokol = @import("sokol");
const builtin = @import("builtin");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const OrbitCamera = rowmath.OrbitCamera;
const InputState = rowmath.InputState;
const ig = @import("cimgui");
const Fbo = @import("Fbo.zig");
pub const FboView = @This();

extern fn Custom_ButtonBehaviorMiddleRight() void;

orbit: OrbitCamera = .{},
hover: bool = false,

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
rendertarget: ?Fbo = null,

pub fn init(self: *@This()) void {
    self.orbit.init();
    // create a sokol-gl context compatible with the view1 render pass
    // (specific color pixel format, no depth-stencil-surface, no MSAA)
    self.sgl_ctx = sokol.gl.makeContext(.{
        .max_vertices = 65535,
        .max_commands = 65535,
        .color_format = .RGBA8,
        .depth_format = .DEPTH,
        .sample_count = 1,
    });
}

pub const RenderTargetImageButtonContext = struct {
    hover: bool,
    cursor: Vec2,
};

fn get_or_create(self: *@This(), width: i32, height: i32) Fbo {
    if (self.rendertarget) |rendertarget| {
        if (rendertarget.width == width and rendertarget.height == height) {
            return rendertarget;
        }
        rendertarget.deinit();
    }

    const rendertarget = Fbo.init(width, height);
    self.rendertarget = rendertarget;
    return rendertarget;
}

pub fn begin(self: *@This(), rendertarget: Fbo) void {
    sokol.gl.setContext(self.sgl_ctx); // !
    sg.beginPass(rendertarget.pass);
    sokol.gl.defaults();
    sokol.gl.matrixModeProjection();
    sokol.gl.loadMatrix(&self.orbit.camera.projection.matrix.m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.loadMatrix(&self.orbit.camera.transform.worldToLocal().m[0]);
}

pub fn end(self: *@This()) void {
    sokol.gl.contextDraw(self.sgl_ctx); // !
    sg.endPass();
}

fn is_contain(pos: ig.ImVec2, size: ig.ImVec2, p: ig.ImVec2) bool {
    return (p.x >= pos.x and p.x <= (pos.x + size.x)) and (p.y >= pos.y and p.y <= (pos.y + size.y));
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
    self.orbit.frame(input);

    // render offscreen
    self.begin(rendertarget);

    return .{
        .hover = hover,
        .cursor = input.cursorScreenPosition(),
    };
}

pub fn endImageButton(self: *@This()) void {
    self.end();
}

pub fn beginButton(self: *@This(), name: [:0]const u8, pos: *ig.ImVec2) bool {
    ig.igPushStyleVar_Vec2(ig.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });

    defer ig.igPopStyleVar(1);
    if (ig.igBegin(
        &name[0],
        null,
        ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse,
    )) {
        // var winpos: ig.ImVec2=undefined;
        // ig.igGetWindowPos(&winpos);
        // var curpos: ig.ImVec2=undefined;
        ig.igGetCursorScreenPos(pos);
        // pos.x = winpos.x ;//+ curpos.x;
        // pos.y = winpos.y ;//+ curpos.y;

        if (self.beginImageButton()) |render_context| {
            self.hover = render_context.hover;
            return true;
        }
    }

    return false;
}

pub fn endButton(self: *@This()) void {
    self.endImageButton();
}
