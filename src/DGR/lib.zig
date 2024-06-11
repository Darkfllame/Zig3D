//! DGR (Dagger) is a cross-platform 2d (and 3d in the future)
//! game framework.
//!
//! have fun using it. (homemade btw)

// TODO: Better FixedBufferAllocator

const std = @import("std");
const builtin = @import("builtin");

const glad = @import("glad");
const glfw = @import("glfw");

const Allocator = std.mem.Allocator;

pub const Error = Allocator.Error || error{
    IsSingleton,
    CannotInit,
    CannotCreateObject,
};

pub const Game = opaque {
    /// In bytes (4 KiB)
    const ERROR_BLOCK_SIZE = 4 * 1024;

    var errorBlock = [_]u8{0} ** ERROR_BLOCK_SIZE;
    var currentError: ?[]const u8 = null;
    var instance: ?*Game = null;

    inline fn cast(self: *Game) *GameInternal {
        return @ptrCast(@alignCast(self));
    }

    pub fn getInstance() ?*Game {
        return instance;
    }

    pub fn setError(comptime fmt: []const u8, args: anytype, err: anytype) @TypeOf(err) {
        if (@typeInfo(@TypeOf(err)) != .ErrorSet) {
            @compileError("'err' must be an error");
        }

        currentError = std.fmt.bufPrint(&errorBlock, fmt, args) catch blk: {
            const truncMessage = " (truncated)";
            @memcpy(errorBlock[ERROR_BLOCK_SIZE - truncMessage.len ..], truncMessage);
            break :blk &errorBlock;
        };

        return err;
    }

    pub fn getError() ?[]const u8 {
        return currentError;
    }

    pub fn clearError() void {
        currentError = null;
    }

    pub fn init(allocator: Allocator, title: []const u8, width: u32, height: u32) Error!*Game {
        if (instance) |_| {
            return Error.IsSingleton;
        }

        const game = allocator.create(GameInternal) catch |e|
            return setError("Cannot create game: Out Of Memory", .{}, e);
        errdefer game.cast().deinit();
        game.allocator = allocator;
        // yes i'm hacky, but the stoopid computer
        // better do what I say or else...
        @as(*usize, @ptrCast(&game.window)).* = 0;

        glfw.initAllocator(&allocator);

        var errStr: []const u8 = "";
        glfw.init(&errStr) catch
            return setError("Cannot initialize GLFW: {s}", .{errStr}, Error.CannotInit);

        game.window = glfw.Window.create(
            title,
            width,
            height,
            .{
                .visible = false,
                .resizable = false,
                .vsync = true,
                .openglProfile = .Core,
                .version = .{ .major = 4, .minor = 6 },
            },
            null,
            null,
            &errStr,
        ) catch
            return setError("Cannot create window: {s}", .{errStr}, Error.CannotCreateObject);
        game.window.makeCurrentContext();

        game.glVersion = glad.init(&glfw.getProcAddress) catch
        // may be useless here :(
            return setError("Cannot initialize GLAD", .{}, Error.CannotInit);

        return game.cast();
    }

    pub fn deinit(self: *Game) void {
        glad.deinit();
        self.cast().window.destroy();
        glfw.terminate();
        self.cast().allocator.destroy(self.cast());
    }

    // Wrapper to game's allocator
    // needed for allocator since it would mess up with init()
    pub usingnamespace struct {
        pub fn allocator(self: *Game) Allocator {
            return self.cast().allocator;
        }
        pub fn create(self: *Game, comptime T: type) Allocator.Error!*T {
            return self.allocator().create(T);
        }
        pub fn destroy(self: *Game, ptr: anytype) void {
            if (@typeInfo(@TypeOf(ptr)) != .Pointer or @typeInfo(@TypeOf(ptr)).Pointer.size != .One) {
                @compileError("'ptr' must be a non-optional pointer to one");
            }
            return self.allocator().destroy(ptr);
        }
        pub fn alloc(self: *Game, comptime T: type, n: usize) Allocator.Error![]T {
            return self.allocator().alloc(T, n);
        }
        pub fn free(self: *Game, ptr: anytype) void {
            if (@typeInfo(@TypeOf(ptr)) != .Pointer or @typeInfo(@TypeOf(ptr)).Pointer.size != .Slice) {
                @compileError("'ptr' must be a non-optional slice");
            }
            return self.allocator().free(ptr);
        }
    };

    pub fn run(self: *Game) void {
        const window = self.cast().window;
        window.show();

        while (!window.shouldClose()) : (window.swapBuffers()) {
            glfw.pollEvents() catch unreachable;

            glad.clearRGBA(.{ .a = 255 }, .{
                .color = true,
                .depth = true,
            });
        }
    }
};

/// How.. did you... found that ? >:( GET THE FUDGE OUT
///
/// If you're still here, first of, go bridge yourself.
/// But this is just the actual data stored at a pointer
/// of `Game`
const GameInternal = struct {
    allocator: Allocator,
    window: *glfw.Window,
    glVersion: glad.Version,

    inline fn cast(self: *GameInternal) *Game {
        return @ptrCast(self);
    }
};
