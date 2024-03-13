const std = @import("std");
const zig3d = @import("zig3d");

const glad = zig3d.glad;
const glfw = zig3d.glfw;
const graphics = zig3d.graphics;
const print = zig3d.print;
const println = zig3d.println;

const Vec3f = glad.Vec3f;
const Vec2f = glad.Vec2f;
const Key = glfw.Key;
const Vertex = graphics.Vertex;
const Mesh = graphics.Mesh;
const MeshBatch = graphics.MeshBatch;

fn autoError(e: anytype, additionalMessage: ?[]const u8, errStr: ?[]const u8) anyerror!void {
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
    return if (@import("builtin").mode == .Debug) e else {};
}

const triangleVertices: []const Vertex = &.{
    Vertex.new(-0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0),
    Vertex.new(0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0),
    Vertex.new(0.0, 0.5, 0.0, 0.0, 0.0, 1.0, 0.5, 1.0),
};
const triangleIndices: []const u32 = &.{
    0, 1, 2,
};

const vertexShaderSource: []const u8 =
    \\#version 460 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aCol;
    \\layout (location = 2) in vec2 aUV;
    \\
    \\out vec3 color;
    \\out vec2 UV;
    \\
    \\void main() {
    \\  gl_Position = vec4(aPos, 1.0);
    \\  color = aCol;
    \\  UV = aUV;
    \\}
;
const fragmentShaderSource: []const u8 =
    \\#version 460 core
    \\
    \\out vec4 FragColor;
    \\
    \\in vec3 color;
    \\in vec2 UV;
    \\
    \\void main() {
    \\  FragColor = vec4(color, 1.0);
    \\}
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    defer glfw.terminate();
    defer glad.deinit();

    var errMess: []const u8 = "";
    var errStr: []const u8 = "";
    main2(allocator, &errMess, &errStr) catch |e| {
        return autoError(e, errMess, errStr);
    };
}

fn main2(allocator: std.mem.Allocator, errMess: *[]const u8, errStr: *[]const u8) !void {
    glfw.init(errStr) catch |e| {
        errMess.* = "Cannot initialize GLFW";
        return e;
    };
    try println("Using GLFW version {d}.{d}.{d}", glfw.getVersion());

    var window = glfw.Window.create(allocator, "Zig3D Demo Window", 800, 600, .{
        .visible = false,
        .resizable = false,
    }, errStr) catch |e| {
        errMess.* = "Cannot create window";
        return e;
    };
    defer window.destroy();
    window.makeCurrentContext();

    const glVersion = glad.init(&glfw.getProcAddress) catch |e| {
        errMess.* = "Cannot initialize OpenGL";
        errStr.* = glad.getErrorMessage();
        return e;
    };
    try println("Using OpenGL version {d}.{d}", glVersion);

    var mbatch = MeshBatch.init(allocator);
    defer mbatch.deinit();

    try mbatch.addMesh(.{
        .vertices = @constCast(triangleVertices),
        .indices = @constCast(triangleIndices),
    });

    var program = glad.ShaderProgram.create();
    defer program.destroy();
    {
        var vert = glad.Shader.create(.Vertex);
        defer vert.destroy();

        var frag = glad.Shader.create(.Fragment);
        defer frag.destroy();

        _ = vert.source(vertexShaderSource).compile(allocator) catch |e| {
            errMess.* = "Cannot compile shader";
            errStr.* = glad.getErrorMessage();
            return e;
        };
        _ = frag.source(fragmentShaderSource).compile(allocator) catch |e| {
            errMess.* = "Cannot compile sahder";
            errStr.* = glad.getErrorMessage();
            return e;
        };

        (program.attachShader(vert).attachShader(frag).linkProgram(allocator) catch |e| {
            errMess.* = "Cannot link shader program";
            errStr.* = glad.getErrorMessage();
            return e;
        }).ready(allocator) catch |e| {
            errMess.* = "Program isn't ready";
            errStr.* = glad.getErrorMessage();
            return e;
        };
    }

    var winW: u32 = 0;
    var winH: u32 = 0;
    window.getSize(&winW, &winH);
    glad.viewport(0, 0, @intCast(winW), @intCast(winH));

    window.show();
    while (!window.shouldClose()) {
        glfw.pollEvents() catch |e| {
            return autoError(e, "Error during events polling", null);
        };
        window.getSize(&winW, &winH);

        glad.clearRGBA(glad.FColor.Black, .{
            .color = true,
            .depth = true,
        });

        program.useProgram();

        try mbatch.draw();

        window.swapBuffers();
    }
}
