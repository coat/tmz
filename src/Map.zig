height: u32,
width: u32,
tile_width: u32,
tile_height: u32,
infinite: bool,
orientation: Orientation,

layers: std.StringHashMapUnmanaged(Layer),
tilesets: std.ArrayList(Tileset),

background_color: ?Color = null,
class: ?[]const u8,

pub const Orientation = enum { orthogonal, isometric, staggered, hexagonal };

pub fn initFromSlice(alloc: Allocator, json: []const u8) !Map {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const parsed_value = try std.json.parseFromSliceLeaky(std.json.Value, arena_allocator, json, .{ .ignore_unknown_fields = true });

    const json_map = try std.json.parseFromValueLeaky(JsonMap, arena_allocator, parsed_value, .{ .ignore_unknown_fields = true });

    var map: Map = .{
        .height = json_map.height,
        .width = json_map.width,
        .tile_width = json_map.tilewidth,
        .tile_height = json_map.tileheight,
        .infinite = json_map.infinite,
        .orientation = json_map.orientation,

        .background_color = if (json_map.backgroundcolor) |color| color else null,
        .class = if (json_map.class) |c| try alloc.dupe(u8, c) else null,
        .tilesets = .empty,
        .layers = .empty,
    };

    if (json_map.tilesets) |json_tilesets| {
        for (json_tilesets) |json_tileset| {
            const tileset = try Tileset.fromJson(alloc, json_tileset);
            try map.tilesets.append(alloc, tileset);
        }
    }

    if (json_map.layers) |json_layers| {
        for (json_layers) |json_layer| {
            const layer = try Layer.fromJson(alloc, json_layer);
            try map.layers.put(alloc, layer.name, layer);
        }
    }

    return map;
}

pub fn initFromFile(allocator: Allocator, path: []const u8) !Map {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var reader: std.fs.File.Reader = .initStreaming(file, &.{});

    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();

    _ = try reader.interface.streamRemaining(&out.writer);

    const json = try out.toOwnedSlice();
    defer allocator.free(json);

    return initFromSlice(allocator, json);
}

pub fn deinit(self: *Map, allocator: Allocator) void {
    if (self.class) |class| allocator.free(class);

    var layers_it = self.layers.valueIterator();
    while (layers_it.next()) |value_ptr| {
        value_ptr.*.deinit(allocator);
    }
    self.layers.deinit(allocator);

    for (self.tilesets.items) |*tileset| {
        tileset.deinit(allocator);
    }
    self.tilesets.deinit(allocator);

    // var properties_it = self.properties.valueIterator();
    // while (properties_it.next()) |value_ptr| {
    //     value_ptr.*.deinit(allocator);
    // }
    // self.properties.deinit(allocator);
}

pub fn getTile(self: Map, gid: u32) ?Tile {
    if (gid == 0) return null;

    var i = self.tilesets.items.len - 1;
    while (i >= 0) : (i -= 1) {
        const tileset = self.tilesets.items[i];
        if (tileset.first_gid <= gid) {
            return tileset.tiles.get(gid - tileset.first_gid);
        }
    }
    return null;
}

/// Finds first object
pub fn findObjectByClass(self: Map, class: []const u8) ?Object {
    var layer_it = self.layers.valueIterator();
    while (layer_it.next()) |layer| {
        if (layer.content == .object_group) {
            if (layer.content.object_group.getByClass(class)) |object| {
                return object;
            }
        }
    }
    return null;
}

/// Finds first object by name
pub fn findObject(self: Map, name: []const u8) ?Object {
    var layer_it = self.layers.valueIterator();
    while (layer_it.next()) |layer| {
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
    hexsidelength: ?u32 = null,
    infinite: bool,
    layers: ?[]Layer.JsonLayer = null,
    /// Auto-increments for each layer
    nextlayerid: u32,
    /// Auto-increments for each placed object
    // next_object_id: u32,
    orientation: Orientation,
    parallaxoriginx: ?f32 = 0,
    parallaxoriginy: ?f32 = 0,
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

const Map = @This();

const tmz = @import("root.zig");
const Layer = tmz.Layer;
const Object = tmz.Object;
const Color = tmz.Color;
const Tileset = tmz.Tileset;
const Tile = tmz.Tile;
const Property = tmz.Property;

const std = @import("std");
const innerParseFromValue = std.json.innerParseFromValue;
const Allocator = std.mem.Allocator;
