const std = @import("std");
const base64_decoder = std.base64.standard.Decoder;
const Gltf = @import("Gltf/Gltf.zig");
const Buffer = @import("Gltf/Buffer.zig");
pub const GltfBuffer = @This();

allocator: std.mem.Allocator,
gltf: Gltf,
bin: []const u8,
uriMap: std.StringHashMap([]const u8),

pub fn init(
    allocator: std.mem.Allocator,
    gltf: Gltf,
    bin: []const u8,
) @This() {
    return .{
        .allocator = allocator,
        .gltf = gltf,
        .bin = bin,
        .uriMap = std.StringHashMap([]const u8).init(allocator),
    };
}

pub fn deinit(self:*@This())void
{
    // TODO:
    self.uriMap.deinit();
}

pub fn getAccessorBytes(self: *@This(), T: type, accessor_index: u32) ![]const T {
    const accessor = self.gltf.accessors[accessor_index];
    std.debug.assert(@sizeOf(T) == accessor.stride());

    if (accessor.bufferView) |bufferView_index| {
        const bufferViewBytes = try self.getBufferViewBytes(bufferView_index);
        const bytes = bufferViewBytes[accessor.byteOffset .. accessor.byteOffset + accessor.count * accessor.stride()];
        return @alignCast(std.mem.bytesAsSlice(T, bytes));
    } else {
        unreachable;
    }
}

pub fn getBufferViewBytes(self: *@This(), bufferView_index: u32) ![]const u8 {
    const bufferView = self.gltf.bufferViews[bufferView_index];
    const buffer_bytes = try self.getBufferBytes(bufferView.buffer);
    return buffer_bytes[bufferView.byteOffset .. bufferView.byteOffset + bufferView.byteLength];
}

pub fn getBufferBytes(self: *@This(), buffer_index: u32) ![]const u8 {
    const buffer = self.gltf.buffers[buffer_index];
    if (buffer.uri) |uri| {
        return try self.getUriBytes(uri);
    } else {
        return self.bin;
    }
}

pub fn getUriBytes(self: *@This(), uri: []const u8) ![]const u8 {
    if (self.uriMap.getPtr(uri)) |ptr| {
        return ptr.*;
    }

    if (Buffer.base64FromUri(uri)) |base64| {
        // std.debug.print("{s}\n", .{base64});
        const len = base64_decoder.calcSizeForSlice(base64) catch |e| {
            return e;
        };
        const buf = try self.allocator.alloc(u8, len);
        // TODO: free
        try base64_decoder.decode(buf, base64);
        try self.uriMap.put(uri, buf);
        return buf;
    } else {
        unreachable;
    }
}
