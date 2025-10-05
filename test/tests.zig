comptime {
    _ = @import("maps.zig");
    _ = @import("layers.zig");
    _ = @import("tilesets.zig");
    _ = @import("properties.zig");
}

pub fn changeTestDir() !void {
    var dir = std.fs.cwd().openDir("test", .{}) catch return;
    defer dir.close();

    try dir.setAsCwd();
}

const std = @import("std");
