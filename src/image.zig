const std = @import("std");
const zlm = @import("zlm");
const zlmi = @import("zlm").SpecializeOn(i32);

const ArrayList = std.ArrayList;
const Vec2f = zlm.Vec2;
const Vec2i = zlmi.Vec2;

const Allocator = std.mem.Allocator;

pub const Image = struct {
    pixels: []u8,
    width: u32,
    height: u32,

    pub fn clone(self: *const Image, allocator: Allocator) Allocator.Error!Image {
        const pixels = try allocator.alloc(u8, self.pixels.len);
        @memcpy(pixels, self.pixels);
        return .{
            .pixels = pixels,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn getUV(self: *const Image, co: Vec2i) Vec2f {
        const size = Vec2f.new(
            @floatFromInt(self.width),
            @floatFromInt(self.height),
        );
        const cof = Vec2f.new(
            @floatFromInt(std.math.clamp(co.x, 0, @intCast(self.width))),
            @floatFromInt(std.math.clamp(co.y, 0, @intCast(self.height))),
        );
        return cof.div(size);
    }
};

// list of images, generates Atlas
pub const AtlasBuilder = struct {
    images: ArrayList(Image),

    pub fn init(allocator: Allocator) AtlasBuilder {
        return .{
            .images = ArrayList(Image).init(allocator),
        };
    }
    pub fn deinit(self: *AtlasBuilder) void {
        self.images.deinit();
        self.* = undefined;
    }

    pub fn generate(self: *AtlasBuilder) Allocator.Error!Atlas {
        const allocator = self.images.allocator;
        _ = allocator; // autofix
        const images = self.images.items;
        _ = images; // autofix

        // goal is to make a power of 2 sized image
        // on both W and H

        // i'm maybe not that qualified to do that idk
        // i mean i could have an algorithm:
        // putting each texture in a diagonal order,
        // bigger on the top left, then smaller on the right
        // even smaller on the bottom, etc, etc...
        // although i can't figure out a solution for that
    }
};
// list of uv's with an image
pub const Atlas = struct {
    allocator: Allocator,
    uvs: []Vec2f,
    img: Image,

    pub fn deinit(self: *Atlas) void {
        self.allocator.free(self.uvs);
        self.allocator.free(self.img.pixels);
        self.* = undefined;
    }
};
