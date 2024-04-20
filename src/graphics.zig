const std = @import("std");
const glad = @import("glad");
const utils = @import("utils");

const ArrayList = std.ArrayList;

const Allocator = std.mem.Allocator;

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

    pub fn deinit(self: *Mesh, allocator: Allocator) void {
        allocator.free(self.vertices);
        allocator.free(self.indices);
        self.* = undefined;
    }

    pub fn clone(self: *const Mesh, allocator: Allocator) Allocator.Error!Mesh {
        const verticesClone = utils.copy(
            Vertex,
            self.vertices,
            try allocator.alloc(Vertex, self.vertices.len),
        );
        errdefer allocator.free(verticesClone);
        const indicesClone = utils.copy(
            u32,
            self.indices,
            try allocator.alloc(u32, self.indices.len),
        );
        errdefer allocator.free(indicesClone);

        return .{
            .vertices = verticesClone,
            .indices = indicesClone,
        };
    }

    pub fn generate(self: *const Mesh) !GLMesh {
        const vao = glad.VertexArray.create();
        const buffers = glad.Buffer.createBuffers(2);

        vao.bind();

        buffers[0].bind(.Array);
        try buffers[0].data(Vertex, self.vertices, .StaticDraw);

        buffers[1].bind(.ElementArray);
        try buffers[1].data(u32, self.indices, .StaticDraw);

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

/// A data-structure responssible for handling a mesh batch.
pub const MeshBatch = struct {
    /// The allocation used for that batch, DO NOT CHANGE
    allocator: Allocator,
    /// And internal state to know if the mesh has changed or not, DO NOT CHANGE
    changed: bool = true,
    /// The last generated mesh, if you want to get it or generate it, use .pack(), do not change it
    lastGeneratedMesh: ?Mesh = null,
    indexCount: u32 = 0,
    /// The internal mesh buferr, god dammit, do not change either
    meshes: ArrayList(Mesh),

    pub fn init(allocator: Allocator) MeshBatch {
        return .{
            .allocator = allocator,
            .meshes = ArrayList(Mesh).init(allocator),
        };
    }
    pub fn deinit(self: *MeshBatch) void {
        self.empty();
        self.meshes.deinit();
        self.* = undefined;
    }

    pub fn addMesh(self: *MeshBatch, m: Mesh, transform: glad.Mat4f) Allocator.Error!void {
        var mclone = try m.clone(self.allocator);
        errdefer mclone.deinit(self.allocator);
        for (mclone.vertices) |*v| {
            v.position = v.position.swizzle("xyz1").transform(transform).swizzle("xyz");
        }
        try self.meshes.append(mclone);
        self.changed = true;
    }
    pub fn addMeshes(self: *MeshBatch, m: Mesh, transforms: []const glad.Mat4f) Allocator.Error!void {
        if (transforms.len == 0) {
            return;
        } else if (transforms.len == 1) {
            return self.addMesh(m, transforms[0]);
        }

        const clones = try self.allocator.alloc(Mesh, transforms.len);
        defer self.allocator.free(clones);
        var maxIdx: usize = 0;
        errdefer {
            for (0..maxIdx) |i| {
                clones[i].deinit(self.allocator);
            }
        }

        for (transforms) |t| {
            const mclone = try m.clone(self.allocator);
            for (mclone.vertices) |*v| {
                v.position = v.position.swizzle("xyz1").transform(t).swizzle("xyz");
            }
            clones[maxIdx] = mclone;
            maxIdx += 1;
        }

        try self.meshes.appendSlice(clones);
        self.changed = true;
    }
    pub fn empty(self: *MeshBatch) void {
        for (self.meshes.items) |*m| m.deinit(self.allocator);
        self.meshes.clearRetainingCapacity();
        if (self.lastGeneratedMesh) |*m| m.deinit(self.allocator);
        self.changed = true;
    }

    pub fn pack(self: *MeshBatch) Allocator.Error!Mesh {
        if (!self.changed) return self.lastGeneratedMesh.?;
        if (self.lastGeneratedMesh) |*m| m.deinit(self.allocator);

        const allocator = self.allocator;
        const meshes = self.meshes.items;

        var vertexCount: usize = 0;
        var indexCount: usize = 0;
        for (meshes) |m| {
            vertexCount += m.vertices.len;
            indexCount += m.indices.len;
        }

        const vertices = try allocator.alloc(Vertex, vertexCount);
        errdefer allocator.free(vertices);
        const indices = try allocator.alloc(u32, indexCount);
        errdefer allocator.free(indices);

        var voffset: u32 = 0;
        var ioffset: u32 = 0;
        for (meshes) |m| {
            for (m.vertices, 0..) |v, i| {
                vertices[voffset + i] = v;
            }
            for (m.indices, 0..) |j, i| {
                indices[ioffset + i] = voffset + j;
            }
            voffset += @intCast(m.vertices.len);
            ioffset += @intCast(m.indices.len);
        }

        self.changed = false;
        self.lastGeneratedMesh = .{
            .vertices = vertices,
            .indices = indices,
        };
        self.indexCount = @intCast(indexCount);
        return self.lastGeneratedMesh.?;
    }

    pub fn draw(self: *MeshBatch) !void {
        var finalM = try (try self.pack()).generate();
        defer finalM.deinit();

        finalM.vao.bind();
        try glad.drawElements(.Triangles, self.indexCount, u32, 0);
        glad.VertexArray.unbindAny();
    }
};
