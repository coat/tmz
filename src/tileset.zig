/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#tileset
pub const Tileset = struct {
    background_color: ?Color,
    class: ?[]const u8 = null,
    columns: ?u32 = null,
    fill_mode: ?FillMode = .stretch,
    first_gid: u32,
    grid: ?Grid = null,
    image: ?[]const u8 = null,
    image_height: ?u32 = null,
    image_width: ?u32 = null,
    margin: ?u32 = null,
    name: ?[]const u8 = null,
    object_alignment: ?ObjectAlignment = .unspecified,
    properties: ?std.StringHashMap(Property) = null,
    source: ?[]const u8 = null,
    spacing: ?i32 = null,
    terrains: ?[]Terrain = null,
    tile_count: ?u32 = null,
    tiled_version: ?[]const u8 = null,
    tile_height: ?u32 = null,
    tile_offset: ?tmz.Point = null,
    tile_render_size: ?TileRenderSize = .tile,
    tiles: ?[]Tile = null,
    tile_width: ?u32 = null,
    transformations: ?Transformations = null,
    transparent_color: ?Color = null,
    type: ?Type = .tileset,
    version: ?[]const u8 = null,
    wang_sets: ?[]WangSet = null,

    pub const FillMode = enum { stretch, preserve_aspect_fit };
    pub const TileRenderSize = enum { tile, grid };
    pub const Type = enum { tileset };

    pub const ObjectAlignment = enum {
        unspecified,
        topleft,
        top,
        topright,
        left,
        center,
        right,
        bottomleft,
        bottom,
        bottomright,
    };

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        var tileset = try tmz.jsonParser(@This(), allocator, source, options);

        if (tileset.source) |s| {
            // TODO: handle errors better
            const managed_tileset = loadFromFile(allocator, s) catch @panic("couldn't open tileset");

            return managed_tileset.value;
        }

        if (source.object.get("properties")) |props| {
            const properties = try std.json.innerParseFromValue([]Property, allocator, props, .{});
            tileset.properties = std.StringHashMap(Property).init(allocator);
            for (properties) |property| {
                try tileset.properties.?.put(property.name, property);
            }
        }

        return tileset;
    }
};

pub const ManagedTileset = tmz.Managed(Tileset);

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#grid
pub const Grid = struct {
    orientation: enum { orthogonal, isometric } = .orthogonal,
    height: i32,
    width: i32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#terrain
pub const Terrain = struct {
    name: []const u8,
    properties: []Property,
    tile: i32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#tile-definition
pub const Tile = struct {
    id: i32,
    name: ?[]const u8,
    image: ?[]const u8,
    image_height: u32,
    image_width: u32,
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
    probability: f32 = 0,
    properties: ?[]Property = null,
    terrain: ?[]i32 = null,
    type: []const u8 = "",

    animation: ?[]Frame,
    objectgroup: ?Layer,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try tmz.jsonParser(@This(), allocator, source, options);
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#frame
pub const Frame = struct {
    duration: i32,
    tile_id: i32,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try tmz.jsonParser(@This(), allocator, source, options);
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#transformations
pub const Transformations = struct {
    h_flip: bool,
    v_flip: bool,
    rotate: bool,
    prefer_untransformed: bool,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try tmz.jsonParser(@This(), allocator, source, options);
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#wang-set
pub const WangSet = struct {
    class: ?[]const u8 = null,
    colors: ?[]WangColor = null,
    name: []const u8,
    properties: ?[]Property = null,
    tile: i32,
    type: Type,
    wang_tiles: []WangTile,

    pub const Type = enum { corner, edge, mixed };

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try tmz.jsonParser(@This(), allocator, source, options);
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#wang-color
pub const WangColor = struct {
    class: ?[]const u8 = null,
    color: Color,
    name: []const u8,
    probability: f32,
    properties: ?[]Property = null,
    tile: i32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#wang-tile
pub const WangTile = struct {
    tile_id: i32,
    wang_id: [8]u8,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !WangTile {
        return try tmz.jsonParser(WangTile, allocator, source, options);
    }
};

/// load Tileset from file
pub fn loadFromFile(allocator: Allocator, file_path: []const u8) !ManagedTileset {
    const file = try std.fs.cwd().openFile(file_path, .{});
    const tileset_json = try file.reader().readAllAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(tileset_json);

    return try load(allocator, tileset_json);
}

test "loadFromFile works" {
    const managed_tileset = try loadFromFile(std.testing.allocator, "src/test/tileset.tsj");
    defer managed_tileset.deinit();

    try testTileset(managed_tileset.value);
}

/// load Tileset from a JSON string
pub fn load(allocator: Allocator, tileset_json: []const u8) !ManagedTileset {
    const parsed_value = try std.json.parseFromSlice(Value, allocator, tileset_json, .{ .ignore_unknown_fields = true });
    defer parsed_value.deinit();
    const tileset = try std.json.parseFromValue(Tileset, allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
    return ManagedTileset.fromJson(tileset);
}

test "load works" {
    const test_tileset_file = @embedFile("test/tileset.tsj");
    const managed_tileset = try load(std.testing.allocator, test_tileset_file[0..]);
    defer managed_tileset.deinit();

    try testTileset(managed_tileset.value);
}

fn testTileset(tileset: Tileset) !void {
    try expectEqual(tmz.Color{ .a = 0, .r = 0xff, .g = 0xaa, .b = 0xff }, tileset.background_color);
    try expectEqual(37, tileset.columns);
    try expectEqualStrings("tilemap.png", tileset.image.?);
    try expectEqual(475, tileset.image_height.?);
    try expectEqual(628, tileset.image_width.?);
    try expectEqual(0, tileset.margin.?);
    try expectEqualStrings("tiles", tileset.name.?);

    const properties = tileset.properties.?;
    try expectEqual(50, properties.get("custom").?.value.int);

    try expectEqual(1, tileset.spacing.?);
    try expectEqual(1131, tileset.tile_count.?);
    try expectEqualStrings("1.11.2", tileset.tiled_version.?);
    try expectEqual(16, tileset.tile_height.?);
    try expectEqual(16, tileset.tile_width.?);
    try expectEqual(Transformations{
        .h_flip = true,
        .v_flip = true,
        .prefer_untransformed = true,
        .rotate = false,
    }, tileset.transformations.?);
    try expectEqual(.tileset, tileset.type);
    try expectEqualStrings("1.10", tileset.version.?);

    const wang_sets = tileset.wang_sets;
    try expectEqual(1, wang_sets.?.len);

    const wang_set = tileset.wang_sets.?[0];
    const colors = wang_set.colors.?;
    try expectEqual(2, colors.len);
    try expectEqual(Color{ .r = 0xff }, colors[0].color);
    try expectEqualStrings("Dirt", colors[0].name);
    try expectEqual(1, colors[0].probability);
    try expectEqual(892, colors[0].tile);
    try expectEqualStrings("Ground", wang_set.name);
    try expectEqual(1002, wang_set.tile);
    try expectEqual(.mixed, wang_set.type);

    const wang_tiles = wang_set.wang_tiles;
    try expectEqual(3, wang_tiles.len);
    const wang_tile = wang_tiles[0];
    try expectEqual(888, wang_tile.tile_id);
    const wang_id = wang_tile.wang_id;
    try expectEqual(8, wang_id.len);

    const tiles = tileset.tiles.?;
    try expectEqual(2, tiles.len);
    try expectEqual(0, tiles[0].id);

    const objectgroup = tiles[0].objectgroup.?;
    try expectEqual(3, objectgroup.id);

    const animation = tiles[1].animation.?;

    try expectEqual(4, animation.len);
}

const std = @import("std");
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const tmz = @import("tmz.zig");
const Color = tmz.Color;
const Property = tmz.Property;

const Layer = @import("layer.zig").Layer;
