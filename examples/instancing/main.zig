const std = @import("std");
const zig3d = @import("zig3d");
const utils = @import("utils");

const glfw = zig3d.glfw;
const glad = zig3d.glad;
const stb = zig3d.stb;

const IS_DEBUG = @import("builtin").mode == .Debug;

const vertices: []const f32 = &.{
    // x    y   z  r  g  b
    -0.5, -0.5, 0, 0, 0, 0,
    0.5,  -0.5, 0, 1, 0, 0,
    0.5,  0.5,  0, 1, 1, 0,
    -0.5, 0.5,  0, 0, 1, 0,
    -0.5, -0.5, 0, 0, 0, 0,
};

const vertexShaderSource =
    \\#version 460 core
    \\
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aCol;
    \\
    \\layout (location = 2) in vec3 offset;
    \\
    \\out vec3 color;
    \\
    \\void main() {
    \\  vec3 finalPos = offset + aPos;
    \\  gl_Position = vec4(finalPos, 1);
    \\  color = vec3(finalPos.x + 0.5, finalPos.y + 0.5, 0);
    \\}
;
const fragmentShaderSource =
    \\#version 460 core
    \\
    \\out vec4 FragColor;
    \\
    \\in vec3 color;
    \\
    \\void main() {
    \\  FragColor = vec4(color, 1);
    \\}
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var offsets = [_]f32{
        0.0,  0.0,  0.0,
        0.5,  0.5,  0.0,
        -0.5, -0.5, 0.0,
    };

    var errStr: []const u8 = "";
    glfw.init(&errStr) catch |e| {
        return utils.println(
            "Error occurred: {s}: Cannot initialize GLFW: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer glfw.terminate();
    try utils.println("Using GLFW version: {d}.{d}.{d}", glfw.getVersion());

    var window = glfw.Window.create(
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

    if (IS_DEBUG) {
        window.setKeyCallback(&keyCallback);
    }

    const glVersion = glad.init(&glfw.getProcAddress) catch |e| {
        return utils.println(
            "Error occurred: {s}: Cannot load OpenGL",
            .{
                @errorName(e),
            },
        );
    };
    defer glad.deinit();
    try utils.println("Using OpenGL version: {d}.{d}", glVersion);

    // init()

    glad.debugMessageCallback(&debugCallback, null);

    var VAO = glad.VertexArray.gen();
    defer VAO.destroy();
    var VBO = glad.Buffer.gen();
    defer VBO.destroy();
    var IBO = glad.Buffer.gen();
    defer IBO.destroy();
    {
        VAO.bind();

        VBO.bind(.Array);
        try glad.Buffer.dataTarget(.Array, f32, vertices, .StaticDraw);
        glad.VertexArray.vertexAttrib(0, 3, f32, false, 6 * @sizeOf(f32), 0);
        glad.VertexArray.vertexAttrib(1, 3, f32, false, 6 * @sizeOf(f32), 3 * @sizeOf(f32));

        IBO.bind(.Array);
        try glad.Buffer.dataTarget(.Array, f32, &offsets, .DynamicDraw);
        glad.VertexArray.vertexAttrib(2, 3, f32, false, 3 * @sizeOf(f32), 0);

        glad.Buffer.unbindAny(.Array);

        VAO.enableAttrib(0);
        VAO.enableAttrib(1);
        VAO.enableAttrib(2);
        try glad.VertexArray.vertexAttribDivisor(2, 1);

        glad.VertexArray.unbindAny();
    }

    var program = glad.ShaderProgram.create();
    defer program.destroy();
    {
        var vertex = glad.Shader.create(.Vertex);
        defer vertex.destroy();
        _ = vertex.source(vertexShaderSource).compile(allocator) catch |e| {
            return utils.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
        var fragment = glad.Shader.create(.Fragment);
        defer fragment.destroy();
        _ = fragment.source(fragmentShaderSource).compile(allocator) catch |e| {
            return utils.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
        _ = program.attachShader(vertex)
            .attachShader(fragment)
            .linkProgram(allocator) catch |e| {
            return utils.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
    }

    glad.viewport(0, 0, 800, 600);
    glad.enable(.CullFace);
    glad.enable(.DepthTest);
    window.show();
    var lt: f128 = 0;
    var delta: f64 = 0;
    while (!window.shouldClose()) {
        const now = @as(f128, @floatFromInt(std.time.nanoTimestamp())) / 1_000_000_000.0;
        const dt: f64 = dtBlk: {
            defer lt = @floatCast(now);
            break :dtBlk @floatCast(now - lt);
        };

        if (dt < 0) {
            std.time.sleep(16_000);
            continue;
        }

        {
            delta += dt;
            if (delta >= 1) {
                try utils.println("FPS: {d:.0}", .{1 / dt});
                delta = 0;
            }
        }

        glfw.pollEvents() catch |e| {
            return utils.println("Caught error during event polling: {s}", .{@errorName(e)});
        };

        // update()

        {
            const rpm = 60;
            const nowRot = rpm * now;
            offsets[3] = @floatCast(@sin(zig3d.zlm.toRadians(nowRot)));
            offsets[4] = @floatCast(@cos(zig3d.zlm.toRadians(nowRot)));
            offsets[6] = @floatCast(@sin(zig3d.zlm.toRadians((nowRot - 180))));
            offsets[7] = @floatCast(@cos(zig3d.zlm.toRadians((nowRot - 180))));
            IBO.bind(.Array);
            glad.Buffer.subdataTarget(.Array, 3, f32, offsets[3..8]) catch unreachable;
            glad.Buffer.unbindAny(.Array);
        }

        glad.clearRGBA(
            glad.FColor.Black,
            .{
                .color = true,
                .depth = true,
            },
        );

        // render()
        program.useProgram();
        VAO.bind();
        try glad.drawArraysInstanced(.TriangleStrip, 0, 5, 3);
        glad.VertexArray.unbindAny();
        glad.ShaderProgram.unuseAny();

        window.swapBuffers();
    }

    // quit()
}

fn debugCallback(source: glad.DebugSource, kind: glad.DebugType, id: glad.Error, severity: glad.DebugSeverity, message: []const u8, userData: ?*anyopaque) void {
    _ = userData; // autofix
    if (severity == .Notification) {
        std.debug.print(
            \\[DEBUG] ({s}) {s} from {s}
            \\  {s}
            \\
        ,
            .{ @errorName(id), @tagName(kind), @tagName(source), message },
        );
    } else {
        std.debug.print(
            \\[ERROR {s}] ({s}) {d} from {d}
            \\  {s}
            \\
        ,
            .{ @tagName(severity), @errorName(id), @tagName(kind), @tagName(source), message },
        );
    }
}

fn keyCallback(window: *glfw.Window, key: glfw.Key, action: glfw.Key.Action, mods: glfw.Key.Mods) anyerror!void {
    _ = key; // autofix
    _ = window; // autofix
    _ = mods; // autofix
    switch (action) {
        else => {},
    }
}
