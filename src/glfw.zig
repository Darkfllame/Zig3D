const std = @import("std");
const utils = @import("utils");
pub const Key = @import("Key").Key;
const c = @cImport({
    @cDefine("__gl_h_", "");
    @cInclude("GLFW/glfw3.h");
});

extern var _glfw: extern struct {
    initialized: c_int,
    allocator: c.GLFWallocator,
};

pub fn strlen(s: [*c]const u8) usize {
    var ss = s;
    while (ss[1] != 0) ss += 1;
    return @intFromPtr(ss - @intFromPtr(s));
}

pub usingnamespace if (@import("build_options").exposeC) struct {
    pub const capi = c;
} else struct {};

pub const Error = error{
    NoError,
    NotInitialized,
    NoCurrentContext,
    InvalidEnum,
    InvalidValue,
    OutOfMemory,
    ApiUnavailable,
    VersionUnavailable,
    Platform,
    FormatUnavailable,
    NoWindowContext,
};

fn errFromC(code: c_int) Error {
    return switch (code) {
        c.GLFW_NOT_INITIALIZED => Error.NotInitialized,
        c.GLFW_NO_CURRENT_CONTEXT => Error.NoCurrentContext,
        c.GLFW_INVALID_ENUM => Error.InvalidEnum,
        c.GLFW_INVALID_VALUE => Error.InvalidValue,
        c.GLFW_OUT_OF_MEMORY => Error.OutOfMemory,
        c.GLFW_API_UNAVAILABLE => Error.ApiUnavailable,
        c.GLFW_VERSION_UNAVAILABLE => Error.VersionUnavailable,
        c.GLFW_PLATFORM_ERROR => Error.Platform,
        c.GLFW_FORMAT_UNAVAILABLE => Error.FormatUnavailable,
        c.GLFW_NO_WINDOW_CONTEXT => Error.NoWindowContext,
        else => Error.NoError,
    };
}

var errorMessage: ?[]const u8 = null;

fn getError(description: ?*[]const u8) Error {
    var desc: []u8 = undefined;
    const err = errFromC(c.glfwGetError(@ptrCast(&desc.ptr)));
    if (err != Error.NoError) {
        desc.len = strlen(desc.ptr);
        errorMessage = desc;
    } else {
        errorMessage = null;
        desc = "";
    }
    if (description) |d| d.* = desc;
    return err;
}
pub fn getErrorMessage() []const u8 {
    return errorMessage orelse "";
}

const Allocator = std.mem.Allocator;

pub const MousePosCallback = *const fn (window: *Window, x: f64, y: f64) anyerror!void;
pub const ButtonCallback = *const fn (window: *Window, button: u32, action: Key.Action, mods: Key.Mods) anyerror!void;
pub const KeyCallback = *const fn (window: *Window, key: Key, action: Key.Action, mods: Key.Mods) anyerror!void;
pub const CharCallback = *const fn (window: *Window, char: u32) anyerror!void;
pub const EnterCallback = *const fn (window: *Window, entered: bool) anyerror!void;
pub const ScrollCallback = *const fn (window: *Window, x: f64, y: f64) anyerror!void;
pub const DropCallback = *const fn (window: *Window, paths: []const []const u8) anyerror!void;
pub const MonitorCallback = *const fn (monitor: *Monitor, event: MonitorEvent) void;
pub const ErrorCallback = *const fn (errorCode: Error, description: []const u8) void;

pub const GlfwVersion = struct {
    major: u8 = 1,
    minor: u8 = 0,
    revision: u8 = 0,
};

pub fn getProcAddress(procname: [*c]const u8) callconv(.C) ?*anyopaque {
    return @ptrCast(@constCast(c.glfwGetProcAddress(procname)));
}

var errorCallback: ?ErrorCallback = null;

pub fn getErrorCallback() ?ErrorCallback {
    return errorCallback;
}
pub fn setErrorCallback(cb: ?ErrorCallback) void {
    const state = struct {
        var first: bool = true;

        pub fn inner(errorCode: c_int, description: [*c]const u8) callconv(.C) void {
            const len = strlen(description);
            if (errorCallback) |f| {
                f(@errorFromInt(errorCode), description[0..len]);
            }
        }
    };
    if (state.first) {
        c.glfwSetErrorCallback(&state.inner);
        state.first = false;
    }
    errorCallback = cb;
}

fn allocFn(size: usize, user: ?*anyopaque) callconv(.C) ?*anyopaque {
    const allocator: *const Allocator = @ptrCast(@alignCast(user));
    const base: *anyopaque = @ptrCast(@alignCast(allocator.alloc(u8, 8 + size) catch return null));
    const usizePtr: *usize = @ptrCast(@alignCast(base));
    usizePtr.* = size;
    return @ptrFromInt(@intFromPtr(base) + 8);
}
fn reallocFn(block: ?*anyopaque, nsize: usize, user: ?*anyopaque) callconv(.C) ?*anyopaque {
    const allocator: *const Allocator = @ptrCast(@alignCast(user));
    const manyPtr: [*]u8 = @ptrFromInt(@intFromPtr(block) - 8);
    const size = @as(*usize, @ptrCast(@alignCast(manyPtr))).*;
    const op: *anyopaque = @ptrCast(@alignCast(allocator.realloc(manyPtr[0 .. size + 8], if (nsize == 0) 0 else 8 + nsize) catch return null));
    @as(*usize, @ptrCast(@alignCast(op))).* = nsize;
    return @ptrFromInt(@intFromPtr(op) + 8);
}
fn deallocFn(block: ?*anyopaque, user: ?*anyopaque) callconv(.C) void {
    const allocator: *const Allocator = @ptrCast(@alignCast(user));
    const manyPtr: [*]u8 = @ptrFromInt(@intFromPtr(block) - 8);
    const size = @as(*usize, @ptrCast(@alignCast(manyPtr))).*;
    allocator.free(manyPtr[0 .. size + 8]);
}

pub fn initAllocator(allocator: ?*const Allocator) void {
    c.glfwInitAllocator(if (allocator) |alloc|
        if (alloc == &std.heap.c_allocator)
            null
        else
            &.{
                .allocate = &allocFn,
                .reallocate = &reallocFn,
                .deallocate = &deallocFn,
                .user = @as(*anyopaque, @constCast(@ptrCast(@alignCast(alloc)))),
            }
    else
        null);
}

pub fn init(errStr: ?*[]const u8) Error!void {
    const status = c.glfwInit();
    if (status != c.GLFW_TRUE) {
        return getError(errStr);
    }
}
pub fn terminate() void {
    c.glfwTerminate();
}

pub fn getVersion() GlfwVersion {
    return .{
        .major = c.GLFW_VERSION_MAJOR,
        .minor = c.GLFW_VERSION_MINOR,
        .revision = c.GLFW_VERSION_REVISION,
    };
}

var pollErr: ?anyerror = null;

pub fn pollEvents() anyerror!void {
    c.glfwPollEvents();
    if (pollErr) |err| {
        pollErr = null;
        return err;
    }
}

pub const DontCare: u32 = @truncate(-1);

pub const GlfwAPI = enum(u32) {
    OpenGL = @intCast(c.GLFW_OPENGL_API),
    OpenGLes = @intCast(c.GLFW_OPENGL_ES_API),
    NoApi = @intCast(c.GLFW_NO_API),
};

pub const CreationAPI = enum(u32) {
    Native = @intCast(c.GLFW_NATIVE_CONTEXT_API),
    EGL = @intCast(c.GLFW_EGL_CONTEXT_API),
    OSMesa = @intCast(c.GLFW_OSMESA_CONTEXT_API),
};

pub const ApiVersion = struct {
    major: u8 = 1,
    minor: u8 = 0,
};

pub const Robustness = enum(u32) {
    NoRobustness = @intCast(c.GLFW_NO_ROBUSTNESS),
    NoResetNotification = @intCast(c.GLFW_NO_RESET_NOTIFICATION),
    LoseContextOnReset = @intCast(c.GLFW_LOSE_CONTEXT_ON_RESET),
};

pub const ReleaseBehaviour = enum(u32) {
    Any = @intCast(c.GLFW_ANY_RELEASE_BEHAVIOR),
    Flush = @intCast(c.GLFW_RELEASE_BEHAVIOR_FLUSH),
    None = @intCast(c.GLFW_RELEASE_BEHAVIOR_NONE),
};

pub const OpenglProfile = enum(u32) {
    Any = @intCast(c.GLFW_OPENGL_ANY_PROFILE),
    Compat = @intCast(c.GLFW_OPENGL_COMPAT_PROFILE),
    Core = @intCast(c.GLFW_OPENGL_CORE_PROFILE),
};

pub const WindowHint = struct {
    vsync: bool = false,
    resizable: bool = true,
    visible: bool = true,
    decorated: bool = true,
    focused: bool = true,
    autoIconify: bool = true,
    floating: bool = false,
    maximized: bool = false,
    centerCursor: bool = true,
    transparentFramebuffer: bool = false,
    focusOnShow: bool = true,
    scaleToMonitor: bool = false,
    redBits: u32 = 8,
    greenBits: u32 = 8,
    blueBits: u32 = 8,
    alphaBits: u32 = 8,
    depthBits: u32 = 24,
    stencilBits: u32 = 8,
    accumRedBits: u32 = 0,
    accumGreenBits: u32 = 0,
    accumBlueBits: u32 = 0,
    accumAphaBits: u32 = 0,
    auxBuffers: u32 = 0,
    samples: u32 = 0,
    refreshRate: u32 = DontCare,
    stereo: bool = false,
    srgbCapable: bool = false,
    doubleBuffer: bool = true,
    clientApi: GlfwAPI = .OpenGL,
    creationApi: CreationAPI = .Native,
    version: ApiVersion = .{},
    robustness: Robustness = .NoRobustness,
    releaseBehaviour: ReleaseBehaviour = .Any,
    forwardCompat: bool = false,
    debug: bool = false,
    openglProfile: OpenglProfile = .Any,
    cocoaRetinaFramebuffer: bool = true,
    cocoaFrameName: [:0]const u8 = "",
    cocoaGraphicsSwitching: bool = false,
    x11ClassName: [:0]const u8 = "",
    x11InstanceName: [:0]const u8 = "",
};

inline fn windowHint(hint: WindowHint) void {
    const wHint = c.glfwWindowHint;
    const wHintS = c.glfwWindowHintString;
    wHint(c.GLFW_RESIZABLE, @intFromBool(hint.resizable));
    wHint(c.GLFW_VISIBLE, @intFromBool(hint.visible));
    wHint(c.GLFW_DECORATED, @intFromBool(hint.decorated));
    wHint(c.GLFW_FOCUSED, @intFromBool(hint.focused));
    wHint(c.GLFW_AUTO_ICONIFY, @intFromBool(hint.autoIconify));
    wHint(c.GLFW_FLOATING, @intFromBool(hint.floating));
    wHint(c.GLFW_MAXIMIZED, @intFromBool(hint.maximized));
    wHint(c.GLFW_CENTER_CURSOR, @intFromBool(hint.centerCursor));
    wHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, @intFromBool(hint.transparentFramebuffer));
    wHint(c.GLFW_FOCUS_ON_SHOW, @intFromBool(hint.focusOnShow));
    wHint(c.GLFW_SCALE_TO_MONITOR, @intFromBool(hint.scaleToMonitor));
    wHint(c.GLFW_RED_BITS, @bitCast(hint.redBits));
    wHint(c.GLFW_GREEN_BITS, @bitCast(hint.greenBits));
    wHint(c.GLFW_BLUE_BITS, @bitCast(hint.blueBits));
    wHint(c.GLFW_ALPHA_BITS, @bitCast(hint.alphaBits));
    wHint(c.GLFW_DEPTH_BITS, @bitCast(hint.depthBits));
    wHint(c.GLFW_STENCIL_BITS, @bitCast(hint.stencilBits));
    wHint(c.GLFW_ACCUM_RED_BITS, @bitCast(hint.accumRedBits));
    wHint(c.GLFW_ACCUM_GREEN_BITS, @bitCast(hint.accumGreenBits));
    wHint(c.GLFW_ACCUM_BLUE_BITS, @bitCast(hint.accumBlueBits));
    wHint(c.GLFW_ACCUM_ALPHA_BITS, @bitCast(hint.accumAphaBits));
    wHint(c.GLFW_AUX_BUFFERS, @bitCast(hint.auxBuffers));
    wHint(c.GLFW_SAMPLES, @bitCast(hint.samples));
    wHint(c.GLFW_REFRESH_RATE, @bitCast(hint.refreshRate));
    wHint(c.GLFW_STEREO, @intFromBool(hint.stereo));
    wHint(c.GLFW_SRGB_CAPABLE, @intFromBool(hint.srgbCapable));
    wHint(c.GLFW_DOUBLEBUFFER, @intFromBool(hint.doubleBuffer));
    wHint(c.GLFW_CLIENT_API, @bitCast(@intFromEnum(hint.clientApi)));
    wHint(c.GLFW_CONTEXT_CREATION_API, @bitCast(@intFromEnum(hint.creationApi)));
    wHint(c.GLFW_CONTEXT_VERSION_MAJOR, @intCast(hint.version.major));
    wHint(c.GLFW_CONTEXT_VERSION_MINOR, @intCast(hint.version.minor));
    wHint(c.GLFW_CONTEXT_ROBUSTNESS, @bitCast(@intFromEnum(hint.robustness)));
    wHint(c.GLFW_CONTEXT_RELEASE_BEHAVIOR, @bitCast(@intFromEnum(hint.releaseBehaviour)));
    wHint(c.GLFW_OPENGL_FORWARD_COMPAT, @intFromBool(hint.forwardCompat));
    wHint(c.GLFW_OPENGL_DEBUG_CONTEXT, @intFromBool(hint.debug));
    wHint(c.GLFW_OPENGL_PROFILE, @bitCast(@intFromEnum(hint.openglProfile)));
    wHint(c.GLFW_COCOA_RETINA_FRAMEBUFFER, @intFromBool(hint.cocoaRetinaFramebuffer));
    wHintS(c.GLFW_COCOA_FRAME_NAME, hint.cocoaFrameName.ptr);
    wHint(c.GLFW_COCOA_GRAPHICS_SWITCHING, @intFromBool(hint.cocoaGraphicsSwitching));
    wHintS(c.GLFW_X11_CLASS_NAME, hint.x11ClassName.ptr);
    wHintS(c.GLFW_X11_INSTANCE_NAME, hint.x11InstanceName.ptr);
}

pub const CursorInputMode = enum(u32) {
    Normal = @intCast(c.GLFW_CURSOR_NORMAL),
    Hidden = @intCast(c.GLFW_CURSOR_HIDDEN),
    Disabled = @intCast(c.GLFW_CURSOR_DISABLED),
};
pub const InputModeTag = enum(u32) {
    StickyKeys = @intCast(c.GLFW_STICKY_KEYS),
    StickyMouseButtons = @intCast(c.GLFW_STICKY_MOUSE_BUTTONS),
    LockKeyMods = @intCast(c.GLFW_LOCK_KEY_MODS),
    Cursor = @intCast(c.GLFW_CURSOR),
};
pub const InputMode = union(InputModeTag) {
    StickyKeys: bool,
    StickyMouseButtons: bool,
    LockKeyMods: bool,
    Cursor: CursorInputMode,
};

inline fn inputModeValue2Glfw(mode: InputMode) c_int {
    return switch (mode) {
        .StickyKeys, .StickyMouseButtons, .LockKeyMods => |v| @intFromBool(v),
        .Cursor => |v| @bitCast(@intFromEnum(v)),
    };
}

/// Set the clipboard content.
///
/// The possible error is needed
/// to convert the slice to a
/// null terminated C string.
///
/// Prefer using setClipboardZ() whenever possible.
pub fn setClipboard(allocator: Allocator, str: []const u8) Allocator.Error!void {
    const str_copy = utils.copy(
        u8,
        str,
        try allocator.allocSentinel(u8, str.len, 0),
    );
    defer allocator.free(str_copy);

    setClipboardZ(str_copy);
}
pub fn setClipboardZ(str: [:0]const u8) void {
    c.glfwSetClipboardString(null, str.ptr);
}
/// Query the clipboard content.
pub fn getClipboard() ?[]const u8 {
    const str = c.glfwGetClipboardString(null) orelse return null;
    return str[0..strlen(str)];
}

pub fn getKeyName(key: Key) []const u8 {
    const str = c.glfwGetKeyName(@bitCast(@intFromEnum(key)), 0);
    return str[0..strlen(str)];
}

inline fn keyFromGlfw(key: c_int) Key {
    return switch (key) {
        c.GLFW_KEY_SPACE => .Space,
        c.GLFW_KEY_APOSTROPHE => .Apostrophe,
        c.GLFW_KEY_COMMA => .Comma,
        c.GLFW_KEY_MINUS => .Minus,
        c.GLFW_KEY_PERIOD => .Period,
        c.GLFW_KEY_SLASH => .Slash,
        c.GLFW_KEY_0 => .@"0",
        c.GLFW_KEY_1 => .@"1",
        c.GLFW_KEY_2 => .@"2",
        c.GLFW_KEY_3 => .@"3",
        c.GLFW_KEY_4 => .@"4",
        c.GLFW_KEY_5 => .@"5",
        c.GLFW_KEY_6 => .@"6",
        c.GLFW_KEY_7 => .@"7",
        c.GLFW_KEY_8 => .@"8",
        c.GLFW_KEY_9 => .@"9",
        c.GLFW_KEY_SEMICOLON => .Semicolon,
        c.GLFW_KEY_EQUAL => .Equal,
        c.GLFW_KEY_A => .A,
        c.GLFW_KEY_B => .B,
        c.GLFW_KEY_C => .C,
        c.GLFW_KEY_D => .D,
        c.GLFW_KEY_E => .E,
        c.GLFW_KEY_F => .F,
        c.GLFW_KEY_G => .G,
        c.GLFW_KEY_H => .H,
        c.GLFW_KEY_I => .I,
        c.GLFW_KEY_J => .J,
        c.GLFW_KEY_K => .K,
        c.GLFW_KEY_L => .L,
        c.GLFW_KEY_M => .M,
        c.GLFW_KEY_N => .N,
        c.GLFW_KEY_O => .O,
        c.GLFW_KEY_P => .P,
        c.GLFW_KEY_Q => .Q,
        c.GLFW_KEY_R => .R,
        c.GLFW_KEY_S => .S,
        c.GLFW_KEY_T => .T,
        c.GLFW_KEY_U => .U,
        c.GLFW_KEY_V => .V,
        c.GLFW_KEY_W => .W,
        c.GLFW_KEY_X => .X,
        c.GLFW_KEY_Y => .Y,
        c.GLFW_KEY_Z => .Z,
        c.GLFW_KEY_LEFT_BRACKET => .LeftBracket,
        c.GLFW_KEY_BACKSLASH => .Backslash,
        c.GLFW_KEY_RIGHT_BRACKET => .RightBracket,
        c.GLFW_KEY_GRAVE_ACCENT => .GraveAccent,
        c.GLFW_KEY_WORLD_1 => .World1,
        c.GLFW_KEY_WORLD_2 => .World2,
        c.GLFW_KEY_ESCAPE => .Escape,
        c.GLFW_KEY_ENTER => .Enter,
        c.GLFW_KEY_TAB => .Tab,
        c.GLFW_KEY_BACKSPACE => .Backspace,
        c.GLFW_KEY_INSERT => .Insert,
        c.GLFW_KEY_DELETE => .Delete,
        c.GLFW_KEY_RIGHT => .Right,
        c.GLFW_KEY_LEFT => .Left,
        c.GLFW_KEY_DOWN => .Down,
        c.GLFW_KEY_UP => .Up,
        c.GLFW_KEY_PAGE_UP => .PageUp,
        c.GLFW_KEY_PAGE_DOWN => .PageDown,
        c.GLFW_KEY_HOME => .Home,
        c.GLFW_KEY_END => .End,
        c.GLFW_KEY_CAPS_LOCK => .CapsLock,
        c.GLFW_KEY_SCROLL_LOCK => .ScrollLock,
        c.GLFW_KEY_NUM_LOCK => .NumLock,
        c.GLFW_KEY_PRINT_SCREEN => .PrintScreen,
        c.GLFW_KEY_PAUSE => .Pause,
        c.GLFW_KEY_F1 => .F1,
        c.GLFW_KEY_F2 => .F2,
        c.GLFW_KEY_F3 => .F3,
        c.GLFW_KEY_F4 => .F4,
        c.GLFW_KEY_F5 => .F5,
        c.GLFW_KEY_F6 => .F6,
        c.GLFW_KEY_F7 => .F7,
        c.GLFW_KEY_F8 => .F8,
        c.GLFW_KEY_F9 => .F9,
        c.GLFW_KEY_F10 => .F10,
        c.GLFW_KEY_F11 => .F11,
        c.GLFW_KEY_F12 => .F12,
        c.GLFW_KEY_F13 => .F13,
        c.GLFW_KEY_F14 => .F14,
        c.GLFW_KEY_F15 => .F15,
        c.GLFW_KEY_F16 => .F16,
        c.GLFW_KEY_F17 => .F17,
        c.GLFW_KEY_F18 => .F18,
        c.GLFW_KEY_F19 => .F19,
        c.GLFW_KEY_F20 => .F20,
        c.GLFW_KEY_F21 => .F21,
        c.GLFW_KEY_F22 => .F22,
        c.GLFW_KEY_F23 => .F23,
        c.GLFW_KEY_F24 => .F24,
        c.GLFW_KEY_F25 => .F25,
        c.GLFW_KEY_KP_0 => .Kp0,
        c.GLFW_KEY_KP_1 => .Kp1,
        c.GLFW_KEY_KP_2 => .Kp2,
        c.GLFW_KEY_KP_3 => .Kp3,
        c.GLFW_KEY_KP_4 => .Kp4,
        c.GLFW_KEY_KP_5 => .Kp5,
        c.GLFW_KEY_KP_6 => .Kp6,
        c.GLFW_KEY_KP_7 => .Kp7,
        c.GLFW_KEY_KP_8 => .Kp8,
        c.GLFW_KEY_KP_9 => .Kp9,
        c.GLFW_KEY_KP_DECIMAL => .KpDecimal,
        c.GLFW_KEY_KP_DIVIDE => .KpDivide,
        c.GLFW_KEY_KP_MULTIPLY => .KpMultiply,
        c.GLFW_KEY_KP_SUBTRACT => .KpSubtract,
        c.GLFW_KEY_KP_ADD => .KpAdd,
        c.GLFW_KEY_KP_ENTER => .KpEnter,
        c.GLFW_KEY_KP_EQUAL => .KpEqual,
        c.GLFW_KEY_LEFT_SHIFT => .LeftShift,
        c.GLFW_KEY_LEFT_CONTROL => .LeftControl,
        c.GLFW_KEY_LEFT_ALT => .LeftAlt,
        c.GLFW_KEY_LEFT_SUPER => .LeftSuper,
        c.GLFW_KEY_RIGHT_SHIFT => .RightShift,
        c.GLFW_KEY_RIGHT_CONTROL => .RightControl,
        c.GLFW_KEY_RIGHT_ALT => .RightAlt,
        c.GLFW_KEY_RIGHT_SUPER => .RightSuper,
        c.GLFW_KEY_MENU => .Menu,
        else => .Unknown,
    };
}
inline fn actionFromGlfw(action: c_int) Key.Action {
    return switch (action) {
        c.GLFW_PRESS => .Pressed,
        c.GLFW_REPEAT => .Repeat,
        else => .Released,
    };
}

/// Get the current allocator set by glfwInitAllocator.
/// If no allocator was given then it returns std.heap.c_allocator
pub fn getCurrentAllocator() Allocator {
    return if (_glfw.allocator.user) |alloc|
        @as(*Allocator, @ptrCast(@alignCast(alloc))).*
    else
        std.heap.c_allocator;
}

/// The main data structure of GLFW.
pub const Window = opaque {
    var current: ?*Window = null;

    inline fn toIntern(self: *Window) *WindowInternal {
        return @ptrCast(@alignCast(c.glfwGetWindowUserPointer(@ptrCast(@alignCast(self)))));
    }

    fn mouseCallback(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.mouseCallback) |f| {
            f(@ptrCast(@alignCast(window)), x, y) catch |e| {
                pollErr = e;
            };
        }
    }
    fn buttonCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.buttonCallback) |f| {
            const kMods: Key.Mods = .{
                .Shift = mods & c.GLFW_MOD_SHIFT != 0,
                .Control = mods & c.GLFW_MOD_CONTROL != 0,
                .Alt = mods & c.GLFW_MOD_ALT != 0,
                .Super = mods & c.GLFW_MOD_SUPER != 0,
                .CapsLock = mods & c.GLFW_MOD_CAPS_LOCK != 0,
                .NumLock = mods & c.GLFW_MOD_NUM_LOCK != 0,
            };
            f(
                @ptrCast(@alignCast(window)),
                @bitCast(button),
                @enumFromInt(@as(u32, @bitCast(action))),
                kMods,
            ) catch |e| {
                pollErr = e;
            };
        }
    }
    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.keyCallback) |f| {
            const kMods: Key.Mods = .{
                .Shift = mods & c.GLFW_MOD_SHIFT != 0,
                .Control = mods & c.GLFW_MOD_CONTROL != 0,
                .Alt = mods & c.GLFW_MOD_ALT != 0,
                .Super = mods & c.GLFW_MOD_SUPER != 0,
                .CapsLock = mods & c.GLFW_MOD_CAPS_LOCK != 0,
                .NumLock = mods & c.GLFW_MOD_NUM_LOCK != 0,
            };
            f(
                @ptrCast(@alignCast(window)),
                @enumFromInt(@as(u32, @bitCast(key))),
                @enumFromInt(@as(u32, @bitCast(action))),
                kMods,
            ) catch |e| {
                pollErr = e;
            };
        }
    }
    fn charCallback(window: ?*c.GLFWwindow, char: c_uint) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.charCallback) |f| {
            f(@ptrCast(@alignCast(window)), @bitCast(char)) catch |e| {
                pollErr = e;
            };
        }
    }
    fn enterCallback(window: ?*c.GLFWwindow, entered: c_int) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.enterCallback) |f| {
            f(@ptrCast(@alignCast(window)), entered == c.GLFW_TRUE) catch |e| {
                pollErr = e;
            };
        }
    }
    fn scrollCallback(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.scrollCallback) |f| {
            f(@ptrCast(@alignCast(window)), x, y) catch |e| {
                pollErr = e;
            };
        }
    }
    fn dropCallback(window: ?*c.GLFWwindow, pathCount: c_int, paths: [*c][*c]const u8) callconv(.C) void {
        const win = @as(*WindowInternal, @ptrCast(@alignCast(c.glfwGetWindowUserPointer(window))));
        if (win.dropCallback) |f| {
            const pathsSlice: [][]const u8 = getCurrentAllocator().alloc([]u8, @intCast(pathCount)) catch |e| {
                pollErr = e;
                return;
            };
            defer getCurrentAllocator().free(pathsSlice);

            for (0..@intCast(pathCount)) |i| {
                const str = paths[i];
                const len: usize = @intCast(strlen(str));
                pathsSlice[i] = str[0..len];
            }

            f(@ptrCast(@alignCast(window)), pathsSlice) catch |e| {
                pollErr = e;
            };
        }
    }

    pub fn create(title: []const u8, width: u32, height: u32, hint: WindowHint, monitor: ?*Monitor, share: ?*Window, errStr: ?*[]const u8) Error!*Window {
        const allocator = getCurrentAllocator();

        const title_copy = try allocator.allocSentinel(u8, title.len, 0);
        @memcpy(title_copy, title);
        errdefer allocator.free(title_copy);

        windowHint(hint);
        const ptr = c.glfwCreateWindow(
            @intCast(width),
            @intCast(height),
            title_copy.ptr,
            @ptrCast(@alignCast(monitor)),
            @ptrCast(@alignCast(share)),
        ) orelse
            return getError(errStr);
        errdefer c.glfwDestroyWindow(ptr);
        _ = c.glfwSetCursorPosCallback(ptr, &mouseCallback);
        _ = c.glfwSetMouseButtonCallback(ptr, &buttonCallback);
        _ = c.glfwSetKeyCallback(ptr, &keyCallback);
        _ = c.glfwSetCharCallback(ptr, &charCallback);
        _ = c.glfwSetCursorEnterCallback(ptr, &enterCallback);
        _ = c.glfwSetScrollCallback(ptr, &scrollCallback);
        _ = c.glfwSetDropCallback(ptr, &dropCallback);
        const winPtr = try allocator.create(WindowInternal);
        winPtr.* = .{
            .title = title_copy[0..title.len :0],
            .hint = hint,
        };
        c.glfwMakeContextCurrent(ptr);
        c.glfwSwapInterval(@intFromBool(hint.vsync));
        if (current) |curr| curr.makeCurrentContext();
        c.glfwSetWindowUserPointer(ptr, @ptrCast(@alignCast(winPtr)));
        return @ptrCast(@alignCast(ptr));
    }
    pub fn destroy(self: *Window) void {
        const win = self.toIntern();

        const allocator = getCurrentAllocator();

        allocator.free(win.title);
        allocator.destroy(win);

        c.glfwDestroyWindow(@ptrCast(@alignCast(self)));
    }

    pub fn getMonitor(self: *Window) *Monitor {
        return @ptrCast(@alignCast(c.glfwGetWindowMonitor(@ptrCast(@alignCast(self)))));
    }
    pub fn setMonitor(self: *Monitor, monitor: *Monitor, x: u32, y: u32, w: u32, h: u32, refreshRate: u32) void {
        c.glfwSetWindowMonitor(
            @ptrCast(@alignCast(self)),
            @ptrCast(@alignCast(monitor)),
            @intCast(x),
            @intCast(y),
            @intCast(w),
            @intCast(h),
            @intCast(refreshRate),
        );
    }

    pub fn makeCurrentContext(self: *Window) void {
        if (self == current)
            return;
        c.glfwMakeContextCurrent(@ptrCast(@alignCast(self)));
        current = self;
    }
    pub fn isCurrentContext(self: *Window) bool {
        return self == current;
    }
    pub fn getCurrentContext() ?*Window {
        return current;
    }

    pub fn setVSync(self: *Window, vsync: bool) void {
        const win = self.toIntern();
        win.hint.vsync = vsync;
        if (self != current) c.glfwMakeContextCurrent(@ptrCast(@alignCast(self)));
        c.glfwSwapInterval(@intFromBool(vsync));
        if (self != current)
            if (current) |curr| c.glfwMakeContextCurrent(toIntern(curr).ptr);
    }

    pub fn swapBuffers(self: *Window) void {
        c.glfwSwapBuffers(@ptrCast(@alignCast(self)));
    }

    pub fn shouldClose(self: *Window) bool {
        return c.glfwWindowShouldClose(@ptrCast(@alignCast(self))) == c.GLFW_TRUE;
    }
    pub fn setShouldClose(self: *Window, value: bool) void {
        c.glfwSetWindowShouldClose(@ptrCast(@alignCast(self)), @intFromBool(value));
    }

    pub fn show(self: *Window) void {
        const win = self.toIntern();
        c.glfwShowWindow(@ptrCast(@alignCast(self)));
        win.hint.visible = true;
    }
    pub fn hide(self: *Window) void {
        const win = self.toIntern();
        c.glfwHideWindow(@ptrCast(@alignCast(self)));
        win.hint.visible = false;
    }

    pub fn getPosition(self: *Window, x: ?*u32, y: ?*u32) void {
        c.glfwGetWindowPos(@ptrCast(@alignCast(self)), @ptrCast(x), @ptrCast(y));
    }
    pub fn setPosition(self: *Window, x: u32, y: u32) void {
        c.glfwSetWindowPos(@ptrCast(@alignCast(self)), @intCast(x), @intCast(y));
    }

    pub fn getSize(self: *Window, w: ?*u32, h: ?*u32) void {
        c.glfwGetWindowSize(@ptrCast(@alignCast(self)), @ptrCast(w), @ptrCast(h));
    }
    pub fn setSize(self: *Window, w: u32, h: u32) void {
        c.glfwSetWindowSize(@ptrCast(@alignCast(self)), @intCast(w), @intCast(h));
    }

    pub fn getTitle(self: *Window) []const u8 {
        return self.toIntern().title;
    }
    pub fn setTitle(self: *Window, title: []const u8) Error!void {
        const win = self.toIntern();
        if (std.mem.eql(u8, win.title, title)) return;

        const allocator = getCurrentAllocator();

        const title_copy = utils.copy(
            u8,
            title,
            allocator.allocSentinel(u8, title.len, 0) catch return Error.OutOfMemory,
        );

        c.glfwSetWindowTitle(@ptrCast(@alignCast(self)), title_copy.ptr);

        allocator.free(win.title);
        win.title = title_copy;
    }

    pub fn setResizable(self: *Window, resiziable: bool) void {
        c.glfwSetWindowAttrib(@ptrCast(@alignCast(self)), c.GLFW_RESIZABLE, @intFromBool(resiziable));
    }

    pub fn setInputMode(self: *Window, mode: InputMode) void {
        c.glfwSetInputMode(@ptrCast(@alignCast(self)), @bitCast(@intFromEnum(std.meta.activeTag(mode))), inputModeValue2Glfw(mode));
    }
    /// Will always return the active tag defined by `mode`
    pub fn getInputMode(self: *Window, mode: InputModeTag) InputMode {
        const v = c.glfwGetInputMode(@ptrCast(@alignCast(self)), @bitCast(@intFromEnum(mode)));
        return switch (mode) {
            .StickyKeys, .StickyMouseButtons, .LockKeyMods => |tag| @unionInit(InputMode, @tagName(tag), v == c.GLFW_TRUE),
            .Cursor => .{
                .Cursor = @enumFromInt(v),
            },
        };
    }

    pub fn setCursor(self: *Window, cursor: Cursor) void {
        c.glfwSetCursor(@ptrCast(@alignCast(self)), cursor.toIntern().ptr);
    }
    pub inline fn setIcon(self: *Window, icon: Image) void {
        self.setIcons(&icon);
    }
    pub fn setIcons(self: *Window, icons: []Image) Allocator.Error!void {
        const allocator = self.toIntern().allocator;

        const imgs = try allocator.alloc(c.GLFWimage, icons.len);
        defer allocator.free(imgs);

        for (icons, 0..) |icon, i| {
            imgs[i] = .{
                .width = @intCast(icon.width),
                .height = @intCast(icon.height),
                .pixels = @ptrCast(icon.pixels.ptr),
            };
        }

        c.glfwSetWindowIcon(@ptrCast(@alignCast(self)), icons.len, imgs);
    }

    pub fn getMousePos(self: *Window, x: ?*f64, y: ?*f64) void {
        c.glfwGetCursorPos(@ptrCast(@alignCast(self)), @ptrCast(x), @ptrCast(y));
    }
    pub fn getMouseButton(self: *Window, button: u32) Key.Action {
        return @enumFromInt(@as(u32, @bitCast(c.glfwGetMouseButton(@ptrCast(@alignCast(self)), @intCast(button)))));
    }
    pub fn getKey(self: *Window, key: Key) Key.Action {
        return @enumFromInt(@as(u32, @bitCast(c.glfwGetKey(@ptrCast(@alignCast(self)), @bitCast(@intFromEnum(key))))));
    }

    // callbacks

    pub fn setMouseCallback(self: *Window, cb: ?MousePosCallback) void {
        self.toIntern().mouseCallback = cb;
    }
    pub fn getMouseCallback(self: *Window) ?MousePosCallback {
        return self.toIntern().mouseCallback;
    }

    pub fn setButtonCallback(self: *Window, cb: ?ButtonCallback) void {
        self.toIntern().buttonCallback = cb;
    }
    pub fn getButtonCallback(self: *Window) ?ButtonCallback {
        return self.toIntern().buttonCallback;
    }

    pub fn setKeyCallback(self: *Window, cb: ?KeyCallback) void {
        self.toIntern().keyCallback = cb;
    }
    pub fn getKeyCallback(self: *Window) ?KeyCallback {
        return self.toIntern().keyCallback;
    }

    pub fn setCharCallback(self: *Window, cb: ?CharCallback) void {
        self.toIntern().charCallback = cb;
    }
    pub fn getCharCallback(self: *Window) ?CharCallback {
        return self.toIntern().charCallback;
    }

    pub fn setEnterCallback(self: *Window, cb: ?EnterCallback) void {
        self.toIntern().enterCallback = cb;
    }
    pub fn getEnterCallback(self: *Window) ?EnterCallback {
        return self.toIntern().enterCallback;
    }

    pub fn setScrollCallback(self: *Window, cb: ?ScrollCallback) void {
        self.toIntern().scrollCallback = cb;
    }
    pub fn getScrollCallback(self: *Window) ?ScrollCallback {
        return self.toIntern().scrollCallback;
    }

    pub fn setDropCallback(self: *Window, cb: ?DropCallback) void {
        self.toIntern().dropCallback = cb;
    }
    pub fn getDropCallback(self: *Window) ?DropCallback {
        return self.toIntern().dropCallback;
    }
};

const WindowInternal = struct {
    title: [:0]const u8,
    hint: WindowHint,

    mouseCallback: ?MousePosCallback = null,
    buttonCallback: ?ButtonCallback = null,
    keyCallback: ?KeyCallback = null,
    charCallback: ?CharCallback = null,
    enterCallback: ?EnterCallback = null,
    scrollCallback: ?ScrollCallback = null,
    dropCallback: ?DropCallback = null,
};

pub const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    comptime {
        if (@sizeOf(Color) != 4) @compileError("Color is not 4 bytes somehow");
    }
};

pub const Image = struct {
    pixels: []Color,
    width: u32,
    height: u32,
};

pub const StandardCursor = enum(u32) {
    Arrow = @bitCast(c.GLFW_ARROW_CURSOR),
    IBeam = @bitCast(c.GLFW_IBEAM_CURSOR),
    Crosshair = @bitCast(c.GLFW_CROSSHAIR_CURSOR),
    Hand = @bitCast(c.GLFW_HAND_CURSOR),
    HResize = @bitCast(c.GLFW_HRESIZE_CURSOR),
    VResize = @bitCast(c.GLFW_VRESIZE_CURSOR),
};

pub const Cursor = opaque {
    inline fn toIntern(self: *Cursor) *CursorInternal {
        return @ptrCast(@alignCast(self));
    }

    pub fn createStandard(allocator: Allocator, cursor: StandardCursor, errStr: ?*[]const u8) Error!*Cursor {
        const ptr = c.glfwCreateStandardCursor(@bitCast(@intFromEnum(cursor))) orelse
            return getError(errStr);
        errdefer c.glfwDestroyCursor(ptr);

        const cur = CursorInternal{
            .allocator = allocator,
            .ptr = ptr,
        };

        const cursorPtr = allocator.create(CursorInternal) catch return Error.OutOfMemory;
        errdefer allocator.destroy(cursorPtr);

        cursorPtr = cur;

        return cursorPtr.toExtern();
    }
    pub fn create(allocator: Allocator, image: Image, errStr: ?*[]const u8) Error!*Cursor {
        const img = c.GLFWimage{
            .width = @intCast(image.width),
            .height = @intCast(image.height),
            .pixels = @ptrCast(image.pixels.ptr),
        };
        const ptr = c.glfwCreateCursor(img, 0, 0) orelse
            return getError(errStr);
        errdefer c.glfwDestroyCursor(ptr);

        const cursor = CursorInternal{
            .allocator = allocator,
            .ptr = ptr,
        };

        const cursorPtr = allocator.create(CursorInternal) catch return Error.OutOfMemory;
        errdefer allocator.destroy(cursorPtr);

        cursorPtr = cursor;

        return cursorPtr.toExtern();
    }
    pub fn destroy(self: *Cursor) void {
        const cur = self.toIntern();

        c.glfwDestroyCursor(cur.ptr);

        cur.allocator.destroy(cur);
    }
};

const CursorInternal = struct {
    allocator: Allocator,
    ptr: *c.GLFWcursor,

    pub inline fn toExtern(self: *CursorInternal) *Cursor {
        return @ptrCast(@alignCast(self));
    }
};

pub const MonitorEvent = enum(u32) {
    Connected = @bitCast(c.GLFW_CONNECTED),
    Disconnected = @bitCast(c.GLFW_DISCONNECTED),
};

pub const Monitor = opaque {
    var monitorCallback: ?MonitorCallback = null;

    fn monitorCb(monitor: ?*c.GLFWmonitor, event: c_int) callconv(.C) void {
        if (monitorCallback) |f| {
            f(@ptrCast(@alignCast(monitor)), @enumFromInt(@as(u32, @bitCast(event))));
        }
    }

    pub fn getCallback() ?MonitorCallback {
        return monitorCallback;
    }
    pub fn setCallback(cb: ?MonitorCallback) void {
        monitorCallback = cb;
    }

    pub fn getPrimary() *Monitor {
        _ = c.glfwSetMonitorCallback(&monitorCb);
        return @ptrCast(@alignCast(c.glfwGetPrimaryMonitor().?));
    }
    pub fn getMonitors() []Monitor {
        _ = c.glfwSetMonitorCallback(&monitorCb);
        var len: c_int = 0;
        return @as([*]Monitor, @ptrCast(@alignCast(c.glfwGetMonitors(&len))))[0..@intCast(len)];
    }

    pub fn getContentScale(self: *Monitor, w: ?*f32, h: ?*f32) void {
        c.glfwGetMonitorContentScale(@ptrCast(@alignCast(self)), w, h);
    }
    pub fn getName(self: *Monitor) []const u8 {
        const ptr = c.glfwGetMonitorName(@ptrCast(@alignCast(self)));
        const len = strlen(ptr);
        return ptr[0..len];
    }
    pub fn getPhysicalSize(self: *Monitor, w: ?*u32, h: u32) void {
        c.glfwGetMonitorPhysicalSize(@ptrCast(@alignCast(self)), @ptrCast(w), @ptrCast(h));
    }
    pub fn getPos(self: *Monitor, x: ?*u32, y: ?*u32) void {
        c.glfwGetMonitorPos(@ptrCast(@alignCast(self)), @ptrCast(x), @ptrCast(y));
    }
    pub fn getWorkArea(self: *Monitor, x: ?*u32, y: ?*u32, w: ?*u32, h: ?*u32) void {
        c.glfwGetMonitorWorkarea(@ptrCast(@alignCast(self)), @ptrCast(x), @ptrCast(y), @ptrCast(w), @ptrCast(h));
    }
};
