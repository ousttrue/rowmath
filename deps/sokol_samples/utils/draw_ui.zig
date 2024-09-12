const std = @import("std");
const cimgui = @import("cimgui");
const rowmath = @import("rowmath");
const Camera = rowmath.Camera;
const Skeleton = @import("Skeleton.zig");

pub const Loaded = struct {
    skeleton: ?Skeleton = null,
    animation: bool = false,
    failed: bool = false,
};
pub const Time = struct {
    frame: f64 = 0,
    absolute: f64 = 0,
    factor: f32 = 0,
    anim_ratio: f32 = 0,
    anim_ratio_ui_override: bool = false,
    paused: bool = false,
};
pub const State = struct {
    loaded: Loaded = .{},
    time: Time = .{},

    pub fn update(state: *@This(), anim_duration: f32) f32 {
        if (!state.time.paused) {
            state.time.absolute += state.time.frame * state.time.factor;
        }

        // convert current time to animation ration (0.0 .. 1.0)
        if (!state.time.anim_ratio_ui_override) {
            state.time.anim_ratio =
                std.math.mod(
                f32,
                @floatCast(state.time.absolute / anim_duration),
                1.0,
            ) catch unreachable;
        }
        return state.time.anim_ratio;
    }
};

pub fn draw_ui(state: *State, camera: *Camera) void {
    cimgui.igSetNextWindowPos(.{ .x = 20, .y = 20 }, cimgui.ImGuiCond_Once, .{ .x = 0, .y = 0 });
    cimgui.igSetNextWindowSize(.{ .x = 220, .y = 150 }, cimgui.ImGuiCond_Once);
    cimgui.igSetNextWindowBgAlpha(0.35);
    if (cimgui.igBegin("Controls", null, cimgui.ImGuiWindowFlags_NoDecoration |
        cimgui.ImGuiWindowFlags_AlwaysAutoResize))
    {
        if (state.loaded.failed) {
            cimgui.igText("Failed loading character data!");
        } else {
            cimgui.igText("Camera Controls:");
            cimgui.igText("  LMB + Mouse Move: Look");
            cimgui.igText("  Mouse Wheel: Zoom");
            _ = cimgui.igSliderFloat(
                "Distance",
                &camera.shift.z,
                0,
                100,
                "%.1f",
                1.0,
            );
            _ = cimgui.igSliderFloat(
                "Latitude",
                &camera.yaw,
                -std.math.pi,
                std.math.pi,
                "%.1f",
                1.0,
            );
            _ = cimgui.igSliderFloat(
                "Longitude",
                &camera.pitch,
                -std.math.pi,
                std.math.pi,
                "%.1f",
                1.0,
            );
            cimgui.igSeparator();
            cimgui.igText("Time Controls:");
            _ = cimgui.igCheckbox("Paused", &state.time.paused);
            _ = cimgui.igSliderFloat(
                "Factor",
                &state.time.factor,
                0.0,
                10.0,
                "%.1f",
                1.0,
            );
            if (cimgui.igSliderFloat(
                "Ratio",
                &state.time.anim_ratio,
                0.0,
                1.0,
                null,
                0,
            )) {
                state.time.anim_ratio_ui_override = true;
            }
            if (cimgui.igIsItemDeactivatedAfterEdit()) {
                state.time.anim_ratio_ui_override = false;
            }
        }
    }
    cimgui.igEnd();
}
