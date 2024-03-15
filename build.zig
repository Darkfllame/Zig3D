const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw = b.dependency("glfw", .{
        .optimize = optimize,
        .target = target,
        .shared = false,
        .x11 = true,
        .wayland = true,
        .opengl = false,
        .gles = false,
        .metal = true,
    });

    const freetype = b.dependency("freetype", .{
        .optimize = optimize,
        .target = target,
        .use_system_zlib = false,
        .enable_brotli = true,
    });

    const zlm = b.dependency("zlm", .{});

    const freetypeModule = b.addModule("freetype", .{
        .root_source_file = .{ .path = "src/freetype.zig" },
    });
    freetypeModule.linkLibrary(freetype.artifact("freetype"));

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
            .{
                .name = "zlm",
                .module = zlm.module("zlm"),
            },
        },
    });
    gladModule.addIncludePath(.{ .path = "include/" });
    gladModule.addCSourceFile(.{ .file = .{ .path = "src/glad.c" } });

    const imageModule = b.addModule("image", .{
        .root_source_file = .{ .path = "src/image.zig" },
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{
                .name = "utils",
                .module = utilsModule,
            },
            .{
                .name = "zlm",
                .module = zlm.module("zlm"),
            },
        },
    });

    const stbModule = b.addModule("stb", .{
        .root_source_file = .{ .path = "src/stb.zig" },
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .imports = &.{
            .{
                .name = "glfw",
                .module = glfwModule,
            },
            .{
                .name = "utils",
                .module = utilsModule,
            },
            .{
                .name = "image",
                .module = imageModule,
            },
        },
    });
    stbModule.addIncludePath(.{ .path = "include/" });
    stbModule.addCSourceFile(.{
        .file = .{ .path = "src/stbdefs.c" },
        .flags = &.{
            "-Iinclude",
        },
    });

    const libModule = b.addModule("zig3d", .{
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
            .{
                .name = "zlm",
                .module = zlm.module("zlm"),
            },
            .{
                .name = "stb",
                .module = stbModule,
            },
            .{
                .name = "freetype",
                .module = freetypeModule,
            },
        },
    });

    makeDemo(b, libModule, "simpleDemo", "demo", "Run the simple demo app", optimize, target);
    makeDemo(b, libModule, "quadDemo", "quad", "Run the demo quad app", optimize, target);
    makeDemo(b, libModule, "batchDemo", "batch", "Run the batch demo app", optimize, target);
    makeDemo(b, libModule, "bindlessTexture", "texture", "Run the bindless texture demo app", optimize, target);
}

fn makeDemo(b: *std.Build, libmodule: *std.Build.Module, comptime path: []const u8, name: []const u8, desc: []const u8, optimize: std.builtin.OptimizeMode, target: std.Build.ResolvedTarget) void {
    const demo = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = "examples/" ++ path ++ "/main.zig" },
        .optimize = optimize,
        .target = target,
    });
    demo.root_module.addImport("zig3d", libmodule);

    b.installArtifact(demo);

    const demo_run = b.addRunArtifact(demo);
    demo_run.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        demo_run.addArgs(args);
    }

    const run_step = b.step(name, desc);
    run_step.dependOn(&demo_run.step);
}
