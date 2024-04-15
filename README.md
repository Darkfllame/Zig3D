# Zig3D

The Zig3D library is maintaned by [me](https://github.com/Darkfllame/) and is made to make 3D games. It provides the user bindings to the glfw, glad, stb libraries and others. The functions are adapted to the Zig conventions and avoid using C strings in profit of slices (and thus a lot of memory allocation sorry). It is updated a lot since i'm fully working on it on my free time.

## How to use

To use this library you have to fetch it with zig: `zig fetch --save=zig3d https://github.com/Darkfllame/Zig3D/archive/master.tar.gz` for the latest update.

##

After adding the dependency, you'll need to add:
```zig
const zig3d = b.dependency("zig3d", .{
  .optimize = optimize,
  .target = target,
});

...

exe.root_module.addImport("zig3d", zig3d.module("zig3d"));
```
to your `build.zig` file.

##

You can check out the [demos](examples/) for examples on how to use the library.

## Help me I guess.

Feel free to use, test it and give me ideas for this, you can also help me by proposing [pull requests](https://github.com/Darkfllame/Zig3D/pulls).

## The only slight little problem right now

Because of the (not existing) current version of hexops's GLFW working with zig's master, i'm using the [0.12.0-dev.3522+b88ae8dbd](https://ziglang.org/builds/zig-windows-x86_64-0.12.0-dev.3522%2Bb88ae8dbd.zip) version (April 3 2024) along with a pre april 3 zls version