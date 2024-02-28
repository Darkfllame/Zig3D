pub const glfw = @import("glfw");
pub const glad = @import("glad");
pub const stb = @import("stb");
pub const ziglm = @import("ziglm");
//pub const freetype = @import("freetype");
pub usingnamespace @import("utils");

fn perspectiveMatrix(fov: f32, aspect: f32, near: f32, far: f32) ziglm.Mat4(f32) {
    if (@abs(aspect - 0.001) <= 0) @panic("Aspect ratio must be greater than 0");
    const tanHalfFovy = @tan(fov / 2);
    return ziglm.Mat4(f32).diagonal(1.0 / (aspect * tanHalfFovy), 1.0 / (tanHalfFovy), 1, -(far * near) / (far - near));
}
fn orthogonalMatrix(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) ziglm.Mat4(f32) {
    var result = ziglm.Mat4x4(f32).identity;
    result.cols[0].x = 2 / (right - left);
    result.cols[1].y = 2 / (top - bottom);
    result.cols[2].z = 1 / (far - near);
    result.cols[0].z = -(right + left) / (right - left);
    result.cols[1].z = -(top + bottom) / (top - bottom);
    result.cols[2].z = -near / (far - near);
    return result;
}
