// this file is required because the c to zig
// translation would fail because of an implicit
// convertion between [*c]u8 and usize
#define STB_IMAGE_IMPLEMENTATION
#include <STB/stb_image.h>