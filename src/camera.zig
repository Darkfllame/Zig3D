const zlm = @import("zig3d").zlm;
const std = @import("std");

const Vec3f = zlm.Vec3;

const Mat4f = zlm.Mat4;

pub const Camera = struct {
    position: Vec3f,
    yaw: f32 = 0,
    pitch: f32 = 0,
    fov: f32,
    near: f32 = 0.01,
    far: f32 = 100,
    perspective: bool = true,
    width: u32,
    height: u32,

    pub fn init(position: Vec3f, fov: f32, width: u32, height: u32) Camera {
        return .{
            .position = position,
            .fov = fov,
            .width = width,
            .height = height,
        };
    }

    pub fn update(self: *Camera, nwidth: u32, nheight: u32) void {
        self.width = nwidth;
        self.height = nheight;
    }

    pub fn translate(self: *Camera, v: Vec3f) void {
        self.position = self.position.add(v);
    }
    pub fn translateXYZ(self: *Camera, x: f32, y: f32, z: f32) void {
        self.position = self.position.add(zlm.vec3(x, y, z));
    }

    pub fn projectionMatrix(self: Camera) Mat4f {
        return if (self.perspective) Mat4f.createPerspective(
            self.fov,
            @as(f32, @floatFromInt(self.width)) / @as(f32, @floatFromInt(self.height)),
            self.near,
            self.far,
        ) else Mat4f.createOrthogonal(-1, 1, -1, 1, self.near, self.far);
    }
    pub fn viewMatrix(self: Camera) Mat4f {
        return Mat4f.batchMul(&.{
            Mat4f.createTranslation(self.position),
            Mat4f.createAngleAxis(Vec3f.unitY, zlm.toRadians(self.yaw)),
            Mat4f.createAngleAxis(Vec3f.unitX, zlm.toRadians(self.pitch)),
        });
    }
    pub fn camMatrix(self: Camera) Mat4f {
        return Mat4f.batchMul(&.{
            self.projectionMatrix(),
            self.camMatrix(),
        });
    }
};
