const std = @import("std");
const tmz = @import("tmz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("thank you for playing wing commander");
    }

    const allocator = gpa.allocator();

    const tileset_file = @embedFile("tiles.tsj");
    const tileset = try tmz.loadTileset(allocator, tileset_file[0..]);
    defer tileset.deinit();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Tileset info: {}.\n", .{tileset});

    try bw.flush();
}
