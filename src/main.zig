const std = @import("std");
const zig3d = @import("zig3d");

const glad = zig3d.glad;
const glfw = zig3d.glfw;
const print = zig3d.print;
const println = zig3d.println;

const Key = glfw.Key;

inline fn autoError(e: anytype, additionalMessage: ?[]const u8, errStr: ?[]const u8) anyerror {
    if (@typeInfo(@TypeOf(e)) != .ErrorSet) @compileError("'e' MUST be an error");
    try if (errStr) |es|
        if (additionalMessage) |mess|
            println("{s} Error | {s}: {s}", .{
                @errorName(e),
                mess,
                es,
            })
        else
            println("{s} Error | {s}", .{
                @errorName(e),
                es,
            })
    else if (additionalMessage) |mess|
        println("{s} Error | {s}", .{
            @errorName(e),
            mess,
        })
    else
        println("{s} Error", .{
            @errorName(e),
        });
    return e;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var errStr: []const u8 = "";

    glfw.init(&errStr) catch |e| {
        return autoError(e, "Cannot initialize GLFW", errStr);
    };
    try println("Using GLFW version {d}.{d}.{d}", glfw.getVersion());

    var window = glfw.Window.create(allocator, "Totally Minecraft", 800, 600, .{
        .visible = false,
        .resizable = false,
    }, &errStr) catch |e| {
        return autoError(e, "Cannot create window", errStr);
    };
    defer window.destroy();
    window.makeCurrentContext();

    const glVersion = glad.init(&glfw.getProcAddress) catch |e| {
        return autoError(e, "Cannot initialize OpenGL", null);
    };
    try println("Using OpenGL version {d}.{d}", glVersion);

    var winW: u32 = 0;
    var winH: u32 = 0;
    window.getSize(&winW, &winH);
    glad.viewport(0, 0, @intCast(winW), @intCast(winH));

    window.show();
    while (!window.shouldClose()) {
        glfw.pollEvents() catch |e| {
            return autoError(e, "Error during polling events", null);
        };
        window.getSize(&winW, &winH);

        glad.clearRGBA(glad.FColor.Black, .{
            .color = true,
            .depth = true,
        });

        window.swapBuffers();
    }
}
