# Zig3D

The Zig3D library is maintaned by [me](https://github.com/Darkfllame/) and is made to make 3D games. It provides the user bindings to the glfw, glad, stb libraries and others. The functions are adapted to the Zig conventions and avoid using C strings in profit of slices (and thus a lot of memory allocation sorry).

## How to use

To use this library you have to fetch it with zig: `zig fetch --save https://github.com/Darkfllame/Zig3D/archive/<commit>.tar.gz`, replace `<commit>` by the commit hash of you choice or replace it with `main` (or `master`, the two works the same) for the latest update.

##

After adding the dependency, you'll need to add:

```zig
const zig3d = b.dependency("zig3d", .{
  .optimize = optimize,
  .target = target,
  // if you're on windows this wont work, look at this [issue](https://github.com/Darkfllame/Zig3D/issues/1) for more infos
  .shared = false,
  .exposeC = true, // optional, set whether to expose c apis under a "capi" namespace. This is for glad, glfw, stb and freetype (even though freetype is always exposed since I did not make the zig API yet)
});

...

exe.root_module.addImport("zig3d", zig3d.module("zig3d"));
```

to your `build.zig` file.

##

You can check out the [demos](examples/) for examples on how to use the library.

**Notes**:

- There is low (almost no) documentation, so you'll need to check out on khronos group's site for errors and what parameters do.
- Most of the library is entirely compiled using zig, so you can expect slow compilation especially when first build.
- Expect bugs, the library is pretty recent and I'm litteraly going back and forth with this one (I do multiple projects at once, dumb me)

## Help me I guess.

Feel free to use, test it and give me ideas for this, you can also help me by proposing [pull requests](https://github.com/Darkfllame/Zig3D/pulls).

## Now on 0.12.0

Now works on zig 0.12.0, probably will update it further more on more recent zig updates.

## Little things so I don't get sued

Also thanks to mach-engine's dev(s?) for zig support on GLFW and freetype, big mwah
