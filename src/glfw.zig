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
pub const KeyCallback = *const fn (window: *Window, key: Key, action: Key.Action, mods: Key.Mods) anyerror!void;

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

var pollErr: ?anyerror = null;

pub fn pollEvents() anyerror!void {
    c.glfwPollEvents();
    if (pollErr) |err| {
        pollErr = null;
        return err;
    }
}

const dontCare: u32 = @truncate(-1);

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
    refreshRate: u32 = dontCare,
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

pub const Window = struct {
    var current: ?*Window = null;
    var windows: ?std.ArrayList(Window) = null;
    allocator: Allocator,
    ptr: *c.GLFWwindow,
    title: [:0]const u8,
    hint: WindowHint,
    mouseCallback: ?MousePosCallback = null,
    keyCallback: ?KeyCallback = null,

    fn mouseCallback(window: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
        const win = windowFromGlfw(window.?);
        if (win.mouseCallback) |f| {
            f(win, x, y) catch |e| {
                pollErr = e;
            };
        }
    }
    fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
        _ = scancode;
        const win = windowFromGlfw(window.?);
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
                win,
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
                    c.GLFW_REPEAT => Key.Action.Repeat,
                    else => Key.Action.Pressed,
                },
                kMods,
            ) catch |e| {
                pollErr = e;
            };
        }
    }

    fn windowFromGlfw(window: *c.GLFWwindow) *Window {
        if (windows == null) @panic("No registered window");
        for (windows.?.items) |*item| {
            if (item.ptr == window) return item;
        }
        terminate();
        windows.?.deinit();
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
        _ = c.glfwSetKeyCallback(ptr, &keyCallback);
        const window = Window{
            .allocator = allocator,
            .ptr = ptr,
            .title = title_copy[0..title.len :0],
            .hint = hint,
        };
        if (windows == null)
            windows = std.ArrayList(Window).init(allocator);
        const winPtr = windows.?.addOne() catch return Error.OutOfMemory;
        winPtr.* = window;
        c.glfwMakeContextCurrent(ptr);
        c.glfwSwapInterval(@intFromBool(hint.vsync));
        if (current) |curr| curr.makeCurrentContext();
        return winPtr;
    }
    pub fn destroy(self: *Window) void {
        if (windows == null)
            return;
        const wArr = windows.?;
        const allocator = self.allocator;

        allocator.free(self.title);
        c.glfwDestroyWindow(self.ptr);

        self.* = undefined;
        if (wArr.items.len <= 1) {
            wArr.deinit();
            windows = null;
        }
    }

    pub fn makeCurrentContext(self: *Window) void {
        if (current == self)
            return;
        c.glfwMakeContextCurrent(self.ptr);
        current = self;
    }

    pub fn setVSync(self: *Window, vsync: bool) void {
        self.hint.vsync = vsync;
        if (current != self) c.glfwMakeContextCurrent(self.ptr);
        c.glfwSwapInterval(@intFromBool(vsync));
        if (current != self)
            if (current) |curr| c.glfwMakeContextCurrent(curr.ptr);
    }

    pub fn swapBuffers(self: *Window) void {
        c.glfwSwapBuffers(self.ptr);
    }
    pub fn shouldClose(self: *Window) bool {
        return c.glfwWindowShouldClose(self.ptr) == c.GLFW_TRUE;
    }

    pub fn show(self: *Window) void {
        c.glfwShowWindow(self.ptr);
        self.hint.visible = true;
    }
    pub fn hide(self: *Window) void {
        c.glfwHideWindow(self.ptr);
        self.hint.visible = false;
    }

    pub fn getPosition(self: *Window, x: ?*u32, y: ?*u32) void {
        c.glfwGetWindowPos(self.ptr, @ptrCast(x), @ptrCast(y));
    }
    pub fn setPosition(self: *Window, x: u32, y: u32) void {
        c.glfwSetWindowPos(self.ptr, @intCast(x), @intCast(y));
    }

    pub fn getSize(self: *Window, w: ?*u32, h: ?*u32) void {
        c.glfwGetWindowSize(self.ptr, @ptrCast(w), @ptrCast(h));
    }
    pub fn setSize(self: *Window, w: u32, h: u32) void {
        c.glfwSetWindowSize(self.ptr, @intCast(w), @intCast(h));
    }

    pub fn getTitle(self: *Window) []const u8 {
        return self.title;
    }
    pub fn setTitle(self: *Window, title: []const u8) Error!void {
        if (title == self.title) return;

        const allocator = self.allocator;

        const title_copy = utils.copy(
            u8,
            title,
            self.allocator.alloc(u8, title.len + 1) catch return Error.OutOfMemory,
        );
        title_copy[title.len] = 0;

        c.glfwSetWindowTitle(self.ptr, title_copy[0..title.len :0]);

        allocator.free(self.title);
        self.title = title_copy;
    }
    pub fn setResizable(self: *Window, resiziable: bool, errStr: ?*[]const u8) Error!void {
        const hint = &self.hint;
        hint.resizable = resiziable;

        windowHint(hint.*);
        c.glfwWindowHint(c.GLFW_VISIBLE, c.GLFW_FALSE);
        var width: u32 = 0;
        var height: u32 = 0;
        self.getSize(&width, &height);
        const ptr = c.glfwCreateWindow(@intCast(width), @intCast(height), self.title.ptr, null, null) orelse
            return getError(errStr);
        _ = c.glfwSetCursorPosCallback(ptr, mouseCallback);
        _ = c.glfwSetKeyCallback(ptr, keyCallback);
        var x: u32 = 0;
        var y: u32 = 0;
        self.getPosition(&x, &y);
        c.glfwSetWindowPos(ptr, @intCast(x), @intCast(y));
        c.glfwDestroyWindow(self.ptr);
        self.ptr = ptr;
        self.show();
        if (current == self)
            self.makeCurrentContext();
    }

    pub fn setMouseCallback(self: *Window, cb: MousePosCallback) void {
        self.mouseCallback = cb;
    }
    pub fn getMouseCallback(self: *Window) MousePosCallback {
        return self.mouseCallback;
    }

    pub fn setKeyCallback(self: *Window, cb: KeyCallback) void {
        self.keyCallback = cb;
    }
    pub fn getKeyCallback(self: *Window) KeyCallback {
        return self.keyCallback;
    }
};
