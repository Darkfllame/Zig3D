const std = @import("std");
const utils = @import("utils");
pub const Key = @import("Key").Key;
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("string.h");
});

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

pub fn getError(description: ?*[]const u8) Error {
    var desc: []u8 = undefined;
    const err = errFromC(c.glfwGetError(@ptrCast(&desc.ptr)));
    if (err != Error.NoError) {
        desc.len = c.strlen(desc.ptr);
    } else {
        desc = "";
    }
    if (description) |_| description.?.* = desc;
    return err;
}

const Allocator = std.mem.Allocator;

pub const MousePosCallback = *const fn (window: *Window, x: f64, y: f64) anyerror!void;
pub const ButtonCallback = *const fn (window: *Window, button: u32, action: Key.Action, mods: Key.Mods) anyerror!void;
pub const KeyCallback = *const fn (window: *Window, key: Key, action: Key.Action, mods: Key.Mods) anyerror!void;
pub const CharCallback = *const fn (window: *Window, char: u32) anyerror!void;
pub const EnterCallback = *const fn (window: *Window, entered: bool) anyerror!void;
pub const ScrollCallback = *const fn (window: *Window, x: f64, y: f64) anyerror!void;
pub const DropCallback = *const fn (window: *Window, paths: []const []const u8) anyerror!void;

pub const GlfwVersion = struct {
    major: u8 = 1,
    minor: u8 = 0,
    revision: u8 = 0,
};

pub fn getProcAddress(procname: [*c]const u8) callconv(.C) ?*anyopaque {
    return @ptrCast(@constCast(c.glfwGetProcAddress(procname)));
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
    debugContext: bool = false,
    openglProfile: OpenglProfile = .Any,
    cocoaRetinaFramebuffer: bool = true,
    cocoaFrameName: [:0]const u8 = "",
    cocoaGraphicsSwitching: bool = false,
    x11ClassName: [:0]const u8 = "",
    x11InstanceName: [:0]const u8 = "",
};

inline fn boolToGlfw(b: bool) c_int {
    return if (b) c.GL_TRUE else c.GL_FALSE;
}

fn windowHint(hint: WindowHint) void {
    // i just put @bitCast() everywhere so if the c_int size is not the same as u32
    // you're quite f'd up
    const wHint = c.glfwWindowHint;
    const wHintS = c.glfwWindowHintString;
    wHint(c.GLFW_RESIZABLE, boolToGlfw(hint.resizable));
    wHint(c.GLFW_VISIBLE, boolToGlfw(hint.visible));
    wHint(c.GLFW_DECORATED, boolToGlfw(hint.decorated));
    wHint(c.GLFW_FOCUSED, boolToGlfw(hint.focused));
    wHint(c.GLFW_AUTO_ICONIFY, boolToGlfw(hint.autoIconify));
    wHint(c.GLFW_FLOATING, boolToGlfw(hint.floating));
    wHint(c.GLFW_MAXIMIZED, boolToGlfw(hint.maximized));
    wHint(c.GLFW_CENTER_CURSOR, boolToGlfw(hint.centerCursor));
    wHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, boolToGlfw(hint.transparentFramebuffer));
    wHint(c.GLFW_FOCUS_ON_SHOW, boolToGlfw(hint.focusOnShow));
    wHint(c.GLFW_SCALE_TO_MONITOR, boolToGlfw(hint.scaleToMonitor));
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
    wHint(c.GLFW_STEREO, boolToGlfw(hint.stereo));
    wHint(c.GLFW_SRGB_CAPABLE, boolToGlfw(hint.srgbCapable));
    wHint(c.GLFW_DOUBLEBUFFER, boolToGlfw(hint.doubleBuffer));
    wHint(c.GLFW_CLIENT_API, @intCast(@intFromEnum(hint.clientApi)));
    wHint(c.GLFW_CONTEXT_CREATION_API, @intCast(@intFromEnum(hint.creationApi)));
    wHint(c.GLFW_CONTEXT_VERSION_MAJOR, @intCast(hint.version.major));
    wHint(c.GLFW_CONTEXT_VERSION_MINOR, @intCast(hint.version.minor));
    wHint(c.GLFW_CONTEXT_ROBUSTNESS, @intCast(@intFromEnum(hint.robustness)));
    wHint(c.GLFW_CONTEXT_RELEASE_BEHAVIOR, @intCast(@intFromEnum(hint.releaseBehaviour)));
    wHint(c.GLFW_OPENGL_FORWARD_COMPAT, boolToGlfw(hint.forwardCompat));
    wHint(c.GLFW_OPENGL_DEBUG_CONTEXT, boolToGlfw(hint.debugContext));
    wHint(c.GLFW_OPENGL_PROFILE, @intCast(@intFromEnum(hint.openglProfile)));
    wHint(c.GLFW_COCOA_RETINA_FRAMEBUFFER, boolToGlfw(hint.cocoaRetinaFramebuffer));
    wHintS(c.GLFW_COCOA_FRAME_NAME, hint.cocoaFrameName.ptr);
    wHint(c.GLFW_COCOA_GRAPHICS_SWITCHING, boolToGlfw(hint.cocoaGraphicsSwitching));
    wHintS(c.GLFW_X11_CLASS_NAME, hint.x11ClassName.ptr);
    wHintS(c.GLFW_X11_INSTANCE_NAME, hint.x11InstanceName.ptr);
}

pub const InputMode = enum {
    StickyKeys,
    StickyMouseButtons,
    LockKeyMods,
};
pub const CursorInputMode = enum {
    Normal,
    Hidden,
    Disabled,
};

inline fn inputMode2Glfw(mode: InputMode) c_int {
    return switch (mode) {
        .StickyKeys => c.GLFW_STICKY_KEYS,
        .StickyMouseButtons => c.GLFW_STICKY_MOUSE_BUTTONS,
        .LockKeyMods => c.GLFW_LOCK_KEY_MODS,
    };
}

/// Set the clipboard content.
///
/// The possible error is needed
/// to convert the slice to a
/// null terminated C string.
pub fn setClipboard(allocator: Allocator, str: []const u8) Allocator.Error!void {
    const str_copy = utils.copy(
        u8,
        str,
        try allocator.alloc(u8, str.len + 1),
    );
    defer allocator.free(str_copy);
    str_copy[str.len] = 0;

    c.glfwSetClipboardString(null, str_copy);
}
/// Query the clipboard content and allocate new memory for it.
///
/// The returned string should be freed by the caller.
pub fn getClipboard(allocator: Allocator) Allocator.Error!?[]const u8 {
    const str = c.glfwGetClipboardString(null) orelse return null;
    const len: usize = @intCast(c.strlen(str));
    return utils.copy(
        u8,
        str[0..len],
        try allocator.alloc(u8, len),
    );
}

/// The main data structure of GLFW.
pub const Window = opaque {
    var current: ?*Window = null;
    var windows: ?std.ArrayList(WindowInternal) = null;

    fn toIntern(self: *Window) *WindowInternal {
        return @ptrCast(@alignCast(self));
    }

    fn mouseCallback(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
        if (win.mouseCallback) |f| {
            f(win.toExtern(), x, y) catch |e| {
                pollErr = e;
            };
        }
    }
    fn buttonCallback(window: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
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
                win.toExtern(),
                @bitCast(button),
                switch (action) {
                    c.GLFW_RELEASE => Key.Action.Released,
                    c.GLFW_PRESS => Key.Action.Pressed,
                    c.GLFW_REPEAT => Key.Action.Repeat,
                    else => unreachable,
                },
                kMods,
            ) catch |e| {
                pollErr = e;
            };
        }
    }
    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        const win = windowFromGlfw(window.?).toIntern();
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
                win.toExtern(),
                switch (key) {
                    c.GLFW_KEY_SPACE => Key.Space,
                    c.GLFW_KEY_APOSTROPHE => Key.Apostrophe,
                    c.GLFW_KEY_COMMA => Key.Comma,
                    c.GLFW_KEY_MINUS => Key.Minus,
                    c.GLFW_KEY_PERIOD => Key.Period,
                    c.GLFW_KEY_SLASH => Key.Slash,
                    c.GLFW_KEY_0 => Key.@"0",
                    c.GLFW_KEY_1 => Key.@"1",
                    c.GLFW_KEY_2 => Key.@"2",
                    c.GLFW_KEY_3 => Key.@"4",
                    c.GLFW_KEY_4 => Key.@"4",
                    c.GLFW_KEY_5 => Key.@"5",
                    c.GLFW_KEY_6 => Key.@"6",
                    c.GLFW_KEY_7 => Key.@"7",
                    c.GLFW_KEY_8 => Key.@"8",
                    c.GLFW_KEY_9 => Key.@"9",
                    c.GLFW_KEY_SEMICOLON => Key.Semicolon,
                    c.GLFW_KEY_EQUAL => Key.Equal,
                    c.GLFW_KEY_A => Key.A,
                    c.GLFW_KEY_B => Key.B,
                    c.GLFW_KEY_C => Key.C,
                    c.GLFW_KEY_D => Key.D,
                    c.GLFW_KEY_E => Key.E,
                    c.GLFW_KEY_F => Key.F,
                    c.GLFW_KEY_G => Key.G,
                    c.GLFW_KEY_H => Key.H,
                    c.GLFW_KEY_I => Key.I,
                    c.GLFW_KEY_J => Key.J,
                    c.GLFW_KEY_K => Key.K,
                    c.GLFW_KEY_L => Key.L,
                    c.GLFW_KEY_M => Key.M,
                    c.GLFW_KEY_N => Key.N,
                    c.GLFW_KEY_O => Key.O,
                    c.GLFW_KEY_P => Key.P,
                    c.GLFW_KEY_Q => Key.Q,
                    c.GLFW_KEY_R => Key.R,
                    c.GLFW_KEY_S => Key.S,
                    c.GLFW_KEY_T => Key.T,
                    c.GLFW_KEY_U => Key.U,
                    c.GLFW_KEY_V => Key.V,
                    c.GLFW_KEY_W => Key.W,
                    c.GLFW_KEY_X => Key.X,
                    c.GLFW_KEY_Y => Key.Y,
                    c.GLFW_KEY_Z => Key.Z,
                    c.GLFW_KEY_LEFT_BRACKET => Key.LeftBracket,
                    c.GLFW_KEY_BACKSLASH => Key.Backslash,
                    c.GLFW_KEY_RIGHT_BRACKET => Key.RightBracket,
                    c.GLFW_KEY_GRAVE_ACCENT => Key.GraveAccent,
                    c.GLFW_KEY_WORLD_1 => Key.World1,
                    c.GLFW_KEY_WORLD_2 => Key.World2,
                    c.GLFW_KEY_ESCAPE => Key.Escape,
                    c.GLFW_KEY_ENTER => Key.Enter,
                    c.GLFW_KEY_TAB => Key.Tab,
                    c.GLFW_KEY_BACKSPACE => Key.Backspace,
                    c.GLFW_KEY_INSERT => Key.Insert,
                    c.GLFW_KEY_DELETE => Key.Delete,
                    c.GLFW_KEY_RIGHT => Key.Right,
                    c.GLFW_KEY_LEFT => Key.Left,
                    c.GLFW_KEY_DOWN => Key.Down,
                    c.GLFW_KEY_UP => Key.Up,
                    c.GLFW_KEY_PAGE_UP => Key.PageUp,
                    c.GLFW_KEY_PAGE_DOWN => Key.PageDown,
                    c.GLFW_KEY_HOME => Key.Home,
                    c.GLFW_KEY_END => Key.End,
                    c.GLFW_KEY_CAPS_LOCK => Key.CapsLock,
                    c.GLFW_KEY_SCROLL_LOCK => Key.ScrollLock,
                    c.GLFW_KEY_NUM_LOCK => Key.NumLock,
                    c.GLFW_KEY_PRINT_SCREEN => Key.PrintScreen,
                    c.GLFW_KEY_PAUSE => Key.Pause,
                    c.GLFW_KEY_F1 => Key.F1,
                    c.GLFW_KEY_F2 => Key.F2,
                    c.GLFW_KEY_F3 => Key.F3,
                    c.GLFW_KEY_F4 => Key.F4,
                    c.GLFW_KEY_F5 => Key.F5,
                    c.GLFW_KEY_F6 => Key.F6,
                    c.GLFW_KEY_F7 => Key.F7,
                    c.GLFW_KEY_F8 => Key.F8,
                    c.GLFW_KEY_F9 => Key.F9,
                    c.GLFW_KEY_F10 => Key.F10,
                    c.GLFW_KEY_F11 => Key.F11,
                    c.GLFW_KEY_F12 => Key.F12,
                    c.GLFW_KEY_F13 => Key.F13,
                    c.GLFW_KEY_F14 => Key.F14,
                    c.GLFW_KEY_F15 => Key.F15,
                    c.GLFW_KEY_F16 => Key.F16,
                    c.GLFW_KEY_F17 => Key.F17,
                    c.GLFW_KEY_F18 => Key.F18,
                    c.GLFW_KEY_F19 => Key.F19,
                    c.GLFW_KEY_F20 => Key.F20,
                    c.GLFW_KEY_F21 => Key.F21,
                    c.GLFW_KEY_F22 => Key.F22,
                    c.GLFW_KEY_F23 => Key.F23,
                    c.GLFW_KEY_F24 => Key.F24,
                    c.GLFW_KEY_F25 => Key.F25,
                    c.GLFW_KEY_KP_0 => Key.Kp0,
                    c.GLFW_KEY_KP_1 => Key.Kp1,
                    c.GLFW_KEY_KP_2 => Key.Kp2,
                    c.GLFW_KEY_KP_3 => Key.Kp3,
                    c.GLFW_KEY_KP_4 => Key.Kp4,
                    c.GLFW_KEY_KP_5 => Key.Kp5,
                    c.GLFW_KEY_KP_6 => Key.Kp6,
                    c.GLFW_KEY_KP_7 => Key.Kp7,
                    c.GLFW_KEY_KP_8 => Key.Kp8,
                    c.GLFW_KEY_KP_9 => Key.Kp9,
                    c.GLFW_KEY_KP_DECIMAL => Key.KpDecimal,
                    c.GLFW_KEY_KP_DIVIDE => Key.KpDivide,
                    c.GLFW_KEY_KP_MULTIPLY => Key.KpMultiply,
                    c.GLFW_KEY_KP_SUBTRACT => Key.KpSubtract,
                    c.GLFW_KEY_KP_ADD => Key.KpAdd,
                    c.GLFW_KEY_KP_ENTER => Key.KpEnter,
                    c.GLFW_KEY_KP_EQUAL => Key.KpEqual,
                    c.GLFW_KEY_LEFT_SHIFT => Key.LeftShift,
                    c.GLFW_KEY_LEFT_CONTROL => Key.LeftControl,
                    c.GLFW_KEY_LEFT_ALT => Key.LeftAlt,
                    c.GLFW_KEY_LEFT_SUPER => Key.LeftSuper,
                    c.GLFW_KEY_RIGHT_SHIFT => Key.RightShift,
                    c.GLFW_KEY_RIGHT_CONTROL => Key.RightControl,
                    c.GLFW_KEY_RIGHT_ALT => Key.RightAlt,
                    c.GLFW_KEY_RIGHT_SUPER => Key.RightSuper,
                    c.GLFW_KEY_MENU => Key.Menu,
                    else => Key.Unknown,
                },
                switch (action) {
                    c.GLFW_RELEASE => Key.Action.Released,
                    c.GLFW_PRESS => Key.Action.Pressed,
                    c.GLFW_REPEAT => Key.Action.Repeat,
                    else => unreachable,
                },
                kMods,
            ) catch |e| {
                pollErr = e;
            };
        }
    }
    fn charCallback(window: ?*c.GLFWwindow, char: c_uint) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
        if (win.charCallback) |f| {
            f(win.toExtern(), @bitCast(char)) catch |e| {
                pollErr = e;
            };
        }
    }
    fn enterCallback(window: ?*c.GLFWwindow, entered: c_int) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
        if (win.enterCallback) |f| {
            f(win.toExtern(), entered == c.GLFW_TRUE) catch |e| {
                pollErr = e;
            };
        }
    }
    fn scrollCallback(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
        if (win.scrollCallback) |f| {
            f(win.toExtern(), x, y) catch |e| {
                pollErr = e;
            };
        }
    }
    fn dropCallback(window: ?*c.GLFWwindow, pathCount: c_int, paths: [*c]const [*c]const u8) callconv(.C) void {
        const win = windowFromGlfw(window.?).toIntern();
        if (win.dropCallback) |f| {
            const pathsSlice: [][]const u8 = win.allocator.alloc([]u8, @intCast(pathCount)) catch |e| {
                pollErr = e;
                return;
            };
            defer win.allocator.free(pathsSlice);

            for (0..@intCast(pathCount)) |i| {
                const str = paths[i];
                const len: usize = @intCast(c.strlen(str));
                pathsSlice[i] = str[0..len];
            }

            f(win.toExtern(), pathsSlice) catch |e| {
                pollErr = e;
            };
        }
    }

    fn windowFromGlfw(window: *c.GLFWwindow) *Window {
        if (windows == null) @panic("No registered window");
        for (windows.?.items) |*item| {
            if (item.ptr == window) return item.toExtern();
        }
        @panic("Cannot find window");
    }

    pub fn create(allocator: Allocator, title: []const u8, width: u32, height: u32, hint: WindowHint, errStr: ?*[]const u8) Error!*Window {
        const title_copy = utils.copy(
            u8,
            title,
            try allocator.alloc(u8, title.len + 1),
        );
        errdefer allocator.free(title_copy);
        title_copy[title.len] = 0;

        windowHint(hint);
        const ptr = c.glfwCreateWindow(@intCast(width), @intCast(height), title_copy.ptr, null, null) orelse
            return getError(errStr);
        errdefer c.glfwDestroyWindow(ptr);
        _ = c.glfwSetCursorPosCallback(ptr, &mouseCallback);
        _ = c.glfwSetMouseButtonCallback(ptr, &buttonCallback);
        _ = c.glfwSetKeyCallback(ptr, &keyCallback);
        _ = c.glfwSetCharCallback(ptr, &charCallback);
        _ = c.glfwSetCursorEnterCallback(ptr, &enterCallback);
        _ = c.glfwSetScrollCallback(ptr, &scrollCallback);
        _ = c.glfwSetDropCallback(ptr, &dropCallback);
        const window = WindowInternal{
            .allocator = allocator,
            .ptr = ptr,
            .title = title_copy[0..title.len :0],
            .hint = hint,
        };
        if (windows == null)
            windows = std.ArrayList(WindowInternal).init(allocator);
        const winPtr = windows.?.addOne() catch return Error.OutOfMemory;
        winPtr.* = window;
        c.glfwMakeContextCurrent(ptr);
        c.glfwSwapInterval(@intFromBool(hint.vsync));
        if (current) |curr| curr.makeCurrentContext();
        return winPtr.toExtern();
    }
    pub fn destroy(self: *Window) void {
        if (windows == null)
            return;
        const win = self.toIntern();

        const wArr = windows.?;
        const allocator = win.allocator;

        allocator.free(win.title);
        c.glfwDestroyWindow(win.ptr);

        win.* = undefined;
        if (wArr.items.len <= 1) {
            wArr.deinit();
            windows = null;
        }
    }

    pub fn getAllocator(self: *Window) Allocator {
        return self.toIntern().allocator;
    }

    pub fn makeCurrentContext(self: *Window) void {
        if (self == current)
            return;
        const win = self.toIntern();
        c.glfwMakeContextCurrent(win.ptr);
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
        if (self != current) c.glfwMakeContextCurrent(win.ptr);
        c.glfwSwapInterval(@intFromBool(vsync));
        if (self != current)
            if (current) |curr| c.glfwMakeContextCurrent(toIntern(curr).ptr);
    }

    pub fn swapBuffers(self: *Window) void {
        const win = self.toIntern();
        c.glfwSwapBuffers(win.ptr);
    }

    pub fn shouldClose(self: *Window) bool {
        const win = self.toIntern();
        return c.glfwWindowShouldClose(win.ptr) == c.GLFW_TRUE;
    }
    pub fn setShouldClose(self: *Window, value: bool) void {
        const win = self.toIntern();
        c.glfwSetWindowShouldClose(win.ptr, @intFromBool(value));
    }

    pub fn show(self: *Window) void {
        const win = self.toIntern();
        c.glfwShowWindow(win.ptr);
        win.hint.visible = true;
    }
    pub fn hide(self: *Window) void {
        const win = self.toIntern();
        c.glfwHideWindow(win.ptr);
        win.hint.visible = false;
    }

    pub fn getPosition(self: *Window, x: ?*u32, y: ?*u32) void {
        const win = self.toIntern();
        c.glfwGetWindowPos(win.ptr, @ptrCast(x), @ptrCast(y));
    }
    pub fn setPosition(self: *Window, x: u32, y: u32) void {
        const win = self.toIntern();
        c.glfwSetWindowPos(win.ptr, @intCast(x), @intCast(y));
    }

    pub fn getSize(self: *Window, w: ?*u32, h: ?*u32) void {
        const win = self.toIntern();
        c.glfwGetWindowSize(win.ptr, @ptrCast(w), @ptrCast(h));
    }
    pub fn setSize(self: *Window, w: u32, h: u32) void {
        const win = self.toIntern();
        c.glfwSetWindowSize(win.ptr, @intCast(w), @intCast(h));
    }

    pub fn getTitle(self: *Window) []const u8 {
        const win = self.toIntern();
        _ = win; // autofix
        return self.toIntern().title;
    }
    pub fn setTitle(self: *Window, title: []const u8) Error!void {
        const win = self.toIntern();
        if (title == win.title) return;

        const allocator = win.allocator;

        const title_copy = utils.copy(
            u8,
            title,
            allocator.alloc(u8, title.len + 1) catch return Error.OutOfMemory,
        );
        title_copy[title.len] = 0;

        c.glfwSetWindowTitle(win.ptr, title_copy[0..title.len :0]);

        allocator.free(win.title);
        win.title = title_copy;
    }

    pub fn setResizable(self: *Window, resiziable: bool, errStr: ?*[]const u8) Error!void {
        const win = self.toIntern();

        const hint = &win.hint;
        hint.resizable = resiziable;

        windowHint(hint.*);
        c.glfwWindowHint(c.GLFW_VISIBLE, c.GLFW_FALSE);
        var width: u32 = 0;
        var height: u32 = 0;
        win.getSize(&width, &height);
        const ptr = c.glfwCreateWindow(@intCast(width), @intCast(height), win.title.ptr, null, null) orelse
            return getError(errStr);
        _ = c.glfwSetCursorPosCallback(ptr, mouseCallback);
        _ = c.glfwSetKeyCallback(ptr, keyCallback);
        var x: u32 = 0;
        var y: u32 = 0;
        self.getPosition(&x, &y);
        c.glfwSetWindowPos(ptr, @intCast(x), @intCast(y));
        c.glfwDestroyWindow(win.ptr);
        win.ptr = ptr;
        self.show();
        if (self == current)
            self.makeCurrentContext();
    }

    pub fn setInputMode(self: *Window, mode: InputMode, value: bool) void {
        const win = self.toIntern();
        c.glfwSetInputMode(win.ptr, inputMode2Glfw(mode), @intFromBool(value));
    }
    pub fn getInputMode(self: *Window, mode: InputMode) bool {
        const win = self.toIntern();
        return c.glfwGetInputMode(win.ptr, inputMode2Glfw(mode)) == c.GLFW_TRUE;
    }

    pub fn setCursorInputMode(self: *Window, value: CursorInputMode) void {
        const win = self.toIntern();
        c.glfwSetInputMode(win.ptr, c.GLFW_CURSOR, switch (value) {
            .Normal => c.GLFW_CURSOR_NORMAL,
            .Hidden => c.GLFW_CURSOR_HIDDEN,
            .Disabled => c.GLFW_CURSOR_DISABLED,
        });
    }
    pub fn getCursorInputMode(self: *Window) CursorInputMode {
        const win = self.toIntern();
        return switch (c.glfwGetInputMode(win.ptr, c.GLFW_CURSOR)) {
            c.GLFW_CURSOR_NORMAL => .Normal,
            c.GLFW_CURSOR_HIDDEN => .Hidden,
            c.GLFW_CURSOR_DISABLED => .Disabled,
            else => unreachable,
        };
    }

    pub fn setCursor(self: *Window, cursor: Cursor) void {
        c.glfwSetCursor(self.toIntern().ptr, cursor.toIntern().ptr);
    }
    pub fn setIcon(self: *Window, icon: Image) void {
        const img = c.GLFWimage{
            .width = @intCast(icon.width),
            .height = @intCast(icon.height),
            .pixels = @ptrCast(icon.pixels.ptr),
        };
        c.glfwSetWindowIcon(self.toIntern().ptr, 1, @ptrCast(&img));
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

        c.glfwSetWindowIcon(self.toIntern().ptr, icons.len, imgs);
    }

    pub fn getMousePos(self: *Window, x: ?*f64, y: ?*f64) void {
        c.glfwGetCursorPos(self.toIntern().ptr, @ptrCast(&x), @ptrCast(&y));
    }
    pub fn getMouseButton(self: *Window, button: u32) bool {
        return c.glfwGetMouseButton(self.toIntern().ptr, @intCast(button)) == c.GLFW_PRESS;
    }
    pub fn getKey(self: *Window, key: Key) bool {
        return c.glfwGetKey(self.toIntern().ptr, switch (key) {
            .Unknown => return false,
            .Space => c.GLFW_KEY_SPACE,
            .Apostrophe => c.GLFW_KEY_APOSTROPHE,
            .Comma => c.GLFW_KEY_COMMA,
            .Minus => c.GLFW_KEY_MINUS,
            .Period => c.GLFW_KEY_PERIOD,
            .Slash => c.GLFW_KEY_SLASH,
            .@"0" => c.GLFW_KEY_0,
            .@"1" => c.GLFW_KEY_1,
            .@"2" => c.GLFW_KEY_2,
            .@"3" => c.GLFW_KEY_3,
            .@"4" => c.GLFW_KEY_4,
            .@"5" => c.GLFW_KEY_5,
            .@"6" => c.GLFW_KEY_6,
            .@"7" => c.GLFW_KEY_7,
            .@"8" => c.GLFW_KEY_8,
            .@"9" => c.GLFW_KEY_9,
            .Semicolon => c.GLFW_KEY_SEMICOLON,
            .Equal => c.GLFW_KEY_EQUAL,
            .A => c.GLFW_KEY_A,
            .B => c.GLFW_KEY_B,
            .C => c.GLFW_KEY_C,
            .D => c.GLFW_KEY_D,
            .E => c.GLFW_KEY_E,
            .F => c.GLFW_KEY_F,
            .G => c.GLFW_KEY_G,
            .H => c.GLFW_KEY_H,
            .I => c.GLFW_KEY_I,
            .J => c.GLFW_KEY_J,
            .K => c.GLFW_KEY_K,
            .L => c.GLFW_KEY_L,
            .M => c.GLFW_KEY_M,
            .N => c.GLFW_KEY_N,
            .O => c.GLFW_KEY_O,
            .P => c.GLFW_KEY_P,
            .Q => c.GLFW_KEY_Q,
            .R => c.GLFW_KEY_R,
            .S => c.GLFW_KEY_S,
            .T => c.GLFW_KEY_T,
            .U => c.GLFW_KEY_U,
            .V => c.GLFW_KEY_V,
            .W => c.GLFW_KEY_W,
            .X => c.GLFW_KEY_X,
            .Y => c.GLFW_KEY_Y,
            .Z => c.GLFW_KEY_Z,
            .LeftBracket => c.GLFW_KEY_LEFT_BRACKET,
            .Backslash => c.GLFW_KEY_BACKSLASH,
            .RightBracket => c.GLFW_KEY_RIGHT_BRACKET,
            .GraveAccent => c.GLFW_KEY_GRAVE_ACCENT,
            .World1 => c.GLFW_KEY_WORLD_1,
            .World2 => c.GLFW_KEY_WORLD_2,
            .Escape => c.GLFW_KEY_ESCAPE,
            .Enter => c.GLFW_KEY_ENTER,
            .Tab => c.GLFW_KEY_TAB,
            .Backspace => c.GLFW_KEY_BACKSPACE,
            .Insert => c.GLFW_KEY_INSERT,
            .Delete => c.GLFW_KEY_DELETE,
            .Right => c.GLFW_KEY_RIGHT,
            .Left => c.GLFW_KEY_LEFT,
            .Down => c.GLFW_KEY_DOWN,
            .Up => c.GLFW_KEY_UP,
            .PageUp => c.GLFW_KEY_PAGE_UP,
            .PageDown => c.GLFW_KEY_PAGE_DOWN,
            .Home => c.GLFW_KEY_HOME,
            .End => c.GLFW_KEY_END,
            .CapsLock => c.GLFW_KEY_CAPS_LOCK,
            .ScrollLock => c.GLFW_KEY_SCROLL_LOCK,
            .NumLock => c.GLFW_KEY_NUM_LOCK,
            .PrintScreen => c.GLFW_KEY_PRINT_SCREEN,
            .Pause => c.GLFW_KEY_PAUSE,
            .F1 => c.GLFW_KEY_F1,
            .F2 => c.GLFW_KEY_F2,
            .F3 => c.GLFW_KEY_F3,
            .F4 => c.GLFW_KEY_F4,
            .F5 => c.GLFW_KEY_F5,
            .F6 => c.GLFW_KEY_F6,
            .F7 => c.GLFW_KEY_F7,
            .F8 => c.GLFW_KEY_F8,
            .F9 => c.GLFW_KEY_F9,
            .F10 => c.GLFW_KEY_F10,
            .F11 => c.GLFW_KEY_F11,
            .F12 => c.GLFW_KEY_F12,
            .F13 => c.GLFW_KEY_F13,
            .F14 => c.GLFW_KEY_F14,
            .F15 => c.GLFW_KEY_F15,
            .F16 => c.GLFW_KEY_F16,
            .F17 => c.GLFW_KEY_F17,
            .F18 => c.GLFW_KEY_F18,
            .F19 => c.GLFW_KEY_F19,
            .F20 => c.GLFW_KEY_F20,
            .F21 => c.GLFW_KEY_F21,
            .F22 => c.GLFW_KEY_F22,
            .F23 => c.GLFW_KEY_F23,
            .F24 => c.GLFW_KEY_F24,
            .F25 => c.GLFW_KEY_F25,
            .Kp0 => c.GLFW_KEY_KP_0,
            .Kp1 => c.GLFW_KEY_KP_1,
            .Kp2 => c.GLFW_KEY_KP_2,
            .Kp3 => c.GLFW_KEY_KP_3,
            .Kp4 => c.GLFW_KEY_KP_4,
            .Kp5 => c.GLFW_KEY_KP_5,
            .Kp6 => c.GLFW_KEY_KP_6,
            .Kp7 => c.GLFW_KEY_KP_7,
            .Kp8 => c.GLFW_KEY_KP_8,
            .Kp9 => c.GLFW_KEY_KP_9,
            .KpDecimal => c.GLFW_KEY_KP_DECIMAL,
            .KpDivide => c.GLFW_KEY_KP_DIVIDE,
            .KpMultiply => c.GLFW_KEY_KP_MULTIPLY,
            .KpSubtract => c.GLFW_KEY_KP_SUBTRACT,
            .KpAdd => c.GLFW_KEY_KP_ADD,
            .KpEnter => c.GLFW_KEY_KP_ENTER,
            .KpEqual => c.GLFW_KEY_KP_EQUAL,
            .LeftShift => c.GLFW_KEY_LEFT_SHIFT,
            .LeftControl => c.GLFW_KEY_LEFT_CONTROL,
            .LeftAlt => c.GLFW_KEY_LEFT_ALT,
            .LeftSuper => c.GLFW_KEY_LEFT_SUPER,
            .RightShift => c.GLFW_KEY_RIGHT_SHIFT,
            .RightControl => c.GLFW_KEY_RIGHT_CONTROL,
            .RightAlt => c.GLFW_KEY_RIGHT_ALT,
            .RightSuper => c.GLFW_KEY_RIGHT_SUPER,
            .Menu => c.GLFW_KEY_MENU,
        }) == c.GLFW_PRESS;
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
        const win = self.toIntern();
        _ = win; // autofix
        return self.toIntern().dropCallback;
    }
};

const WindowInternal = struct {
    allocator: Allocator,
    ptr: *c.GLFWwindow,
    title: [:0]const u8,
    hint: WindowHint,

    mouseCallback: ?MousePosCallback = null,
    buttonCallback: ?ButtonCallback = null,
    keyCallback: ?KeyCallback = null,
    charCallback: ?CharCallback = null,
    enterCallback: ?EnterCallback = null,
    scrollCallback: ?ScrollCallback = null,
    dropCallback: ?DropCallback = null,

    pub fn toExtern(self: *WindowInternal) *Window {
        return @ptrCast(@alignCast(self));
    }
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

pub const StandardCursor = enum {
    Arrow,
    IBeam,
    Crosshair,
    Hand,
    HResize,
    VResize,
};

inline fn stdCur2Glfw(cursor: StandardCursor) c_int {
    return switch (cursor) {
        .Arrow => c.GLFW_ARROW_CURSOR,
        .IBeam => c.GLFW_IBEAM_CURSOR,
        .Crosshair => c.GLFW_CROSSHAIR_CURSOR,
        .Hand => c.GLFW_HAND_CURSOR,
        .HResize => c.GLFW_HRESIZE_CURSOR,
        .VResize => c.GLFW_VRESIZE_CURSOR,
    };
}

pub const Cursor = opaque {
    fn toIntern(self: *Cursor) *CursorInternal {
        return @ptrCast(@alignCast(self));
    }

    pub fn createStandard(allocator: Allocator, cursor: StandardCursor, errStr: ?*[]const u8) Error!*Cursor {
        const ptr = c.glfwCreateStandardCursor(stdCur2Glfw(cursor)) orelse
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

    pub fn toExtern(self: *CursorInternal) *Cursor {
        return @ptrCast(@alignCast(self));
    }
};
