const std = @import("std");
const utils = @import("utils");
const zlm = @import("zlm");
const zlmd = @import("zlm").SpecializeOn(f64);
pub const c = @cImport({
    @cInclude("GLAD/glad.h");
});

const Allocator = std.mem.Allocator;

pub const Vec2f = zlm.Vec2;
pub const Vec2d = zlmd.Vec2;
pub const Vec3f = zlm.Vec3;
pub const Vec3d = zlmd.Vec3;
pub const Vec4f = zlm.Vec4;
pub const Vec4d = zlmd.Vec4;

pub const Mat2f = zlm.Mat2;
pub const Mat2d = zlmd.Mat2;
pub const Mat3f = zlm.Mat3;
pub const Mat3d = zlmd.Mat3;
pub const Mat4f = zlm.Mat4;
pub const Mat4d = zlmd.Mat4;

pub const GladLoadProc = *const fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub const DebugProc = *const fn (source: DebugSource, kind: DebugType, id: u32, severity: DebugSeverity, message: []const u8, userData: ?*anyopaque) void;

var messageAllocator: ?Allocator = null;
var errMessage: ?[]const u8 = null;

pub const Version = struct {
    major: u32 = 1,
    minor: u32 = 0,

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

/// You can do try glad.checkError() to check for any
/// OpenGL errors
pub fn checkError() Error!void {
    return switch (errFromC(c.glGetError())) {
        Error.NoError => {},
        else => |e| e,
    };
}

/// if loader is null it will use the builtin glad loader
/// otherwise it will use the loader.
///
/// glfw.getProcAddress is recommended for the loader function.
pub fn init(loader: ?GladLoadProc) Error!Version {
    const status = if (loader != null) c.gladLoadGLLoader(loader) else c.gladLoadGL();
    if (status == 0)
        return errFromC(@bitCast(status));
    var ver = Version{};
    c.glGetIntegerv(c.GL_MAJOR_VERSION, @ptrCast(&ver.major));
    c.glGetIntegerv(c.GL_MINOR_VERSION, @ptrCast(&ver.minor));
    return ver;
}
/// deinitialize the library
pub fn deinit() void {
    clearError();
}

/// clears the error message.
pub fn clearError() void {
    if (errMessage) |_| {
        if (messageAllocator) |_| {
            messageAllocator.?.free(errMessage.?);
        }
    }
    messageAllocator = null;
    errMessage = null;
}

/// returns the error message
pub fn getErrorMessage() []const u8 {
    return errMessage orelse "";
}

/// sets the error message
pub fn setErrorMessage(allocator: Allocator, mess: []const u8) void {
    clearError();
    messageAllocator = allocator;
    errMessage = mess;
}

/// specifies the affine transformation of x and y
/// from normalized device coordinates to window coordinates.
///
/// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glViewport.xhtml
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

/// enable a capability of OpenGL
///
/// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glEnable.xhtml
pub fn enable(cap: Capability) void {
    c.glEnable(capability2GL(cap));
}
/// disable a capability of OpenGL
///
/// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDisable.xhtml
pub fn disable(cap: Capability) void {
    c.glDisable(capability2GL(cap));
}

pub const BlendFunc = enum {
    Zero,
    One,
    SrcColor,
    InvertSrcColor,
    DstColor,
    InvertDstColor,
    SrcAlpha,
    InvertSrcAlpha,
    DstAlpha,
    InvertDstAlpha,
    ConstantColor,
    InvertConstantColor,
    ConstantAlpha,
    InvertConstantAlpha,
    SrcAlphaSaturate,
    Src1Color,
    InvertSrc1Color,
    Src1Alpha,
    InvertSrc1Alpha,
};

inline fn blendFunc2GL(func: BlendFunc) c.GLenum {
    return switch (func) {
        .Zero => c.GL_ZERO,
        .One => c.GL_ONE,
        .SrcColor => c.GL_SRC_COLOR,
        .InvertSrcColor => c.GL_ONE_MINUS_SRC_COLOR,
        .DstColor => c.GL_DST_COLOR,
        .InvertDstColor => c.GL_ONE_MINUS_DST_COLOR,
        .SrcAlpha => c.GL_SRC_ALPHA,
        .InvertSrcAlpha => c.GL_ONE_MINUS_SRC_ALPHA,
        .DstAlpha => c.GL_DST_ALPHA,
        .InvertDstAlpha => c.GL_ONE_MINUS_DST_ALPHA,
        .ConstantColor => c.GL_CONSTANT_COLOR,
        .InvertConstantColor => c.GL_ONE_MINUS_CONSTANT_COLOR,
        .ConstantAlpha => c.GL_CONSTANT_ALPHA,
        .InvertConstantAlpha => c.GL_ONE_MINUS_CONSTANT_ALPHA,
        .SrcAlphaSaturate => c.GL_SRC_ALPHA_SATURATE,
        .Src1Color => c.GL_SRC1_COLOR,
        .InvertSrc1Color => c.GL_ONE_MINUS_SRC1_COLOR,
        .Src1Alpha => c.GL_SRC1_ALPHA,
        .InvertSrc1Alpha => c.GL_ONE_MINUS_SRC1_ALPHA,
    };
}

pub fn blendFunc(func: BlendFunc) void {
    c.glBlendFunc(blendFunc2GL(func));
}

pub fn cullFace(face: Face) void {
    c.glCullFace(face2GL(face));
}

pub const FrontFaceMode = enum {
    CW,
    CCW,
};

inline fn ffm2GL(face: FrontFaceMode) c.GLenum {
    return switch (face) {
        .CW => c.GL_CW,
        .CCW => c.GL_CCW,
    };
}

pub fn frontFace(face: FrontFaceMode) void {
    c.glFrontFace(ffm2GL(face));
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

    pub fn gen() VertexArray {
        var vao = VertexArray{};
        c.glGenVertexArrays(1, @ptrCast(&vao.id));
        return vao;
    }
    pub fn genSlice(allocator: Allocator, count: usize) Error![]VertexArray {
        const slice = try allocator.alloc(VertexArray, count);
        // yeah dangerous cast i know thanks
        c.glGenVertexArrays(count, @ptrCast(slice.ptr));
        return slice;
    }
    pub fn genArrays(comptime N: comptime_int) [N]Buffer {
        var arrs: [N]Buffer = undefined;
        c.glGenVertexArrays(N, @ptrCast(&arrs));
        return arrs;
    }

    pub fn create() VertexArray {
        var vao = VertexArray{};
        c.glCreateVertexArrays(1, @ptrCast(&vao.id));
        return vao;
    }
    pub fn createSlice(allocator: Allocator, count: usize) Error![]VertexArray {
        const slice = try allocator.alloc(VertexArray, count);
        // yeah dangerous cast i know thanks
        c.glCreateVertexArrays(count, @ptrCast(slice.ptr));
        return slice;
    }
    pub fn createArrays(comptime N: comptime_int) [N]Buffer {
        var arrs: [N]Buffer = undefined;
        c.glCreateVertexArrays(N, @ptrCast(&arrs));
        return arrs;
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

    pub fn gen() Buffer {
        var buf = Buffer{};
        c.glGenBuffers(1, @ptrCast(&buf.id));
        return buf;
    }
    pub fn genSlice(allocator: Allocator, count: usize) Error![]Buffer {
        const slice = try allocator.alloc(Buffer, count);
        // yeah dangerous cast i know thanks
        c.glGenBuffers(@intCast(count), @ptrCast(slice.ptr));
        return slice;
    }
    pub fn genBuffers(comptime N: comptime_int) [N]Buffer {
        var bufs: [N]Buffer = undefined;
        c.glGenBuffers(N, @ptrCast(&bufs));
        return bufs;
    }

    /// Creates a non-named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn create() Buffer {
        var buf = Buffer{};
        c.glCreateBuffers(1, @ptrCast(&buf.id));
        return buf;
    }
    /// Creates a non-named buffer object slice
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn createSlice(allocator: Allocator, count: usize) Error![]Buffer {
        const slice = try allocator.alloc(Buffer, count);
        // yeah dangerous cast i know thanks
        c.glCreateBuffers(@intCast(count), @ptrCast(slice.ptr));
        return slice;
    }
    /// Creates a non-named buffer object array
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn createBuffers(comptime N: comptime_int) [N]Buffer {
        var bufs: [N]Buffer = undefined;
        c.glCreateBuffers(N, @ptrCast(&bufs));
        return bufs;
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

    /// sets data for named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    pub fn data(self: Buffer, comptime T: type, dat: []const T, access: DataAccess) Error!void {
        c.glNamedBufferData(
            @intCast(self.id),
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat.ptr),
            dataAccedd2GL(access),
        );
        try checkError();
    }
    /// sets data for non-named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    pub fn dataTarget(target: BufferType, comptime T: type, dat: []const T, access: DataAccess) Error!void {
        c.glBufferData(
            bufferType2GL(target),
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat.ptr),
            dataAccedd2GL(access),
        );
        try checkError();
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
        defer allocator.free(content);
        return self.source(content);
    }
    pub fn source(self: *const Shader, src: [:0]const u8) *const Shader {
        // for some reasons the lengths arguments on this functions
        // doesn't work as intended. This is irritating.
        c.glShaderSource(
            @intCast(self.id),
            1,
            &src.ptr,
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

            c.glGetShaderInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
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
    pub fn unuseAny() void {
        c.glUseProgram(0);
    }
    pub fn ready(self: ShaderProgram, allocator: Allocator) Error!void {
        c.glValidateProgram(@intCast(self.id));
        var status: i32 = 0;
        c.glGetProgramiv(@intCast(self.id), c.GL_VALIDATE_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetProgramiv(@intCast(self.id), c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);
            errdefer allocator.free(log);

            c.glGetProgramInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
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
            errdefer allocator.free(log);

            c.glGetProgramInfoLog(@intCast(self.id), @intCast(length), null, @ptrCast(log.ptr));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
        }
        return self;
    }

    pub fn uniformLocation(self: ShaderProgram, name: [:0]const u8) u32 {
        return @bitCast(c.glGetUniformLocation(@intCast(self.id), @ptrCast(name.ptr)));
    }
    pub fn setUniformLoc(self: ShaderProgram, location: u32, value: anytype) void {
        _ = self;

        if (location == @as(u32, @truncate(-1))) return;

        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        switch (tinfo) {
            inline .Struct => {
                switch (T) {
                    TextureHandle => c.glUniformHandleui64ARB(@intCast(location), @intCast(value.id)),
                    Vec2f => c.glUniform2f(@intCast(location), value.x, value.y),
                    Vec2d => c.glUniform2d(@intCast(location), value.x, value.y),
                    Vec3f => c.glUniform3f(@intCast(location), value.x, value.y, value.z),
                    Vec3d => c.glUniform3d(@intCast(location), value.x, value.y, value.z),
                    Vec4f => c.glUniform4f(@intCast(location), value.x, value.y, value.z, value.w),
                    Vec4d => c.glUniform4d(@intCast(location), value.x, value.y, value.z, value.w),
                    Mat2f => c.glUniformMatrix2fv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
                    Mat2d => c.glUniformMatrix2dv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
                    Mat3f => c.glUniformMatrix3fv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
                    Mat3d => c.glUniformMatrix3dv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
                    Mat4f => c.glUniformMatrix4fv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
                    Mat4d => c.glUniformMatrix4dv(@intCast(location), 1, @intFromBool(false), @ptrCast(&value.fields)),
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

pub fn drawElements(mode: DrawMode, count: usize, comptime T: type, indices: usize) Error!void {
    c.glDrawElements(
        drawMod2GL(mode),
        @intCast(count),
        type2GL(T),
        @ptrFromInt(indices),
    );
    try checkError();
}

pub fn drawElementsInstanced(mode: DrawMode, count: usize, comptime T: type, indices: usize, instanceCount: u32) Error!void {
    c.glDrawElementsInstanced(
        drawMod2GL(mode),
        @intCast(count),
        type2GL(T),
        @ptrFromInt(indices),
        @intCast(instanceCount),
    );
    try checkError();
}

pub const DrawElementsIndirectCommand = struct {
    count: u32,
    instanceCount: u32,
    firstIndex: u32,
    baseVertex: i32,
    baseInstance: u32,
};

pub fn drawElementsIndirect(mode: DrawMode, comptime T: type, indirect: *const DrawElementsIndirectCommand) Error!void {
    c.glDrawElementsIndirect(
        drawMod2GL(mode),
        type2GL(T),
        @ptrCast(indirect),
    );
    try checkError();
}

pub fn drawArrays(mode: DrawMode, first: u32, count: u32) Error!void {
    c.glDrawArrays(drawMod2GL(mode), @intCast(first), @intCast(count));
    try checkError();
}

pub fn drawArraysInstanced(mode: DrawMode, first: u32, count: u32, instanceCount: u32) Error!void {
    c.glDrawArraysInstanced(
        drawMod2GL(mode),
        @intCast(first),
        @intCast(count),
        @intCast(instanceCount),
    );
    try checkError();
}

pub const DrawArraysIndirectCommand = struct {
    count: u32,
    instanceCount: u32,
    first: u32,
    baseInstance: u32,
};

pub fn drawArraysIndirect(mode: DrawMode, indirect: *const DrawArraysIndirectCommand) Error!void {
    c.glDrawArraysIndirect(
        drawMod2GL(mode),
        @ptrCast(indirect),
    );
    try checkError();
}

pub fn multiDrawArraysIndirect(mode: DrawMode, indirect: []const DrawArraysIndirectCommand) Error!void {
    c.glMultiDrawArraysIndirect(
        drawMod2GL(mode),
        @ptrCast(indirect),
        @intCast(indirect.len),
        0,
    );
    try checkError();
}

pub fn drawArraysInstancedBaseInstance(mode: DrawMode, first: u32, count: u32, instanceCount: u32, baseInstance: u32) Error!void {
    c.glDrawArraysInstancedBaseInstance(
        mode,
        first,
        count,
        instanceCount,
        baseInstance,
    );
    try checkError();
}

pub const Face = enum {
    Front,
    Back,
    FrontAndBack,
};

inline fn face2GL(mode: Face) c.GLenum {
    return switch (mode) {
        .Front => c.GL_FRONT,
        .Back => c.GL_BACK,
        .FrontAndBack => c.GL_FRONT_AND_BACK,
    };
}

pub const FaceMode = enum {
    Point,
    Line,
    Fill,
};

inline fn faceMode2GL(mode: FaceMode) c.GLenum {
    return switch (mode) {
        .Point => c.GL_POINT,
        .Line => c.GL_LINE,
        .Fill => c.GL_FILL,
    };
}

pub fn polygonMode(mode: FaceMode) void {
    c.glPolygonMode(c.GL_FRONT_AND_BACK, faceMode2GL(mode));
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

pub const CompareFunction = enum {
    LessEqual,
    GreaterEqual,
    Less,
    Greater,
    Equal,
    NotEqual,
    Always,
    Never,
};

inline fn compFn2GL(compfn: CompareFunction) c.GLenum {
    return switch (compfn) {
        .LessEqual => c.GL_LEQUAL,
        .GreaterEqual => c.GL_GEQUAL,
        .Less => c.GL_LESS,
        .Greater => c.GL_GREATER,
        .Equal => c.GL_EQUAL,
        .NotEqual => c.GL_NOTEQUAL,
        .Always => c.GL_ALWAYS,
        .Never => c.GL_NEVER,
    };
}

pub const CompareMode = enum {
    RefToTexture,
    None,
};

inline fn compMode2GL(mode: CompareMode) c.GLenum {
    return switch (mode) {
        .RefToTexture => c.GL_COMPARE_REF_TO_TEXTURE,
        .None => c.GL_NONE,
    };
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

pub const DepthStencilTextureMode = enum {
    DepthComponent,
    StencilIndex,
};

inline fn dstm2GL(mode: DepthStencilTextureMode) c.GLenum {
    return switch (mode) {
        .DepthComponent => c.GL_DEPTH_COMPONENT,
        .StencilIndex => c.GL_STENCIL_INDEX,
    };
}

pub const Swizzle = enum {
    Red,
    Green,
    Blue,
    Alpha,
    Zero,
    One,
};

inline fn swizzle2GL(swizzle: Swizzle) c.GLenum {
    return switch (swizzle) {
        .Red => c.GL_RED,
        .Green => c.GL_GREEN,
        .Blue => c.GL_BLUE,
        .Alpha => c.GL_ALPHA,
        .Zero => c.GL_ZERO,
        .One => c.GL_ONE,
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

pub const BaseTextureFormat = enum {
    RED,
    RG,
    RGB,
    RGBA,
};

inline fn btf2GL(fmt: BaseTextureFormat) c.GLenum {
    return switch (fmt) {
        .RED => c.GL_RED,
        .RG => c.GL_RG,
        .RGB => c.GL_RGB,
        .RGBA => c.GL_RGBA,
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

    pub fn gen() Texture {
        var id: u32 = 0;
        c.glGenTextures(1, @ptrCast(&id));
        return .{ .id = id };
    }
    pub fn genSlice(size: usize, allocator: Allocator) Allocator.Error![]Texture {
        const arr = try allocator.alloc(TextureType, size);
        c.glGenTextures(@intCast(size), @ptrCast(arr.ptr));
        return arr;
    }
    pub fn genTextures(comptime N: comptime_int) Allocator.Error![N]Texture {
        var texs: [N]Texture = undefined;
        c.glGenTextures(N, @ptrCast(&texs));
        return texs;
    }

    pub fn create() Texture {
        var id: u32 = 0;
        c.glCreateTextures(1, @ptrCast(&id));
        return .{ .id = id };
    }
    pub fn createSlice(size: usize, allocator: Allocator) Allocator.Error![]Texture {
        const arr = try allocator.alloc(TextureType, size);
        c.glCreateTextures(@intCast(size), @ptrCast(arr.ptr));
        return arr;
    }
    pub fn createTextures(comptime N: comptime_int) Allocator.Error![N]Texture {
        var texs: [N]Texture = undefined;
        c.glCreateTextures(N, @ptrCast(&texs));
        return texs;
    }

    pub fn destroy(self: *Texture) void {
        c.glDeleteTextures(1, @ptrCast(&self.id));
        self.* = undefined;
    }
    pub fn destroyArray(self: *[]Texture, allocator: Allocator) []Texture {
        c.glDeleteTextures(@intCast(self.len), @ptrCast(self.ptr));
        allocator.free(self.*);
        self.* = undefined;
    }

    pub fn bind(self: Texture, @"type": TextureType) void {
        c.glBindTexture(texType2GL(@"type"), @intCast(self.id));
    }

    pub fn unbindAny(@"type": TextureType) void {
        c.glBindTexture(texType2GL(@"type"), 0);
    }

    pub const ParamError = error{InvalidArgument};

    inline fn checkParams(param: TextureParameter, comptime params: []const TextureParameter) ParamError!void {
        inline for (params) |p| {
            if (param == p)
                return;
        }
        return ParamError.InvalidArgument;
    }

    fn textureParamEnum(self: Texture, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        if (tinfo != .Enum and tinfo != .EnumLiteral)
            @compileError("Only accepts enum and enum literals");

        try checkParams(param, &.{
            .DepthStencilMode,
            .CompareFunc,
            .CompareMode,
            .MinFilter,
            .MagFilter,
            .SwizzleR,
            .SwizzleG,
            .SwizzleB,
            .SwizzleA,
            .WrapS,
            .WrapT,
            //.WrapR,
        });

        switch (T) {
            inline DepthStencilTextureMode => {
                try checkParams(param, &.{.DepthStencilMode});
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), dstm2GL(value));
            },
            inline CompareFunction => {
                try checkParams(param, &.{.CompareFunc});
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), compFn2GL(value));
            },
            inline CompareMode => {
                try checkParams(param, &.{.CompareMode});
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), compMode2GL(value));
            },
            inline Filter => {
                try checkParams(param, &.{ .MinFilter, .MagFilter });
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), filter2GL(value));
            },
            inline Swizzle => {
                try checkParams(param, &.{ .SwizzleR, .SwizzleG, .SwizzleB, .SwizzleA });
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), swizzle2GL(value));
            },
            inline WrapMode => {
                try checkParams(param, &.{ .WrapS, .WrapT });
                c.glTextureParameteri(@intCast(self.id), texParam2GL(param), wrapMode2GL(value));
            },
            inline else => {
                switch (value) {
                    inline .DepthComponent, .StencilIndex => self.textureParamEnum(param, @as(DepthStencilTextureMode, value)),
                    inline .LessEqual, .GreaterEqual, .Less, .Greater, .Equal, .NotEqual, .Always, .Never => self.textureParamEnum(param, @as(CompareFunction, value)),
                    inline .RefToTexture, .None => self.textureParamEnum(param, @as(CompareMode, value)),
                    inline .Nearest, .Linear, .NearestMipmapNearest, .LinearMipmapNearest, .NearestMipmapLinear, .LinearMipmapLinear => self.textureParamEnum(param, @as(Filter, value)),
                    inline .Red, .Green, .Blue, .Alpha, .Zero, .One => self.textureParamEnum(param, @as(Swizzle, value)),
                    inline .ClampEdge, .MirroredRepeat, .Repeat => self.textureParamEnum(param, @as(WrapMode, value)),
                    inline else => return ParamError.InvalidArgument,
                }
            },
        }
    }

    inline fn textureParamInt(self: Texture, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        try checkParams(param, &.{
            .BaseLevel,
        });

        switch (tinfo) {
            inline .Int => |d| {
                const signedness = comptime d.signedness;
                const bits = comptime d.bits;

                switch (bits) {
                    inline 32 => {
                        if (signedness == .signed)
                            c.glTextureParameteri(@intCast(self.id), texParam2GL(param), value)
                        else
                            c.glTextureParameterIuiv(@intCast(self.id), texParam2GL(param), @ptrCast(&value));
                    },
                    inline else => @compileError(std.fmt.comptimePrint("invalid int bit length, got: {d} expected 32", .{bits})),
                }
            },
            else => @compileError("Only int type is accepted, got: " ++ @typeName(T)),
        }
    }

    inline fn textureParamFloat(self: Texture, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        try checkParams(param, &.{
            .LodBias,
            .MinLod,
            .MaxLod,
            .MaxLevel,
        });

        switch (tinfo) {
            inline .Float => |d| {
                const bits = comptime d.bits;

                switch (bits) {
                    inline 32 => {
                        c.glTextureParameterf(@intCast(self.id), texParam2GL(param), value);
                    },
                    inline else => @compileError(std.fmt.comptimePrint("invalid float bit length, got: {d} expected 32", .{bits})),
                }
            },
            else => @compileError("Only float type is accepted, got: " ++ @typeName(T)),
        }
    }

    pub fn textureParam(self: Texture, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        switch (tinfo) {
            inline .Enum, .EnumLiteral => try self.textureParamEnum(param, value),
            inline .Int => try self.textureParamInt(param, value),
            inline .Float => try self.textureParamFloat(param, value),
            inline .ComptimeFloat, .ComptimeInt => @compileError("Comptime values aren't accepted in textureParam"),
            else => @compileError("Invalid texture parameter type: " ++ @typeName(T)),
        }
    }

    fn texParamEnum(@"type": TextureType, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        if (tinfo != .Enum and tinfo != .EnumLiteral)
            @compileError("Only accepts enum and enum literals");

        try checkParams(param, &.{
            .DepthStencilMode,
            .CompareFunc,
            .CompareMode,
            .MinFilter,
            .MagFilter,
            .SwizzleR,
            .SwizzleG,
            .SwizzleB,
            .SwizzleA,
            .WrapS,
            .WrapT,
            //.WrapR,
        });

        switch (T) {
            inline DepthStencilTextureMode => {
                try checkParams(param, &.{.DepthStencilMode});
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), dstm2GL(value));
            },
            inline CompareFunction => {
                try checkParams(param, &.{.CompareFunc});
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), compFn2GL(value));
            },
            inline CompareMode => {
                try checkParams(param, &.{.CompareMode});
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), compMode2GL(value));
            },
            inline Filter => {
                try checkParams(param, &.{ .MinFilter, .MagFilter });
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), filter2GL(value));
            },
            inline Swizzle => {
                try checkParams(param, &.{ .SwizzleR, .SwizzleG, .SwizzleB, .SwizzleA });
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), swizzle2GL(value));
            },
            inline WrapMode => {
                try checkParams(param, &.{ .WrapS, .WrapT });
                c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), wrapMode2GL(value));
            },
            inline else => {
                switch (value) {
                    inline .DepthComponent, .StencilIndex => try texParamEnum(@"type", param, @as(DepthStencilTextureMode, value)),
                    inline .LessEqual, .GreaterEqual, .Less, .Greater, .Equal, .NotEqual, .Always, .Never => try texParamEnum(@"type", param, @as(CompareFunction, value)),
                    inline .RefToTexture, .None => try texParamEnum(@"type", param, @as(CompareMode, value)),
                    inline .Nearest, .Linear, .NearestMipmapNearest, .LinearMipmapNearest, .NearestMipmapLinear, .LinearMipmapLinear => try texParamEnum(@"type", param, @as(Filter, value)),
                    inline .Red, .Green, .Blue, .Alpha, .Zero, .One => try texParamEnum(@"type", param, @as(Swizzle, value)),
                    inline .ClampEdge, .MirroredRepeat, .Repeat => try texParamEnum(@"type", param, @as(WrapMode, value)),
                    inline else => return ParamError.InvalidArgument,
                }
            },
        }
    }

    inline fn texParamInt(@"type": TextureType, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        try checkParams(param, &.{
            .BaseLevel,
        });

        switch (tinfo) {
            inline .Int => |d| {
                const signedness = comptime d.signedness;
                const bits = comptime d.bits;

                switch (bits) {
                    inline 32 => {
                        if (signedness == .signed)
                            c.glTexParameteri(texType2GL(@"type"), texParam2GL(param), value)
                        else
                            c.glTexParameterIuiv(texType2GL(@"type"), texParam2GL(param), @ptrCast(&value));
                    },
                    inline else => @compileError(std.fmt.comptimePrint("invalid int bit length, got: {d} expected 32", .{bits})),
                }
            },
            else => @compileError("Only int type is accepted, got: " ++ @typeName(T)),
        }
    }

    inline fn texParamFloat(@"type": TextureType, param: TextureParameter, value: anytype) ParamError!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        try checkParams(param, &.{
            .LodBias,
            .MinLod,
            .MaxLod,
            .MaxLevel,
        });

        switch (tinfo) {
            inline .Float => |d| {
                const bits = comptime d.bits;

                switch (bits) {
                    inline 32 => {
                        c.glTexParameterf(texType2GL(@"type"), texParam2GL(param), value);
                    },
                    inline else => @compileError(std.fmt.comptimePrint("invalid float bit length, got: {d} expected 32", .{bits})),
                }
            },
            else => @compileError("Only float type is accepted, got: " ++ @typeName(T)),
        }
    }

    pub fn texParam(@"type": TextureType, param: TextureParameter, value: anytype) (ParamError || Error)!void {
        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        switch (tinfo) {
            inline .Enum, .EnumLiteral => try texParamEnum(@"type", param, value),
            inline .Int => try texParamInt(@"type", param, value),
            inline .Float => try texParamFloat(@"type", param, value),
            inline .ComptimeFloat, .ComptimeInt => @compileError("Comptime values aren't accepted to textureParam"),
            else => @compileError("Invalid texture parameter type: " ++ @typeName(T)),
        }
        try checkError();
    }

    pub fn textureStorage(self: Texture, comptime dim: u2, levels: u32, format: TextureFormat, width: u32, height: u32, depth: u32) void {
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
            inline else => @compileError(std.fmt.comptimePrint("Cannot call glTextureStorage with {d} dimensions", .{dim})),
        }
    }
    pub fn texStorage(@"type": TextureType, comptime dim: u2, levels: u32, format: TextureFormat, width: u32, height: u32, depth: u32) void {
        switch (dim) {
            inline 1 => c.glTexStorage1D(
                texType2GL(@"type"),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
            ),
            inline 2 => c.glTexStorage2D(
                texType2GL(@"type"),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
                @intCast(height),
            ),
            inline 3 => c.glTexStorage3D(
                texType2GL(@"type"),
                @intCast(levels),
                texFormat2GL(format),
                @intCast(width),
                @intCast(height),
                @intCast(depth),
            ),
            inline else => @compileError(std.fmt.comptimePrint("Cannot call glTexStorage with {d} dimensions", .{dim})),
        }
    }

    pub fn texImage(comptime dim: u2, @"type": TextureType, level: u32, format: BaseTextureFormat, width: u32, height: u32, depth: u32, comptime T: type, data: []const T) Error!void {
        switch (dim) {
            inline 1 => c.glTexImage1D(
                texType2GL(@"type"),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                0,
                btf2GL(format),
                type2GL(T),
                utils.opaqueCast(*anyopaque, data.ptr),
            ),
            inline 2 => c.glTexImage2D(
                texType2GL(@"type"),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                @intCast(height),
                0,
                btf2GL(format),
                type2GL(T),
                utils.opaqueCast(*anyopaque, data.ptr),
            ),
            inline 3 => c.glTexImage2D(
                texType2GL(@"type"),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                @intCast(height),
                @intCast(depth),
                0,
                btf2GL(format),
                type2GL(T),
                utils.opaqueCast(*anyopaque, data.ptr),
            ),
            inline else => @compileError(std.fmt.comptimePrint("Cannot call glTexImage with {d} dimensions", .{dim})),
        }
        try checkError();
    }

    pub fn generateMipmap(@"type": TextureType) void {
        c.glGenerateMipmap(texType2GL(@"type"));
    }

    pub fn active(slot: u32) void {
        c.glActiveTexture(c.GL_TEXTURE0 + @as(c_int, @intCast(slot)));
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

pub const TextureHandle = struct {
    id: u64,

    pub fn init(tex: Texture) TextureHandle {
        return .{
            .id = @intCast(c.glGetTextureHandleARB(@intCast(tex.id))),
        };
    }

    pub fn makeResident(self: TextureHandle) void {
        c.glMakeTextureHandleResidentARB(@intCast(self.id));
    }
    pub fn makeNonResident(self: TextureHandle) void {
        c.glMakeTextureHandleNonResidentARB(@intCast(self.id));
    }
};

inline fn checkSize(comptime T: type, comptime bitSize: comptime_int) void {
    if (@bitSizeOf(T) != bitSize)
        @compileError(std.fmt.comptimePrint(
            "{s} is not {d} bits wide but {d}.",
            .{
                @typeName(T),
                bitSize,
                @bitSizeOf(T),
            },
        ));
}

// check for gl struct sizes, avoid unwanted "undefined" behaviour
comptime {
    checkSize(VertexArray, 32);
    checkSize(Buffer, 32);
    checkSize(Shader, 32);
    checkSize(ShaderProgram, 32);
    checkSize(Texture, 32);
    checkSize(TextureHandle, 64);
}
