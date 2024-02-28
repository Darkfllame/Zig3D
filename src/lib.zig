pub const glfw = @import("glfw");
pub const glad = @import("glad");
pub const stb = @import("stb");
pub const zlm = @import("zlm");
pub usingnamespace @import("utils");

comptime {
    _ = glfw;
    _ = glad;
    _ = stb;
    _ = zlm;
    _ = @This();
}
