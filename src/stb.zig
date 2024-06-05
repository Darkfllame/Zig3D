const std = @import("std");
const glfw = @import("glfw");
const c = @cImport({
    @cInclude("STB/stb_image.h");
    @cInclude("string.h");
});

pub usingnamespace if (@import("build_options").exposeC) struct {
    pub const capi = c;
} else struct {};

const Allocator = std.mem.Allocator;

pub fn setFlipVerticallyOnLoad(b: bool) void {
    c.stbi_set_flip_vertically_on_load(@intFromBool(b));
}
pub fn setFlipVerticallyOnLoadThread(b: bool) void {
    c.stbi_set_flip_vertically_on_load_thread(@intFromBool(b));
}

pub const Image = struct {
    pixels: []u8,
    width: u32,
    height: u32,
    channels: u32,

    pub fn load(allocator: Allocator, filename: []const u8, errStr: ?*[]const u8) Allocator.Error!?Image {
        const filenameZ = try allocator.allocSentinel(u8, filename.len + 1);
        @memcpy(filenameZ, filename);
        defer allocator.free(filenameZ);

        return loadZ(filenameZ[0..filename.len :0], errStr);
    }
    pub fn loadZ(filename: [:0]const u8, errStr: ?*[]const u8) ?Image {
        var x: c_int = 0;
        var y: c_int = 0;
        var channels: c_int = 0;
        const pixels: [*c]u8 = c.stbi_load(
            filename,
            &x,
            &y,
            &channels,
            4,
        ) orelse {
            if (errStr) |es| {
                const reason = c.stbi_failure_reason();
                const len = c.strlen(reason);
                es.* = reason[0..len];
            }
            return null;
        };

        return .{
            .pixels = pixels[0..@intCast(x * y)],
            .width = @intCast(x),
            .height = @intCast(y),
            .channels = @intCast(channels),
        };
    }
    pub fn loadFromMemory(buffer: []const u8, errStr: ?*[]const u8) ?Image {
        var x: c_int = 0;
        var y: c_int = 0;
        var channels: c_int = 0;
        const pixels: [*c]u8 = c.stbi_load_from_memory(
            @ptrCast(buffer.ptr),
            @intCast(buffer.len),
            &x,
            &y,
            &channels,
            4,
        ) orelse {
            if (errStr) |es| {
                const reason = c.stbi_failure_reason();
                const len = c.strlen(reason);
                es.* = reason[0..len];
            }
            return null;
        };

        return .{
            .pixels = pixels[0..@intCast(x * y)],
            .width = @intCast(x),
            .height = @intCast(y),
            .channels = @intCast(channels),
        };
    }
    pub fn delete(self: *Image) void {
        c.stbi_image_free(@ptrCast(self.pixels.ptr));
        self.* = undefined;
    }

    /// returns null only if pixels.len is not a multiple
    /// of 4.
    pub fn toGlfw(self: Image) ?glfw.Image {
        if (self.pixels.len % 4 != 0) return null;
        return .{
            .pixels = @ptrCast(self.pixels),
            .width = self.width,
            .height = self.height,
        };
    }
};

comptime {
    std.testing.refAllDeclsRecursive(@This());
}
