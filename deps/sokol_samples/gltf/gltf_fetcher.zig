const std = @import("std");
const sokol = @import("sokol");
const rowmath = @import("rowmath");
const zigltf = @import("zigltf");

const GltfCallback = fn (gltf: std.json.Parsed(zigltf.Gltf)) void;

const Task = union(enum) {
    gltf: struct {
        path: []const u8,
        callback: *const GltfCallback,
    },
    buffer: struct {
        path: []const u8,
        buffer_index: u32,
    },
};

pub var status: [:0]const u8 = "loading...";
var status_buffer: [1024]u8 = undefined;
var tasks: [32]Task = undefined;
var task_count: u32 = 0;
var fetch_buffer: [1024 * 1024]u8 = undefined;

pub fn init() void {
    // setup sokol-fetch with 2 channels and 6 lanes per channel,
    // we'll use one channel for mesh data and the other for textures
    sokol.fetch.setup(.{
        .max_requests = 8,
        .num_channels = 1,
        .num_lanes = 8,
        .logger = .{ .func = sokol.log.func },
    });
}

pub fn fetch_gltf(path: [:0]const u8, on_gltf: *const GltfCallback) !void {
    tasks[task_count] = .{
        .gltf = .{
            .path = path,
            .callback = on_gltf,
        },
    };

    _ = sokol.fetch.send(.{
        .path = &path[0],
        .callback = fetch_callback,
        .buffer = sokol.fetch.asRange(&fetch_buffer),
        .user_data = sokol.fetch.asRange(&tasks[task_count]),
    });

    task_count += 1;
}

export fn fetch_callback(response: [*c]const sokol.fetch.Response) void {
    if (response.*.fetched) {
        const user: *const Task = @ptrCast(@alignCast(response.*.user_data));
        switch (user.*) {
            .gltf => |gltf_task| {
                status = std.fmt.bufPrintZ(
                    &status_buffer,
                    "{}bytes\n",
                    .{response.*.data.size},
                ) catch @panic("bufPrintZ");

                const p: [*]const u8 = @ptrCast(response.*.data.ptr);
                const allocator = std.heap.c_allocator;
                if (std.json.parseFromSlice(
                    zigltf.Gltf,
                    allocator,
                    p[0..response.*.data.size],
                    .{
                        .ignore_unknown_fields = true,
                    },
                )) |parsed| {
                    // defer parsed.deinit();
                    status = "parsed";
                    gltf_task.callback(parsed);
                } else |e| {
                    status = std.fmt.bufPrintZ(
                        &status_buffer,
                        "fail to parse: {s}",
                        .{@errorName(e)},
                    ) catch @panic("bufPrintZ");
                }
            },
            .buffer => |buffer_task| {
                _ = buffer_task;
                unreachable;
            },
        }
    } else if (response.*.failed) {
        // state.status = "fetch fail";
    }
}
