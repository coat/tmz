test "initFromSlice" {
    try changeTestDir();

    const test_map = @embedFile("map.tmj");

    const allocator = std.testing.allocator;

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try baseTests(map);
}

test "initFromFile" {
    try changeTestDir();

    const allocator = std.testing.allocator;

    const test_maps = [_][]const u8{
        "map.tmj",
        "map-base64-none.tmj",
        "map-base64-gzip.tmj",
        "map-base64-zlib.tmj",
        "map-base64-zstd.tmj",
    };

    for (test_maps) |test_map| {
        var map = try Map.initFromFile(allocator, test_map);
        defer map.deinit(allocator);

        try regularMapTests(map);
    }
}

fn regularMapTests(map: Map) !void {
    try baseTests(map);

    try expectEqual(false, map.infinite);

    const layer = map.layers.get("Tile Layer 1").?;
    try expectEqual(1, layer.content.tile_layer.data.items[0]);
}

test "infinite maps" {
    try changeTestDir();

    const allocator = std.testing.allocator;

    const test_maps = [_][]const u8{
        "map-infinite-csv.tmj",
        "map-infinite-base64-zstd.tmj",
    };

    for (test_maps) |test_map| {
        var map = try Map.initFromFile(allocator, test_map);
        defer map.deinit(allocator);

        try infiniteMapTests(map);
    }
}

fn infiniteMapTests(map: Map) !void {
    try baseTests(map);

    try expectEqual(true, map.infinite);

    const layer = map.layers.get("ground").?;
    try expectEqual(7, layer.content.tile_layer.chunks.?[0].data[0]);
}

fn baseTests(map: Map) !void {
    try expectEqual(0xaa, map.background_color.?.a);
    try expectEqual(0xbb, map.background_color.?.r);
    try expectEqual(0xcc, map.background_color.?.g);

    try expectEqualStrings("bar", map.class.?);
    try expectEqual(30, map.height);
    try expectEqual(30, map.width);
    try expectEqual(.orthogonal, map.orientation);
    try expectEqual(16, map.tile_width);
    try expectEqual(16, map.tile_height);

    try expectEqual(2, map.tilesets.items.len);

    const tileset = map.tilesets.items[0];
    try expectEqual(1, tileset.first_gid);
    try expectEqualStrings("tilemap.png", tileset.image.?);

    const bad_tile = map.getTile(0);
    try expectEqual(null, bad_tile);

    const foo = map.getTile(2).?;
    try expectEqual(1, foo.id);
    try expectEqual(16, foo.x);
    try expectEqual(0, foo.y);

    const tile = map.getTile(4).?;
    try expectEqual(3, tile.id);
    try expectEqual(16, tile.x);
    try expectEqual(16, tile.y);
    try expectEqual(16, tile.width);
    try expectEqual(16, tile.height);

    try expectEqual(tileset.first_gid, tile.tileset.first_gid);

    try expectEqual(480, map.pixelWidth());
    try expectEqual(480, map.pixelHeight());
}

test "findObject" {
    try changeTestDir();

    const allocator = std.testing.allocator;
    const test_map = @embedFile("map.tmj");

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    const object = map.findObject("hello").?;
    try expectEqualStrings("hello", object.name);
    try expectEqual(70.0, object.x);
    try expectEqual(44.0, object.y);

    try expectEqual(null, map.findObject("non_existent"));
}

const tmz = @import("tmz");
const Map = tmz.Map;

const changeTestDir = @import("tests.zig").changeTestDir;

const std = @import("std");
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
