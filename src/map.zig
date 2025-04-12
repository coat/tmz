pub const ManagedMap = tmz.Managed(Map);

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#map
pub const Map = struct {
    /// Hex-formatted color (#RRGGBB or #AARRGGBB)
    background_color: ?[]const u8 = null,
    class: ?[]const u8 = null,
    /// The compression level to use for tile layer data (defaults to -1, which means to use the algorithm default)
    // TODO: actually support this?
    compression_level: i32 = -1,
    /// Number of tile rows
    height: u32,
    /// Length of the side of a hex tile in pixels (hexagonal maps only)
    hex_side_length: ?u32 = null,
    infinite: bool,
    layers: []tmz.Layer,
    /// Auto-increments for each layer
    next_layer_id: u32,
    /// Auto-increments for each placed object
    next_object_id: u32,
    orientation: Orientation,
    parallax_origin_x: ?f32 = 0,
    parallax_origin_y: ?f32 = 0,
    properties: ?[]const tmz.Property = null,
    /// currently only supported for orthogonal maps
    render_order: RenderOrder,
    /// staggered / hexagonal maps only
    stagger_axis: ?StaggerAxis = null,
    /// staggered / hexagonal maps only
    stagger_index: ?StaggerIndex = null,
    tiled_version: []const u8,
    /// Map grid height
    tile_height: u32,
    tilesets: []tmz.Tileset,
    /// Map grid width
    tile_width: u32,
    version: []const u8,
    /// Number of tile columns
    width: u32,

    pub const Orientation = enum { orthogonal, isometric, staggered, hexagonal };
    pub const RenderOrder = enum { @"right-down", @"right-up", @"left-down", @"left-up" };
    pub const StaggerAxis = enum { x, y };
    pub const StaggerIndex = enum { odd, even };

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try tmz.jsonParser(@This(), allocator, source, options);
    }
};

/// load Map from a JSON string
pub fn load(allocator: Allocator, json: []const u8) !ManagedMap {
    const parsed_value = try std.json.parseFromSlice(Value, allocator, json, .{ .ignore_unknown_fields = true });
    defer parsed_value.deinit();
    const map = try std.json.parseFromValue(Map, allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
    return ManagedMap.fromJson(map);
}

pub fn loadFromFile(allocator: Allocator, file_path: []const u8) !ManagedMap {
    const file = try std.fs.cwd().openFile(file_path, .{});
    const json = try file.reader().readAllAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(json);

    return try load(allocator, json);
}

test "load works" {
    const test_maps = [_][]const u8{
        "src/test/map.tmj",
        "src/test/map-base64-none.tmj",
        "src/test/map-base64-gzip.tmj",
        "src/test/map-base64-zlib.tmj",
        "src/test/map-base64-zstd.tmj",
    };

    for (test_maps) |file| {
        const managed_map = try loadFromFile(std.testing.allocator, file);
        defer managed_map.deinit();

        const map = managed_map.value;
        try regularMapTests(map);
    }
}

test "infinite map with base64 chunks" {
    const infinite_map = @embedFile("test/map-infinite-base64-zstd.tmj");
    const managed_map = try load(std.testing.allocator, infinite_map);
    defer managed_map.deinit();

    const map = managed_map.value;
    try equals(true, map.infinite);

    try equals(3, map.layers.len);

    const chunk_layer = map.layers[0];
    try equals(4, chunk_layer.chunks.?.len);

    const chunk = chunk_layer.chunks.?[0];
    try equals(256, chunk.data.csv.len);
    try equals(16, chunk.data.csv[0]);
}

test "infinite map with csv chunks" {
    const infinite_map = @embedFile("test/map-infinite-csv.tmj");
    const managed_map = try load(std.testing.allocator, infinite_map);
    defer managed_map.deinit();

    const map = managed_map.value;
    try equals(true, map.infinite);
}

fn regularMapTests(map: Map) !void {
    try equals(false, map.infinite);
    try equals(null, map.background_color);
    try stringEquals("bar", map.class.?);
    try equals(-1, map.compression_level);
    try equals(30, map.height);
    try equals(null, map.hex_side_length);
    try equals(false, map.infinite);
    try equals(4, map.next_layer_id);
    try equals(3, map.next_object_id);
    try equals(.orthogonal, map.orientation);
    try equals(0, map.parallax_origin_x);
    try equals(0, map.parallax_origin_y);

    try equals(Map.RenderOrder.@"right-down", map.render_order);

    try stringEquals("1.10", map.version);

    try equals(3, map.layers.len);
    const layer = map.layers[0];

    try stringEquals("bar", layer.class.?);
    try equals(tmz.Layer.Type.tilelayer, layer.type);

    try equals(0, layer.x);
    try equals(0, layer.y);

    try equals(17, layer.data.?[0]);
    try equals(12, layer.data.?[1]);
}

const std = @import("std");
const equals = std.testing.expectEqual;
const stringEquals = std.testing.expectEqualStrings;
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;

const tmz = @import("tmz.zig");
const Tileset = @import("tileset.zig").Tileset;
