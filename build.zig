const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = b.addOptions();

    const exposeC = b.option(bool, "exposeC", "set whether to expose the underlaying c API of the wrappers") orelse false;
    const buildAllDemos = b.option(bool, "buildAllDemos", "set whether to force building all the demos") orelse false;

    options.addOption(bool, "exposeC", exposeC);

    const build_options = options.createModule();

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
        .root_source_file = b.path("src/freetype.zig"),
        .imports = &.{
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    freetypeModule.linkLibrary(freetype.artifact("freetype"));

    const KeyModule = b.createModule(.{
        .root_source_file = b.path("src/Key.zig"),
        .optimize = optimize,
        .target = target,
    });

    const utilsModule = b.createModule(.{
        .root_source_file = b.path("src/utils.zig"),
        .optimize = optimize,
        .target = target,
    });

    const glfwModule = b.addModule("glfw", .{
        .root_source_file = b.path("src/glfw.zig"),
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
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    glfwModule.linkLibrary(glfw.artifact("glfw"));

    const gladModule = b.addModule("glad", .{
        .root_source_file = b.path("src/glad.zig"),
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
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    gladModule.addIncludePath(b.path("include/"));
    gladModule.addCSourceFile(.{ .file = b.path("src/glad.c") });

    const imageModule = b.addModule("image", .{
        .root_source_file = b.path("src/image.zig"),
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
        .root_source_file = b.path("src/stb.zig"),
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
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    stbModule.addIncludePath(b.path("include/"));
    stbModule.addCSourceFile(.{
        .file = b.path("src/stbdefs.c"),
        .flags = &.{
            "-Iinclude",
        },
    });

    const libModule = b.addModule("zig3d", .{
        .root_source_file = b.path("src/lib.zig"),
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

    makeDemo(b, libModule, buildAllDemos, "demo", "Run the simple demo app", optimize, target);
    makeDemo(b, libModule, buildAllDemos, "quad", "Run the demo quad app", optimize, target);
    makeDemo(b, libModule, buildAllDemos, "bindlessTexture", "Run the bindless texture demo app", optimize, target);
    makeDemo(b, libModule, buildAllDemos, "instancing", "Run the instancing demo app", optimize, target);
}

fn makeDemo(b: *std.Build, libmodule: *std.Build.Module, forceInstall: bool, comptime name: []const u8, desc: []const u8, optimize: std.builtin.OptimizeMode, target: std.Build.ResolvedTarget) void {
    const demo = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("examples/" ++ name ++ "/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    demo.root_module.addImport("zig3d", libmodule);

    const install = b.addInstallArtifact(demo, .{});
    if (forceInstall) {
        b.install_tls.step.dependOn(&install.step);
    }

    const demo_run = b.addRunArtifact(demo);
    demo_run.step.dependOn(&install.step);

    if (b.args) |args| {
        demo_run.addArgs(args);
    }

    const run_step = b.step(name, desc);
    run_step.dependOn(&demo_run.step);
}
