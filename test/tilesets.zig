test "initFromSlice" {
    const test_tileset = @embedFile("tileset.tsj");

    const allocator = std.testing.allocator;

    var tileset = try Tileset.initFromSlice(allocator, test_tileset);
    defer tileset.deinit(allocator);

    try expectEqual(4, tileset.tilecount);
    try expectEqual(16, tileset.tile_width);
    try expectEqual(16, tileset.tile_height);
    try expectEqual(4, tileset.tiles.size);
    try expectEqual(1, tileset.first_gid);
    try expectEqualStrings("tilemap.png", tileset.image.?);

    const tile_0 = tileset.tiles.get(0).?;
    try expectEqual(0, tile_0.id);
    try expectEqual(null, tile_0.animation);
    try expectEqual(0, tile_0.x);
    try expectEqual(0, tile_0.y);
    try expectEqual(tileset.tile_width, 16);

    const tile_1 = tileset.tiles.get(1).?;
    try expectEqual(1, tile_1.id);
    try expectEqual(1 * tileset.tile_width, tile_1.x);
    try expectEqual(0, tile_1.y);

    const tile_2 = tileset.tiles.get(2).?;
    try expectEqual(2, tile_2.id);
    try expectEqual(0, tile_2.x);
    try expectEqual(1 * tileset.tile_height, tile_2.y);

    const tile_3 = tileset.tiles.get(3).?;
    try expectEqual(3, tile_3.id);
    try expectEqual(1 * tileset.tile_width, tile_3.x);
    try expectEqual(1 * tileset.tile_height, tile_3.y);
    try expectEqual(4, tile_3.animation.?.len);

    const properties = tileset.properties;
    try expectEqual(1, properties.size);

    const prop = properties.get("custom").?;
    try expectEqualStrings("custom", prop.name);
    try expectEqual(.int, prop.type);
    try expectEqual(50, prop.value.int);
}

const tmz = @import("tmz");
const Tileset = tmz.Tileset;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
