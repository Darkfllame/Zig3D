const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const options = b.addOptions();

    const exposeC = b.option(bool, "exposeC", "Whether to expose the underlaying c API of the wrappers (default: false)") orelse false;
    const shared = b.option(bool, "shared", "Whether to dynamically link GLFW, GLAD and stb (default: false)") orelse false;
    const buildAllDemos = b.option(bool, "buildAll", "Whether to force building all the demos (default: false)") orelse false;

    options.addOption(bool, "exposeC", exposeC);

    const build_options = options.createModule();

    const glfw = b.dependency("glfw", .{
        .optimize = optimize,
        .target = target,
        .shared = shared,
        .x11 = true,
        .wayland = true,
        .opengl = false,
        .gles = false,
        .metal = true,
    });
    b.installArtifact(glfw.artifact("glfw"));

    const freetype = b.dependency("freetype", .{
        .optimize = optimize,
        .target = target,
        .use_system_zlib = false,
        .enable_brotli = true,
    });
    b.installArtifact(freetype.artifact("freetype"));

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

    const glfwModule = b.addModule("glfw", .{
        .root_source_file = b.path("src/glfw.zig"),
        .link_libc = true,
        .imports = &.{
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    glfwModule.linkLibrary(glfw.artifact("glfw"));

    const gladLibOptions = .{
        .name = "glad",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    };
    const gladLib = if (shared)
        b.addSharedLibrary(gladLibOptions)
    else
        b.addStaticLibrary(gladLibOptions);
    gladLib.addIncludePath(b.path("include/"));
    gladLib.installHeadersDirectory(b.path("include/glad/"), "glad", .{});
    gladLib.installHeadersDirectory(b.path("include/KHR/"), "KHR", .{});
    gladLib.addCSourceFile(.{ .file = b.path("src/glad.c") });
    b.installArtifact(gladLib);

    const gladModule = b.addModule("glad", .{
        .root_source_file = b.path("src/glad.zig"),
        .link_libc = true,
        .imports = &.{
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
    gladModule.linkLibrary(gladLib);

    const stbLibOptions = .{
        .name = "stb",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    };
    const stbLib = if (shared)
        b.addSharedLibrary(stbLibOptions)
    else
        b.addStaticLibrary(stbLibOptions);
    stbLib.addIncludePath(b.path("include/"));
    stbLib.installHeadersDirectory(b.path("include/STB/"), "STB", .{});
    stbLib.addCSourceFile(.{ .file = b.path("src/stbdefs.c") });
    b.installArtifact(stbLib);

    const stbModule = b.addModule("stb", .{
        .root_source_file = b.path("src/stb.zig"),
        .link_libc = true,
        .imports = &.{
            .{
                .name = "glfw",
                .module = glfwModule,
            },
            .{
                .name = "build_options",
                .module = build_options,
            },
        },
    });
    stbModule.linkLibrary(stbLib);

    const libModule = b.addModule("zig3d", .{
        .root_source_file = b.path("src/lib.zig"),
        .link_libc = true,
        .imports = &.{
            .{
                .name = "glfw",
                .module = glfwModule,
            },
            .{
                .name = "glad",
                .module = gladModule,
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

    libModule.addImport("zig3d", libModule);

    const utils = b.createModule(.{
        .root_source_file = b.path("examples/utils.zig"),
        .target = target,
        .optimize = optimize,
    });

    makeDemo(b, utils, buildAllDemos, "demo", "Run the simple demo app", optimize, target);
    makeDemo(b, utils, buildAllDemos, "quad", "Run the demo quad app", optimize, target);
    makeDemo(b, utils, buildAllDemos, "bindlessTexture", "Run the bindless texture demo app", optimize, target);
    makeDemo(b, utils, buildAllDemos, "instancing", "Run the instancing demo app", optimize, target);

    { // autodoc
        const docgen = b.addObject(.{
            .name = "zig3d",
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = .Debug,
        });
        const installDocs = b.addInstallDirectory(.{
            .source_dir = docgen.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs/",
        });

        const docgenStep = b.step("gen-docs", "Generate Zig3D's documentation (currently kinda useless)");
        docgenStep.dependOn(&installDocs.step);
    }
}

fn makeDemo(b: *std.Build, utils: *std.Build.Module, forceInstall: bool, comptime name: []const u8, desc: []const u8, optimize: std.builtin.OptimizeMode, target: std.Build.ResolvedTarget) void {
    const demo = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("examples/" ++ name ++ "/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    demo.root_module.addImport("zig3d", b.modules.get("zig3d").?);
    demo.root_module.addImport("utils", utils);

    if (forceInstall) {
        b.getInstallStep().dependOn(&demo.step);
    }

    const demo_run = b.addRunArtifact(demo);
    demo_run.step.dependOn(&demo.step);
    demo_run.addArgs(b.args orelse &.{});

    const run_step = b.step(name, desc);
    run_step.dependOn(&demo_run.step);
}
