# Zig3D

The Zig3D library is maintaned by [me](https://github.com/Darkfllame/) and is made to make 3D games. It provides the user bindings to the glfw, glad, stb libraries and others. The functions are adapted to the Zig conventions and avoid using C strings in profit of slices (and thus a lot of memory allocation sorry). It is updated a lot since i'm fully working on it on my free time.

## How to use

To use this library you have to add a dependency in your `build.zig.zon` file:
```zig
.zig3d = .{
  .url = "https://github.com/Darkfllame/Zig3D/archive/7831191059abf96cb60ff0e3a42e1ff71b30466c.tar.gz",
  .hash = "1220471c1ccae62433a10c2115cb1dcdf4f18bc00a8b2a755ab18fec504182b5df6e",
},
```
For the latest update.

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