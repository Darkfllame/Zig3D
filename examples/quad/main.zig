const std = @import("std");
const zig3d = @import("zig3d");

const glad = zig3d.glad;

const triangleVertices: []const f32 = &.{
    -0.5, -0.5, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0,
    0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,
    0.5,  0.5,  0.0, 0.0, 0.0, 1.0, 1.0, 1.0,
    -0.5, 0.5,  0.0, 1.0, 1.0, 1.0, 0.0, 1.0,
};
const triangleIndices: []const u32 = &.{
    0, 1, 2,
    0, 2, 3,
};

const vertexShaderSource =
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
const fragmentShaderSource =
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

    var errStr: []const u8 = "";
    zig3d.glfw.init(&errStr) catch |e| {
        return zig3d.println(
            "Error occurred: {s}: Cannot initialize GLFW: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer zig3d.glfw.terminate();
    try zig3d.println("Using GLFW version: {d}.{d}.{d}", zig3d.glfw.getVersion());

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
        &errStr,
    ) catch |e| {
        return zig3d.println(
            "Error occurred: {s}: Cannot create window: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer window.destroy();
    window.makeCurrentContext();

    const glVersion = glad.init(&zig3d.glfw.getProcAddress) catch |e| {
        return zig3d.println(
            "Error occurred: {s}: Cannot load OpenGL",
            .{
                @errorName(e),
            },
        );
    };
    try zig3d.println("Using OpenGL version: {d}.{d}", glVersion);

    // init()

    var program = glad.ShaderProgram.create();
    defer program.destroy();
    {
        var vert = glad.Shader.create(.Vertex);
        defer vert.destroy();

        var frag = glad.Shader.create(.Fragment);
        defer frag.destroy();

        _ = vert.source(vertexShaderSource).compile(allocator) catch |e| {
            return zig3d.println(
                "Error occurred: {s}: Cannot compile vertex shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
        _ = frag.source(fragmentShaderSource).compile(allocator) catch |e| {
            return zig3d.println(
                "Error occurred: {s}: Cannot compile fragment shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };

        (program.attachShader(vert).attachShader(frag).linkProgram(allocator) catch |e| {
            return zig3d.println(
                "Error occurred: {s}: Cannot link shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        }).ready(allocator) catch |e| {
            return zig3d.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
    }

    var vao = glad.VertexArray.create();
    defer vao.destroy();
    var buffers = glad.Buffer.createBuffers(2);
    defer glad.Buffer.destroyArray(2, &buffers);
    {
        vao.bind();

        buffers[0].bind(.Array);
        try buffers[0].data(f32, triangleVertices, .StaticDraw);

        buffers[1].bind(.ElementArray);
        try buffers[1].data(u32, triangleIndices, .StaticDraw);

        glad.VertexArray.vertexAttrib(0, 3, f32, false, 8 * @sizeOf(f32), 0);
        glad.VertexArray.vertexAttrib(1, 3, f32, false, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
        glad.VertexArray.vertexAttrib(2, 2, f32, false, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
        vao.enableAttrib(0);
        vao.enableAttrib(1);
        vao.enableAttrib(2);

        glad.Buffer.unbindAny(.ElementArray);
        glad.Buffer.unbindAny(.Array);
        glad.VertexArray.unbindAny();
    }

    glad.viewport(0, 0, 800, 600);
    window.show();
    while (!window.shouldClose()) {
        zig3d.glfw.pollEvents() catch |e| {
            return zig3d.println("Caught error during event polling: {s}", .{@errorName(e)});
        };

        // update()

        glad.clearRGBA(
            glad.FColor.Black,
            .{
                .color = true,
                .depth = true,
            },
        );

        program.useProgram();
        vao.bind();
        try glad.drawElements(.Triangles, triangleIndices.len, u32, 0);
        glad.VertexArray.unbindAny();
        glad.ShaderProgram.unuseAny();

        window.swapBuffers();
    }

    // quit()
}
