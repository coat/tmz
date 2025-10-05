pub const Tileset = struct {
    columns: u32,
    tilecount: u32,
    tile_width: u32,
    tile_height: u32,
    first_gid: u32,

    image: ?[]const u8 = null,

    tiles: std.AutoHashMapUnmanaged(u32, Tile),
    properties: std.StringHashMapUnmanaged(Property),

    pub fn initFromSlice(alloc: Allocator, json: []const u8) !Tileset {
        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        const parsed_value = try std.json.parseFromSliceLeaky(
            std.json.Value,
            arena_allocator,
            json,
            .{ .ignore_unknown_fields = true },
        );

        const json_tileset = try std.json.parseFromValueLeaky(
            JsonTileset,
            arena_allocator,
            parsed_value,
            .{ .ignore_unknown_fields = true },
        );

        return try fromJson(alloc, json_tileset);
    }

    pub fn fromJson(allocator: Allocator, json_tileset: JsonTileset) !Tileset {
        if (json_tileset.source) |source| {
            var source_tileset = try initFromFile(allocator, source);
            source_tileset.first_gid = json_tileset.firstgid orelse 1;

            return source_tileset;
        }

        var tileset: Tileset = .{
            .columns = json_tileset.columns orelse 0,
            .tilecount = json_tileset.tilecount orelse 0,
            .tile_width = json_tileset.tilewidth orelse 0,
            .tile_height = json_tileset.tileheight orelse 0,
            .first_gid = json_tileset.firstgid orelse 1,

            .image = if (json_tileset.image) |image| try allocator.dupe(u8, image) else null,

            .tiles = .empty,
            .properties = .empty,
        };

        if (json_tileset.tiles) |json_tiles| {
            for (json_tiles) |json_tile| {
                const tile = try Tile.fromJson(allocator, json_tile, tileset);
                try tileset.tiles.put(allocator, tile.id, tile);
            }
        }

        var x: u32 = 0;
        var y: u32 = 0;

        var gid = tileset.first_gid - 1;

        const last_gid: u32 = gid + tileset.tilecount -| 1;
        while (gid <= last_gid) : (gid += 1) {
            const tile_x = x * (tileset.tile_width + json_tileset.spacing) + json_tileset.margin;
            const tile_y = y * (tileset.tile_height + json_tileset.spacing) + json_tileset.margin;

            var tile: Tile = fetch_or_create: {
                if (tileset.tiles.getPtr(gid)) |t| {
                    t.*.x = tile_x;
                    t.*.y = tile_y;
                    break :fetch_or_create t.*;
                } else {
                    break :fetch_or_create .{
                        .id = gid,
                        .x = tile_x,
                        .y = tile_y,

                        .tileset = tileset,
                    };
                }
            };
            tile.width = tileset.tile_width;
            tile.height = tileset.tile_height;
            try tileset.tiles.put(allocator, gid, tile);

            if (x >= @as(i64, @intCast(tileset.columns)) - 1) {
                y += 1;
                x = 0;
            } else {
                x += 1;
            }
        }

        if (json_tileset.properties) |properties| {
            for (properties) |property| {
                const prop = try Property.fromJson(allocator, property);
                try tileset.properties.put(allocator, prop.name, prop);
            }
        }

        return tileset;
    }

    pub fn initFromFile(allocator: Allocator, path: []const u8) anyerror!Tileset {
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

    pub fn deinit(self: *Tileset, allocator: Allocator) void {
        if (self.image) |image| allocator.free(image);

        var tiles_it = self.tiles.valueIterator();
        while (tiles_it.next()) |value_ptr| {
            value_ptr.*.deinit(allocator);
        }

        self.tiles.deinit(allocator);

        var properties_it = self.properties.valueIterator();
        while (properties_it.next()) |value_ptr| {
            value_ptr.*.deinit(allocator);
        }
        self.properties.deinit(allocator);
    }

    pub const JsonTileset = struct {
        columns: ?u32 = null,
        tilecount: ?u32 = null,
        firstgid: ?u32 = 1,
        margin: u32 = 0,
        source: ?[]const u8 = null,
        spacing: u32 = 0,
        image: ?[]const u8 = null,
        tiles: ?[]Tile.JsonTile = null,
        tilewidth: ?u32 = null,
        tileheight: ?u32 = null,
        properties: ?[]Property = null,
    };
};

pub const Tile = struct {
    id: u32 = 1,
    x: u32 = 0,
    y: u32 = 0,
    width: u32 = 0,
    height: u32 = 0,
    animation: ?[]const Frame = null,
    tileset: Tileset,

    pub const JsonTile = struct {
        id: u32,
        x: ?u32 = null,
        y: ?u32 = null,
        width: ?u32 = null,
        height: ?u32 = null,
        animation: ?[]const Frame = null,
    };

    pub fn fromJson(allocator: Allocator, json_tile: JsonTile, tileset: Tileset) !Tile {
        return .{
            .id = json_tile.id,
            .x = json_tile.x orelse 0,
            .y = json_tile.y orelse 0,
            .width = json_tile.width orelse tileset.tile_width,
            .height = json_tile.height orelse tileset.tile_height,
            .animation = if (json_tile.animation) |animation| try allocator.dupe(Frame, animation) else null,
            .tileset = tileset,
        };
    }

    pub fn deinit(self: *Tile, allocator: Allocator) void {
        if (self.animation) |animation| allocator.free(animation);
    }

    pub fn jsonParseFromValue(allocator: Allocator, source: std.json.Value, options: std.json.ParseOptions) !Tile {
        return .{
            .id = try innerParseFromValue(u32, allocator, source.object.get("id").?, options),
            .animation = if (source.object.get("animation")) |animation| try innerParseFromValue([]const Frame, allocator, animation, options) else null,
            .tileset = undefined,
        };
    }
};

pub const Frame = struct {
    duration: u32,
    tileid: u32,
};

inline fn get(value: anytype) @TypeOf(value) {
    return if (value) |v| return v else null;
}

const Property = @import("Property.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
const innerParseFromValue = std.json.innerParseFromValue;
