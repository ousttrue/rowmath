const std = @import("std");
const builtin = @import("builtin");

fn subPath() []const u8 {
    return comptime switch (builtin.os.tag) {
        .windows => "bin/win32/sokol-shdc.exe",
        .linux => "bin/linux/sokol-shdc",
        .macos => if (builtin.cpu.arch.isX86()) "bin/osx/sokol-shdc" else "bin/osx_arm64/sokol-shdc",
        else => @panic("unsupported host platform: " ++ @tagName(builtin.os.tag)),
    };
}

// a separate step to compile shaders
pub fn runShdcCommand(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    shader: []const u8,
) std.Build.LazyPath {
    const tools = b.dependency("sokol-tools-bin", .{});
    const shdc_path = tools.path(subPath()).getPath(b);
    const glsl = if (target.result.isDarwin()) "glsl410" else "glsl430";
    const slang = glsl ++ ":metal_macos:hlsl5:glsl300es:wgsl";
    const tool_step = b.addSystemCommand(&.{
        shdc_path,
        "-i",
        shader,
        "-l",
        slang,
        "-f",
        "sokol_zig",
        "-o",
    });
    return tool_step.addOutputFileArg("shader.glsl.zig");
}
