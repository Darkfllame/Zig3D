const std = @import("std");
const glad = @import("glad");

const ArrayList = std.ArrayList;

const Allocator = std.mem.Allocator;

pub const Error = error{};

pub const Vertex = struct {
    pub const FLOATS_PER_VERTEX = @sizeOf(Vertex) / @sizeOf(f32);

    position: glad.Vec3f,
    color: glad.Vec3f,
    uv: glad.Vec2f,

    pub fn newV(p: glad.Vec3f, c: glad.Vec3f, uv: glad.Vec2f) Vertex {
        return .{ .position = p, .color = c, .uv = uv };
    }
    pub fn new(x: f32, y: f32, z: f32, r: f32, g: f32, b: f32, u: f32, v: f32) Vertex {
        return .{
            .position = glad.Vec3f.new(x, y, z),
            .color = glad.Vec3f.new(r, g, b),
            .uv = glad.Vec2f.new(u, v),
        };
    }

    pub fn format(self: *const Vertex, comptime _: []const u8, _: std.fmt.FormatOptions, stream: anytype) !void {
        try stream.print("(x: {d:.2}, x: {d:.2}, x: {d:.2}, #{x:0>2}{x:0>2}{x:0>2}, u: {d:.2}, v: {d:.2})", .{
            self.position.x,
            self.position.y,
            self.position.z,
            @as(u8, @intFromFloat(std.math.clamp(self.color.x, 0.0, 1.0) * 255.0)),
            @as(u8, @intFromFloat(std.math.clamp(self.color.y, 0.0, 1.0) * 255.0)),
            @as(u8, @intFromFloat(std.math.clamp(self.color.z, 0.0, 1.0) * 255.0)),
            self.uv.x,
            self.uv.y,
        });
    }
};

pub const GLMesh = struct {
    vao: glad.VertexArray,
    vbo: glad.Buffer,
    ebo: glad.Buffer,

    pub fn deinit(self: *GLMesh) void {
        self.vao.destroy();
        self.vbo.destroy();
        self.ebo.destroy();
        self.* = undefined;
    }
};

pub const Mesh = struct {
    vertices: []Vertex = &.{},
    indices: []u32 = &.{},

    pub fn generate(self: *const Mesh) glad.Error!GLMesh {
        const vao = glad.VertexArray.create();
        const buffers = glad.Buffer.createBuffers(2);

        vao.bind();

        buffers[0].bind(.Array);
        buffers[0].data(Vertex, self.vertices, .StaticDraw);

        buffers[1].bind(.ElementArray);
        buffers[1].data(u32, self.indices, .StaticDraw);

        vao.vertexAttrib(0, 3, f32, false, @sizeOf(Vertex), 0);
        vao.vertexAttrib(1, 3, f32, false, @sizeOf(Vertex), @offsetOf(Vertex, "color"));
        vao.vertexAttrib(2, 2, f32, false, @sizeOf(Vertex), @offsetOf(Vertex, "uv"));
        vao.enableAttrib(0);
        vao.enableAttrib(1);
        vao.enableAttrib(2);

        glad.Buffer.unbindAny(.ElementArray);
        glad.Buffer.unbindAny(.Array);
        glad.VertexArray.unbindAny();

        return .{
            .vao = vao,
            .vbo = buffers[0],
            .ebo = buffers[1],
        };
    }
};

pub const MeshBatch = struct {
    allocator: Allocator,
    meshes: ArrayList(Mesh),

    pub fn init(allocator: Allocator) MeshBatch {
        return .{
            .allocator = allocator,
            .meshes = ArrayList(Mesh).init(allocator),
        };
    }
    pub fn deinit(self: *MeshBatch) void {
        self.meshes.deinit();
        self.* = undefined;
    }

    pub fn pack(self: *const MeshBatch) Allocator.Error!Mesh {
        const allocator = self.allocator;
        const meshes = self.meshes.items;

        var vertexCount: usize = 0;
        var indexCount: usize = 0;
        for (meshes) |m| {
            vertexCount += m.vertices.len;
            indexCount += m.indices.len;
        }

        const vertices = try allocator.alloc(Vertex, vertexCount);
        defer allocator.free(vertices);
        const indices = try allocator.alloc(u32, indexCount);
        defer allocator.free(indices);

        var offset: usize = 0;
        for (meshes) |m| {
            for (m.vertices, 0..) |v, i| {
                vertices[offset + i] = v;
            }
            for (m.indices, 0..) |j, i| {
                indices[offset + i] = offset + j;
            }
            offset += m.vertices.len;
        }

        return .{
            .vertices = vertices,
            .indices = indices,
        };
    }
};
