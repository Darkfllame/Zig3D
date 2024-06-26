const std = @import("std");

const fs = std.fs;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

pub const getStdOut = std.io.getStdOut;

pub const toRadians = std.math.pi / 180.0;
pub const toDegrees = 180.0 / std.math.pi;

pub fn print(comptime format: []const u8, args: anytype) File.WriteError!void {
    const stdout = getStdOut().writer();
    try stdout.print(format, args);
}
pub fn println(comptime format: []const u8, args: anytype) File.WriteError!void {
    try print(format ++ "\n", args);
}
pub fn printAlloc(allocator: Allocator, comptime fmt: []const u8, args: anytype) std.fmt.AllocPrintError![]u8 {
    return std.fmt.allocPrint(allocator, fmt, args);
}
pub fn printlnAlloc(allocator: Allocator, comptime fmt: []const u8, args: anytype) Allocator.Error![]u8 {
    return printAlloc(allocator, fmt ++ "\n", args);
}

pub fn copy(comptime T: type, src: []const T, dst: []T) []T {
    const len = @min(src.len, dst.len);
    for (0..len) |i|
        dst[i] = src[i];
    return dst;
}

pub fn slice2ZSent(allocator: Allocator, slice: []const u8) Allocator.Error![:0]u8 {
    const block = copy(
        u8,
        slice,
        allocator.alloc(u8, slice.len + 1) catch return Allocator.Error.OutOfMemory,
    );
    block[slice.len] = 0;
    return block[0..slice.len :0];
}

// return a null-terminated string by default
pub fn readFile(allocator: Allocator, filename: []const u8) (File.ReadError || File.OpenError || Allocator.Error || fs.SelfExePathError)![:0]u8 {
    const SEPARATOR = comptime if (@import("builtin").os.tag == .windows) "\\" else "/";

    const file = fs.cwd().openFile(filename, .{}) catch |e| blk: {
        if (e == File.OpenError.FileNotFound) {
            const exeDirPath = try fs.selfExePathAlloc(allocator);
            defer allocator.free(exeDirPath);

            const pathFromExe = try std.mem.join(allocator, SEPARATOR, &.{
                exeDirPath,
                filename,
            });
            defer allocator.free(pathFromExe);

            break :blk fs.openFileAbsolute(pathFromExe, .{}) catch |e2| return e2;
        }
        return e;
    };
    defer file.close();

    // as I read, it is unexpected to get an error here
    const sz = file.getEndPos() catch unreachable;
    const buf = try allocator.allocSentinel(u8, sz, 0);
    errdefer allocator.free(buf);
    _ = try file.read(buf);
    return buf;
}

pub fn FnErrorSet(comptime F: anytype) type {
    return @typeInfo(@typeInfo(@TypeOf(F)).Fn.return_type.?).ErrorUnion.error_set;
}

pub inline fn opaqueCast(comptime T: type, v: anytype) @TypeOf(v) {
    if (@typeInfo(T) != .Pointer or @typeInfo(@TypeOf(v)) != .Pointer) {
        @compileError("'T' and 'v' must be/have pointer type, got " ++ @tagName(@typeInfo(T)) ++ " and " ++ @tagName(@typeInfo(@TypeOf(v))));
    }

    return @ptrCast(@alignCast(@constCast(@volatileCast(v))));
}

pub const ErrorLogger = struct {
    allocator: Allocator,
    buffer: ?[]u8 = null,

    pub fn init(allocator: Allocator) ErrorLogger {
        return .{
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *ErrorLogger) void {
        self.clearError();
        self.* = undefined;
    }

    pub fn clearError(self: *ErrorLogger) void {
        if (self.buffer) |buf| self.allocator.free(buf);
        self.buffer = null;
    }
    pub fn getMessage(self: *ErrorLogger) []const u8 {
        return self.buffer orelse "";
    }
    pub fn log(self: *ErrorLogger, comptime E: type, err: (E || Allocator.Error), comptime fmt: []const u8, args: anytype) @TypeOf(err) {
        self.clearError();

        var arr = std.ArrayList(u8).init(self.allocator);
        defer arr.deinit();

        try arr.writer().print(fmt, args);

        self.buffer = try arr.toOwnedSlice();

        return err;
    }
};
