# Zig3D

This project uses a [glfw](https://github.com/hexops/glfw) from the Mach Engine dev, [GLAD](https://glad.dav1d.de) and the [STB library](https://github.com/nothings/stb).

## How to use

To use this you just have to add a dependency in your `build.zig.zon` file:
```zig
.dependencies = .{
  .zig3d = .{
    .url = "https://github.com/Darkfllame/Zig3D/archive/9d45fc49b6ae8df17610efe21dc008eb23a9e3b7.tar.gz",
    .hash = "1220ecef10039f71dfdbe4c5bf04b7fce4ce40c56351040e850d9f1f79b74b613e71",
  }
}
```
For the latest update.

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