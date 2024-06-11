const std = @import("std");
const zig3d = @import("zig3d");

const DGR = zig3d.DGR;

const Game = DGR.Game;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const game = try Game.init(allocator, "DGR - Test", 800, 600);
    defer game.deinit();

    game.run();
}
