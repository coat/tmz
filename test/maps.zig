test "initFromSlice" {
    try changeTestDir();

    const test_map = @embedFile("map.tmj");

    const allocator = std.testing.allocator;

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try baseTests(map);
    try templateObjectTests(map);
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

    const layer = map.findLayer("Tile Layer 1").?;
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

test "negative coordinate infinite maps" {
    try changeTestDir();

    const allocator = std.testing.allocator;

    const test_maps = [_][]const u8{
        "map-infinite-csv-negative.tmj",
        "map-infinite-base64-zstd-negative.tmj",
    };

    for (test_maps) |test_map| {
        var map = try Map.initFromFile(allocator, test_map);
        defer map.deinit(allocator);

        try expectEqual(true, map.infinite);

        const layer = map.findLayer("ground").?;
        const chunks = layer.content.tile_layer.chunks.?;
        try expectEqual(2, chunks.len);
        try expectEqual(7, chunks[1].data[0]);
        try expectEqual(0, chunks[0].data[0]);
        try expectEqual(4, chunks[0].data[chunks[0].data.len - 1]);
    }
}

fn infiniteMapTests(map: Map) !void {
    try baseTests(map);

    try expectEqual(true, map.infinite);

    const layer = map.findLayer("ground").?;
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
    try expectEqual(2 - tileset.first_gid, foo.tile.id);
    try expectEqual(16, foo.tile.x);
    try expectEqual(0, foo.tile.y);

    const result = map.getTile(4).?;
    try expectEqual(3, result.tile.id);
    try expectEqual(16, result.tile.x);
    try expectEqual(16, result.tile.y);
    try expectEqual(16, result.tile.width);
    try expectEqual(16, result.tile.height);

    try expectEqual(tileset.first_gid, result.tileset.first_gid);

    try expectEqual(480, map.pixelWidth());
    try expectEqual(480, map.pixelHeight());

    const properties = map.properties;
    try expectEqual(1, properties.size);

    const prop = properties.get("test_property").?;
    try expectEqualStrings("test_property", prop.name);
    try expectEqual(.string, prop.type);
    try expectEqualStrings("test_value", prop.value.string);
}

fn templateObjectTests(map: Map) !void {
    const obj = map.findObject("template_instance").?;

    // Instance overrides template's name "oh"
    try expectEqualStrings("template_instance", obj.name);
    // Instance width=80 overrides template width=100
    try expectEqual(80.0, obj.width);
    // height not in instance → inherited from template (84)
    try expectEqual(84.0, obj.height);
    // rotation not in instance → inherited from template (0)
    try expectEqual(0.0, obj.rotation);
    try expectEqual(true, obj.visible);
    try expectEqual(246.0, obj.x);
    try expectEqual(161.0, obj.y);
    try expectEqual(.rectangle, obj.type);

    // Both template and instance properties present
    try expectEqual(2, obj.properties.size);
    const template_prop = obj.properties.get("test").?;
    try expectEqual(.bool, template_prop.type);
    try expectEqual(true, template_prop.value.bool);
    const instance_prop = obj.properties.get("instance_prop").?;
    try expectEqual(.bool, instance_prop.type);
    try expectEqual(true, instance_prop.value.bool);
}

test "getTile with multiple tilesets" {
    try changeTestDir();

    const allocator = std.testing.allocator;
    const test_map = @embedFile("map.tmj");

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try expectEqual(null, map.getTile(0));

    const tile_from_first = map.getTile(2).?;
    try expectEqual(1, tile_from_first.tile.id);
    try expectEqual(1, tile_from_first.tileset.first_gid);

    const tile_from_second = map.getTile(5).?;
    try expectEqual(0, tile_from_second.tile.id);
    try expectEqual(5, tile_from_second.tileset.first_gid);

    try expectEqual(null, map.getTile(9999));
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

test "findLayerByClass" {
    try changeTestDir();

    const allocator = std.testing.allocator;
    const test_map = @embedFile("map.tmj");

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    const layer = map.findLayerByClass("bar").?;
    try expectEqualStrings("Tile Layer 1", layer.name);
    try expectEqualStrings("bar", layer.class.?);

    const obj_layer = map.findLayerByClass("objects_class").?;
    try expectEqualStrings("Object Layer 1", obj_layer.name);

    try expectEqual(null, map.findLayerByClass("non_existent"));
}

test "findLayersByClass" {
    try changeTestDir();

    const allocator = std.testing.allocator;
    const test_map = @embedFile("map.tmj");

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    var results: std.ArrayList(tmz.Layer) = .empty;
    defer results.deinit(allocator);

    try map.findLayersByClass(allocator, "bar", &results);
    try expectEqual(1, results.items.len);
    try expectEqualStrings("Tile Layer 1", results.items[0].name);

    var no_results: std.ArrayList(tmz.Layer) = .empty;
    defer no_results.deinit(allocator);

    try map.findLayersByClass(allocator, "non_existent", &no_results);
    try expectEqual(0, no_results.items.len);
}

const tmz = @import("tmz");
const Map = tmz.Map;

const changeTestDir = @import("tests.zig").changeTestDir;

const std = @import("std");
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
