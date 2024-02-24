const std = @import("std");
const utils = @import("utils.zig");
const ziglm = @import("ziglm");
const c = @cImport({
    @cInclude("GLAD/glad.h");
});

const Allocator = std.mem.Allocator;

pub const Vec2f = ziglm.Vec2(f32);
pub const Vec2d = ziglm.Vec2(f64);
pub const Vec3f = ziglm.Vec3(f32);
pub const Vec3d = ziglm.Vec3(f64);
pub const Vec4f = ziglm.Vec4(f32);
pub const Vec4d = ziglm.Vec4(f64);

pub const Mat2f = ziglm.Mat2(f32);
pub const Mat2d = ziglm.Mat2(f64);
pub const Mat3f = ziglm.Mat3(f32);
pub const Mat3d = ziglm.Mat3(f64);
pub const Mat4f = ziglm.Mat4(f32);
pub const Mat4d = ziglm.Mat4(f64);

pub const GladLoadProc = *const fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub const DebugProc = *const fn (source: DebugSource, kind: DebugType, id: u32, severity: DebugSeverity, message: []const u8, userData: ?*anyopaque) void;

pub const Version = struct {
    minor: u32 = 1,
    major: u32 = 0,

    comptime {
        if (@sizeOf(u32) != @sizeOf(c_int) or @alignOf(u32) != @alignOf(c_int))
            @compileError("u32 and c_int aren't the same size and alignement ! Consider using another platform");
    }
};

pub const Error = error{
    NoError,
    InvalidEnum,
    InvalidValue,
    InvalidOperation,
    StackOverflow,
    StackUnderflow,
    OutOfMemory,
    InvalidFramebufferOperation,
    ContextLost,
    TableTooLarge,
};

fn errFromC(err: c.GLenum) Error {
    return switch (err) {
        c.GL_INVALID_ENUM => Error.InvalidEnum,
        c.GL_INVALID_VALUE => Error.InvalidValue,
        c.GL_INVALID_OPERATION => Error.InvalidOperation,
        c.GL_STACK_OVERFLOW => Error.StackOverflow,
        c.GL_STACK_UNDERFLOW => Error.StackUnderflow,
        c.GL_OUT_OF_MEMORY => Error.OutOfMemory,
        c.GL_INVALID_FRAMEBUFFER_OPERATION => Error.InvalidFramebufferOperation,
        else => {
            // edge cases for different versions of glad apparently
            if ((comptime @hasDecl(c, "GL_CONTEXT_LOST")) and err == c.GL_CONTEXT_LOST)
                return Error.ContextLost;
            if ((comptime @hasDecl(c, "GL_TABLE_TOO_LARGE")) and err == c.GL_TABLE_TOO_LARGE)
                return Error.TableTooLarge;
            return Error.NoError;
        },
    };
}

/// if loader is null it will use the builtin glad loader
/// otherwise it will use the loader.
///
/// I recommend using glfw.getProcAddress for loader.
pub fn init(loader: ?GladLoadProc) Error!Version {
    const status = if (loader != null) c.gladLoadGLLoader(loader) else c.gladLoadGL();
    if (status == 0)
        return errFromC(@bitCast(status));
    var ver = Version{};
    c.glGetIntegerv(c.GL_MAJOR_VERSION, @ptrCast(&ver.major));
    c.glGetIntegerv(c.GL_MINOR_VERSION, @ptrCast(&ver.minor));
    return ver;
}

pub fn viewport(x: u32, y: u32, width: usize, height: usize) void {
    c.glViewport(
        @intCast(x),
        @intCast(y),
        @intCast(width),
        @intCast(height),
    );
}

pub const Capability = enum {
    Blend,
    ColorLogicOp,
    CullFace,
    DebugOutput,
    DebugOutputSync,
    DepthClamp,
    DepthTest,
    Dither,
    FramebufferSRGB,
    LineSmooth,
    Multisample,
    PolygonOffsetFill,
    PolygonOffsetLine,
    PolygonSmooth,
    PrimitiveRestart,
    PrimitiveRestartFixedIndex,
    RasterizerDiscard,
    SampleAlphaToCoverage,
    SampleAlphaToOne,
    SampleCoverage,
    SampleShading,
    SampleMask,
    ScissorTest,
    StencilTest,
    TextureCubeMapSeamless,
    ProgramPointSize,
};

inline fn capability2GL(cap: Capability) c.GLenum {
    return switch (cap) {
        .Blend => c.GL_BLEND,
        .ColorLogicOp => c.GL_COLOR_LOGIC_OP,
        .CullFace => c.GL_CULL_FACE,
        .DebugOutput => c.GL_DEBUG_OUTPUT,
        .DebugOutputSync => c.GL_DEBUG_OUTPUT_SYNCHRONOUS,
        .DepthClamp => c.GL_DEPTH_CLAMP,
        .DepthTest => c.GL_DEPTH_TEST,
        .Dither => c.GL_DITHER,
        .FramebufferSRGB => c.GL_FRAMEBUFFER_SRGB,
        .LineSmooth => c.GL_LINE_SMOOTH,
        .Multisample => c.GL_MULTISAMPLE,
        .PolygonOffsetFill => c.GL_POLYGON_OFFSET_FILL,
        .PolygonOffsetLine => c.GL_POLYGON_OFFSET_LINE,
        .PolygonSmooth => c.GL_POLYGON_SMOOTH,
        .PrimitiveRestart => c.GL_PRIMITIVE_RESTART,
        .PrimitiveRestartFixedIndex => c.GL_PRIMITIVE_RESTART_FIXED_INDEX,
        .RasterizerDiscard => c.GL_RASTERIZER_DISCARD,
        .SampleAlphaToCoverage => c.GL_SAMPLE_ALPHA_TO_COVERAGE,
        .SampleAlphaToOne => c.GL_SAMPLE_ALPHA_TO_ONE,
        .SampleCoverage => c.GL_SAMPLE_COVERAGE,
        .SampleShading => c.GL_SAMPLE_SHADING,
        .SampleMask => c.GL_SAMPLE_MASK,
        .ScissorTest => c.GL_SCISSOR_TEST,
        .StencilTest => c.GL_STENCIL_TEST,
        .TextureCubeMapSeamless => c.GL_TEXTURE_CUBE_MAP_SEAMLESS,
        .ProgramPointSize => c.GL_PROGRAM_POINT_SIZE,
    };
}

pub fn enable(cap: Capability) void {
    c.glEnable(capability2GL(cap));
}
pub fn disable(cap: Capability) void {
    c.glDisable(capability2GL(cap));
}

pub const DebugSource = enum {
    Api,
    WindowSystem,
    ShaderCompiler,
    ThirdParty,
    Application,
    Other,
};
inline fn dbSrcFromGL(s: c.GLenum) DebugSource {
    return switch (s) {
        c.GL_DEBUG_SOURCE_API => .Api,
        c.GL_DEBUG_SOURCE_WINDOW_SYSTEM => .WindowSystem,
        c.GL_DEBUG_SOURCE_SHADER_COMPILER => .ShaderCompiler,
        c.GL_DEBUG_SOURCE_THIRD_PARTY => .ThirdParty,
        c.GL_DEBUG_SOURCE_APPLICATION => .Application,
        else => .Other,
    };
}
pub const DebugType = enum {
    Error,
    DeprecatedBehaviour,
    UndefinedBehaviour,
    Portability,
    Performance,
    Marker,
    PushGroup,
    PopGroup,
    Other,
};
inline fn dbTypeFromGL(t: c.GLenum) DebugType {
    return switch (t) {
        c.GL_DEBUG_TYPE_ERROR => .Error,
        c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR => .DeprecatedBehaviour,
        c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR => .UndefinedBehaviour,
        c.GL_DEBUG_TYPE_PORTABILITY => .Portability,
        c.GL_DEBUG_TYPE_PERFORMANCE => .Performance,
        c.GL_DEBUG_TYPE_MARKER => .Marker,
        c.GL_DEBUG_TYPE_PUSH_GROUP => .PushGroup,
        c.GL_DEBUG_TYPE_POP_GROUP => .PopGroup,
        else => .Other,
    };
}
pub const DebugSeverity = enum {
    High,
    Medium,
    Low,
    Notification,
};
inline fn dbSevFromGL(s: c.GLenum) DebugSeverity {
    return switch (s) {
        c.GL_DEBUG_SEVERITY_HIGH => .High,
        c.GL_DEBUG_SEVERITY_MEDIUM => .Medium,
        c.GL_DEBUG_SEVERITY_LOW => .Low,
        else => .Notification,
    };
}

pub fn debugMessageCallback(callback: DebugProc, userParam: ?*anyopaque) void {
    const state = struct {
        pub var cb: ?DebugProc = null;
        pub var setupDone: bool = false;
        pub var userData: ?*anyopaque = null;

        pub fn debugCb(
            source: c.GLenum,
            @"type": c.GLenum,
            id: c.GLuint,
            severity: c.GLenum,
            length: c.GLsizei,
            message: [*c]const c.GLchar,
            _: ?*const anyopaque,
        ) callconv(.C) void {
            const zSource = dbSrcFromGL(source);
            const zKind = dbTypeFromGL(@"type");
            const zId: u32 = @intCast(id);
            const zSev = dbSevFromGL(severity);
            const len: usize = @intCast(@as(c_uint, @bitCast(length)));
            const zMessage: []const u8 = message[0..len];
            if (cb != null) cb.?(zSource, zKind, zId, zSev, zMessage, userData);
        }
    };
    if (!state.setupDone) {
        c.glDebugMessageCallback(&state.debugCb, null);
        state.setupDone = true;
    }
    state.cb = callback;
    state.userData = userParam;
}

pub const ClearBits = struct {
    depth: bool = false,
    color: bool = false,
    accum: bool = false,
};

pub fn clearColor(red: f32, green: f32, blue: f32, alpha: f32) void {
    c.glClearColor(red, green, blue, alpha);
}
pub fn clear(mask: ClearBits) void {
    c.glClear(
        @as(c_uint, if (mask.depth) c.GL_DEPTH_BUFFER_BIT else 0) |
            @as(c_uint, if (mask.color) c.GL_COLOR_BUFFER_BIT else 0) |
            @as(c_uint, if (mask.accum) c.GL_ACCUM_BUFFER_BIT else 0),
    );
}

pub const FColor = struct {
    pub const Black = FColor{ .a = 1 };
    pub const White = FColor{ .r = 1, .g = 1, .b = 1, .a = 1 };
    pub const Red = FColor{ .r = 1, .a = 1 };
    pub const Green = FColor{ .g = 1, .a = 1 };
    pub const Blue = FColor{ .b = 1, .a = 1 };

    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,

    pub fn maxVal(self: *const FColor) f32 {
        return @max(@max(self.r, self.g), @max(self.b, self.a));
    }
    pub fn clamp(self: FColor) FColor {
        const mVal = self.maxVal();
        if (mVal == 0) return .{};
        return self.scl(1 / mVal);
    }
    pub fn scl(self: FColor, scalar: f32) FColor {
        return .{
            .r = self.r * scalar,
            .g = self.g * scalar,
            .b = self.b * scalar,
            .a = self.a * scalar,
        };
    }
    pub fn mul(self: FColor, rhs: FColor) FColor {
        return .{
            .r = self.r * rhs.r,
            .g = self.g * rhs.g,
            .b = self.b * rhs.b,
            .a = self.a * rhs.a,
        };
    }
};

pub fn clearRGBA(color: FColor, mask: ClearBits) void {
    clearColor(color.r, color.g, color.b, color.a);
    clear(mask);
}

inline fn type2GL(comptime T: type) c.GLenum {
    return switch (T) {
        bool => c.GL_BOOL,
        i8 => c.GL_BYTE,
        u8 => c.GL_UNSIGNED_BYTE,
        i16 => c.GL_SHORT,
        u16 => c.GL_UNSIGNED_SHORT,
        i32 => c.GL_INT,
        u32 => c.GL_UNSIGNED_INT,
        f16 => c.GL_HALF_FLOAT,
        f32 => c.GL_FLOAT,
        f64 => c.GL_DOUBLE,
        else => @compileError("Unsupported type: " ++ @typeName(T)),
    };
}

pub const VertexArray = struct {
    id: u32 = 0,

    pub fn create() VertexArray {
        var vao = VertexArray{};
        c.glCreateVertexArrays(1, @ptrCast(&vao.id));
        return vao;
    }
    pub fn createArray(allocator: Allocator, count: usize) Error![]VertexArray {
        const slice = try allocator.alloc(VertexArray, count);
        // yeah dangerous cast i know thanks
        c.glCreateVertexArrays(count, @ptrCast(slice.ptr));
        return slice;
    }
    pub fn destroy(self: *VertexArray) void {
        c.glDeleteVertexArrays(1, @ptrCast(&self.id));
        self.* = undefined;
    }
    pub fn destroyArray(allocator: Allocator, arr: *[]VertexArray) void {
        c.glDeleteVertexArrays(arr.len, @ptrCast(arr.ptr));
        allocator.free(arr.*);
        arr.* = undefined;
    }

    pub fn bind(self: VertexArray) void {
        c.glBindVertexArray(@intCast(self.id));
    }
    pub fn unbindAny() void {
        c.glBindVertexArray(0);
    }

    pub fn enableAttrib(self: VertexArray, location: u32) void {
        c.glEnableVertexArrayAttrib(@intCast(self.id), @intCast(location));
    }
    pub fn vertexAttrib(self: VertexArray, location: u32, size: u32, comptime T: type, normalized: bool, stride: usize, offset: usize) void {
        self.bind();
        c.glVertexAttribPointer(
            location,
            @bitCast(size),
            type2GL(T),
            @intFromBool(normalized),
            @intCast(stride),
            @ptrFromInt(offset),
        );
        c.glEnableVertexAttribArray(location);
        unbindAny();
    }
};

pub const BufferType = enum {
    Array,
    AtomicCounter,
    CopyRead,
    CopyWrite,
    DispatchIndirect,
    DrawIndirect,
    ElementArray,
    PixelPack,
    PixelUnpack,
    Query,
    ShaderStorage,
    Texture,
    TransformFeedback,
    Uniform,
};

inline fn bufferType2GL(@"type": BufferType) c.GLenum {
    return switch (@"type") {
        .Array => c.GL_ARRAY_BUFFER,
        .AtomicCounter => c.GL_ATOMIC_COUNTER_BUFFER,
        .CopyRead => c.GL_COPY_READ_BUFFER,
        .CopyWrite => c.GL_COPY_WRITE_BUFFER,
        .DispatchIndirect => c.GL_DISPATCH_INDIRECT_BUFFER,
        .DrawIndirect => c.GL_DRAW_INDIRECT_BUFFER,
        .ElementArray => c.GL_ELEMENT_ARRAY_BUFFER,
        .PixelPack => c.GL_PIXEL_PACK_BUFFER,
        .PixelUnpack => c.GL_PIXEL_UNPACK_BUFFER,
        .Query => c.GL_QUERY_BUFFER,
        .ShaderStorage => c.GL_SHADER_STORAGE_BUFFER,
        .Texture => c.GL_TEXTURE_BUFFER,
        .TransformFeedback => c.GL_TRANSFORM_FEEDBACK_BUFFER,
        .Uniform => c.GL_UNIFORM_BUFFER,
    };
}

pub const DataAccess = enum {
    StreamDraw,
    StreamRead,
    StreamCopy,

    StaticDraw,
    StaticRead,
    StaticCopy,

    DynamicDraw,
    DynamicRead,
    DynamicCopy,
};

inline fn dataAccedd2GL(access: DataAccess) c.GLenum {
    return switch (access) {
        .StreamDraw => c.GL_STREAM_DRAW,
        .StreamRead => c.GL_STREAM_READ,
        .StreamCopy => c.GL_STREAM_COPY,

        .StaticDraw => c.GL_STATIC_DRAW,
        .StaticRead => c.GL_STATIC_READ,
        .StaticCopy => c.GL_STATIC_COPY,

        .DynamicDraw => c.GL_DYNAMIC_DRAW,
        .DynamicRead => c.GL_DYNAMIC_READ,
        .DynamicCopy => c.GL_DYNAMIC_COPY,
    };
}

pub const Buffer = struct {
    id: u32 = 0,

    pub fn create() Buffer {
        var buf = Buffer{};
        c.glCreateBuffers(1, @ptrCast(&buf.id));
        return buf;
    }
    pub fn createArray(allocator: Allocator, count: usize) Error![]Buffer {
        const slice = try allocator.alloc(Buffer, count);
        // yeah dangerous cast i know thanks
        c.glCreateBuffers(@intCast(count), @ptrCast(slice.ptr));
        return slice;
    }
    pub fn destroy(self: *Buffer) void {
        c.glDeleteBuffers(1, @ptrCast(&self.id));
        self.* = undefined;
    }
    pub fn destroyArray(allocator: Allocator, arr: *[]Buffer) void {
        c.glDeleteBuffers(@intCast(arr.len), @ptrCast(arr.ptr));
        allocator.free(arr.*);
        arr.* = undefined;
    }

    pub fn bind(self: Buffer, btype: BufferType) void {
        c.glBindBuffer(bufferType2GL(btype), @intCast(self.id));
    }
    pub fn unbindAny(btype: BufferType) void {
        c.glBindBuffer(bufferType2GL(btype), 0);
    }

    pub fn data(self: Buffer, comptime T: type, dat: []const T, access: DataAccess) void {
        c.glNamedBufferData(@intCast(self.id), @intCast(dat.len * @sizeOf(T)), @ptrCast(dat.ptr), dataAccedd2GL(access));
    }
};

pub const ShaderType = enum {
    Compute,
    Vertex,
    TessControl,
    TessEval,
    Geometry,
    Fragment,
};

inline fn shaderType2GL(@"type": ShaderType) c.GLenum {
    return switch (@"type") {
        .Compute => c.GL_COMPUTE_SHADER,
        .Vertex => c.GL_VERTEX_SHADER,
        .TessControl => c.GL_TESS_CONTROL_SHADER,
        .TessEval => c.GL_TESS_EVALUATION_SHADER,
        .Geometry => c.GL_GEOMETRY_SHADER,
        .Fragment => c.GL_FRAGMENT_SHADER,
    };
}

pub const Shader = struct {
    id: u32 = 0,

    pub fn create(@"type": ShaderType) Shader {
        return .{
            .id = c.glCreateShader(shaderType2GL(@"type")),
        };
    }
    pub fn destroy(self: *Shader) void {
        c.glDeleteShader(@intCast(self.id));
        self.* = undefined;
    }

    // Error type was too long
    pub fn sourceFile(self: *const Shader, allocator: Allocator, filename: []const u8) utils.FnErrorSet(utils.readFile)!*const Shader {
        const content = try utils.readFile(allocator, filename);
        _ = try self.source(content, allocator);
        allocator.free(content);
        return self;
    }
    pub fn source(self: *const Shader, src: []const u8, allocator: Allocator) Allocator.Error!*const Shader {
        const src_cpy = utils.copy(
            u8,
            try allocator.alloc(u8, src.len + 1),
            src,
        );
        defer allocator.free(src_cpy);

        src_cpy[src.len] = 0;

        c.glShaderSource(
            @intCast(self.id),
            1,
            @ptrCast(&src_cpy.ptr),
            null,
        );
        return self;
    }
    pub fn compile(self: *const Shader, allocator: Allocator) Error!*const Shader {
        c.glCompileShader(@intCast(self.id));
        var status: u32 = 0;
        c.glGetShaderiv(@intCast(self.id), c.GL_COMPILE_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetShaderiv(@intCast(self.id), c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);
            defer allocator.free(log);

            c.glGetShaderInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            return errFromC(status);
        }
        return self;
    }
};

pub const BarrierBits = struct {
    pub const All = BarrierBits{
        .vertexAttribArray = true,
        .elementArray = true,
        .uniform = true,
        .textureFetch = true,
        .shaderImageAccess = true,
        .command = true,
        .pixelBuffer = true,
        .textureUpdate = true,
        .bufferUpdate = true,
        .clientMappedBuffer = true,
        .framebuffer = true,
        .transformFeedback = true,
        .atomicCounter = true,
        .shaderStorage = true,
        .queryBuffer = true,
    };
    vertexAttribArray: bool = false,
    elementArray: bool = false,
    uniform: bool = false,
    textureFetch: bool = false,
    shaderImageAccess: bool = false,
    command: bool = false,
    pixelBuffer: bool = false,
    textureUpdate: bool = false,
    bufferUpdate: bool = false,
    clientMappedBuffer: bool = false,
    framebuffer: bool = false,
    transformFeedback: bool = false,
    atomicCounter: bool = false,
    shaderStorage: bool = false,
    queryBuffer: bool = false,
};

inline fn barrierBits2GL(bits: BarrierBits) c.GLbitfield {
    return @intCast((if (bits.vertexAttribArray) c.GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT else 0) |
        (if (bits.elementArray) c.GL_ELEMENT_ARRAY_BARRIER_BIT else 0) |
        (if (bits.uniform) c.GL_UNIFORM_BARRIER_BIT else 0) |
        (if (bits.textureFetch) c.GL_TEXTURE_FETCH_BARRIER_BIT else 0) |
        (if (bits.shaderImageAccess) c.GL_SHADER_IMAGE_ACCESS_BARRIER_BIT else 0) |
        (if (bits.command) c.GL_COMMAND_BARRIER_BIT else 0) |
        (if (bits.pixelBuffer) c.GL_PIXEL_BUFFER_BARRIER_BIT else 0) |
        (if (bits.textureUpdate) c.GL_TEXTURE_UPDATE_BARRIER_BIT else 0) |
        (if (bits.bufferUpdate) c.GL_BUFFER_UPDATE_BARRIER_BIT else 0) |
        (if (bits.clientMappedBuffer) c.GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT else 0) |
        (if (bits.framebuffer) c.GL_FRAMEBUFFER_BARRIER_BIT else 0) |
        (if (bits.transformFeedback) c.GL_TRANSFORM_FEEDBACK_BARRIER_BIT else 0) |
        (if (bits.atomicCounter) c.GL_ATOMIC_COUNTER_BARRIER_BIT else 0) |
        (if (bits.shaderStorage) c.GL_SHADER_STORAGE_BARRIER_BIT else 0) |
        (if (bits.queryBuffer) c.GL_QUERY_BUFFER_BARRIER_BIT else 0));
}

pub const ShaderProgram = struct {
    // TODO: Make uniforms functions

    id: u32 = 0,

    pub fn create() ShaderProgram {
        return .{
            .id = c.glCreateProgram(),
        };
    }
    pub fn destroy(self: *ShaderProgram) void {
        if (self.id != 0)
            c.glDeleteProgram(@intCast(self.id));
        self.* = undefined;
    }

    pub fn useProgram(self: ShaderProgram) void {
        c.glUseProgram(@intCast(self.id));
    }
    pub fn ready(self: ShaderProgram, allocator: Allocator) Error!void {
        c.glValidateProgram(@intCast(self.id));
        var status: i32 = 0;
        c.glGetProgramiv(@intCast(self.id), c.GL_VALIDATE_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetProgramiv(@intCast(self.id), c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);
            defer allocator.free(log);

            c.glGetProgramInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            return errFromC(status);
        }
    }

    pub fn attachShader(self: *const ShaderProgram, shader: Shader) *const ShaderProgram {
        c.glAttachShader(@intCast(self.id), @intCast(shader.id));
        return self;
    }
    pub fn linkProgram(self: *const ShaderProgram, allocator: Allocator) Error!*const ShaderProgram {
        c.glLinkProgram(@intCast(self.id));
        var status: u32 = 0;
        c.glGetProgramiv(@intCast(self.id), c.GL_LINK_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetProgramiv(@intCast(self.id), c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);
            defer allocator.free(log);

            c.glGetProgramInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            return errFromC(status);
        }
        return self;
    }

    pub fn uniformLocation(self: ShaderProgram, name: [:0]const u8) u32 {
        const loc = c.glGetUniformLocation(@intCast(self.id), @ptrCast(name.ptr));
        return @intCast(loc);
    }
    pub fn setUniformLoc(self: ShaderProgram, location: u32, value: anytype) void {
        _ = self;

        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        switch (tinfo) {
            inline .Struct => {
                switch (T) {
                    Vec2f => c.glUniform2f(@intCast(location), value.x, value.y),
                    Vec2d => c.glUniform2d(@intCast(location), value.x, value.y),
                    Vec3f => c.glUniform3f(@intCast(location), value.x, value.y, value.z),
                    Vec3d => c.glUniform3d(@intCast(location), value.x, value.y, value.z),
                    Vec4f => c.glUniform4f(@intCast(location), value.x, value.y, value.z, value.w),
                    Vec4d => c.glUniform4d(@intCast(location), value.x, value.y, value.z, value.w),
                    Mat2f => c.glUniformMatrix2fv(@intCast(location), comptime 2 * 2, false, value.cols),
                    Mat2d => c.glUniformMatrix2dv(@intCast(location), comptime 2 * 2, false, value.cols),
                    Mat3f => c.glUniformMatrix3fv(@intCast(location), comptime 3 * 3, false, value.cols),
                    Mat3d => c.glUniformMatrix3dv(@intCast(location), comptime 3 * 3, false, value.cols),
                    Mat4f => c.glUniformMatrix4fv(@intCast(location), comptime 4 * 4, false, value.cols),
                    Mat4d => c.glUniformMatrix4dv(@intCast(location), comptime 4 * 4, false, value.cols),
                    else => @compileError("Cannot set uniform with type " ++ T),
                }
            },
            inline .Int => |v| {
                (switch (v.bits) {
                    inline 32 => if (v.signedness == .signed) c.glUniform1i else c.glUniform1ui,
                    inline else => @compileError("Cannot set int uniform with " ++ v.bits ++ " bits, available is 32"),
                })(@intCast(location), value);
            },
            inline .Float => |v| {
                (switch (v.bits) {
                    inline 32 => c.glUniform1f,
                    inline 64 => c.glUniform1d,
                    inline else => @compileError("Cannot set float uniform with " ++ v.bits ++ " bits, available are 32 and 64"),
                })(@intCast(location), value);
            },
            inline else => @compileError("Cannot set uniform with type " ++ T),
        }
    }
    pub fn setUniform(self: ShaderProgram, name: [:0]const u8, value: anytype) void {
        self.setUniformLoc(self.uniformLocation(name), value);
    }

    pub fn dispatchCompute(self: ShaderProgram, x: u32, y: u32, z: u32) void {
        _ = self;
        c.glDispatchCompute(@intCast(x), @intCast(y), @intCast(z));
    }
    pub fn memoryBarrier(self: ShaderProgram, barrier: BarrierBits) void {
        _ = self;
        c.glMemoryBarrier(barrierBits2GL(barrier));
    }
};

pub const DrawMode = enum {
    Points,
    LineStrip,
    LineLoop,
    Lines,
    LineStripAdjacency,
    LinesAdjacency,
    TriangleStrip,
    TriangleFan,
    Triangles,
    TriangleStripAdjacency,
    TrianglesAdjacency,
    Patches,
};

inline fn drawMod2GL(mode: DrawMode) c.GLenum {
    return switch (mode) {
        .Points => c.GL_POINTS,
        .LineStrip => c.GL_LINE_STRIP,
        .LineLoop => c.GL_LINE_LOOP,
        .Lines => c.GL_LINES,
        .LineStripAdjacency => c.GL_LINES_ADJACENCY,
        .LinesAdjacency => c.GL_LINES_ADJACENCY,
        .TriangleStrip => c.GL_TRIANGLE_STRIP,
        .TriangleFan => c.GL_TRIANGLE_FAN,
        .Triangles => c.GL_TRIANGLES,
        .TriangleStripAdjacency => c.GL_TRIANGLE_STRIP_ADJACENCY,
        .TrianglesAdjacency => c.GL_TRIANGLES_ADJACENCY,
        .Patches => c.GL_PATCHES,
    };
}

pub fn drawElements(mode: DrawMode, count: usize, comptime T: type, indices: ?*const anyopaque) void {
    c.glDrawElements(drawMod2GL(mode), @intCast(count), type2GL(T), indices);
}

pub const TextureType = enum {
    Texture1D,
    Texture2D,
    Texture3D,
    Array1D,
    Array2D,
    Rectangle,
    CubeMap,
    ArrayCubeMap,
    TextureBuffer,
    Multisample2D,
    ArrayMultisample2D,
};

inline fn texType2GL(@"type": TextureType) c.GLenum {
    return switch (@"type") {
        .Texture1D => c.GL_TEXTURE_1D,
        .Texture2D => c.GL_TEXTURE_2D,
        .Texture3D => c.GL_TEXTURE_3D,
        .Array1D => c.GL_TEXTURE_1D_ARRAY,
        .Array2D => c.GL_TEXTURE_2D_ARRAY,
        .Rectangle => c.GL_TEXTURE_RECTANGLE,
        .CubeMap => c.GL_TEXTURE_CUBE_MAP,
        .ArrayCubeMap => c.GL_TEXTURE_CUBE_MAP_ARRAY,
        .TextureBuffer => c.GL_TEXTURE_BUFFER,
        .Multisample2D => c.GL_TEXTURE_2D_MULTISAMPLE,
        .ArrayMultisample2D => c.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
    };
}

pub const TextureParameter = enum {
    DepthStencilMode,
    BaseLevel,
    CompareFunc,
    CompareMode,
    LodBias,
    MinFilter,
    MagFilter,
    MinLod,
    MaxLod,
    MaxLevel,
    SwizzleR,
    SwizzleG,
    SwizzleB,
    SwizzleA,
    SwizzleRGBA,
    WrapS,
    WrapT,
    //WrapR,
    BorderColor,
};

inline fn texParam2GL(param: TextureParameter) c.GLenum {
    return switch (param) {
        .DepthStencilMode => c.GL_DEPTH_STENCIL_TEXTURE_MODE,
        .BaseLevel => c.GL_TEXTURE_BASE_LEVEL,
        .CompareFunc => c.GL_TEXTURE_COMPARE_FUNC,
        .CompareMode => c.GL_TEXTURE_COMPARE_MODE,
        .LodBias => c.GL_TEXTURE_LOD_BIAS,
        .MinFilter => c.GL_TEXTURE_MIN_FILTER,
        .MagFilter => c.GL_TEXTURE_MAG_FILTER,
        .MinLod => c.GL_TEXTURE_MIN_LOD,
        .MaxLod => c.GL_TEXTURE_MAX_LOD,
        .MaxLevel => c.GL_TEXTURE_MAX_LEVEL,
        .SwizzleR => c.GL_TEXTURE_SWIZZLE_R,
        .SwizzleG => c.GL_TEXTURE_SWIZZLE_G,
        .SwizzleB => c.GL_TEXTURE_SWIZZLE_B,
        .SwizzleA => c.GL_TEXTURE_SWIZZLE_A,
        .SwizzleRGBA => c.GL_TEXTURE_SWIZZLE_RGBA,
        .WrapS => c.GL_TEXTURE_WRAP_S,
        .WrapT => c.GL_TEXTURE_WRAP_T,
        //.WrapR => c.GL_TEXTURE_WRAP_R,
        .BorderColor => c.GL_TEXTURE_BORDER_COLOR,
    };
}

fn canBeEnum(comptime T: type, value: anytype) bool {
    const vtinfo = @typeInfo(@TypeOf(value));
    const tinfo = @typeInfo(T);

    if (tinfo != .Enum or !(vtinfo == .Enum or vtinfo == .EnumLiteral))
        @compileError("Expected enum, got value: " ++ @typeName(@TypeOf(value)) ++ ", T: " ++ @typeName(T));

    return comptime std.meta.stringToEnum(T, @tagName(value)) != null;
}

pub const Filter = enum {
    Nearest,
    Linear,
    /// Only with TextureParameter.MinFilter
    NearestMipmapNearest,
    /// Only with TextureParameter.MinFilter
    LinearMipmapNearest,
    /// Only with TextureParameter.MinFilter
    NearestMipmapLinear,
    /// Only with TextureParameter.MinFilter
    LinearMipmapLinear,
};

inline fn filter2GL(filter: Filter) c.GLint {
    return switch (filter) {
        .Nearest => c.GL_NEAREST,
        .Linear => c.GL_LINEAR,
        .NearestMipmapNearest => c.GL_NEAREST_MIPMAP_NEAREST,
        .LinearMipmapNearest => c.GL_LINEAR_MIPMAP_NEAREST,
        .NearestMipmapLinear => c.GL_NEAREST_MIPMAP_LINEAR,
        .LinearMipmapLinear => c.GL_LINEAR_MIPMAP_LINEAR,
    };
}

pub const WrapMode = enum {
    ClampEdge,
    MirroredRepeat,
    Repeat,
};

inline fn wrapMode2GL(mode: WrapMode) c.GLint {
    return switch (mode) {
        .ClampEdge => c.GL_CLAMP_TO_EDGE,
        .MirroredRepeat => c.GL_MIRRORED_REPEAT,
        .Repeat => c.GL_REPEAT,
    };
}

pub const TextureFormat = enum {
    R8,
    R8_SNORM,
    R16,
    R16_SNORM,
    RG8,
    RG8_SNORM,
    RG16,
    RG16_SNORM,
    R3_G3_B2,
    RGB4,
    RGB5,
    RGB8,
    RGB8_SNORM,
    RGB10,
    RGB12,
    RGB16_SNORM,
    RGBA2,
    RGBA4,
    RGB5_A1,
    RGBA8,
    RGBA8_SNORM,
    RGB10_A2,
    RGB10_A2UI,
    RGBA12,
    RGBA16,
    SRGB8,
    SRGB8_ALPHA8,
    R16F,
    RG16F,
    RGB16F,
    RGBA16F,
    R32F,
    RG32F,
    RGB32F,
    RGBA32F,
    R11F_G11F_B10F,
    RGB9_E5,
    R8I,
    R8UI,
    R16I,
    R16UI,
    R32I,
    R32UI,
    RG8I,
    RG8UI,
    RG16I,
    RG16UI,
    RG32I,
    RG32UI,
    RGB8I,
    RGB8UI,
    RGB16I,
    RGB16UI,
    RGB32I,
    RGB32UI,
    RGBA8I,
    RGBA8UI,
    RGBA16I,
    RGBA16UI,
    RGBA32I,
    RGBA32UI,
};

inline fn texFormat2GL(fmt: TextureFormat) c.GLenum {
    return switch (fmt) {
        inline else => |tag| @field(c, "GL_" ++ @tagName(tag)),
    };
}

pub const TextureAccess = enum {
    ReadOnly,
    WriteOnly,
    ReadWrite,
};

inline fn texAccess2GL(access: TextureAccess) c.GLenum {
    return switch (access) {
        .ReadOnly => c.GL_READ_ONLY,
        .WriteOnly => c.GL_WRITE_ONLY,
        .ReadWrite => c.GL_READ_WRITE,
    };
}

pub const Texture = struct {
    id: u32,

    pub fn create(@"type": TextureType) Texture {
        var id: u32 = 0;
        c.glCreateTextures(texType2GL(@"type"), 1, @ptrCast(&id));
        return .{ .id = id };
    }
    pub fn destroy(self: *Texture) void {
        c.glDeleteTextures(1, @ptrCast(&self.id));
        self.* = undefined;
    }
    pub fn createArray(@"type": TextureType, size: usize, allocator: Allocator) Allocator.Error![]Texture {
        const arr = try allocator.alloc(TextureType, size);

        c.glCreateTextures(texType2GL(@"type"), @intCast(size), @ptrCast(arr.ptr));

        return arr;
    }
    pub fn destroyArray(self: *[]Texture, allocator: Allocator) []Texture {
        c.glDeleteTextures(@intCast(self.len), @ptrCast(self.ptr));
        allocator.free(self.*);
        self.* = undefined;
    }

    pub fn textureParami(self: Texture, param: TextureParameter, value: i32) !void {
        c.glTextureParameteri(@intCast(self.id), texParam2GL(param), @intCast(value));
    }
    pub fn textureParamFilter(self: Texture, param: TextureParameter, value: Filter) !void {
        c.glTextureParameteri(@intCast(self.id), texParam2GL(param), filter2GL(value));
    }
    pub fn textureParamWrap(self: Texture, param: TextureParameter, value: WrapMode) !void {
        c.glTextureParameteri(@intCast(self.id), texParam2GL(param), wrapMode2GL(value));
    }
    pub fn textureParamf(self: Texture, param: TextureParameter, value: f32) !void {
        c.glTextureParameterf(@intCast(self.id), texParam2GL(param), @floatCast(value));
    }
    pub fn storage(self: Texture, comptime dim: u32, levels: u32, format: TextureFormat, width: u32, height: u32, depth: u32) void {
        switch (dim) {
            inline 1 => c.glTextureStorage1D(
                @intCast(self.id),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
            ),
            inline 2 => c.glTextureStorage2D(
                @intCast(self.id),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
                @intCast(height),
            ),
            inline 3 => c.glTextureStorage3D(
                @intCast(self.id),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
                @intCast(height),
                @intCast(depth),
            ),
            inline else => @compileError("Cannot call glTextureStorage with " ++ dim ++ " dimensions"),
        }
    }
    pub fn bindImageTexture(self: Texture, unit: u32, level: u32, layered: bool, layer: u32, access: TextureAccess, format: TextureFormat) void {
        c.glBindImageTexture(
            @intCast(unit),
            @intCast(self.id),
            @intCast(level),
            @intFromBool(layered),
            @intCast(layer),
            texAccess2GL(access),
            texFormat2GL(format),
        );
    }
    pub fn bindUnit(self: Texture, unit: u32) void {
        c.glBindTextureUnit(@intCast(unit), @intCast(self.id));
    }
};

// check for gl struct sizes, avoid unwanted "undefined" behaviour
comptime {
    if (@sizeOf(VertexArray) != @sizeOf(u32)) @compileError("Size of VertexArray is not the same as the size of u32");
    if (@sizeOf(Buffer) != @sizeOf(u32)) @compileError("Size of Buffer is not the same as the size of u32");
    if (@sizeOf(Texture) != @sizeOf(u32)) @compileError("Size of Texture is not the same as the size of u32");
    if (@sizeOf(Shader) != @sizeOf(u32)) @compileError("Size of Shader is not the same as the size of u32");
    if (@sizeOf(ShaderProgram) != @sizeOf(u32)) @compileError("Size of ShaderProgram is not the same as the size of u32");
}
