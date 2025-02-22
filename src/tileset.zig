pub const Tileset = struct {
    columns: u32,
    tile_count: u32,
    tile_width: u32,
    tile_height: u32,
    first_gid: u32,
    image: ?[]const u8,

    tiles: std.AutoHashMapUnmanaged(u32, Tile),

    pub fn initFromFile(allocator: Allocator, path: []const u8) anyerror!Tileset {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const json = try file.reader().readAllAlloc(allocator, std.math.maxInt(u32));
        defer allocator.free(json);

        return try initFromSlice(allocator, json);
    }

    pub fn initFromSlice(allocator: Allocator, json: []const u8) !Tileset {
        const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, json, .{ .ignore_unknown_fields = true });
        defer parsed_value.deinit();

        const tileset = try std.json.parseFromValue(JsonTileset, allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
        defer tileset.deinit();

        const json_tileset = tileset.value;

        return fromJson(allocator, json_tileset);
    }

    pub fn deinit(self: *Tileset, allocator: Allocator) void {
        if (self.image) |image| allocator.free(image);

        self.tiles.deinit(allocator);
    }

    pub fn fromJson(allocator: Allocator, tileset_json: JsonTileset) !Tileset {
        if (tileset_json.source) |source| {
            var tileset = try Tileset.initFromFile(allocator, source);
            tileset.first_gid = tileset_json.firstgid orelse 1;

            return tileset;
        }

        var tileset: Tileset = .{
            .columns = tileset_json.columns orelse 0,
            .tile_count = tileset_json.tilecount orelse 0,
            .tile_width = tileset_json.tilewidth orelse 0,
            .tile_height = tileset_json.tileheight orelse 0,
            .first_gid = tileset_json.firstgid orelse 1,
            .image = if (tileset_json.image) |image| try allocator.dupe(u8, image) else null,
            .tiles = .empty,
        };

        var tiles_by_id: std.AutoHashMapUnmanaged(u32, Tile.JsonTile) = .empty;
        defer tiles_by_id.deinit(allocator);

        if (tileset_json.tiles) |json_tiles| {
            for (json_tiles) |json_tile| {
                try tiles_by_id.put(allocator, json_tile.id, json_tile);
            }
        }

        var x: u32 = 0;
        var y: u32 = 0;

        var gid = tileset.first_gid - 1;

        const last_gid: u32 = gid + tileset.tile_count - 1;
        while (gid <= last_gid) : (gid += 1) {
            var tile: Tile = .{
                .tileset = tileset,
                .image = tileset.image,
                .id = gid,
                .x = x * (tileset_json.tilewidth.? + tileset_json.spacing) + tileset_json.margin,
                .y = y * (tileset_json.tileheight.? + tileset_json.spacing) + tileset_json.margin,
                .width = tileset_json.tilewidth.?,
                .height = tileset_json.tileheight.?,
            };

            if (tiles_by_id.get(gid)) |json_tile| {
                tile.animation = json_tile.animation;
                // tile = Tile.fromJson(json_tile);
            }
            try tileset.tiles.put(allocator, gid, tile);
            if (x >= @as(i64, @intCast(tileset.columns)) - 1) {
                y += 1;
                x = 0;
            } else {
                x += 1;
            }
        }

        return tileset;
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
    };
};

pub const Tile = struct {
    id: u32 = 1,
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    tileset: Tileset,
    image: ?[]const u8 = null,
    animation: ?[]const Frame = null,

    // pub fn fromJson(json_tile: JsonTile) Tile {
    //     return .{
    //         .id = json_tile.id,
    //         // .x = if (json_tile.x) |x| x else 0,
    //         // .y = if (json_tile.y) |y| y else 0,
    //         // .width = if (json_tile.width) |width| width else 0,
    //         // .height = if (json_tile.height) |height| height else 0,
    //     };
    // }

    pub const JsonTile = struct {
        id: u32,
        x: ?u32 = null,
        y: ?u32 = null,
        width: ?u32 = null,
        height: ?u32 = null,
        animation: ?[]const Frame = null,
    };
};

pub const Frame = struct {
    duration: u32,
    tile_id: u32,

    pub fn jsonParseFromValue(allocator: Allocator, source: std.json.Value, options: std.json.ParseOptions) !@This() {
        return try jsonParser(@This(), allocator, source, options);
    }
};

inline fn get(value: anytype) @TypeOf(value) {
    return if (value) |v| return v else null;
}

const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const jsonParser = @import("tmz.zig").jsonParser;
