//!The Zig3D library is maintaned by [me](https://github.com/Darkfllame/)
//! and is made to make 3D games. It provides the user bindings to the glfw,
//! glad, stb libraries and others. The functions are adapted to the Zig
//! conventions and avoid using C strings in profit of slices (and thus a
//! lot of memory allocation sorry).

pub const glfw = @import("glfw");
pub const glad = @import("glad");
pub const stb = @import("stb");
pub const freetype = @import("freetype");
pub const zlm = @import("zlm");
pub const DGR = @import("DGR/lib.zig");

comptime {
    @setEvalBranchQuota(0xFFFFFFFF);
    @import("std").testing.refAllDeclsRecursive(@This());
}
