This project uses a [glfw fork from the Mach Engine dev](https://github.com/hexops/glfw) and [GLAD](https://glad.dav1d.de).

To use this you just have to add a dependency in your `build.zig.zon` file: `https://github.com/Darkfllame/zig-glad-glfw/archive/<commit>.tar.gz`. <commit>
being the git commit to use. Zig will tell you the hash when compiling.

After adding the dependency, you'll add
```zig
const glad_glfw = b.dependency(<the name of the dep>, .{
  .optimize = optimize,
  .target = target,
});

...

exe.linkLibrary(glad_glfw.artifact("glad-glfw"))
exe.root_module.addImport("glad-glfw", glad_glfw.module("glad-glfw"));
```
