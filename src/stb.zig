const std = @import("std");
const utils = @import("utils");
const c = @cImport({
    @cDefine("STB_IMAGE_IMPLEMENTATION", "");
    @cInclude("STB/stb_image.h");
});

const Allocator = std.mem.Allocator;

pub const Image = struct {
    pixels: []u8,
    width: u32,
    height: u32,

    pub fn load(allocator: Allocator, filename: []const u8, errStr: ?*[]const u8) Allocator.Error!?Image {
        const filenameZ = utils.copy(
            u8,
            filename,
            try allocator.alloc(u8, filename.len + 1),
        );
        defer allocator.free(filenameZ);

        return loadZ(filename, errStr);
    }
    pub fn loadZ(filename: [:0]const u8, errStr: ?*[]const u8) ?Image {
        var x: c_int = 0;
        var y: c_int = 0;
        var channels: c_int = 0;
        const pixels: [*c]u8 = c.stbi_load(filename, &x, &y, &channels, 0) orelse {
            if (errStr != null) errStr.?.* = c.stbi_failure_reason();
            return null;
        };

        return .{
            .pixels = pixels[0..@intCast(x * y)],
            .width = @intCast(x),
            .height = @intCast(y),
        };
    }
    pub fn delete(self: *Image) void {
        c.stbi_image_free(self.pixels);
        self.* = undefined;
    }
};
