comptime {
    _ = @import("maps.zig");
    _ = @import("layers.zig");
    _ = @import("tilesets.zig");
    _ = @import("properties.zig");
}

pub fn changeTestDir() !void {
    const file_name = try std.fs.cwd().realpathAlloc(std.testing.allocator, ".");
    defer std.testing.allocator.free(file_name);

    if (std.mem.endsWith(u8, file_name, "test")) return;

    var dir = try std.fs.cwd().openDir("test", .{});
    defer dir.close();

    try dir.setAsCwd();
}

const std = @import("std");
