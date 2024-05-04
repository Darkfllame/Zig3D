const std = @import("std");
const zig3d = @import("zig3d");
const utils = @import("utils");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();

    zig3d.glfw.initAllocator(&allocator);

    var errStr: []const u8 = "";
    zig3d.glfw.init(&errStr) catch |e| {
        return utils.println(
            "Error occurred: {s}: Cannot initialize GLFW: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer zig3d.glfw.terminate();
    try utils.println("Using GLFW version: {d}.{d}.{d}", zig3d.glfw.getVersion());

    var window = zig3d.glfw.Window.create(
        "Hello, Window!",
        800,
        600,
        .{
            .visible = false,
            .resizable = false,
            .vsync = true,
            .version = .{
                .major = 4,
                .minor = 6,
            },
        },
        null,
        null,
        &errStr,
    ) catch |e| {
        return utils.println(
            "Error occurred: {s}: Cannot create window: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer window.destroy();
    window.makeCurrentContext();

    const glVersion = zig3d.glad.init(&zig3d.glfw.getProcAddress) catch |e| {
        return utils.println(
            "Error occurred: {s}: Cannot load OpenGL",
            .{
                @errorName(e),
            },
        );
    };
    try utils.println("Using OpenGL version: {d}.{d}", glVersion);

    // init()

    zig3d.glad.viewport(0, 0, 800, 600);
    window.setResizable(true);
    window.show();
    while (!window.shouldClose()) {
        zig3d.glfw.pollEvents() catch |e| {
            return utils.println("Caught error during event polling: {s}", .{@errorName(e)});
        };

        // update()

        zig3d.glad.clearRGBA(
            zig3d.glad.FColor.Black,
            .{
                .color = true,
                .depth = true,
            },
        );

        // render()

        window.swapBuffers();
    }

    // quit()
}
