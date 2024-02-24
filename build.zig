const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw = b.dependency("glfw", .{
        .optimize = optimize,
        .target = target,
        .shared = false,
        .use_x11 = true,
        .use_w1 = true,
        .use_opengl = false,
        .use_gles = false,
        .use_metal = true,
    });
    const KeyModule = b.createModule(.{
        .root_source_file = .{ .path = "src/Key.zig" },
        .optimize = optimize,
        .target = target,
    });
    const utilsModule = b.createModule(.{
        .root_source_file = .{ .path = "src/utils.zig" },
        .optimize = optimize,
        .target = target,
    });
    const glfwModule = b.addModule("glfw", .{
        .root_source_file = .{ .path = "src/glfw.zig" },
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{
                .name = "Key",
                .module = KeyModule,
            },
            .{
                .name = "utils",
                .module = utilsModule,
            },
        },
    });
    glfwModule.linkLibrary(glfw.artifact("glfw"));

    const gladModule = b.addModule("glad", .{
        .root_source_file = .{ .path = "src/glad.zig" },
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{
                .name = "utils",
                .module = utilsModule,
            },
        },
    });
    gladModule.addIncludePath(.{ .path = "include/" });
    gladModule.addCSourceFile(.{ .file = .{ .path = "src/glad.c" } });

    const libModule = b.addModule("glad-glfw", .{
        .root_source_file = .{ .path = "src/lib.zig" },
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{
                .name = "Key",
                .module = KeyModule,
            },
            .{
                .name = "glfw",
                .module = glfwModule,
            },
            .{
                .name = "glad",
                .module = gladModule,
            },
            .{
                .name = "utils",
                .module = utilsModule,
            },
        },
    });
    _ = libModule; // autofix
}
