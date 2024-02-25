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

    // freetype is on it's way

    const freetype = b.dependency("freetype", .{
        .optimize = optimize,
        .target = target,
        .use_system_zlib = false,
        .enable_brotli = true,
    });
    _ = freetype; // autofix

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

    // const freetypeModule = b.addModule("freetype", .{
    //     .root_source_file = .{ .path = "src/freetype.zig" },
    //     .optimize = optimize,
    //     .target = target,
    //     .imports = &.{
    //         .{
    //             .name = "utils",
    //             .module = utilsModule,
    //         },
    //     },
    // });
    // freetypeModule.linkLibrary(freetype.artifact("freetype"));

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

    const ziglmModule = b.addModule("ziglm", .{
        .root_source_file = .{ .path = "src/ziglm/ziglm.zig" },
        .optimize = optimize,
        .target = target,
    });

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
                .name = "ziglm",
                .module = ziglmModule,
            },
        },
    });
    gladModule.addIncludePath(.{ .path = "include/" });
    gladModule.addCSourceFile(.{ .file = .{ .path = "src/glad.c" } });

    const stbModule = b.addModule("stb", .{
        .root_source_file = .{ .path = "src/stb.zig" },
        .optimize = optimize,
        .target = target,
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
                .name = "ziglm",
                .module = ziglmModule,
            },
            .{
                .name = "stb",
                .module = stbModule,
            },
            // .{
            //     .name = "freetype",
            //     .module = freetypeModule,
            // },
        },
    });

    const exe = b.addExecutable(.{
        .name = "Demo",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
        .target = target,
    });

    exe.root_module.addImport("zig3d", libModule);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    {
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe_unit_tests = b.addTest(.{
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }
}
