const sokol = @import("sokol");
const sg = sokol.gfx;
const rowmath = @import("rowmath");
const Vec2 = rowmath.Vec2;
const OrbitCamera = rowmath.OrbitCamera;
const InputState = rowmath.InputState;
const ig = @import("cimgui");
pub const SwapchainView = @This();

orbit: OrbitCamera = .{},
cursor: Vec2 = undefined,

pip: sg.Pipeline = .{},
pass_action: sg.PassAction = .{},

pub fn init(self: *@This()) void {
    self.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };
    self.orbit.init();
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

pub fn frame(self: *@This()) void {
    const input = inputFromScreen();
    self.orbit.frame(input);
    self.cursor = input.cursorScreenPosition();
}

pub fn begin(self: *@This()) void {
    sg.beginPass(.{
        .action = self.pass_action,
        .swapchain = sokol.glue.swapchain(),
    });
    sokol.gl.setContext(sokol.gl.defaultContext());
    sokol.gl.defaults();
    sokol.gl.matrixModeProjection();
    sokol.gl.loadMatrix(&self.orbit.camera.projection.matrix.m[0]);
    sokol.gl.matrixModeModelview();
    sokol.gl.loadMatrix(&self.orbit.camera.transform.worldToLocal().m[0]);
}

pub fn end(_: @This()) void {
    sokol.gl.contextDraw(sokol.gl.defaultContext());
    sokol.imgui.render(); // !
    sg.endPass();
}
