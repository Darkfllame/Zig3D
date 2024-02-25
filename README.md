# Zig3D

This project uses a [glfw](https://github.com/hexops/glfw) and [freetype](https://github.com/hexops/freetype) from the Mach Engine dev, [GLAD](https://glad.dav1d.de) and the [STB library](https://github.com/nothings/stb).

## How to use

To use this you just have to add a dependency in your `build.zig.zon` file:
```zig
.dependencies = .{
  .zig3d = .{
    .url = "https://github.com/Darkfllame/Zig3D/archive/<commit>.tag.gz",
  }
}
```
You can get the hash with the command `zig fetch https://github.com/Darkfllame/Zig3D/archive/<commit>.tag.gz` or when compiling.

After adding the dependency, you'll add:
```zig
const zig3d = b.dependency("zig3d", .{
  .optimize = optimize,
  .target = target,
});

...

exe.linkLibrary(glad_glfw.artifact("zig3d"))
exe.root_module.addImport("zig3d", glad_glfw.module("zig3d"));
```
to your `build.zig` file.

##

You can check out the [demo](src/main.zig) to know how to setup a simple.

## Why ?

The Zig3D library is maintaned by [me](https://github.com/Darkfllame/) to make 3D games. This library is bindings to the glfw, glad and stb library. The functions are adapted to the Zig conventions and avoid using C strings in profit of slices.