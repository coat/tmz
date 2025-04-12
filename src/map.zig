pub const Map = struct {
    background_color: ?tmz.Color = null,
    height: u32,
    width: u32,
    tile_width: u32,
    tile_height: u32,
    infinite: bool,
    orientation: Orientation,

    layers: std.ArrayListUnmanaged(Layer),
    tilesets: std.ArrayListUnmanaged(Tileset),

    class: ?[]const u8,

    pub const Orientation = enum { orthogonal, isometric, staggered, hexagonal };

    pub fn initFromFile(allocator: Allocator, path: []const u8) anyerror!Map {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const json = try file.reader().readAllAlloc(allocator, std.math.maxInt(u32));
        defer allocator.free(json);

        return try initFromSlice(allocator, json);
    }

    pub fn initFromSlice(allocator: Allocator, json: []const u8) !Map {
        const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, json, .{ .ignore_unknown_fields = true });
        defer parsed_value.deinit();

        const map = try std.json.parseFromValue(JsonMap, allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
        defer map.deinit();

        return try init(allocator, map);
    }

    pub fn init(allocator: std.mem.Allocator, parsed_map: std.json.Parsed(JsonMap)) !Map {
        const json_map = parsed_map.value;

        var map: Map = .{
            .background_color = json_map.backgroundcolor,
            .height = json_map.height,
            .width = json_map.width,
            .tile_width = json_map.tilewidth,
            .tile_height = json_map.tileheight,
            .infinite = json_map.infinite,
            .orientation = json_map.orientation,
            .tilesets = .empty,
            .layers = .empty,

            .class = if (json_map.class) |class| try allocator.dupe(u8, class) else null,
        };

        if (json_map.tilesets) |json_tilesets| {
            for (json_tilesets) |json_tileset| {
                const tileset = try Tileset.fromJson(allocator, json_tileset);
                try map.tilesets.append(allocator, tileset);
            }
        }

        if (json_map.layers) |json_layers| {
            for (json_layers) |json_layer| {
                const layer = try Layer.fromJson(allocator, json_layer);
                try map.layers.append(allocator, layer);
            }
        }

        return map;
    }

    pub fn deinit(self: *Map, allocator: std.mem.Allocator) void {
        if (self.class) |class| allocator.free(class);

        for (self.tilesets.items) |*tileset| {
            tileset.deinit(allocator);
        }
        self.tilesets.deinit(allocator);

        for (self.layers.items) |*layer| {
            layer.deinit(allocator);
        }
        self.layers.deinit(allocator);
    }

    pub fn getTile(self: Map, gid: u32) ?Tile {
        if (gid == 0) return null;

        const tileset_len = self.tilesets.items.len;
        var i = tileset_len - 1;
        while (i >= 0) : (i -= 1) {
            const tileset = self.tilesets.items[i];
            if (tileset.first_gid <= gid) {
                return tileset.tiles.get(gid - tileset.first_gid);
            }
        }
        return null;
    }

    /// Finds first object
    pub fn getObjectByClass(self: Map, class: []const u8) ?tmz.Object {
        for (self.layers.items) |layer| {
            if (layer.content == .object_group) {
                if (layer.content.object_group.getByClass(class)) |object| {
                    return object;
                }
            }
        }
        return null;
    }

    /// Finds first object by name
    pub fn getObject(self: Map, name: []const u8) ?tmz.Object {
        for (self.layers.items) |layer| {
            if (layer.content == .object_group) {
                if (layer.content.object_group.get(name)) |object| {
                    return object;
                }
            }
        }
        return null;
    }

    pub fn pixelWidth(self: Map) u32 {
        return self.width * self.tile_width;
    }

    pub fn pixelHeight(self: Map) u32 {
        return self.height * self.tile_height;
    }

    /// https://doc.mapeditor.org/en/stable/reference/json-map-format/#map
    const JsonMap = struct {
        /// Hex-formatted color (#RRGGBB or #AARRGGBB)
        backgroundcolor: ?tmz.Color = null,
        class: ?[]const u8 = null,
        /// The compression level to use for tile layer data (defaults to -1, which means to use the algorithm default)
        // TODO: actually support this?
        compression_level: i32 = -1,
        /// Number of tile rows
        height: u32,
        /// Length of the side of a hex tile in pixels (hexagonal maps only)
        hex_side_length: ?u32 = null,
        infinite: bool,
        layers: ?[]Layer.JsonLayer = null,
        /// Auto-increments for each layer
        nextlayerid: u32,
        /// Auto-increments for each placed object
        // next_object_id: u32,
        orientation: Orientation,
        parallax_origin_x: ?f32 = 0,
        parallax_origin_y: ?f32 = 0,
        properties: ?[]Property = null,
        /// currently only supported for orthogonal maps
        renderorder: ?RenderOrder = null,
        /// staggered / hexagonal maps only
        staggeraxis: ?StaggerAxis = null,
        /// staggered / hexagonal maps only
        staggerindex: ?StaggerIndex = null,
        tiledversion: []const u8,
        /// Map grid height
        tileheight: u32,
        tilesets: ?[]Tileset.JsonTileset = null,
        /// Map grid width
        tilewidth: u32,
        version: []const u8,
        /// Number of tile columns
        width: u32,

        pub const RenderOrder = enum { @"right-down", @"right-up", @"left-down", @"left-up" };
        pub const StaggerAxis = enum { x, y };
        pub const StaggerIndex = enum { odd, even };
    };
};

test "initFromFile" {
    const allocator = std.testing.allocator;
    const test_maps = [_][]const u8{
        "src/test/map.tmj",
        "src/test/map-base64-none.tmj",
        "src/test/map-base64-gzip.tmj",
        "src/test/map-base64-zlib.tmj",
        "src/test/map-base64-zstd.tmj",
    };

    for (test_maps) |test_map| {
        var map = try Map.initFromFile(allocator, test_map);
        defer map.deinit(allocator);

        try testMap(map);
    }
}

test "initFromSlice" {
    const test_map = @embedFile("test/map.tmj");

    const allocator = std.testing.allocator;

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try testMap(map);
}

test "infinite map with base64 chunks" {
    const test_map = @embedFile("test/map-infinite-base64-zstd.tmj");

    const allocator = std.testing.allocator;

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try expectEqual(true, map.infinite);
}

test "infinite map with csv chunks" {
    const test_map = @embedFile("test/map-infinite-csv.tmj");

    const allocator = std.testing.allocator;

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    try expectEqual(true, map.infinite);

    try expectEqual(3, map.layers.items.len);

    // const chunk_layer = map.layers.items[0].tile_layer;
    // try expectEqual(4, chunk_layer.chunks.?.len);

    // const chunk = chunk_layer.chunks.?[0];
    // try expectEqual(256, chunk.data.csv.len);
    // try expectEqual(16, chunk.data.csv[0]);
}

fn testMap(map: Map) !void {
    try expectEqualStrings("bar", map.class.?);
    try expectEqual(30, map.height);
    try expectEqual(30, map.width);
    try expectEqual(false, map.infinite);
    try expectEqual(.orthogonal, map.orientation);
    try expectEqual(32, map.tile_width);
    try expectEqual(32, map.tile_height);
    try expectEqual(2, map.tilesets.items.len);

    const tileset = map.tilesets.items[0];
    try expectEqual(1, tileset.first_gid);
    try expectEqualStrings("tilemap.png", tileset.image.?);

    const layer = map.layers.items[0];
    try expectEqual(17, layer.content.tile_layer.data.items[0]);

    const bad_tile = map.getTile(0);
    try expectEqual(null, bad_tile);

    const foo = map.getTile(2).?;
    try expectEqual(1, foo.id);
    try expectEqual(17, foo.x);
    try expectEqual(0, foo.y);

    const tile = map.getTile(17).?;
    try expectEqual(16, tile.id);
    try expectEqual(272, tile.x);
    try expectEqual(0, tile.y);
    try expectEqual(16, tile.width);
    try expectEqual(16, tile.height);

    try expectEqual(tileset.first_gid, tile.tileset.first_gid);

    try expectEqual(960, map.pixelWidth());
    try expectEqual(960, map.pixelHeight());
}

test "findObjectByClass" {
    const allocator = std.testing.allocator;
    const test_map = @embedFile("test/map.tmj");

    var map = try Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    const object = map.getObjectByClass("hello_world").?;
    try expectEqualStrings("hello", object.name);
    try expectEqual(70.0, object.x);
    try expectEqual(44.0, object.y);

    try expectEqual(null, map.getObjectByClass("non_existent"));
}

const tmz = @import("tmz.zig");
const Tileset = tmz.Tileset;
const Tile = tmz.Tile;
const Property = tmz.Property;
const Layer = tmz.Layer;

const std = @import("std");
const Allocator = std.mem.Allocator;
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
