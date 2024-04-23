const std = @import("std");

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// glfw opaque types

/// Opaque monitor object.
/// 
/// **Since** 3.0
pub const GLFWmonitor = opaque {};
/// Opaque window object.
/// 
/// **Since** 3.0
pub const GLFWwindow = opaque {};
/// Opaque cursor object.
/// 
/// **Since** 3.1
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga89261ae18c75e863aaf2656ecdd238f4
pub const GLFWcursor = opaque {};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// glfw function types

pub const GLFWglproc = ?*const fn () callconv(.C) void;
pub const GLFWvkproc = ?*const fn () callconv(.C) void;
/// The function pointer type for memory allocation callbacks.
/// 
/// This function must return either a memory block at least size bytes long, or null if allocation failed. Note that not all parts of GLFW handle allocation failures gracefully yet.
/// 
/// This function must support being called during `glfwInit` but before the library is flagged as initialized, as well as during `glfwTerminate` after the library is no longer flagged as initialized.
/// 
/// Any memory allocated via this function will be deallocated via the same allocator during library termination or earlier.
/// 
/// Any memory allocated via this function must be suitably aligned for any object type. If you are using C99 or earlier, this alignment is platform-dependent but will be the same as what malloc provides. If you are using C11 or later, this is the value of alignof(max_align_t).
/// 
/// The size will always be greater than zero. Allocations of size zero are filtered out before reaching the custom allocator.
/// 
/// If this function returns null, GLFW will emit `GLFW_OUT_OF_MEMORY`.
/// 
/// This function must not call any GLFW function.
/// 
/// **Parameters**:
/// - [in] size: The minimum size, in bytes, of the memory block.
/// - [in] user: The user-defined pointer from the allocator.
/// 
/// **Returns**: The address of the newly allocated memory block, or null if an error occurred.
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga4306a564e9f60f4de8cc8f31731a3120
pub const GLFWallocatefun = ?*const fn (size: usize, user: ?*anyopaque) callconv(.C) ?*anyopaque;
/// The function pointer type for memory reallocation callbacks.
/// 
/// This function must return a memory block at least size bytes long, or null if allocation failed. Note that not all parts of GLFW handle allocation failures gracefully yet.
///
/// This function must support being called during `glfwInit` but before the library is flagged as initialized, as well as during `glfwTerminate` after the library is no longer flagged as initialized.
/// 
/// Any memory allocated via this function will be deallocated via the same allocator during library termination or earlier.
/// 
/// Any memory allocated via this function must be suitably aligned for any object type. If you are using C99 or earlier, this alignment is platform-dependent but will be the same as what realloc provides. If you are using C11 or later, this is the value of alignof(max_align_t).
/// 
/// The block address will never be null and the size will always be greater than zero. Reallocations of a block to size zero are converted into deallocations before reaching the custom allocator. Reallocations of null to a non-zero size are converted into regular allocations before reaching the custom allocator.
/// 
/// If this function returns null, GLFW will emit `GLFW_OUT_OF_MEMORY`.
/// 
/// This function must not call any GLFW function.
/// 
/// **Parameters**:
/// - [in] block: The address of the memory block to reallocate.
/// - [in] size: The new minimum size, in bytes, of the memory block.
/// - [in] user: The user-defined pointer from the allocator.
/// 
/// **Returns**: The address of the newly allocated or resized memory block, or NULL if an error occurred.
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga3e88a829615d8efe8bec1746f7309c63
pub const GLFWreallocatefun = ?*const fn (block: ?*anyopaque, size: usize, user: ?*anyopaque) callconv(.C) ?*anyopaque;
/// The function pointer type for memory deallocation callbacks.
/// 
/// This function may deallocate the specified memory block. This memory block will have been allocated with the same allocator.
/// 
/// This function must support being called during `glfwInit` but before the library is flagged as initialized, as well as during `glfwTerminate` after the library is no longer flagged as initialized.
/// 
/// The block address will never be null. Deallocations of null are filtered out before reaching the custom allocator.
/// 
/// If this function returns null, GLFW will emit `GLFW_OUT_OF_MEMORY`.
/// 
/// This function must not call any GLFW function.
/// 
/// **Parameters**:
/// - [in] block: The address of the memory block to deallocate.
/// - [in] user: The user-defined pointer from the allocator.
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga7181615eda94c4b07bd72bdcee39fa28
pub const GLFWdeallocatefun = ?*const fn (block: ?*anyopaque, user: ?*anyopaque) callconv(.C) void;
/// The function pointer type for error callbacks.
/// 
/// **Parameters**:
/// - [in] error_code: An error code. Future releases may add more error codes.
/// - [in] description: A UTF-8 encoded string describing the error.
/// 
/// **Since** 3.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga8184701785c096b3862a75cda1bf44a3
pub const GLFWerrorfun = ?*const fn (err_code: c_int, description: [*]const u8) callconv(.C) void;
pub const GLFWwindowposfun = ?*const fn (?*GLFWwindow, c_int, c_int) callconv(.C) void;
pub const GLFWwindowsizefun = ?*const fn (?*GLFWwindow, c_int, c_int) callconv(.C) void;
pub const GLFWwindowclosefun = ?*const fn (?*GLFWwindow) callconv(.C) void;
pub const GLFWwindowrefreshfun = ?*const fn (?*GLFWwindow) callconv(.C) void;
pub const GLFWwindowfocusfun = ?*const fn (?*GLFWwindow, c_int) callconv(.C) void;
pub const GLFWwindowiconifyfun = ?*const fn (?*GLFWwindow, c_int) callconv(.C) void;
pub const GLFWwindowmaximizefun = ?*const fn (?*GLFWwindow, c_int) callconv(.C) void;
pub const GLFWframebuffersizefun = ?*const fn (?*GLFWwindow, c_int, c_int) callconv(.C) void;
pub const GLFWwindowcontentscalefun = ?*const fn (?*GLFWwindow, f32, f32) callconv(.C) void;
/// The function pointer type for mouse button callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window taht received the event
/// - [in] button: The mouse button that was pressed or released
/// - [in] action: On of `GLFW_PRESS`, `GLFW_RELEASE`, `GLFW_REPEAT`, Future released may add more actions.
/// - [in] mods: Bit field describing which modifier keys were held down.
/// 
/// **Since** 1.0. GLFW 3: Added window handle and modifier mask parameters.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga0184dcb59f6d85d735503dcaae809727
pub const GLFWmousebuttonfun = ?*const fn (?*GLFWwindow, c_int, c_int, c_int) callconv(.C) void;
/// The function pointer type for cursor position callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] xpos: The new cursor x-coordinate, relative to the left edge of the content area.
/// - [in] ypos: The new cursor y-coordinate, relative to the top edge of the content area.
/// 
/// **Since** 3.0. Replaces `GLFWmouseposfun`.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gad6fae41b3ac2e4209aaa87b596c57f68
pub const GLFWcursorposfun = ?*const fn (?*GLFWwindow, f64, f64) callconv(.C) void;
/// The function pointer type for cursor enter/leave callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] entered: GLFW_TRUE if the cursor entered the window's content area, or GLFW_FALSE if it left it.
/// 
/// **Since** 3.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gaa93dc4818ac9ab32532909d53a337cbe
pub const GLFWcursorenterfun = ?*const fn (?*GLFWwindow, c_int) callconv(.C) void;
/// The function pointer type for scroll callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] xoffset: The scroll offset along the x-axis.
/// - [in] yoffset: The scroll offset along the y-axis.
/// 
/// **Since** 3.0. Replaces `GLFWmousewheelfun`.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gaf656112c33de3efdb227fa58f0134cf5
pub const GLFWscrollfun = ?*const fn (?*GLFWwindow, f64, f64) callconv(.C) void;
/// The function pointer type for keyboard key callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] key: The keyboard key that was pressed or released.
/// - [in] scancode: The platform-specific scancode of the key.
/// - [in] action: GLFW_PRESS, GLFW_RELEASE or GLFW_REPEAT. Future releases may add more actions.
/// - [in] mods: Bit field describing which modifier keys were held down
/// 
/// **Since** 1.0. GLFW 3: Added window handle, scancode and modifier mask parameters.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga5bd751b27b90f865d2ea613533f0453c
pub const GLFWkeyfun = ?*const fn (?*GLFWwindow, c_int, c_int, c_int, c_int) callconv(.C) void;
/// The function pointer type for Unicode character callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] codepoint: The Unicode code point of the character
/// 
/// **Since** 2.4. GLFW 3: Added window handle parameter.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga1ab90a55cf3f58639b893c0f4118cb6e
pub const GLFWcharfun = ?*const fn (?*GLFWwindow, c_uint) callconv(.C) void;
/// # Deprecated
/// **Scheduled for removal in version 4.0.**
/// 
/// The function pointer type for Unicode character with modifiers callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] codepoint: The Unicode code point of the character.
/// - [in] mods: Bit field describing which modifier keys were held down.
/// 
/// **Since** 3.1
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gac3cf64f90b6219c05ac7b7822d5a4b8f
pub const GLFWcharmodsfun = ?*const fn (?*GLFWwindow, c_uint, c_int) callconv(.C) void;
/// The function pointer type for path drop callbacks.
/// 
/// **Parameters**:
/// - [in] window: The window that received the event.
/// - [in] path_count: The number of dropped paths.
/// - [in] paths: The UTF-8 encoded file and/or directory path names.
/// 
/// **Since** 3.1
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gaaba73c3274062c18723b7f05862d94b2
pub const GLFWdropfun = ?*const fn (?*GLFWwindow, c_int, [*]const [*]const u8) callconv(.C) void;
pub const GLFWmonitorfun = ?*const fn (?*GLFWmonitor, c_int) callconv(.C) void;
/// The function pointer type for joystick configuration callbacks.
/// 
/// **Parameters**:
/// - [in] jid: The joystick that was connected or disconnected.
/// - [in] event: One of GLFW_CONNECTED or GLFW_DISCONNECTED. Future releases may add more events.
/// 
/// **Since** 3.2
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gaa21ad5986ae9a26077a40142efb56243
pub const GLFWjoystickfun = ?*const fn (c_int, c_int) callconv(.C) void;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// glfw structures

pub const GLFWvidmode = extern struct {
    width: c_int,
    height: c_int,
    redBits: c_int,
    greenBits: c_int,
    blueBits: c_int,
    refreshRate: c_int,
};
pub const GLFWgammaramp = extern struct {
    red: [*]c_ushort,
    green: [*]c_ushort,
    blue: [*]c_ushort,
    size: c_uint = 0,
};
pub const GLFWimage = extern struct {
    width: c_int,
    height: c_int,
    pixels: [*]u8,
};
/// Gamepad input state.
/// 
/// **Since** 3.3
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga61acfb1f28f751438dd221225c5e725d
pub const GLFWgamepadstate = extern struct {
    buttons: [15]u8 = std.mem.zeroes([15]u8),
    axes: [6]f32 = std.mem.zeroes([6]f32),
};
/// Custom heap memory allocator.
/// 
/// This describes a custom heap memory allocator for GLFW. To set an allocator, pass it to `glfwInitAllocator` before initializing the library.
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga145c57d7f2aeda0b704a5a4ba1d6104b 
pub const GLFWallocator = extern struct {
    allocate: GLFWallocatefun = null,
    reallocate: GLFWreallocatefun = null,
    deallocate: GLFWdeallocatefun = null,
    user: ?*anyopaque = null,
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// glfw functions

/// Initializes the GLFW library.
///
/// This function initializes the GLFW library. Before most GLFW functions can be used, GLFW must be initialized, and before an application terminates GLFW should be terminated in order to free any resources allocated during or after initialization.
/// 
/// If this function fails, it calls `glfwTerminate` before returning. If it succeeds, you should call `glfwTerminate` before the application exits.
/// 
/// Additional calls to this function after successful initialization but before termination will return GLFW_TRUE immediately.
/// 
/// The `GLFW_PLATFORM` init hint controls which platforms are considered during initialization. This also depends on which platforms the library was compiled to support.
/// 
/// **Returns**: `GLFW_TRUE` if successful, or `GLFW_FALSE` if an error occurred.
/// 
/// **Errors**:
/// - `GLFW_PLATFORM_UNAVAILABLE`
/// - `GLFW_PLATFORM_ERROR`
/// 
/// **Remarks**:
/// - **macOS**: This function will change the current directory of the application to the Contents/Resources subdirectory of the application's bundle, if present. This can be disabled with the `GLFW_COCOA_CHDIR_RESOURCES` init hint.
/// - **macOS**: This function will create the main menu and dock icon for the application. If GLFW finds a MainMenu.nib it is loaded and assumed to contain a menu bar. Otherwise a minimal menu bar is created manually with common commands like Hide, Quit and About. The About entry opens a minimal about dialog with information from the application's bundle. The menu bar and dock icon can be disabled entirely with the `GLFW_COCOA_MENUBAR` init hint.
/// - **Wayland, X11**: If the library was compiled with support for both Wayland and X11, and the `GLFW_PLATFORM` init hint is set to `GLFW_ANY_PLATFORM`, the XDG_SESSION_TYPE environment variable affects which platform is picked. If the environment variable is not set, or is set to something other than wayland or x11, the regular detection mechanism will be used instead.
/// - **X11**: This function will set the LC_CTYPE category of the application locale according to the current environment if that category is still "C". This is because the "C" locale breaks Unicode text input.
/// 
/// **Since** 1.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga317aac130a235ab08c6db0834907d85e
pub extern fn glfwInit() c_int;
/// Terminates the GLFW library.
///
/// This function destroys all remaining windows and cursors, restores any modified gamma ramps and frees any other allocated resources. Once this function is called, you must again call glfwInit successfully before you will be able to use most GLFW functions.
/// 
/// If GLFW has been successfully initialized, this function should be called before the application exits. If initialization fails, there is no need to call this function, as it is called by glfwInit before it returns failure.
/// 
/// This function has no effect if GLFW is not initialized.
/// 
/// **Errors**:
/// - `GLFW_PLATFORM_ERROR`
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **Since** 1.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#gaaae48c0a18607ea4a4ba951d939f0901
pub extern fn glfwTerminate() void;
/// Sets the specified init hint to the desired value.
/// 
/// This function sets hints for the next initialization of GLFW.
/// 
/// The values you set hints to are never reset by GLFW, but they only take effect during initialization. Once GLFW has been initialized, any values you set will be ignored until the library is terminated and initialized again.
/// 
/// Some hints are platform specific. These may be set on any platform but they will only affect their specific platform. Other platforms will ignore them. Setting these hints requires no platform specific headers or functions.
/// 
/// **Parameters**:
/// - [in] hint: The init hint to set.
/// - [in] value: The new value of the init hint.
/// 
/// 
/// **Errors**:
/// - `GLFW_INVALID_ENUM`
/// - `GLFW_INVALID_VALUE`
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **Since** 3.3
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga110fd1d3f0412822b4f1908c026f724a
pub extern fn glfwInitHint(hint: c_int, value: c_int) void;
/// Sets the init allocator to the desired value.
/// 
/// To use the default allocator, call this function with a null argument.
/// 
/// If you specify an allocator struct, every member must be a valid function pointer. If any member is null, this function will emit `GLFW_INVALID_VALUE` and the init allocator will be unchanged.
/// 
/// The functions in the allocator must fulfil a number of requirements. See the documentation for `GLFWallocatefun`, `GLFWreallocatefun` and `GLFWdeallocatefun` for details.
/// 
/// **Parameters**:
/// - [in] allocator: The allocator to use at the next initialization, or null to use the default one.
/// 
/// **Errors**:
/// - `GLFW_INVALID_VALUE`
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga9dde93e9891fa7dd17e4194c9f3ae7c6
pub extern fn glfwInitAllocator(allocator: ?*const GLFWallocator) void;
/// Retrieves the version of the GLFW library.
/// 
/// This function retrieves the major, minor and revision numbers of the GLFW library. It is intended for when you are using GLFW as a shared library and want to ensure that you are using the minimum required version.
/// 
/// Any or all of the version arguments may be null.
/// 
/// **Parameters**:
/// - [out] major: Where to store the major version number, or null.
/// - [out] minor: Where to store the minor version number, or null.
/// - [out] rev: Where to store the revision number, or null.
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga9f8ffaacf3c269cc48eafbf8b9b71197
pub extern fn glfwGetVersion(major: ?*c_int, minor: ?*c_int, rev: ?*c_int) void;
/// Returns a string describing the compile-time configuration.
/// 
/// This function returns the compile-time generated version string of the GLFW library binary. It describes the version, platforms, compiler and any platform or operating system specific compile-time options. It should not be confused with the OpenGL or OpenGL ES version string, queried with glGetString.
/// 
/// Do not use the version string to parse the GLFW library version. The glfwGetVersion function provides the version of the running library binary in numerical format.
/// 
/// **Returns**: The ASCII encoded GLFW version string.
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga026abd003c8e6501981ab1662062f1c0
pub extern fn glfwGetVersionString() [*]const u8;
/// Returns and clears the last error for the calling thread.
/// 
/// This function returns and clears the error code of the last error that occurred on the calling thread, and optionally a UTF-8 encoded human-readable description of it. If no error has occurred since the last call, it returns `GLFW_NO_ERROR` (zero) and the description pointer is set to null.
/// 
/// **Parameters**:
/// - [out] description: Where to store the error description pointer, or null.
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **Since**: 3.3
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga944986b4ec0b928d488141f92982aa18
pub extern fn glfwGetError(description: ?*[*]const u8) c_int;
/// Sets the error callback
/// 
/// This function sets the error callback, which is called with an error code and a human-readable description each time a GLFW error occurs.
/// 
/// The error code is set before the callback is called. Calling glfwGetError from the error callback will return the same value as the error code argument.
/// 
/// The error callback is called on the thread where the error occurred. If you are using GLFW from multiple threads, your error callback needs to be written accordingly.
/// 
/// Because the description string may have been generated specifically for that error, it is not guaranteed to be valid after the callback has returned. If you wish to use it after the callback returns, you need to make a copy.
/// 
/// Once set, the error callback remains set even after the library has been terminated.
/// 
/// **Parameters**:
/// - [in] callback: The new callbak, or null to remove the currently set callback
/// 
/// **Returns**: The previously set callback, or NULL if no callback was set.
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **Since**: 3.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#gaff45816610d53f0b83656092a4034f40
pub extern fn glfwSetErrorCallback(callback: GLFWerrorfun) GLFWerrorfun;
/// Returns the currently selected platform.
/// 
/// This function returns the platform that was selected during initialization. The returned value will be one of:
/// - `GLFW_PLATFORM_WIN32`
/// - `GLFW_PLATFORM_COCOA`
/// - `GLFW_PLATFORM_WAYLAND`
/// - `GLFW_PLATFORM_X11`
/// - `GLFW_PLATFORM_NULL`
/// 
/// **Returns**: The currently selected platform, or zero if an error occurred.
/// 
/// **Errors**:
/// - `GLFW_NOT_INITIALIZED`
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga6d6a983d38bd4e8fd786d7a9061d399e
pub extern fn glfwGetPlatform() c_int;
/// Returns whether the library includes support for the specified platform.
/// 
/// This function returns whether the library was compiled with support for the specified platform. The platform must be one of:
/// - `GLFW_PLATFORM_WIN32`
/// - `GLFW_PLATFORM_COCOA`
/// - `GLFW_PLATFORM_WAYLAND`
/// - `GLFW_PLATFORM_X11`
/// - `GLFW_PLATFORM_NULL`.
/// 
/// **Parameters**:
/// - [in] platform: The platform to query.
/// 
/// **Returns**: `GLFW_TRUE` if the platform is supported, or `GLFW_FALSE` otherwise.
/// 
/// **Errors**:
/// - `GLFW_INVALID_ENUM`
/// 
/// **Remarks**:
/// - This function may be called before `glfwInit`.
/// 
/// **Since** 3.4
/// 
/// **See** https://www.glfw.org/docs/3.4/group__init.html#ga8785d2b6b36632368d803e78079d38ed
pub extern fn glfwPlatformSupported(platform: c_int) c_int;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitors(count: ?*c_int) [*]?*GLFWmonitor;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetPrimaryMonitor() ?*GLFWmonitor;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorPos(monitor: ?*GLFWmonitor, xpos: ?*c_int, ypos: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorWorkarea(monitor: ?*GLFWmonitor, xpos: ?*c_int, ypos: ?*c_int, width: ?*c_int, height: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorPhysicalSize(monitor: ?*GLFWmonitor, widthMM: ?*c_int, heightMM: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorContentScale(monitor: ?*GLFWmonitor, xscale: ?*f32, yscale: ?*f32) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorName(monitor: ?*GLFWmonitor) [*]const u8;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetMonitorUserPointer(monitor: ?*GLFWmonitor, pointer: ?*anyopaque) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetMonitorUserPointer(monitor: ?*GLFWmonitor) ?*anyopaque;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetMonitorCallback(callback: GLFWmonitorfun) GLFWmonitorfun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetVideoModes(monitor: ?*GLFWmonitor, count: ?*c_int) [*]const GLFWvidmode;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetVideoMode(monitor: ?*GLFWmonitor) ?*const GLFWvidmode;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetGamma(monitor: ?*GLFWmonitor, gamma: f32) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetGammaRamp(monitor: ?*GLFWmonitor) ?*const GLFWgammaramp;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetGammaRamp(monitor: ?*GLFWmonitor, ramp: ?*const GLFWgammaramp) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwDefaultWindowHints() void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwWindowHint(hint: c_int, value: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwWindowHintString(hint: c_int, value: [*]const u8) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwCreateWindow(width: c_int, height: c_int, title: [*]const u8, monitor: ?*GLFWmonitor, share: ?*GLFWwindow) ?*GLFWwindow;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwDestroyWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwWindowShouldClose(window: ?*GLFWwindow) c_int;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowShouldClose(window: ?*GLFWwindow, value: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowTitle(window: ?*GLFWwindow, title: [*]const u8) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowIcon(window: ?*GLFWwindow, count: c_int, images: ?*const GLFWimage) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowPos(window: ?*GLFWwindow, xpos: ?*c_int, ypos: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowPos(window: ?*GLFWwindow, xpos: c_int, ypos: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowSize(window: ?*GLFWwindow, width: ?*c_int, height: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowSizeLimits(window: ?*GLFWwindow, minwidth: c_int, minheight: c_int, maxwidth: c_int, maxheight: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowAspectRatio(window: ?*GLFWwindow, numer: c_int, denom: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowSize(window: ?*GLFWwindow, width: c_int, height: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetFramebufferSize(window: ?*GLFWwindow, width: ?*c_int, height: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowFrameSize(window: ?*GLFWwindow, left: ?*c_int, top: ?*c_int, right: ?*c_int, bottom: ?*c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowContentScale(window: ?*GLFWwindow, xscale: ?*f32, yscale: ?*f32) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowOpacity(window: ?*GLFWwindow) f32;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowOpacity(window: ?*GLFWwindow, opacity: f32) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwIconifyWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwRestoreWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwMaximizeWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwShowWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwHideWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwFocusWindow(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwRequestWindowAttention(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowMonitor(window: ?*GLFWwindow) ?*GLFWmonitor;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowMonitor(window: ?*GLFWwindow, monitor: ?*GLFWmonitor, xpos: c_int, ypos: c_int, width: c_int, height: c_int, refreshRate: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowAttrib(window: ?*GLFWwindow, attrib: c_int) c_int;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowAttrib(window: ?*GLFWwindow, attrib: c_int, value: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowUserPointer(window: ?*GLFWwindow, pointer: ?*anyopaque) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetWindowUserPointer(window: ?*GLFWwindow) ?*anyopaque;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowPosCallback(window: ?*GLFWwindow, callback: GLFWwindowposfun) GLFWwindowposfun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowSizeCallback(window: ?*GLFWwindow, callback: GLFWwindowsizefun) GLFWwindowsizefun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowCloseCallback(window: ?*GLFWwindow, callback: GLFWwindowclosefun) GLFWwindowclosefun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowRefreshCallback(window: ?*GLFWwindow, callback: GLFWwindowrefreshfun) GLFWwindowrefreshfun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowFocusCallback(window: ?*GLFWwindow, callback: GLFWwindowfocusfun) GLFWwindowfocusfun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowIconifyCallback(window: ?*GLFWwindow, callback: GLFWwindowiconifyfun) GLFWwindowiconifyfun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowMaximizeCallback(window: ?*GLFWwindow, callback: GLFWwindowmaximizefun) GLFWwindowmaximizefun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetFramebufferSizeCallback(window: ?*GLFWwindow, callback: GLFWframebuffersizefun) GLFWframebuffersizefun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetWindowContentScaleCallback(window: ?*GLFWwindow, callback: GLFWwindowcontentscalefun) GLFWwindowcontentscalefun;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwPollEvents() void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwWaitEvents() void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwWaitEventsTimeout(timeout: f64) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwPostEmptyEvent() void;
/// Returns the value of an input option for the specified window.
/// 
/// This function returns the value of an input option for the specified window. The mode must be one of:
/// - `GLFW_CURSOR`
/// - `GLFW_STICKY_KEYS`
/// - `GLFW_STICKY_MOUSE_BUTTONS`
/// - `GLFW_LOCK_KEY_MODS`
/// - `GLFW_RAW_MOUSE_MOTION`
/// 
/// **Parameters**:
/// - [in] window: The window to query.
/// - [in] mode: One of:
///     - `GLFW_CURSOR`
///     - `GLFW_STICKY_KEYS`
///     - `GLFW_STICKY_MOUSE_BUTTONS`
///     - `GLFW_LOCK_KEY_MODS` 
///     - `GLFW_RAW_MOUSE_MOTION`
/// 
/// **Errors**:
/// - `GLFW_NOT_INITIALIZED`
/// - `GLFW_INVALID_ENUM`
/// 
/// **Since** 3.0
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gaf5b859dbe19bdf434e42695ea45cc5f4
pub extern fn glfwGetInputMode(window: ?*GLFWwindow, mode: c_int) c_int;
/// Sets an input option for the specified window.
/// 
/// This function sets an input mode option for the specified window. The mode must be one of:
/// - `GLFW_CURSOR`
/// - `GLFW_STICKY_KEYS`
/// - `GLFW_STICKY_MOUSE_BUTTONS`
/// - `GLFW_LOCK_KEY_MODS`
/// - `GLFW_RAW_MOUSE_MOTION`
/// 
/// If the mode is `GLFW_CURSOR`, the value must be one of the following cursor modes:
/// 
/// `GLFW_CURSOR_NORMAL` makes the cursor visible and behaving normally.
/// `GLFW_CURSOR_HIDDEN` makes the cursor invisible when it is over the content area of the window but does not restrict the cursor from leaving.
/// `GLFW_CURSOR_DISABLED` hides and grabs the cursor, providing virtual and unlimited cursor movement. This is useful for implementing for example 3D camera controls.
/// `GLFW_CURSOR_CAPTURED` makes the cursor visible and confines it to the content area of the window.
/// If the mode is `GLFW_STICKY_KEYS`, the value must be either `GLFW_TRUE` to enable sticky keys, or `GLFW_FALSE` to disable it. If sticky keys are enabled, a key press will ensure that `glfwGetKey` returns `GLFW_PRESS` the next time it is called even if the key had been released before the call. This is useful when you are only interested in whether keys have been pressed but not when or in which order.
/// 
/// If the mode is `GLFW_STICKY_MOUSE_BUTTONS`, the value must be either `GLFW_TRUE` to enable sticky mouse buttons, or `GLFW_FALSE` to disable it. If sticky mouse buttons are enabled, a mouse button press will ensure that `glfwGetMouseButton` returns `GLFW_PRESS` the next time it is called even if the mouse button had been released before the call. This is useful when you are only interested in whether mouse buttons have been pressed but not when or in which order.
/// 
/// If the mode is `GLFW_LOCK_KEY_MODS`, the value must be either `GLFW_TRUE` to enable lock key modifier bits, or `GLFW_FALSE` to disable them. If enabled, callbacks that receive modifier bits will also have the `GLFW_MOD_CAPS_LOCK` bit set when the event was generated with Caps Lock on, and the `GLFW_MOD_NUM_LOCK` bit when Num Lock was on.
/// 
/// If the mode is `GLFW_RAW_MOUSE_MOTION`, the value must be either `GLFW_TRUE` to enable raw (unscaled and unaccelerated) mouse motion when the cursor is disabled, or `GLFW_FALSE` to disable it. If raw motion is not supported, attempting to set this will emit `GLFW_FEATURE_UNAVAILABLE`. Call `glfwRawMouseMotionSupported` to check for support.
/// 
/// **Parameters**:
/// - [in] window: The window whose input mode to set.
/// - [in] mode: One of:
///     - `GLFW_CURSOR`
///     - `GLFW_STICKY_KEYS`
///     - `GLFW_STICKY_MOUSE_BUTTONS`
///     - `GLFW_LOCK_KEY_MODS`
///     - `GLFW_RAW_MOUSE_MOTION`
/// - [in] value: The new value of the specified input mode.
/// 
/// **Errors**:
/// - `GLFW_NOT_INITIALIZED`
/// - `GLFW_INVALID_ENUM`
/// - `GLFW_PLATFORM_ERROR`
/// - `GLFW_FEATURE_UNAVAILABLE`
/// 
/// **Since** 3.0, Replaces `glfwEnable` and `glfwDisable`.
/// 
/// **See** Sets an input option for the specified window.
pub extern fn glfwSetInputMode(window: ?*GLFWwindow, mode: c_int, value: c_int) void;
/// Returns whether raw mouse motion is supported.
/// 
/// **Since**
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gae4ee0dbd0d256183e1ea4026d897e1c2
pub extern fn glfwRawMouseMotionSupported() c_int;
/// Returns the layout-specific name of the specified printable key.
/// 
/// **Since**
/// 
/// **See** Returns the layout-specific name of the specified printable key.
pub extern fn glfwGetKeyName(key: c_int, scancode: c_int) [*]const u8;
/// Returns the platform-specific scancode of the specified key.
/// 
/// **Since**
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga67ddd1b7dcbbaff03e4a76c0ea67103a
pub extern fn glfwGetKeyScancode(key: c_int) c_int;
/// Returns the last reported state of a keyboard key for the specified window.
/// 
/// **Since**
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#gadd341da06bc8d418b4dc3a3518af9ad2
pub extern fn glfwGetKey(window: ?*GLFWwindow, key: c_int) c_int;
/// Returns the last reported state of a mouse button for the specified window.
/// 
/// **Since**
/// 
/// **See** Returns the last reported state of a mouse button for the specified window.
pub extern fn glfwGetMouseButton(window: ?*GLFWwindow, button: c_int) c_int;
/// Retrieves the position of the cursor relative to the content area of the window.
/// 
/// **Since**
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga01d37b6c40133676b9cea60ca1d7c0cc
pub extern fn glfwGetCursorPos(window: ?*GLFWwindow, xpos: ?*f64, ypos: ?*f64) void;
/// Sets the position of the cursor, relative to the content area of the window.
/// 
/// **Since**
/// 
/// **See** https://www.glfw.org/docs/3.4/group__input.html#ga04b03af936d906ca123c8f4ee08b39e7
pub extern fn glfwSetCursorPos(window: ?*GLFWwindow, xpos: f64, ypos: f64) void;
/// Creates a custom cursor.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwCreateCursor(image: ?*const GLFWimage, xhot: c_int, yhot: c_int) ?*GLFWcursor;
/// Creates a cursor with a standard shape.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwCreateStandardCursor(shape: c_int) ?*GLFWcursor;
/// Destroys a cursor.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwDestroyCursor(cursor: ?*GLFWcursor) void;
/// Sets the cursor for the window.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetCursor(window: ?*GLFWwindow, cursor: ?*GLFWcursor) void;
/// Sets the key callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetKeyCallback(window: ?*GLFWwindow, callback: GLFWkeyfun) GLFWkeyfun;
/// Sets the Unicode character callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetCharCallback(window: ?*GLFWwindow, callback: GLFWcharfun) GLFWcharfun;
/// Sets the Unicode character with modifiers callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetCharModsCallback(window: ?*GLFWwindow, callback: GLFWcharmodsfun) GLFWcharmodsfun;
/// Sets the mouse button callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetMouseButtonCallback(window: ?*GLFWwindow, callback: GLFWmousebuttonfun) GLFWmousebuttonfun;
/// Sets the cursor position callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetCursorPosCallback(window: ?*GLFWwindow, callback: GLFWcursorposfun) GLFWcursorposfun;
/// Sets the cursor enter/leave callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetCursorEnterCallback(window: ?*GLFWwindow, callback: GLFWcursorenterfun) GLFWcursorenterfun;
/// Sets the scroll callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetScrollCallback(window: ?*GLFWwindow, callback: GLFWscrollfun) GLFWscrollfun;
/// Sets the path drop callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetDropCallback(window: ?*GLFWwindow, callback: GLFWdropfun) GLFWdropfun;
/// Returns whether the specified joystick is present
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwJoystickPresent(jid: c_int) c_int;
/// Returns the values of all axes of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickAxes(jid: c_int, count: ?*c_int) [*]const f32;
/// Returns the state of all buttons of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickButtons(jid: c_int, count: ?*c_int) [*]const u8;
/// Returns the state of all hats of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickHats(jid: c_int, count: ?*c_int) [*]const u8;
/// Returns the name of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickName(jid: c_int) [*]const u8;
/// Returns the SDL compatible GUID of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickGUID(jid: c_int) [*]const u8;
/// Sets the user pointer of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetJoystickUserPointer(jid: c_int, pointer: ?*anyopaque) void;
/// Returns the user pointer of the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetJoystickUserPointer(jid: c_int) ?*anyopaque;
/// Returns whether the specified joystick has a gamepad mapping.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwJoystickIsGamepad(jid: c_int) c_int;
/// Sets the joystick configuration callback.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetJoystickCallback(callback: GLFWjoystickfun) GLFWjoystickfun;
/// Adds the specified SDL_GameControllerDB gamepad mappings.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwUpdateGamepadMappings(string: [*]const u8) c_int;
/// Returns the human-readable gamepad name for the specified joystick.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetGamepadName(jid: c_int) [*]const u8;
/// Retrieves the state of the specified joystick remapped as a gamepad.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetGamepadState(jid: c_int, state: [*]GLFWgamepadstate) c_int;
/// Sets the clipboard to the specified string.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetClipboardString(window: ?*GLFWwindow, string: [*]const u8) void;
/// Returns the contents of the clipboard as a string.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetClipboardString(window: ?*GLFWwindow) [*]const u8;
/// Returns the GLFW time.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetTime() f64;
/// Sets the GLFW time.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSetTime(time: f64) void;
/// Returns the current value of the raw timer.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetTimerValue() u64;
/// Returns the frequency, in Hz, of the raw timer.
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetTimerFrequency() u64;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwMakeContextCurrent(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetCurrentContext() ?*GLFWwindow;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSwapBuffers(window: ?*GLFWwindow) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwSwapInterval(interval: c_int) void;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwExtensionSupported(extension: [*]const u8) c_int;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetProcAddress(procname: [*]const u8) GLFWglproc;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwVulkanSupported() c_int;
/// 
/// 
/// **Since**
/// 
/// **See**
pub extern fn glfwGetRequiredInstanceExtensions(count: ?*u32) [*]const [*]const u8;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// glfw macros definition

/// The major version number of the GLFW header. This is incremented when the API is changed in non-compatible ways.
pub const GLFW_VERSION_MAJOR = 3;
/// The minor version number of the GLFW header. This is incremented when features are added to the API but it remains backward-compatible.
pub const GLFW_VERSION_MINOR = 4;
/// The revision number of the GLFW header. This is incremented when a bug fix release is made that does not contain any API changes.
pub const GLFW_VERSION_REVISION = 0;
/// One.
/// 
/// This is only semantic sugar for the number 1. You can instead use 1 or true or _True or GL_TRUE or VK_TRUE or anything else that is equal to one.
pub const GLFW_TRUE = 1;
/// Zero.
/// 
/// This is only semantic sugar for the number 0. You can instead use 0 or false or _False or GL_FALSE or VK_FALSE or anything else that is equal to zero.
pub const GLFW_FALSE = 0;
pub const GLFW_RELEASE = 0;
pub const GLFW_PRESS = 1;
pub const GLFW_REPEAT = 2;
pub const GLFW_HAT_CENTERED = 0;
pub const GLFW_HAT_UP = 1;
pub const GLFW_HAT_RIGHT = 2;
pub const GLFW_HAT_DOWN = 4;
pub const GLFW_HAT_LEFT = 8;
pub const GLFW_HAT_RIGHT_UP = GLFW_HAT_RIGHT | GLFW_HAT_UP;
pub const GLFW_HAT_RIGHT_DOWN = GLFW_HAT_RIGHT | GLFW_HAT_DOWN;
pub const GLFW_HAT_LEFT_UP = GLFW_HAT_LEFT | GLFW_HAT_UP;
pub const GLFW_HAT_LEFT_DOWN = GLFW_HAT_LEFT | GLFW_HAT_DOWN;
pub const GLFW_KEY_UNKNOWN = -1;
pub const GLFW_KEY_SPACE = 32;
pub const GLFW_KEY_APOSTROPHE = 39;
pub const GLFW_KEY_COMMA = 44;
pub const GLFW_KEY_MINUS = 45;
pub const GLFW_KEY_PERIOD = 46;
pub const GLFW_KEY_SLASH = 47;
pub const GLFW_KEY_0 = 48;
pub const GLFW_KEY_1 = 49;
pub const GLFW_KEY_2 = 50;
pub const GLFW_KEY_3 = 51;
pub const GLFW_KEY_4 = 52;
pub const GLFW_KEY_5 = 53;
pub const GLFW_KEY_6 = 54;
pub const GLFW_KEY_7 = 55;
pub const GLFW_KEY_8 = 56;
pub const GLFW_KEY_9 = 57;
pub const GLFW_KEY_SEMICOLON = 59;
pub const GLFW_KEY_EQUAL = 61;
pub const GLFW_KEY_A = 65;
pub const GLFW_KEY_B = 66;
pub const GLFW_KEY_C = 67;
pub const GLFW_KEY_D = 68;
pub const GLFW_KEY_E = 69;
pub const GLFW_KEY_F = 70;
pub const GLFW_KEY_G = 71;
pub const GLFW_KEY_H = 72;
pub const GLFW_KEY_I = 73;
pub const GLFW_KEY_J = 74;
pub const GLFW_KEY_K = 75;
pub const GLFW_KEY_L = 76;
pub const GLFW_KEY_M = 77;
pub const GLFW_KEY_N = 78;
pub const GLFW_KEY_O = 79;
pub const GLFW_KEY_P = 80;
pub const GLFW_KEY_Q = 81;
pub const GLFW_KEY_R = 82;
pub const GLFW_KEY_S = 83;
pub const GLFW_KEY_T = 84;
pub const GLFW_KEY_U = 85;
pub const GLFW_KEY_V = 86;
pub const GLFW_KEY_W = 87;
pub const GLFW_KEY_X = 88;
pub const GLFW_KEY_Y = 89;
pub const GLFW_KEY_Z = 90;
pub const GLFW_KEY_LEFT_BRACKET = 91;
pub const GLFW_KEY_BACKSLASH = 92;
pub const GLFW_KEY_RIGHT_BRACKET = 93;
pub const GLFW_KEY_GRAVE_ACCENT = 96;
pub const GLFW_KEY_WORLD_1 = 161;
pub const GLFW_KEY_WORLD_2 = 162;
pub const GLFW_KEY_ESCAPE = 256;
pub const GLFW_KEY_ENTER = 257;
pub const GLFW_KEY_TAB = 258;
pub const GLFW_KEY_BACKSPACE = 259;
pub const GLFW_KEY_INSERT = 260;
pub const GLFW_KEY_DELETE = 261;
pub const GLFW_KEY_RIGHT = 262;
pub const GLFW_KEY_LEFT = 263;
pub const GLFW_KEY_DOWN = 264;
pub const GLFW_KEY_UP = 265;
pub const GLFW_KEY_PAGE_UP = 266;
pub const GLFW_KEY_PAGE_DOWN = 267;
pub const GLFW_KEY_HOME = 268;
pub const GLFW_KEY_END = 269;
pub const GLFW_KEY_CAPS_LOCK = 280;
pub const GLFW_KEY_SCROLL_LOCK = 281;
pub const GLFW_KEY_NUM_LOCK = 282;
pub const GLFW_KEY_PRINT_SCREEN = 283;
pub const GLFW_KEY_PAUSE = 284;
pub const GLFW_KEY_F1 = 290;
pub const GLFW_KEY_F2 = 291;
pub const GLFW_KEY_F3 = 292;
pub const GLFW_KEY_F4 = 293;
pub const GLFW_KEY_F5 = 294;
pub const GLFW_KEY_F6 = 295;
pub const GLFW_KEY_F7 = 296;
pub const GLFW_KEY_F8 = 297;
pub const GLFW_KEY_F9 = 298;
pub const GLFW_KEY_F10 = 299;
pub const GLFW_KEY_F11 = 300;
pub const GLFW_KEY_F12 = 301;
pub const GLFW_KEY_F13 = 302;
pub const GLFW_KEY_F14 = 303;
pub const GLFW_KEY_F15 = 304;
pub const GLFW_KEY_F16 = 305;
pub const GLFW_KEY_F17 = 306;
pub const GLFW_KEY_F18 = 307;
pub const GLFW_KEY_F19 = 308;
pub const GLFW_KEY_F20 = 309;
pub const GLFW_KEY_F21 = 310;
pub const GLFW_KEY_F22 = 311;
pub const GLFW_KEY_F23 = 312;
pub const GLFW_KEY_F24 = 313;
pub const GLFW_KEY_F25 = 314;
pub const GLFW_KEY_KP_0 = 320;
pub const GLFW_KEY_KP_1 = 321;
pub const GLFW_KEY_KP_2 = 322;
pub const GLFW_KEY_KP_3 = 323;
pub const GLFW_KEY_KP_4 = 324;
pub const GLFW_KEY_KP_5 = 325;
pub const GLFW_KEY_KP_6 = 326;
pub const GLFW_KEY_KP_7 = 327;
pub const GLFW_KEY_KP_8 = 328;
pub const GLFW_KEY_KP_9 = 329;
pub const GLFW_KEY_KP_DECIMAL = 330;
pub const GLFW_KEY_KP_DIVIDE = 331;
pub const GLFW_KEY_KP_MULTIPLY = 332;
pub const GLFW_KEY_KP_SUBTRACT = 333;
pub const GLFW_KEY_KP_ADD = 334;
pub const GLFW_KEY_KP_ENTER = 335;
pub const GLFW_KEY_KP_EQUAL = 336;
pub const GLFW_KEY_LEFT_SHIFT = 340;
pub const GLFW_KEY_LEFT_CONTROL = 341;
pub const GLFW_KEY_LEFT_ALT = 342;
pub const GLFW_KEY_LEFT_SUPER = 343;
pub const GLFW_KEY_RIGHT_SHIFT = 344;
pub const GLFW_KEY_RIGHT_CONTROL = 345;
pub const GLFW_KEY_RIGHT_ALT = 346;
pub const GLFW_KEY_RIGHT_SUPER = 347;
pub const GLFW_KEY_MENU = 348;
pub const GLFW_KEY_LAST = GLFW_KEY_MENU;
/// If this bit is set one or more Shift keys were held down.
pub const GLFW_MOD_SHIFT = 0x0001;
/// If this bit is set one or more Control keys were held down.
pub const GLFW_MOD_CONTROL = 0x0002;
/// If this bit is set one or more Alt keys were held down.
pub const GLFW_MOD_ALT = 0x0004;
/// If this bit is set one or more Super keys were held down.
pub const GLFW_MOD_SUPER = 0x0008;
/// If this bit is set the Caps Lock key is enabled.
pub const GLFW_MOD_CAPS_LOCK = 0x0010;
/// If this bit is set the Num Lock key is enabled.
pub const GLFW_MOD_NUM_LOCK = 0x0020;
pub const GLFW_MOUSE_BUTTON_1 = 0;
pub const GLFW_MOUSE_BUTTON_2 = 1;
pub const GLFW_MOUSE_BUTTON_3 = 2;
pub const GLFW_MOUSE_BUTTON_4 = 3;
pub const GLFW_MOUSE_BUTTON_5 = 4;
pub const GLFW_MOUSE_BUTTON_6 = 5;
pub const GLFW_MOUSE_BUTTON_7 = 6;
pub const GLFW_MOUSE_BUTTON_8 = 7;
pub const GLFW_MOUSE_BUTTON_LAST = GLFW_MOUSE_BUTTON_8;
pub const GLFW_MOUSE_BUTTON_LEFT = GLFW_MOUSE_BUTTON_1;
pub const GLFW_MOUSE_BUTTON_RIGHT = GLFW_MOUSE_BUTTON_2;
pub const GLFW_MOUSE_BUTTON_MIDDLE = GLFW_MOUSE_BUTTON_3;
pub const GLFW_JOYSTICK_1 = 0;
pub const GLFW_JOYSTICK_2 = 1;
pub const GLFW_JOYSTICK_3 = 2;
pub const GLFW_JOYSTICK_4 = 3;
pub const GLFW_JOYSTICK_5 = 4;
pub const GLFW_JOYSTICK_6 = 5;
pub const GLFW_JOYSTICK_7 = 6;
pub const GLFW_JOYSTICK_8 = 7;
pub const GLFW_JOYSTICK_9 = 8;
pub const GLFW_JOYSTICK_10 = 9;
pub const GLFW_JOYSTICK_11 = 10;
pub const GLFW_JOYSTICK_12 = 11;
pub const GLFW_JOYSTICK_13 = 12;
pub const GLFW_JOYSTICK_14 = 13;
pub const GLFW_JOYSTICK_15 = 14;
pub const GLFW_JOYSTICK_16 = 15;
pub const GLFW_JOYSTICK_LAST = GLFW_JOYSTICK_16;
pub const GLFW_GAMEPAD_BUTTON_A = 0;
pub const GLFW_GAMEPAD_BUTTON_B = 1;
pub const GLFW_GAMEPAD_BUTTON_X = 2;
pub const GLFW_GAMEPAD_BUTTON_Y = 3;
pub const GLFW_GAMEPAD_BUTTON_LEFT_BUMPER = 4;
pub const GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER = 5;
pub const GLFW_GAMEPAD_BUTTON_BACK = 6;
pub const GLFW_GAMEPAD_BUTTON_START = 7;
pub const GLFW_GAMEPAD_BUTTON_GUIDE = 8;
pub const GLFW_GAMEPAD_BUTTON_LEFT_THUMB = 9;
pub const GLFW_GAMEPAD_BUTTON_RIGHT_THUMB = 10;
pub const GLFW_GAMEPAD_BUTTON_DPAD_UP = 11;
pub const GLFW_GAMEPAD_BUTTON_DPAD_RIGHT = 12;
pub const GLFW_GAMEPAD_BUTTON_DPAD_DOWN = 13;
pub const GLFW_GAMEPAD_BUTTON_DPAD_LEFT = 14;
pub const GLFW_GAMEPAD_BUTTON_LAST = GLFW_GAMEPAD_BUTTON_DPAD_LEFT;
pub const GLFW_GAMEPAD_BUTTON_CROSS = GLFW_GAMEPAD_BUTTON_A;
pub const GLFW_GAMEPAD_BUTTON_CIRCLE = GLFW_GAMEPAD_BUTTON_B;
pub const GLFW_GAMEPAD_BUTTON_SQUARE = GLFW_GAMEPAD_BUTTON_X;
pub const GLFW_GAMEPAD_BUTTON_TRIANGLE = GLFW_GAMEPAD_BUTTON_Y;
pub const GLFW_GAMEPAD_AXIS_LEFT_X = 0;
pub const GLFW_GAMEPAD_AXIS_LEFT_Y = 1;
pub const GLFW_GAMEPAD_AXIS_RIGHT_X = 2;
pub const GLFW_GAMEPAD_AXIS_RIGHT_Y = 3;
pub const GLFW_GAMEPAD_AXIS_LEFT_TRIGGER = 4;
pub const GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER = 5;
pub const GLFW_GAMEPAD_AXIS_LAST = GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER;
/// No error has occurred.
pub const GLFW_NO_ERROR = 0;
/// GLFW has not been initialized.
/// 
/// This occurs if a GLFW function was called that must not be called unless the library is initialized.
pub const GLFW_NOT_INITIALIZED = 0x10001;
/// No context is current for this thread.
/// 
/// This occurs if a GLFW function was called that needs and operates on the current OpenGL or OpenGL ES context but no context is current on the calling thread. One such function is `glfwSwapInterval`.
pub const GLFW_NO_CURRENT_CONTEXT = 0x10002;
/// One of the arguments to the function was an invalid enum value.
/// 
/// One of the arguments to the function was an invalid enum value, for example requesting `GLFW_RED_BITS` with `glfwGetWindowAttrib`.
pub const GLFW_INVALID_ENUM = 0x10003;
/// One of the arguments to the function was an invalid value.
/// 
/// One of the arguments to the function was an invalid value, for example requesting a non-existent OpenGL or OpenGL ES version like 2.7.
/// 
/// Requesting a valid but unavailable OpenGL or OpenGL ES version will instead result in a `GLFW_VERSION_UNAVAILABLE` error.
pub const GLFW_INVALID_VALUE = 0x10004;
/// A memory allocation failed.
pub const GLFW_OUT_OF_MEMORY = 0x10005;
/// GLFW could not find support for the requested API on the system.
pub const GLFW_API_UNAVAILABLE = 0x10006;
/// The requested OpenGL or OpenGL ES version is not available.
pub const GLFW_VERSION_UNAVAILABLE = 0x10007;
/// A platform-specific error occurred that does not match any of the more specific categories.
pub const GLFW_PLATFORM_ERROR = 0x10008;
/// The requested format is not supported or available.
/// 
/// If emitted during window creation, the requested pixel format is not supported.
/// 
/// If emitted when querying the clipboard, the contents of the clipboard could not be converted to the requested format.
pub const GLFW_FORMAT_UNAVAILABLE = 0x10009;
/// The specified window does not have an OpenGL or OpenGL ES context.
pub const GLFW_NO_WINDOW_CONTEXT = 0x1000A;
pub const GLFW_CURSOR_UNAVAILABLE = 0x1000B;
pub const GLFW_FEATURE_UNAVAILABLE = 0x1000C;
pub const GLFW_FEATURE_UNIMPLEMENTED = 0x1000D;
pub const GLFW_PLATFORM_UNAVAILABLE = 0x1000E;
pub const GLFW_FOCUSED = 0x20001;
pub const GLFW_ICONIFIED = 0x20002;
pub const GLFW_RESIZABLE = 0x20003;
pub const GLFW_VISIBLE = 0x20004;
pub const GLFW_DECORATED = 0x20005;
pub const GLFW_AUTO_ICONIFY = 0x20006;
pub const GLFW_FLOATING = 0x20007;
pub const GLFW_MAXIMIZED = 0x20008;
pub const GLFW_CENTER_CURSOR = 0x20009;
pub const GLFW_TRANSPARENT_FRAMEBUFFER = 0x2000A;
pub const GLFW_HOVERED = 0x2000B;
pub const GLFW_FOCUS_ON_SHOW = 0x2000C;
pub const GLFW_MOUSE_PASSTHROUGH = 0x2000D;
pub const GLFW_POSITION_X = 0x2000E;
pub const GLFW_POSITION_Y = 0x2000F;
pub const GLFW_RED_BITS = 0x21001;
pub const GLFW_GREEN_BITS = 0x21002;
pub const GLFW_BLUE_BITS = 0x21003;
pub const GLFW_ALPHA_BITS = 0x21004;
pub const GLFW_DEPTH_BITS = 0x21005;
pub const GLFW_STENCIL_BITS = 0x21006;
pub const GLFW_ACCUM_RED_BITS = 0x21007;
pub const GLFW_ACCUM_GREEN_BITS = 0x21008;
pub const GLFW_ACCUM_BLUE_BITS = 0x21009;
pub const GLFW_ACCUM_ALPHA_BITS = 0x2100A;
pub const GLFW_AUX_BUFFERS = 0x2100B;
pub const GLFW_STEREO = 0x2100C;
pub const GLFW_SAMPLES = 0x2100D;
pub const GLFW_SRGB_CAPABLE = 0x2100E;
pub const GLFW_REFRESH_RATE = 0x2100F;
pub const GLFW_DOUBLEBUFFER = 0x21010;
pub const GLFW_CLIENT_API = 0x22001;
pub const GLFW_CONTEXT_VERSION_MAJOR = 0x22002;
pub const GLFW_CONTEXT_VERSION_MINOR = 0x22003;
pub const GLFW_CONTEXT_REVISION = 0x22004;
pub const GLFW_CONTEXT_ROBUSTNESS = 0x22005;
pub const GLFW_OPENGL_FORWARD_COMPAT = 0x22006;
pub const GLFW_CONTEXT_DEBUG = 0x22007;
pub const GLFW_OPENGL_DEBUG_CONTEXT = GLFW_CONTEXT_DEBUG;
pub const GLFW_OPENGL_PROFILE = 0x22008;
pub const GLFW_CONTEXT_RELEASE_BEHAVIOR = 0x22009;
pub const GLFW_CONTEXT_NO_ERROR = 0x2200A;
pub const GLFW_CONTEXT_CREATION_API = 0x2200B;
pub const GLFW_SCALE_TO_MONITOR = 0x2200C;
pub const GLFW_COCOA_RETINA_FRAMEBUFFER = 0x23001;
pub const GLFW_COCOA_FRAME_NAME = 0x23002;
pub const GLFW_COCOA_GRAPHICS_SWITCHING = 0x23003;
pub const GLFW_X11_CLASS_NAME = 0x24001;
pub const GLFW_X11_INSTANCE_NAME = 0x24002;
pub const GLFW_WIN32_KEYBOARD_MENU = 0x25001;
pub const GLFW_WAYLAND_APP_ID = 0x26001;
pub const GLFW_NO_API = 0;
pub const GLFW_OPENGL_API = 0x30001;
pub const GLFW_OPENGL_ES_API = 0x30002;
pub const GLFW_NO_ROBUSTNESS = 0;
pub const GLFW_NO_RESET_NOTIFICATION = 0x31001;
pub const GLFW_LOSE_CONTEXT_ON_RESET = 0x31002;
pub const GLFW_OPENGL_ANY_PROFILE = 0;
pub const GLFW_OPENGL_CORE_PROFILE = 0x32001;
pub const GLFW_OPENGL_COMPAT_PROFILE = 0x32002;
pub const GLFW_CURSOR = 0x33001;
pub const GLFW_STICKY_KEYS = 0x33002;
pub const GLFW_STICKY_MOUSE_BUTTONS = 0x33003;
pub const GLFW_LOCK_KEY_MODS = 0x33004;
pub const GLFW_RAW_MOUSE_MOTION = 0x33005;
pub const GLFW_CURSOR_NORMAL = 0x34001;
pub const GLFW_CURSOR_HIDDEN = 0x34002;
pub const GLFW_CURSOR_DISABLED = 0x34003;
pub const GLFW_CURSOR_CAPTURED = 0x34004;
pub const GLFW_ANY_RELEASE_BEHAVIOR = 0;
pub const GLFW_RELEASE_BEHAVIOR_FLUSH = 0x35001;
pub const GLFW_RELEASE_BEHAVIOR_NONE = 0x35002;
pub const GLFW_NATIVE_CONTEXT_API = 0x36001;
pub const GLFW_EGL_CONTEXT_API = 0x36002;
pub const GLFW_OSMESA_CONTEXT_API = 0x36003;
pub const GLFW_ANGLE_PLATFORM_TYPE_NONE = 0x37001;
pub const GLFW_ANGLE_PLATFORM_TYPE_OPENGL = 0x37002;
pub const GLFW_ANGLE_PLATFORM_TYPE_OPENGLES = 0x37003;
pub const GLFW_ANGLE_PLATFORM_TYPE_D3D9 = 0x37004;
pub const GLFW_ANGLE_PLATFORM_TYPE_D3D11 = 0x37005;
pub const GLFW_ANGLE_PLATFORM_TYPE_VULKAN = 0x37007;
pub const GLFW_ANGLE_PLATFORM_TYPE_METAL = 0x37008;
pub const GLFW_WAYLAND_PREFER_LIBDECOR = 0x38001;
pub const GLFW_WAYLAND_DISABLE_LIBDECOR = 0x38002;
pub const GLFW_ANY_POSITION = 0x00000;
/// The regular arrow cursor shape.
pub const GLFW_ARROW_CURSOR = 0x36001;
/// The text input I-beam cursor shape.
pub const GLFW_IBEAM_CURSOR = 0x36002;
/// The crosshair shape.
pub const GLFW_CROSSHAIR_CURSOR = 0x36003;
/// The pointing hand cursor shape.
pub const GLFW_POINTING_HAND_CURSOR = 0x36004;
/// The horizontal resize/move arrow shape.
pub const GLFW_RESIZE_EW_CURSOR = 0x36005;
/// The vertical resize/move arrow shape.
pub const GLFW_RESIZE_NS_CURSOR = 0x36006;
/// The top-left to bottom-right diagonal resize/move arrow shape.
pub const GLFW_RESIZE_NWSE_CURSOR = 0x36007;
/// The top-right to bottom-left diagonal resize/move arrow shape.
pub const GLFW_RESIZE_NESW_CURSOR = 0x36008;
/// The omni-directional resize/move cursor shape.
pub const GLFW_RESIZE_ALL_CURSOR = 0x36009;
/// The operation-not-allowed shape.
pub const GLFW_NOT_ALLOWED_CURSOR = 0x3600A;
/// Legacy name for compatibility.
pub const GLFW_HRESIZE_CURSOR = GLFW_RESIZE_EW_CURSOR;
/// Legacy name for compatibility.
pub const GLFW_VRESIZE_CURSOR = GLFW_RESIZE_NS_CURSOR;
/// Legacy name for compatibility.
pub const GLFW_HAND_CURSOR = GLFW_POINTING_HAND_CURSOR;
pub const GLFW_CONNECTED = 0x40001;
pub const GLFW_DISCONNECTED = 0x40002;
/// Joystick hat buttons init hint.
pub const GLFW_JOYSTICK_HAT_BUTTONS = 0x50001;
/// ANGLE rendering backend init hint.
pub const GLFW_ANGLE_PLATFORM_TYPE = 0x50002;
/// Platform selection init hint.
pub const GLFW_PLATFORM = 0x50003;
/// macOS specific hint.
pub const GLFW_COCOA_CHDIR_RESOURCES = 0x51001;
/// macOS specific hint.
pub const GLFW_COCOA_MENUBAR = 0x51002;
/// X11 specific hint.
pub const GLFW_X11_XCB_VULKAN_SURFACE = 0x52001;
/// Wayland specific hint.
pub const GLFW_WAYLAND_LIBDECOR = 0x53001;
/// hint value that enables automatic platform slection.
pub const GLFW_ANY_PLATFORM = 0x60000;
pub const GLFW_PLATFORM_WIN32 = 0x60001;
pub const GLFW_PLATFORM_COCOA = 0x60002;
pub const GLFW_PLATFORM_WAYLAND = 0x60003;
pub const GLFW_PLATFORM_X11 = 0x60004;
pub const GLFW_PLATFORM_NULL = 0x60005;
pub const GLFW_DONT_CARE = -1;
