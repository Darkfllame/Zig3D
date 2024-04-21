const std = @import("std");
const zig3d = @import("zig3d");

const glfw = zig3d.glfw;
const glad = zig3d.glad;
const stb = zig3d.stb;

const vertices: []const f32 = &.{
    // x    y   z  r  g  b  u  v
    -0.5, -0.5, 0, 0, 0, 0, 0, 0,
    0.5,  -0.5, 0, 1, 0, 0, 1, 0,
    0.5,  0.5,  0, 1, 1, 0, 1, 1,
    -0.5, 0.5,  0, 0, 1, 0, 0, 1,
    -0.5, -0.5, 0, 0, 0, 0, 0, 0,
};

const vertexShaderSource =
    \\#version 460 core
    \\
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aCol;
    \\layout (location = 2) in vec2 aUV;
    \\
    \\out vec3 color;
    \\out vec2 uv;
    \\
    \\void main() {
    \\  gl_Position = vec4(aPos, 1);
    \\  color = aCol;
    \\  uv = aUV;
    \\}
;
const fragmentShaderSource =
    \\#version 460 core
    \\#extension GL_ARB_bindless_texture : require
    \\
    \\out vec4 FragColor;
    \\
    \\in vec3 color;
    \\in vec2 uv;
    \\
    \\layout (bindless_sampler) uniform sampler2D tex;
    \\
    \\void main() {
    \\  FragColor = texture(tex, uv) * vec4(color, 1);
    \\}
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var errStr: []const u8 = "";
    glfw.init(&errStr) catch |e| {
        return zig3d.println(
            "Error occurred: {s}: Cannot initialize GLFW: {s}",
            .{
                @errorName(e),
                errStr,
            },
        );
    };
    defer glfw.terminate();
    try zig3d.println("Using GLFW version: {d}.{d}.{d}", glfw.getVersion());

    var window = glfw.Window.create(
        allocator,
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

    window.setKeyCallback(&keyCallback);

    const glVersion = glad.init(&glfw.getProcAddress) catch |e| {
        return zig3d.println(
            "Error occurred: {s}: Cannot load OpenGL",
            .{
                @errorName(e),
            },
        );
    };
    defer glad.deinit();
    try zig3d.println("Using OpenGL version: {d}.{d}", glVersion);

    // init()

    var VAO = glad.VertexArray.gen();
    defer VAO.destroy();
    var VBO = glad.Buffer.gen();
    defer VBO.destroy();
    {
        VAO.bind();
        VBO.bind(.Array);
        try glad.Buffer.dataTarget(.Array, f32, vertices, .StaticDraw);
        const stride = 8 * @sizeOf(f32);
        VAO.vertexAttrib(0, 3, f32, false, stride, 0);
        VAO.vertexAttrib(1, 3, f32, false, stride, 3 * @sizeOf(f32));
        VAO.vertexAttrib(2, 2, f32, false, stride, 6 * @sizeOf(f32));
        VAO.enableAttrib(0);
        VAO.enableAttrib(1);
        VAO.enableAttrib(2);
        glad.Buffer.unbindAny(.Array);
        glad.VertexArray.unbindAny();
    }

    var program = glad.ShaderProgram.create();
    defer program.destroy();
    {
        var vertex = glad.Shader.create(.Vertex);
        defer vertex.destroy();
        _ = vertex.source(vertexShaderSource).compile(allocator) catch |e| {
            return zig3d.println(
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
            return zig3d.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
        _ = program
            .attachShader(vertex)
            .attachShader(fragment)
            .linkProgram(allocator) catch |e| {
            return zig3d.println(
                "Error occurred: {s}: Cannot compile shader: {s}",
                .{
                    @errorName(e),
                    glad.getErrorMessage(),
                },
            );
        };
    }

    stb.setFlipVerticallyOnLoad(true);

    var texture = glad.Texture.gen();
    defer texture.destroy();
    {
        var image = stb.Image.loadZ("texture.png", &errStr) orelse {
            return zig3d.println("Cannot load texture from file: {s}", .{errStr});
        };
        defer image.delete();

        texture.bind(.Texture2D);

        try glad.Texture.texParam(.Texture2D, .MinFilter, .Nearest);
        try glad.Texture.texParam(.Texture2D, .MagFilter, .Nearest);

        try glad.Texture.texParam(.Texture2D, .WrapS, .Repeat);
        try glad.Texture.texParam(.Texture2D, .WrapT, .Repeat);

        try glad.Texture.texParam(.Texture2D, .WrapS, .Repeat);
        try glad.Texture.texParam(.Texture2D, .WrapT, .Repeat);

        try glad.Texture.texImage(
            2,
            .Texture2D,
            0,
            .RGBA,
            image.width,
            image.height,
            0,
            u8,
            image.pixels,
        );

        glad.Texture.generateMipmap(.Texture2D);
        glad.Texture.unbindAny(.Texture2D);
    }
    const textureHandle = glad.TextureHandle.init(texture);
    defer textureHandle.makeNonResident();
    textureHandle.makeResident();

    program.useProgram();
    try program.setUniform("tex", textureHandle);

    glad.viewport(0, 0, 800, 600);
    glad.enable(.CullFace);
    glad.enable(.DepthTest);
    window.show();
    var lt: f64 = 0;
    var delta: f64 = 0;
    while (!window.shouldClose()) {
        const dt: f64 = dtBlk: {
            const now = @as(f64, @floatFromInt(std.time.nanoTimestamp())) / 1_000_000_000.0;
            defer lt = now;
            break :dtBlk now - lt;
        };

        if (dt <= 1e-8) {
            std.time.sleep(16_000);
            continue;
        }

        {
            delta += dt;
            if (delta >= 1) {
                try zig3d.println("FPS: {d:.0}", .{1 / dt});
                delta = 0;
            }
        }

        glfw.pollEvents() catch |e| {
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

        // render()
        VAO.bind();
        try glad.drawArrays(.TriangleStrip, 0, 5);
        glad.VertexArray.unbindAny();

        window.swapBuffers();
    }

    // quit()
}

fn keyCallback(window: *glfw.Window, key: glfw.Key, action: glfw.Key.Action, mods: glfw.Key.Mods) anyerror!void {
    _ = key; // autofix
    _ = window; // autofix
    _ = mods; // autofix
    switch (action) {
        else => {},
    }
}
