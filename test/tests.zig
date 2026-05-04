comptime {
    _ = @import("maps.zig");
    _ = @import("layers.zig");
    _ = @import("tilesets.zig");
    _ = @import("properties.zig");
    _ = @import("objects.zig");
}

pub fn changeTestDir() !void {
    const io = std.testing.io;

    const file_name = try Io.Dir.cwd().realPathFileAlloc(io, ".", std.testing.allocator);
    defer std.testing.allocator.free(file_name);

    if (std.mem.endsWith(u8, file_name, "test")) return;

    var dir = try Io.Dir.cwd().openDir(io, "test", .{});
    defer dir.close(io);

    try std.process.setCurrentDir(io, dir);
}

const std = @import("std");
const Io = std.Io;
