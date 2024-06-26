//! Wraps the GLAD library to the zig conventions

const std = @import("std");
const zlm = @import("zlm");
const zlmd = zlm.SpecializeOn(f64);
const zlmi = zlm.SpecializeOn(i32);
const zlmu = zlm.SpecializeOn(u32);
const c = @cImport({
    @cInclude("glad/glad.h");
});

pub usingnamespace if (@import("build_options").exposeC) struct {
    pub const capi = c;
} else struct {};

const Allocator = std.mem.Allocator;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// helper functions

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// math types

pub const Vec2f = zlm.Vec2;
pub const Vec3f = zlm.Vec3;
pub const Vec4f = zlm.Vec4;
pub const Mat2f = zlm.Mat2;
pub const Mat3f = zlm.Mat3;
pub const Mat4f = zlm.Mat4;

pub const Vec3d = zlmd.Vec3;
pub const Vec2d = zlmd.Vec2;
pub const Vec4d = zlmd.Vec4;
pub const Mat2d = zlmd.Mat2;
pub const Mat3d = zlmd.Mat3;
pub const Mat4d = zlmd.Mat4;

pub const Vec3i = zlmi.Vec3;
pub const Vec2i = zlmi.Vec2;
pub const Vec4i = zlmi.Vec4;
pub const Mat2i = zlmi.Mat2;
pub const Mat3i = zlmi.Mat3;
pub const Mat4i = zlmi.Mat4;

pub const Vec3u = zlmu.Vec3;
pub const Vec2u = zlmu.Vec2;
pub const Vec4u = zlmu.Vec4;
pub const Mat2u = zlmu.Mat2;
pub const Mat3u = zlmu.Mat3;
pub const Mat4u = zlmu.Mat4;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// enums

pub const Extension = @import("GLAD_extensions.zig").Extension;
pub const Capability = enum(c.GLenum) {
    Blend = c.GL_BLEND,
    ColorLogicOp = c.GL_COLOR_LOGIC_OP,
    CullFace = c.GL_CULL_FACE,
    DebugOutput = c.GL_DEBUG_OUTPUT,
    DebugOutputSync = c.GL_DEBUG_OUTPUT_SYNCHRONOUS,
    DepthClamp = c.GL_DEPTH_CLAMP,
    DepthTest = c.GL_DEPTH_TEST,
    Dither = c.GL_DITHER,
    FramebufferSRGB = c.GL_FRAMEBUFFER_SRGB,
    LineSmooth = c.GL_LINE_SMOOTH,
    Multisample = c.GL_MULTISAMPLE,
    PolygonOffsetFill = c.GL_POLYGON_OFFSET_FILL,
    PolygonOffsetLine = c.GL_POLYGON_OFFSET_LINE,
    PolygonSmooth = c.GL_POLYGON_SMOOTH,
    PrimitiveRestart = c.GL_PRIMITIVE_RESTART,
    PrimitiveRestartFixedIndex = c.GL_PRIMITIVE_RESTART_FIXED_INDEX,
    RasterizerDiscard = c.GL_RASTERIZER_DISCARD,
    SampleAlphaToCoverage = c.GL_SAMPLE_ALPHA_TO_COVERAGE,
    SampleAlphaToOne = c.GL_SAMPLE_ALPHA_TO_ONE,
    SampleCoverage = c.GL_SAMPLE_COVERAGE,
    SampleShading = c.GL_SAMPLE_SHADING,
    SampleMask = c.GL_SAMPLE_MASK,
    ScissorTest = c.GL_SCISSOR_TEST,
    StencilTest = c.GL_STENCIL_TEST,
    TextureCubeMapSeamless = c.GL_TEXTURE_CUBE_MAP_SEAMLESS,
    ProgramPointSize = c.GL_PROGRAM_POINT_SIZE,
};
pub const BlendFunc = enum(c.GLenum) {
    Zero = c.GL_ZERO,
    One = c.GL_ONE,
    SrcColor = c.GL_SRC_COLOR,
    InvertSrcColor = c.GL_ONE_MINUS_SRC_COLOR,
    DstColor = c.GL_DST_COLOR,
    InvertDstColor = c.GL_ONE_MINUS_DST_COLOR,
    SrcAlpha = c.GL_SRC_ALPHA,
    InvertSrcAlpha = c.GL_ONE_MINUS_SRC_ALPHA,
    DstAlpha = c.GL_DST_ALPHA,
    InvertDstAlpha = c.GL_ONE_MINUS_DST_ALPHA,
    ConstantColor = c.GL_CONSTANT_COLOR,
    InvertConstantColor = c.GL_ONE_MINUS_CONSTANT_COLOR,
    ConstantAlpha = c.GL_CONSTANT_ALPHA,
    InvertConstantAlpha = c.GL_ONE_MINUS_CONSTANT_ALPHA,
    SrcAlphaSaturate = c.GL_SRC_ALPHA_SATURATE,
    Src1Color = c.GL_SRC1_COLOR,
    InvertSrc1Color = c.GL_ONE_MINUS_SRC1_COLOR,
    Src1Alpha = c.GL_SRC1_ALPHA,
    InvertSrc1Alpha = c.GL_ONE_MINUS_SRC1_ALPHA,
};
pub const FrontFaceMode = enum(c.GLenum) {
    CW = c.GL_CW,
    CCW = c.GL_CCW,
};
pub const DebugSource = enum(c.GLenum) {
    Api = c.GL_DEBUG_SOURCE_API,
    WindowSystem = c.GL_DEBUG_SOURCE_WINDOW_SYSTEM,
    ShaderCompiler = c.GL_DEBUG_SOURCE_SHADER_COMPILER,
    ThirdParty = c.GL_DEBUG_SOURCE_THIRD_PARTY,
    Application = c.GL_DEBUG_SOURCE_APPLICATION,
    Other = c.GL_DEBUG_TYPE_OTHER,
};
pub const DebugType = enum(c.GLenum) {
    Error = c.GL_DEBUG_TYPE_ERROR,
    DeprecatedBehavior = c.GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR,
    UndefinedBehavior = c.GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR,
    Portability = c.GL_DEBUG_TYPE_PORTABILITY,
    Performance = c.GL_DEBUG_TYPE_PERFORMANCE,
    Marker = c.GL_DEBUG_TYPE_MARKER,
    PushGroup = c.GL_DEBUG_TYPE_PUSH_GROUP,
    PopGroup = c.GL_DEBUG_TYPE_POP_GROUP,
    Other = c.GL_DEBUG_TYPE_OTHER,
};
pub const DebugSeverity = enum(c.GLenum) {
    High = c.GL_DEBUG_SEVERITY_HIGH,
    Medium = c.GL_DEBUG_SEVERITY_MEDIUM,
    Low = c.GL_DEBUG_SEVERITY_LOW,
    Notification = c.GL_DEBUG_SEVERITY_NOTIFICATION,
};
pub const BufferType = enum(c.GLenum) {
    Array = c.GL_ARRAY_BUFFER,
    AtomicCounter = c.GL_ATOMIC_COUNTER_BUFFER,
    CopyRead = c.GL_COPY_READ_BUFFER,
    CopyWrite = c.GL_COPY_WRITE_BUFFER,
    DispatchIndirect = c.GL_DISPATCH_INDIRECT_BUFFER,
    DrawIndirect = c.GL_DRAW_INDIRECT_BUFFER,
    ElementArray = c.GL_ELEMENT_ARRAY_BUFFER,
    PixelPack = c.GL_PIXEL_PACK_BUFFER,
    PixelUnpack = c.GL_PIXEL_UNPACK_BUFFER,
    Query = c.GL_QUERY_BUFFER,
    ShaderStorage = c.GL_SHADER_STORAGE_BUFFER,
    Texture = c.GL_TEXTURE_BUFFER,
    TransformFeedback = c.GL_TRANSFORM_FEEDBACK_BUFFER,
    Uniform = c.GL_UNIFORM_BUFFER,
};
pub const DataAccess = enum(c.GLenum) {
    StreamDraw = c.GL_STREAM_DRAW,
    StreamRead = c.GL_STREAM_READ,
    StreamCopy = c.GL_STREAM_COPY,
    StaticDraw = c.GL_STATIC_DRAW,
    StaticRead = c.GL_STATIC_READ,
    StaticCopy = c.GL_STATIC_COPY,
    DynamicDraw = c.GL_DYNAMIC_DRAW,
    DynamicRead = c.GL_DYNAMIC_READ,
    DynamicCopy = c.GL_DYNAMIC_COPY,
};
pub const ShaderType = enum(c.GLenum) {
    Compute = c.GL_COMPUTE_SHADER,
    Vertex = c.GL_VERTEX_SHADER,
    TessControl = c.GL_TESS_CONTROL_SHADER,
    TessEval = c.GL_TESS_EVALUATION_SHADER,
    Geometry = c.GL_GEOMETRY_SHADER,
    Fragment = c.GL_FRAGMENT_SHADER,
};
pub const BarrierBits = packed struct {
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
    _: bool = false,
    shaderImageAccess: bool = false,
    command: bool = false,
    pixelBuffer: bool = false,
    textureUpdate: bool = false,
    bufferUpdate: bool = false,
    framebuffer: bool = false,
    transformFeedback: bool = false,
    atomicCounter: bool = false,
    shaderStorage: bool = false,
    clientMappedBuffer: bool = false,
    queryBuffer: bool = false,
};
pub const DrawMode = enum(c.GLenum) {
    Points = c.GL_POINTS,
    LineStrip = c.GL_LINE_STRIP,
    LineLoop = c.GL_LINE_LOOP,
    Lines = c.GL_LINES,
    LineStripAdjacency = c.GL_LINE_STRIP_ADJACENCY,
    LinesAdjacency = c.GL_LINES_ADJACENCY,
    TriangleStrip = c.GL_TRIANGLE_STRIP,
    TriangleFan = c.GL_TRIANGLE_FAN,
    Triangles = c.GL_TRIANGLES,
    TriangleStripAdjacency = c.GL_TRIANGLE_STRIP_ADJACENCY,
    TrianglesAdjacency = c.GL_TRIANGLES_ADJACENCY,
    Patches = c.GL_PATCHES,
};
pub const Face = enum(c.GLenum) {
    Front = c.GL_FRONT,
    Back = c.GL_BACK,
    FrontAndBack = c.GL_FRONT_AND_BACK,
};
pub const FaceMode = enum(c.GLenum) {
    Point = c.GL_POINT,
    Line = c.GL_LINE,
    Fill = c.GL_FILL,
};
pub const TextureType = enum(c.GLenum) {
    Texture1D = c.GL_TEXTURE_1D,
    Texture2D = c.GL_TEXTURE_2D,
    Texture3D = c.GL_TEXTURE_3D,
    Array1D = c.GL_TEXTURE_1D_ARRAY,
    Array2D = c.GL_TEXTURE_2D_ARRAY,
    Rectangle = c.GL_TEXTURE_RECTANGLE,
    CubeMap = c.GL_TEXTURE_CUBE_MAP,
    ArrayCubeMap = c.GL_TEXTURE_CUBE_MAP_ARRAY,
    TextureBuffer = c.GL_TEXTURE_BUFFER,
    Multisample2D = c.GL_TEXTURE_2D_MULTISAMPLE,
    ArrayMultisample2D = c.GL_TEXTURE_2D_MULTISAMPLE_ARRAY,
};
pub const TextureParameter = enum(c.GLenum) {
    DepthStencilMode = c.GL_DEPTH_STENCIL_TEXTURE_MODE,
    BaseLevel = c.GL_TEXTURE_BASE_LEVEL,
    CompareFunc = c.GL_TEXTURE_COMPARE_FUNC,
    CompareMode = c.GL_TEXTURE_COMPARE_MODE,
    LodBias = c.GL_TEXTURE_LOD_BIAS,
    MinFilter = c.GL_TEXTURE_MIN_FILTER,
    MagFilter = c.GL_TEXTURE_MAG_FILTER,
    MinLod = c.GL_TEXTURE_MIN_LOD,
    MaxLod = c.GL_TEXTURE_MAX_LOD,
    MaxLevel = c.GL_TEXTURE_MAX_LEVEL,
    SwizzleR = c.GL_TEXTURE_SWIZZLE_R,
    SwizzleG = c.GL_TEXTURE_SWIZZLE_G,
    SwizzleB = c.GL_TEXTURE_SWIZZLE_B,
    SwizzleA = c.GL_TEXTURE_SWIZZLE_A,
    SwizzleRGBA = c.GL_TEXTURE_SWIZZLE_RGBA,
    WrapS = c.GL_TEXTURE_WRAP_S,
    WrapT = c.GL_TEXTURE_WRAP_T,
    BorderColor = c.GL_TEXTURE_BORDER_COLOR,
};
pub const CompareFunction = enum(c.GLenum) {
    LessEqual = c.GL_LEQUAL,
    GreaterEqual = c.GL_GEQUAL,
    Less = c.GL_LESS,
    Greater = c.GL_GREATER,
    Equal = c.GL_EQUAL,
    NotEqual = c.GL_NOTEQUAL,
    Always = c.GL_ALWAYS,
    Never = c.GL_NEVER,
};
pub const CompareMode = enum(c.GLenum) {
    RefToTexture = c.GL_COMPARE_REF_TO_TEXTURE,
    None = c.GL_NONE,
};
pub const Filter = enum(c.GLenum) {
    Nearest = c.GL_NEAREST,
    Linear = c.GL_LINEAR,
    /// Only with TextureParameter.MinFilter
    NearestMipmapNearest = c.GL_NEAREST_MIPMAP_NEAREST,
    /// Only with TextureParameter.MinFilter
    LinearMipmapNearest = c.GL_LINEAR_MIPMAP_NEAREST,
    /// Only with TextureParameter.MinFilter
    NearestMipmapLinear = c.GL_NEAREST_MIPMAP_LINEAR,
    /// Only with TextureParameter.MinFilter
    LinearMipmapLinear = c.GL_LINEAR_MIPMAP_LINEAR,
};
pub const WrapMode = enum(c.GLenum) {
    ClampEdge = c.GL_CLAMP_TO_EDGE,
    MirroredRepeat = c.GL_MIRRORED_REPEAT,
    Repeat = c.GL_REPEAT,
};
pub const DepthStencilTextureMode = enum(c.GLenum) {
    DepthComponent = c.GL_DEPTH_COMPONENT,
    StencilIndex = c.GL_STENCIL_INDEX,
};
pub const Swizzle = enum(c.GLenum) {
    Red = c.GL_RED,
    Green = c.GL_GREEN,
    Blue = c.GL_BLUE,
    Alpha = c.GL_ALPHA,
    Zero = c.GL_ZERO,
    One = c.GL_ONE,
};
pub const TextureFormat = enum(c.GLenum) {
    R8 = c.GL_R8,
    R8_SNORM = c.GL_R8_SNORM,
    R16 = c.GL_R16,
    R16_SNORM = c.GL_R16_SNORM,
    RG8 = c.GL_RG8,
    RG8_SNORM = c.GL_RG8_SNORM,
    RG16 = c.GL_RG16,
    RG16_SNORM = c.GL_RG16_SNORM,
    R3_G3_B2 = c.GL_R3_G3_B2,
    RGB4 = c.GL_RGB4,
    RGB5 = c.GL_RGB5,
    RGB8 = c.GL_RGB8,
    RGB8_SNORM = c.GL_RGB8_SNORM,
    RGB10 = c.GL_RGB10,
    RGB12 = c.GL_RGB12,
    RGB16_SNORM = c.GL_RGB16_SNORM,
    RGBA2 = c.GL_RGBA2,
    RGBA4 = c.GL_RGBA4,
    RGB5_A1 = c.GL_RGB5_A1,
    RGBA8 = c.GL_RGBA8,
    RGBA8_SNORM = c.GL_RGBA8_SNORM,
    RGB10_A2 = c.GL_RGB10_A2,
    RGB10_A2UI = c.GL_RGB10_A2UI,
    RGBA12 = c.GL_RGBA12,
    RGBA16 = c.GL_RGBA16,
    SRGB8 = c.GL_SRGB8,
    SRGB8_ALPHA8 = c.GL_SRGB8_ALPHA8,
    R16F = c.GL_R16F,
    RG16F = c.GL_RG16F,
    RGB16F = c.GL_RGB16F,
    RGBA16F = c.GL_RGBA16F,
    R32F = c.GL_R32F,
    RG32F = c.GL_RG32F,
    RGB32F = c.GL_RGB32F,
    RGBA32F = c.GL_RGBA32F,
    R11F_G11F_B10F = c.GL_R11F_G11F_B10F,
    RGB9_E5 = c.GL_RGB9_E5,
    R8I = c.GL_R8I,
    R8UI = c.GL_R8UI,
    R16I = c.GL_R16I,
    R16UI = c.GL_R16UI,
    R32I = c.GL_R32I,
    R32UI = c.GL_R32UI,
    RG8I = c.GL_RG8I,
    RG8UI = c.GL_RG8UI,
    RG16I = c.GL_RG16I,
    RG16UI = c.GL_RG16UI,
    RG32I = c.GL_RG32I,
    RG32UI = c.GL_RG32UI,
    RGB8I = c.GL_RGB8I,
    RGB8UI = c.GL_RGB8UI,
    RGB16I = c.GL_RGB16I,
    RGB16UI = c.GL_RGB16UI,
    RGB32I = c.GL_RGB32I,
    RGB32UI = c.GL_RGB32UI,
    RGBA8I = c.GL_RGBA8I,
    RGBA8UI = c.GL_RGBA8UI,
    RGBA16I = c.GL_RGBA16I,
    RGBA16UI = c.GL_RGBA16UI,
    RGBA32I = c.GL_RGBA32I,
    RGBA32UI = c.GL_RGBA32UI,
};
pub const BaseTextureFormat = enum(c.GLenum) {
    RED = c.GL_RED,
    RG = c.GL_RG,
    RGB = c.GL_RGB,
    RGBA = c.GL_RGBA,
};
pub const TextureAccess = enum(c.GLenum) {
    ReadOnly = c.GL_READ_ONLY,
    WriteOnly = c.GL_WRITE_ONLY,
    ReadWrite = c.GL_READ_ONLY,
};
pub const StringName = enum(c.GLenum) {
    Vendor = c.GL_VENDOR,
    Renderer = c.GL_RENDERER,
    Version = c.GL_VERSION,
    ShadingLanguageVersion = c.GL_SHADING_LANGUAGE_VERSION,
    Extensions = c.GL_EXTENSIONS,
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// side types

pub const GladLoadProc = *const fn ([*c]const u8) callconv(.C) ?*anyopaque;
pub const DebugProc = *const fn (source: DebugSource, kind: DebugType, errId: Error, severity: DebugSeverity, message: []const u8, userData: ?*anyopaque) void;

pub const ClearBits = packed struct {
    _padding0: u8 = 0,
    depth: bool = false,
    _padding1: u1 = 0,
    stencil: bool = false,
    _padding2: u3 = 0,
    color: bool = false,
    /// Pad to 32 bits
    _padding3: u17 = 0,
};

pub const DrawElementsIndirectCommand = struct {
    count: u32,
    instanceCount: u32,
    firstIndex: u32,
    baseVertex: u32,
    baseInstance: u32,
};

pub const DrawArraysIndirectCommand = struct {
    count: u32,
    instanceCount: u32,
    first: u32,
    baseInstance: u32,
};

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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// main functions

var messageAllocator: ?Allocator = null;
var errMessage: ?[]const u8 = null;

pub inline fn hasExtension(comptime ext: Extension) bool {
    return @hasDecl(c, "GLAD_GL" ++ @tagName(ext)) and
        @field(c, "GLAD_GL" ++ @tagName(ext)) != 0;
}

/// **Return**: How many extensions there is.
pub fn getExtensions(extensions: ?[]const []const u8) usize {
    var nExt: c.GLint = undefined;
    c.glGetIntegerv(c.GL_NUM_EXTENSIONS, &nExt);
    if (extensions) |exts| {
        var i: c.GLint = 0;
        while (i < nExt) : (i += 1) {
            if (i >= exts.len) break;
            exts[i] = std.mem.span(c.glGetStringi(c.GL_EXTENSIONS, i));
        }
    }
    return @as(u32, @bitCast(nExt));
}

/// You can do try glad.checkError() to check for any
/// OpenGL errors
pub inline fn checkError() Error!void {
    return switch (errFromC(c.glGetError())) {
        Error.NoError => {},
        else => |e| e,
    };
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

pub fn frontFace(face: FrontFaceMode) void {
    c.glFrontFace(@bitCast(@intFromEnum(face)));
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
            const zSource: DebugSource = @enumFromInt(source);
            const zKind: DebugType = @enumFromInt(@"type");
            const zId = errFromC(id);
            const zSev: DebugSeverity = @enumFromInt(severity);
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

pub fn clearColor(red: f32, green: f32, blue: f32, alpha: f32) void {
    c.glClearColor(red, green, blue, alpha);
}

pub fn clear(mask: ClearBits) void {
    c.glClear(@bitCast(mask));
}

pub fn clearRGBA(color: FColor, mask: ClearBits) void {
    clearColor(color.r, color.g, color.b, color.a);
    clear(mask);
}

pub fn polygonMode(mode: FaceMode) void {
    c.glPolygonMode(c.GL_FRONT_AND_BACK, @bitCast(@intFromEnum(mode)));
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

/// enable a capability of OpenGL
///
/// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glEnable.xhtml
pub fn enable(cap: Capability) void {
    c.glEnable(@bitCast(@intFromEnum(cap)));
}

/// disable a capability of OpenGL
///
/// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDisable.xhtml
pub fn disable(cap: Capability) void {
    c.glDisable(@bitCast(@intFromEnum(cap)));
}

pub fn blendFunc(func: BlendFunc) void {
    c.glBlendFunc(@bitCast(@intFromEnum(func)));
}

pub fn cullFace(face: Face) void {
    c.glCullFace(@bitCast(@intFromEnum(face)));
}

pub fn getString(name: StringName) ?[]const u8 {
    const str = c.glGetString(@bitCast(@intFromEnum(name)));
    return if (str != null) std.mem.span(str) else null;
}

pub fn getStringI(name: StringName, index: u32) ?[]const u8 {
    const str = c.glGetStringi(@bitCast(@intFromEnum(name)), @bitCast(index));
    return if (str != null) std.mem.span(str) else null;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// draw functions

pub fn drawArrays(mode: DrawMode, first: u32, count: u32) Error!void {
    c.glDrawArrays(@bitCast(@intFromEnum(mode)), @intCast(first), @intCast(count));
    try checkError();
}

pub fn multiDrawArrays(mode: DrawMode, firsts: []const u32, counts: []const u32) Error!void {
    if (firsts.len != counts.len) return Error.InvalidValue;
    c.glMultiDrawArrays(
        @bitCast(@intFromEnum(mode)),
        @ptrCast(firsts),
        @ptrCast(counts),
        firsts.len,
    );
    try checkError();
}

pub fn drawArraysInstanced(mode: DrawMode, first: u32, count: u32, instanceCount: u32) Error!void {
    c.glDrawArraysInstanced(
        @bitCast(@intFromEnum(mode)),
        @intCast(first),
        @intCast(count),
        @intCast(instanceCount),
    );
    try checkError();
}

pub fn drawArraysIndirect(mode: DrawMode, indirect: ?*const DrawArraysIndirectCommand) Error!void {
    c.glDrawArraysIndirect(
        @bitCast(@intFromEnum(mode)),
        @ptrCast(indirect),
    );
    try checkError();
}

pub fn multiDrawArraysIndirect(mode: DrawMode, indirect: ?[]const DrawArraysIndirectCommand) Error!void {
    c.glMultiDrawArraysIndirect(
        @bitCast(@intFromEnum(mode)),
        if (indirect) @ptrCast(indirect.?) else null,
        if (indirect) @intCast(indirect.?.len) else 0,
        0,
    );
    try checkError();
}

pub fn drawArraysInstancedBaseInstance(mode: DrawMode, first: u32, count: u32, instanceCount: u32, baseInstance: u32) Error!void {
    c.glDrawArraysInstancedBaseInstance(
        @bitCast(@intFromEnum(mode)),
        @intCast(first),
        @intCast(count),
        @intCast(instanceCount),
        @intCast(baseInstance),
    );
    try checkError();
}

pub fn drawElements(mode: DrawMode, count: u32, comptime T: type, indices: usize) Error!void {
    c.glDrawElements(
        @bitCast(@intFromEnum(mode)),
        @intCast(count),
        type2GL(T),
        @ptrFromInt(indices),
    );
    try checkError();
}

/// works like drawElements() but with indices as a slice. Specific to this API
pub fn drawElementsSlice(mode: DrawMode, comptime T: type, indices: []const T) Error!void {
    c.glDrawElements(
        @bitCast(@intFromEnum(mode)),
        @intCast(indices.len),
        type2GL(T),
        @ptrCast(indices),
    );
    try checkError();
}

/// works like drawElements() but with indices as an array. Specific to this API
pub fn drawElementsArray(mode: DrawMode, comptime T: type, comptime N: comptime_int, indices: *const [N]T) Error!void {
    c.glDrawElements(
        @bitCast(@intFromEnum(mode)),
        N,
        type2GL(T),
        @ptrCast(indices),
    );
    try checkError();
}

pub fn multiDrawElements(mode: DrawMode, counts: []const u32, comptime T: type, indices: ?[]const usize) Error!void {
    if (indices and counts.len != indices.?.len) return Error.InvalidValue;
    c.glMultiDrawElements(
        @bitCast(@intFromEnum(mode)),
        @ptrCast(counts),
        type2GL(T),
        @ptrCast(indices),
        @intCast(counts.len),
    );
    try checkError();
}

pub fn drawElementsInstanced(mode: DrawMode, count: usize, comptime T: type, indices: usize, instanceCount: u32) Error!void {
    c.glDrawElementsInstanced(
        @bitCast(@intFromEnum(mode)),
        @intCast(count),
        type2GL(T),
        @ptrFromInt(indices),
        @intCast(instanceCount),
    );
    try checkError();
}

/// works like drawElementsInstanced() but with indices as a slice. Specific to this API
pub fn drawElementsInstancedSlice(mode: DrawMode, comptime T: type, indices: []const T, instanceCount: u32) Error!void {
    c.glDrawElementsInstanced(
        @bitCast(@intFromEnum(mode)),
        @intCast(indices.len),
        type2GL(T),
        @ptrCast(indices),
        @intCast(instanceCount),
    );
    try checkError();
}

/// works like drawElementsInstanced() but with indices as an array. Specific to this API
pub fn drawElementsInstancedArray(mode: DrawMode, comptime T: type, comptime N: comptime_int, indices: *const [N]T, instanceCount: u32) Error!void {
    c.glDrawElementsInstanced(
        @bitCast(@intFromEnum(mode)),
        N,
        type2GL(T),
        @ptrCast(indices),
        @intCast(instanceCount),
    );
    try checkError();
}

pub fn drawElementsIndirect(mode: DrawMode, comptime T: type, indirect: ?*const DrawElementsIndirectCommand) Error!void {
    c.glDrawElementsIndirect(
        @bitCast(@intFromEnum(mode)),
        type2GL(T),
        @ptrCast(indirect),
    );
    try checkError();
}

pub fn multiDrawElementsIndirect(mode: DrawMode, comptime T: type, indirect: ?[]const DrawElementsIndirectCommand) Error!void {
    c.glMultiDrawElementsIndirect(
        @bitCast(@intFromEnum(mode)),
        type2GL(T),
        @ptrCast(indirect),
        if (indirect) |ind| @intCast(ind.len) else 0,
        0,
    );
    try checkError();
}

pub fn drawElementsInstancedBaseInstance(mode: DrawMode, count: u32, comptime T: type, indices: usize, instanceCount: u32, baseInstance: 32) Error!void {
    c.glDrawElementsInstancedBaseInstance(
        @bitCast(@intFromEnum(mode)),
        @intCast(count),
        type2GL(T),
        @ptrFromInt(indices),
        @intCast(instanceCount),
        @intCast(baseInstance),
    );
    try checkError();
}

/// works like drawElementsInstancedBaseInstance() but with indices as an array. Specific to this API
pub fn drawElementsInstancedBaseInstanceSlice(mode: DrawMode, comptime T: type, indices: []const T, instanceCount: u32, baseInstance: 32) Error!void {
    c.glDrawElementsInstancedBaseInstance(
        @bitCast(@intFromEnum(mode)),
        @intCast(indices.len),
        type2GL(T),
        @ptrCast(indices),
        @intCast(instanceCount),
        @intCast(baseInstance),
    );
    try checkError();
}

/// works like drawElementsInstancedBaseInstance() but with indices as an array. Specific to this API
pub fn drawElementsInstancedBaseInstanceArray(mode: DrawMode, comptime T: type, comptime N: comptime_int, indices: *const [N]T, instanceCount: u32, baseInstance: 32) Error!void {
    c.glDrawElementsInstancedBaseInstance(
        @bitCast(@intFromEnum(mode)),
        N,
        type2GL(T),
        @ptrCast(indices),
        @intCast(instanceCount),
        @intCast(baseInstance),
    );
    try checkError();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// main types

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

pub const VertexArray = struct {
    id: c.GLuint = 0,

    pub fn gen() VertexArray {
        var id: c.GLuint = undefined;
        c.glGenVertexArrays(1, &id);
        return .{ .id = id };
    }
    pub fn genSlice(allocator: Allocator, count: usize) Error![]VertexArray {
        const slice = try allocator.alloc(VertexArray, count);
        // yeah dangerous cast i know thanks
        c.glGenVertexArrays(count, @ptrCast(slice));
        return slice;
    }
    pub fn genArray(comptime N: comptime_int) [N]Buffer {
        var arrs: [N]Buffer = undefined;
        c.glGenVertexArrays(N, @ptrCast(&arrs));
        return arrs;
    }

    pub fn create() VertexArray {
        var id: c.GLuint = undefined;
        c.glCreateVertexArrays(1, &id);
        return .{ .id = id };
    }
    pub fn createSlice(allocator: Allocator, count: usize) Error![]VertexArray {
        const slice = try allocator.alloc(VertexArray, count);
        // yeah dangerous cast i know thanks
        c.glCreateVertexArrays(count, @ptrCast(slice));
        return slice;
    }
    pub fn createArray(comptime N: comptime_int) [N]Buffer {
        var arrs: [N]Buffer = undefined;
        c.glCreateVertexArrays(N, @ptrCast(&arrs));
        return arrs;
    }

    pub fn destroy(self: *VertexArray) void {
        c.glDeleteVertexArrays(1, &self.id);
        self.* = undefined;
    }
    pub fn destroySlice(allocator: Allocator, arr: *[]VertexArray) void {
        c.glDeleteVertexArrays(@intCast(arr.len), @ptrCast(arr));
        allocator.free(arr.*);
        arr.* = undefined;
    }
    pub fn destroyArray(comptime N: comptime_int, arrays: *[N]VertexArray) void {
        c.glDeleteVertexArrays(N, @ptrCast(arrays));
        @memset(arrays, undefined);
    }

    pub fn bind(self: VertexArray) void {
        c.glBindVertexArray(self.id);
    }
    pub fn unbindAny() void {
        c.glBindVertexArray(0);
    }

    pub fn enableAttrib(self: VertexArray, location: u32) void {
        c.glEnableVertexArrayAttrib(self.id, @intCast(location));
    }
    pub fn disableAttrib(self: VertexArray, location: u32) void {
        c.glDisableVertexArrayAttrib(self.id, @intCast(location));
    }

    /// will converts ints to floats, use vertexAttribI instead if you wanna use ints
    pub fn vertexAttrib(location: u32, size: u32, comptime T: type, normalized: bool, stride: usize, offset: usize) void {
        if (T != f64) {
            c.glVertexAttribPointer(
                location,
                @bitCast(size),
                type2GL(T),
                @intFromBool(normalized),
                @intCast(stride),
                @ptrFromInt(offset),
            );
        } else {
            c.glVertexAttribLPointer(
                location,
                @bitCast(size),
                type2GL(T),
                @intCast(stride),
                @ptrFromInt(offset),
            );
        }
    }
    /// only for ints
    pub fn vertexAttribI(location: u32, size: u32, comptime T: type, stride: usize, offset: usize) void {
        c.glVertexAttribIPointer(
            location,
            @bitCast(size),
            type2GL(T),
            @intCast(stride),
            @ptrFromInt(offset),
        );
    }

    pub fn vertexAttribDivisor(location: u32, divisor: u32) Error!void {
        c.glVertexAttribDivisor(@intCast(location), @intCast(divisor));
        try checkError();
    }
};

pub const Buffer = struct {
    id: c.GLuint = 0,

    pub fn gen() Buffer {
        var id: c.GLuint = undefined;
        c.glGenBuffers(1, &id);
        return .{ .id = id };
    }
    pub fn genSlice(allocator: Allocator, count: usize) Error![]Buffer {
        const slice = try allocator.alloc(Buffer, count);
        // yeah dangerous cast i know thanks
        c.glGenBuffers(@intCast(count), @ptrCast(slice));
        return slice;
    }
    pub fn genArray(comptime N: comptime_int) [N]Buffer {
        var bufs: [N]Buffer = undefined;
        c.glGenBuffers(N, @ptrCast(&bufs));
        return bufs;
    }

    /// Creates a non-named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn create() Buffer {
        var id: c.GLuint = undefined;
        c.glCreateBuffers(1, &id);
        return .{ .id = id };
    }
    /// Creates a non-named buffer object slice
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn createSlice(allocator: Allocator, count: usize) Error![]Buffer {
        const slice = try allocator.alloc(Buffer, count);
        // yeah dangerous cast i know thanks
        c.glCreateBuffers(@intCast(count), @ptrCast(slice));
        return slice;
    }
    /// Creates a non-named buffer object array
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCreateBuffers.xhtml
    pub fn createArray(comptime N: comptime_int) [N]Buffer {
        var bufs: [N]Buffer = undefined;
        c.glCreateBuffers(N, @ptrCast(&bufs));
        return bufs;
    }

    pub fn destroy(self: *Buffer) void {
        c.glDeleteBuffers(1, &self.id);
        self.* = undefined;
    }
    pub fn destroySlice(allocator: Allocator, arr: *[]Buffer) void {
        c.glDeleteBuffers(@intCast(arr.len), @ptrCast(arr));
        allocator.free(arr.*);
        arr.* = undefined;
    }
    pub fn destroyArray(comptime N: comptime_int, buffers: *[N]Buffer) void {
        c.glDeleteBuffers(@intCast(N), @ptrCast(buffers));
        @memset(buffers, undefined);
    }

    pub fn bind(self: Buffer, btype: BufferType) void {
        c.glBindBuffer(@bitCast(@intFromEnum(btype)), self.id);
    }
    pub fn unbindAny(btype: BufferType) void {
        c.glBindBuffer(@bitCast(@intFromEnum(btype)), 0);
    }

    /// sets data for named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    pub fn data(self: Buffer, comptime T: type, dat: []const T, access: DataAccess) Error!void {
        c.glNamedBufferData(
            self.id,
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat),
            @bitCast(@intFromEnum(access)),
        );
        try checkError();
    }
    pub fn subdata(self: Buffer, offset: usize, comptime T: type, dat: []const T) Error!void {
        c.glNamedBufferSubData(
            self.id,
            @intCast(offset),
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat),
        );
        try checkError();
    }
    /// sets data for non-named buffer object
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    pub fn dataTarget(target: BufferType, comptime T: type, dat: []const T, access: DataAccess) Error!void {
        c.glBufferData(
            @bitCast(@intFromEnum(target)),
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat),
            @bitCast(@intFromEnum(access)),
        );
        try checkError();
    }
    pub fn subdataTarget(target: BufferType, offset: usize, comptime T: type, dat: []const T) Error!void {
        c.glBufferSubData(
            @bitCast(@intFromEnum(target)),
            @intCast(offset * @sizeOf(T)),
            @intCast(dat.len * @sizeOf(T)),
            @ptrCast(dat),
        );
        try checkError();
    }
};

pub const Shader = struct {
    id: c.GLuint = 0,

    pub fn create(@"type": ShaderType) Shader {
        return .{
            .id = c.glCreateShader(@intFromEnum(@"type")),
        };
    }
    pub fn destroy(self: *Shader) void {
        c.glDeleteShader(self.id);
        self.* = undefined;
    }

    // Error type was too long
    pub fn source(self: *const Shader, src: [:0]const u8) *const Shader {
        // for some reasons the lengths arguments on this functions
        // doesn't work as intended. This is irritating.
        c.glShaderSource(
            self.id,
            1,
            &src.ptr,
            null,
        );
        return self;
    }
    pub fn compile(self: *const Shader, allocator: Allocator) Error!*const Shader {
        c.glCompileShader(self.id);
        var status: u32 = 0;
        c.glGetShaderiv(self.id, c.GL_COMPILE_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetShaderiv(self.id, c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);

            c.glGetShaderInfoLog(self.id, @intCast(length), null, @ptrCast(log));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
        }
        return self;
    }
};

pub const ShaderProgram = struct {
    id: c.GLuint = 0,

    pub fn create() ShaderProgram {
        return .{
            .id = c.glCreateProgram(),
        };
    }
    pub fn destroy(self: *ShaderProgram) void {
        if (self.id != 0)
            c.glDeleteProgram(self.id);
        self.* = undefined;
    }

    pub fn useProgram(self: ShaderProgram) void {
        c.glUseProgram(self.id);
    }
    pub fn unuseAny() void {
        c.glUseProgram(0);
    }
    pub fn ready(self: ShaderProgram, allocator: Allocator) Error!void {
        c.glValidateProgram(self.id);
        var status: i32 = 0;
        c.glGetProgramiv(self.id, c.GL_VALIDATE_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetProgramiv(self.id, c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);
            errdefer allocator.free(log);

            c.glGetProgramInfoLog(self.id, @intCast(length), null, @ptrCast(log));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
        }
    }

    pub fn attachShader(self: *const ShaderProgram, shader: Shader) *const ShaderProgram {
        c.glAttachShader(self.id, @intCast(shader.id));
        return self;
    }
    pub fn linkProgram(self: *const ShaderProgram, allocator: Allocator) Error!*const ShaderProgram {
        c.glLinkProgram(self.id);
        var status: u32 = 0;
        c.glGetProgramiv(self.id, c.GL_LINK_STATUS, @ptrCast(&status));
        if (status == c.GL_FALSE) {
            var length: usize = 0;
            c.glGetProgramiv(self.id, c.GL_INFO_LOG_LENGTH, @ptrCast(&length));

            const log = try allocator.alloc(u8, length);

            c.glGetProgramInfoLog(self.id, @intCast(length), null, @ptrCast(log));

            setErrorMessage(allocator, log);

            return errFromC(@intCast(status));
        }
        return self;
    }

    /// returns the location for a uniform name.
    ///
    /// returns:
    ///
    ///     - null if `name`:
    ///         - does not correspond to an active uniform variable in the program.
    ///         - starts with the reserved prefix "gl_".
    ///         - is associated with an atomic counter or a named uniform block.
    ///     - a non-null value on success.
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGetUniformLocation.xhtml for more infos.
    pub fn uniformLocation(self: ShaderProgram, name: [:0]const u8) ?u32 {
        const loc = c.glGetUniformLocation(self.id, @ptrCast(name));
        return if (loc == -1) null else @intCast(loc);
    }

    inline fn SelectArrayFunctionName(comptime T: type) []const u8 {
        comptime {
            const tinfo = @typeInfo(T);
            return switch (tinfo) {
                inline .Struct => switch (T) {
                    inline TextureHandle => "glUniformHandleui64vARB",
                    inline Vec2f => "glUniform2fv",
                    inline Vec3f => "glUniform3fv",
                    inline Vec4f => "glUniform4fv",
                    inline Mat2f => "glUniformMatrix2fv",
                    inline Mat3f => "glUniformMatrix3fv",
                    inline Mat4f => "glUniformMatrix4fv",
                    inline Vec2d => "glUniform2dv",
                    inline Vec3d => "glUniform3dv",
                    inline Vec4d => "glUniform4dv",
                    inline Mat2d => "glUniformMatrix2dv",
                    inline Mat3d => "glUniformMatrix3dv",
                    inline Mat4d => "glUniformMatrix4dv",
                    inline Vec2i => "glUniform2iv",
                    inline Vec3i => "glUniform3iv",
                    inline Vec4i => "glUniform4iv",
                    inline else => @compileError("Unsupported uniform array type: " ++ @typeName(T) ++ " (" ++ @tagName(tinfo) ++ ")"),
                },
                inline .Int => |d2| switch (d2.bits) {
                    inline 32 => if (d2.signedness == .signed) "glUniform1iv" else "glUniform1uiv",
                    inline else => @compileError(std.fmt.comptimePrint("Unsupported {d} bits uniform float type, available is 32 bits only", .{d2.bits})),
                },
                inline .Float => |d2| switch (d2.bits) {
                    inline 32 => "glUniform1fv",
                    inline else => @compileError(std.fmt.comptimePrint("Unsupported {d} bits uniform float type, available is 32 bits only", .{d2.bits})),
                },
                inline else => @compileError("Unsupported uniform array type: " ++ @typeName(T) ++ " (" ++ @tagName(tinfo) ++ ")"),
            };
        }
    }

    /// sets a uniform at the given location with the given value.
    ///
    /// errors:
    ///
    ///     - Error.InvalidOperation if:
    ///         - the size of the uniform variable declared in the shader does not match the size indicated by the setUniform command.
    ///         - one of the signed or unsigned integer variants of this function is used to load a uniform variable of type:
    ///             - float
    ///             - vec2
    ///             - vec3
    ///             - vec4
    ///           or an array of these
    ///         - one of the floating-point variants of this function is used to load a uniform variable of type:
    ///             - int
    ///             - ivec2
    ///             - ivec3
    ///             - ivec4
    ///             - unsigned int
    ///             - uvec2
    ///             - uvec3
    ///             - uvec4
    ///             or an array of these.
    ///         - one of the signed integer variants of this function is used to load a uniform variable of type:
    ///             - unsigned int
    ///             - uvec2
    ///             - uvec3
    ///             - uvec4
    ///             or an array of these.
    ///         - one of the unsigned integer variants of this function is used to load a uniform variable of type:
    ///             - int
    ///             - ivec2
    ///             - ivec3
    ///             - ivec4
    ///             or an array of these.
    ///         - location is an invalid uniform `location` for the current program objectand `location` is not equal to -1.
    ///
    /// see https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGetUniformLocation.xhtml for more infos.
    pub fn setUniformLoc(location: ?u32, value: anytype) Error!void {
        if (location == null) return;

        const T = @TypeOf(value);
        const tinfo = @typeInfo(T);

        switch (T) {
            // apparently by "length" they khronos meant "objectCount" for some reasons
            Mat2f, Mat2d, Mat3f, Mat3d, Mat4f, Mat4d => @field(c, SelectArrayFunctionName(T))(@intCast(location.?), 1, @intFromBool(false), @ptrCast(@alignCast(&value))),
            else => switch (tinfo) {
                inline .Struct, .Int, .Float => try setUniformLoc(location, [1]T{value}),
                inline .Array => |d| @field(c, SelectArrayFunctionName(d.child))(@intCast(location.?), d.len, @ptrCast(@alignCast(&value))),
                inline .Pointer => |d| {
                    switch (d.size) {
                        .One => try setUniformLoc(location.?, value.*),
                        .Slice => @field(c, SelectArrayFunctionName(d.child))(@intCast(location.?), @intCast(value.len), @ptrCast(@alignCast(value))),
                        else => @compileError("Pointers passed to ShaderProgram.setUniformLoc() must be pointer-to-one or slice, got " ++ @tagName(d.size)),
                    }
                },
                inline else => @compileError("Unsuported unform type: " ++ @typeName(T) ++ "(" ++ @tagName(tinfo) ++ ")"),
            },
        }
        try checkError();
    }
    // setUniformLoc but accepts a string name instead of a location
    pub fn setUniform(self: ShaderProgram, name: [:0]const u8, value: anytype) Error!void {
        try setUniformLoc(self.uniformLocation(name), value);
    }

    pub fn dispatchCompute(x: u32, y: u32, z: u32) void {
        c.glDispatchCompute(@intCast(x), @intCast(y), @intCast(z));
    }
    pub fn memoryBarrier(barrier: BarrierBits) void {
        c.glMemoryBarrier(@bitCast(@intFromEnum(barrier)));
    }
};

pub const Texture = struct {
    id: c.GLuint,

    pub fn gen() Texture {
        var id: c.GLuint = 0;
        c.glGenTextures(1, &id);
        return .{ .id = id };
    }
    pub fn genSlice(size: usize, allocator: Allocator) Allocator.Error![]Texture {
        const arr = try allocator.alloc(TextureType, size);
        c.glGenTextures(@intCast(size), @ptrCast(arr));
        return arr;
    }
    pub fn genArray(comptime N: comptime_int) Allocator.Error![N]Texture {
        var texs: [N]Texture = undefined;
        c.glGenTextures(N, @ptrCast(&texs));
        return texs;
    }

    pub fn create() Texture {
        var id: c.GLuint = 0;
        c.glCreateTextures(1, &id);
        return .{ .id = id };
    }
    pub fn createSlice(size: usize, allocator: Allocator) Allocator.Error![]Texture {
        const arr = try allocator.alloc(TextureType, size);
        c.glCreateTextures(@intCast(size), @ptrCast(arr));
        return arr;
    }
    pub fn createArray(comptime N: comptime_int) [N]Texture {
        var texs: [N]Texture = undefined;
        c.glCreateTextures(N, @ptrCast(&texs));
        return texs;
    }

    pub fn destroy(self: *Texture) void {
        c.glDeleteTextures(1, &self.id);
        self.* = undefined;
    }
    pub fn destroyArray(comptime N: comptime_int, textures: *[N]Texture) void {
        c.glDeleteTextures(N, @ptrCast(textures));
        @memset(textures, undefined);
    }
    pub fn destroySlice(allocator: Allocator, textures: *[]Texture) void {
        c.glDeleteTextures(@intCast(textures.len), @ptrCast(textures));
        allocator.free(textures.*);
        textures.* = undefined;
    }

    pub fn bind(self: Texture, @"type": TextureType) void {
        c.glBindTexture(@bitCast(@intFromEnum(@"type")), self.id);
    }

    pub fn unbindAny(@"type": TextureType) void {
        c.glBindTexture(@bitCast(@intFromEnum(@"type")), 0);
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
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline CompareFunction => {
                try checkParams(param, &.{.CompareFunc});
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline CompareMode => {
                try checkParams(param, &.{.CompareMode});
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline Filter => {
                try checkParams(param, &.{ .MinFilter, .MagFilter });
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline Swizzle => {
                try checkParams(param, &.{ .SwizzleR, .SwizzleG, .SwizzleB, .SwizzleA });
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline WrapMode => {
                try checkParams(param, &.{ .WrapS, .WrapT });
                c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
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
                            c.glTextureParameteri(self.id, @bitCast(@intFromEnum(param)), value)
                        else
                            c.glTextureParameterIuiv(self.id, @bitCast(@intFromEnum(param)), @ptrCast(&value));
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
                        c.glTextureParameterf(self.id, @bitCast(@intFromEnum(param)), value);
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
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline CompareFunction => {
                try checkParams(param, &.{.CompareFunc});
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline CompareMode => {
                try checkParams(param, &.{.CompareMode});
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline Filter => {
                try checkParams(param, &.{ .MinFilter, .MagFilter });
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline Swizzle => {
                try checkParams(param, &.{ .SwizzleR, .SwizzleG, .SwizzleB, .SwizzleA });
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
            },
            inline WrapMode => {
                try checkParams(param, &.{ .WrapS, .WrapT });
                c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @bitCast(@intFromEnum(value)));
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
                            c.glTexParameteri(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), value)
                        else
                            c.glTexParameterIuiv(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), @ptrCast(&value));
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
                        c.glTexParameterf(@bitCast(@intFromEnum(@"type")), @bitCast(@intFromEnum(param)), value);
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
                self.id,
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
                @intCast(width),
            ),
            inline 2 => c.glTextureStorage2D(
                self.id,
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
                @intCast(width),
                @intCast(height),
            ),
            inline 3 => c.glTextureStorage3D(
                self.id,
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
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
                @bitCast(@intFromEnum(@"type")),
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
                @intCast(width),
            ),
            inline 2 => c.glTexStorage2D(
                @bitCast(@intFromEnum(@"type")),
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
                @intCast(width),
                @intCast(height),
            ),
            inline 3 => c.glTexStorage3D(
                @bitCast(@intFromEnum(@"type")),
                @intCast(levels),
                @bitCast(@intFromEnum(format)),
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
                @bitCast(@intFromEnum(@"type")),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                0,
                @bitCast(@intFromEnum(format)),
                type2GL(T),
                @ptrCast(@alignCast(data)),
            ),
            inline 2 => c.glTexImage2D(
                @bitCast(@intFromEnum(@"type")),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                @intCast(height),
                0,
                @bitCast(@intFromEnum(format)),
                type2GL(T),
                @ptrCast(@alignCast(data)),
            ),
            inline 3 => c.glTexImage2D(
                @bitCast(@intFromEnum(@"type")),
                @intCast(level),
                c.GL_RGBA,
                @intCast(width),
                @intCast(height),
                @intCast(depth),
                0,
                @bitCast(@intFromEnum(format)),
                type2GL(T),
                @ptrCast(@alignCast(data)),
            ),
            inline else => @compileError(std.fmt.comptimePrint("Cannot call glTexImage with {d} dimensions", .{dim})),
        }
        try checkError();
    }

    pub fn generateMipmap(@"type": TextureType) void {
        c.glGenerateMipmap(@bitCast(@intFromEnum(@"type")));
    }

    pub fn active(slot: u32) void {
        c.glActiveTexture(c.GL_TEXTURE0 + @as(c_int, @intCast(slot)));
    }

    pub fn bindImageTexture(self: Texture, unit: u32, level: u32, layered: bool, layer: u32, access: TextureAccess, format: TextureFormat) void {
        c.glBindImageTexture(
            @intCast(unit),
            self.id,
            @intCast(level),
            @intFromBool(layered),
            @intCast(layer),
            @bitCast(@intFromEnum(access)),
            @bitCast(@intFromEnum(format)),
        );
    }
    pub fn bindUnit(self: Texture, unit: u32) void {
        c.glBindTextureUnit(@intCast(unit), self.id);
    }
};

pub const TextureHandle = struct {
    id: c.GLuint64,

    pub fn init(tex: Texture) TextureHandle {
        return .{
            .id = @intCast(c.glGetTextureHandleARB(tex.id)),
        };
    }

    pub fn makeResident(self: TextureHandle) void {
        c.glMakeTextureHandleResidentARB(self.id);
    }
    pub fn makeNonResident(self: TextureHandle) void {
        c.glMakeTextureHandleNonResidentARB(self.id);
    }
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// compile time checks for struct sizes, mainly to avoid unwanted weird behaviour

inline fn checkSize(comptime T: type, comptime bitSize: comptime_int) void {
    if (@bitSizeOf(T) != bitSize)
        @compileError(std.fmt.comptimePrint(
            "Expected {s} to be {d} bits wide, but is {d} wide.",
            .{
                @typeName(T),
                bitSize,
                @bitSizeOf(T),
            },
        ));
}

comptime {
    std.testing.refAllDeclsRecursive(@This());
    checkSize(c_int, 32);
    checkSize(c_longlong, 64);
    checkSize(ClearBits, 32);
    checkSize(VertexArray, 32);
    checkSize(Buffer, 32);
    checkSize(Shader, 32);
    checkSize(ShaderProgram, 32);
    checkSize(Texture, 32);
    checkSize(TextureHandle, 64);
}
