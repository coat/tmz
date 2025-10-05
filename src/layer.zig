pub const Layer = struct {
    id: u32,
    name: []const u8,
    content: LayerContent,
    visible: bool,
    class: ?[]const u8 = null,

    pub fn fromJson(allocator: Allocator, json_layer: JsonLayer) !Layer {
        return .{
            .class = if (json_layer.class) |class| try allocator.dupe(u8, class) else null,
            .id = json_layer.id,
            .name = try allocator.dupe(u8, json_layer.name),
            .visible = json_layer.visible,
            .content = try LayerContent.fromJson(allocator, json_layer),
        };
    }

    pub fn deinit(self: *Layer, allocator: Allocator) void {
        if (self.class) |class| allocator.free(class);
        allocator.free(self.name);
        self.content.deinit(allocator);
    }

    /// https://doc.mapeditor.org/en/stable/reference/jsonk-map-format/#layer
    pub const JsonLayer = struct {
        /// `tilelayer` only.
        chunks: ?[]Chunk.JsonChunk = null,
        class: ?[]const u8 = null,
        /// `tilelayer` only.
        compression: ?Compression = null,
        /// Array of unsigned int (GIDs)
        /// `tilelayer` only.
        layer_data: ?[]u32 = null,
        /// `objectgroup` only.
        draw_order: ?DrawOrder = .topdown,
        /// `tilelayer` only.
        encoding: ?Encoding = .csv,
        /// Row count. Same as map height for fixed-size maps.
        /// `tilelayer` only.
        height: ?u32 = null,
        /// Incremental ID - unique across all layers
        id: u32,
        /// `imagelayer` only
        image: ?[]const u8 = null,
        /// `group` only
        layers: ?[]JsonLayer = null,
        /// Whether layer is locked in the editor
        locked: bool = false,
        name: []const u8,
        /// `objectgroup` only.
        objects: ?[]Object.JsonObject = null,
        /// Horizontal layer offset in pixels
        offsetx: f32 = 0,
        /// Vertical layer offset in pixels
        offsety: f32 = 0,
        opacity: f32,
        parallaxx: f32 = 1,
        parallaxy: f32 = 1,
        properties: ?[]Property = null,
        /// `imagelayer` only
        repeatx: ?bool = null,
        /// `imagelayer` only
        repeaty: ?bool = null,
        /// X coordinate where layer content starts (for infinite maps)
        startx: ?i32 = null,
        /// Y coordinate where layer content starts (for infinite maps)
        starty: ?i32 = null,
        /// Hex-formatted tint color (#RRGGBB or #AARRGGBB) that is multiplied with any graphics drawn by this layer or any child layers
        tintcolor: ?Color = null,
        /// `imagelayer` only
        transparentcolor: ?Color = null,
        type: Type,
        visible: bool,
        /// Column count. Same as map width for fixed-size maps.
        /// `tilelayer` only.
        width: ?u32 = null,
        /// Horizontal layer offset in tiles. Always 0.
        x: i32 = 0,
        /// Vertical layer offset in tiles. Always 0.
        y: i32 = 0,

        pub const DrawOrder = enum { topdown, index };
        pub const Encoding = enum { csv, base64 };
        pub const Type = enum { tilelayer, objectgroup, imagelayer, group };

        pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !JsonLayer {
            var layer: JsonLayer = .{
                .class = if (source.object.get("class")) |class| try innerParseFromValue([]const u8, allocator, class, options) else null,
                .compression = if (source.object.get("compression")) |compression| try innerParseFromValue(Compression, allocator, compression, options) else null,
                .chunks = if (source.object.get("chunks")) |chunks| try innerParseFromValue([]Chunk.JsonChunk, allocator, chunks, options) else null,
                .layer_data = if (source.object.get("layerdata")) |layerdata| try innerParseFromValue([]u32, allocator, layerdata, options) else null,
                .draw_order = if (source.object.get("draworder")) |draworder| try innerParseFromValue(DrawOrder, allocator, draworder, options) else .topdown,
                .encoding = if (source.object.get("encoding")) |encoding| try innerParseFromValue(Encoding, allocator, encoding, options) else .csv,
                .height = if (source.object.get("height")) |height| try innerParseFromValue(u32, allocator, height, options) else null,

                .id = try innerParseFromValue(u32, allocator, source.object.get("id").?, options),
                .image = if (source.object.get("image")) |image| try innerParseFromValue([]const u8, allocator, image, options) else null,
                .layers = if (source.object.get("layers")) |layers| try innerParseFromValue([]JsonLayer, allocator, layers, options) else null,
                .locked = if (source.object.get("locked")) |locked| try innerParseFromValue(bool, allocator, locked, options) else false,
                .name = try innerParseFromValue([]const u8, allocator, source.object.get("name").?, options),
                .objects = if (source.object.get("objects")) |objects| try innerParseFromValue([]Object.JsonObject, allocator, objects, options) else null,
                .offsetx = if (source.object.get("offsetx")) |offsetx| try innerParseFromValue(f32, allocator, offsetx, options) else 0,
                .offsety = if (source.object.get("offsety")) |offsety| try innerParseFromValue(f32, allocator, offsety, options) else 0,
                .opacity = try innerParseFromValue(f32, allocator, source.object.get("opacity").?, options),
                .parallaxx = if (source.object.get("parallaxx")) |parallaxx| try innerParseFromValue(f32, allocator, parallaxx, options) else 1,
                .parallaxy = if (source.object.get("parallaxy")) |parallaxy| try innerParseFromValue(f32, allocator, parallaxy, options) else 1,
                .properties = if (source.object.get("properties")) |properties| try innerParseFromValue([]Property, allocator, properties, options) else null,
                .repeatx = if (source.object.get("repeatx")) |repeatx| try innerParseFromValue(bool, allocator, repeatx, options) else null,
                .startx = if (source.object.get("startx")) |startx| try innerParseFromValue(i32, allocator, startx, options) else null,
                .starty = if (source.object.get("starty")) |starty| try innerParseFromValue(i32, allocator, starty, options) else null,
                .tintcolor = if (source.object.get("tintcolor")) |tintcolor| try innerParseFromValue(Color, allocator, tintcolor, options) else null,
                .transparentcolor = if (source.object.get("transparentcolor")) |transparentcolor| try innerParseFromValue(Color, allocator, transparentcolor, options) else null,
                .type = try innerParseFromValue(Type, allocator, source.object.get("type").?, options),
                .visible = try innerParseFromValue(bool, allocator, source.object.get("visible").?, options),
                .width = if (source.object.get("width")) |width| try innerParseFromValue(u32, allocator, width, options) else null,
                .x = if (source.object.get("x")) |x| try innerParseFromValue(i32, allocator, x, options) else 0,
                .y = if (source.object.get("y")) |y| try innerParseFromValue(i32, allocator, y, options) else 0,
            };

            if (layer.type == .tilelayer) {
                if (source.object.get("data")) |data| {
                    if (layer.encoding == .csv) {
                        layer.layer_data = try innerParseFromValue([]u32, allocator, data, options);
                    } else {
                        const base64_data = try innerParseFromValue([]const u8, allocator, data, options);
                        const layer_size: usize = (layer.width orelse 0) * (layer.height orelse 0);

                        layer.layer_data = parseBase64Data(allocator, base64_data, layer_size, layer.compression orelse .none);
                    }
                }
            }

            return layer;
        }
    };
};

pub const Compression = enum {
    none,
    zlib,
    gzip,
    zstd,

    pub fn jsonParseFromValue(_: Allocator, source: Value, _: ParseOptions) !@This() {
        return switch (source) {
            .string, .number_string => |value| cmp: {
                if (value.len == 0) {
                    break :cmp .none;
                } else {
                    break :cmp std.meta.stringToEnum(Compression, value) orelse .none;
                }
            },
            else => .none,
        };
    }
};

pub const TileLayer = struct {
    data: std.ArrayList(u32),
    chunks: ?[]Chunk = null,

    pub fn fromJson(allocator: Allocator, json_layer: Layer.JsonLayer) !TileLayer {
        var layer: TileLayer = .{
            .data = .empty,
        };
        if (json_layer.layer_data) |json_data| {
            try layer.data.insertSlice(allocator, 0, json_data);
        }
        if (json_layer.chunks) |json_chunks| {
            layer.chunks = try allocator.alloc(Chunk, json_chunks.len);
            for (json_chunks, 0..) |json_chunk, i| {
                layer.chunks.?[i] = try Chunk.fromJson(allocator, json_chunk, json_layer.compression orelse .none);
            }
        }
        return layer;
    }

    pub fn deinit(self: *TileLayer, allocator: Allocator) void {
        if (self.chunks) |chunks| {
            for (chunks) |*chunk| {
                chunk.deinit(allocator);
            }
            allocator.free(chunks);
        }
        self.data.deinit(allocator);
    }
};

pub const ObjectGroup = struct {
    objects: std.ArrayListUnmanaged(Object),

    pub fn fromJson(allocator: Allocator, json_layer: Layer.JsonLayer) !ObjectGroup {
        var object_group: ObjectGroup = .{
            .objects = .empty,
        };
        if (json_layer.objects) |json_objects| {
            for (json_objects) |json_object| {
                const object = try Object.fromJson(allocator, json_object);
                try object_group.objects.append(allocator, object);
            }
        }

        return object_group;
    }

    pub fn deinit(self: *ObjectGroup, allocator: Allocator) void {
        for (self.objects.items) |*object| {
            object.deinit(allocator);
        }
        self.objects.deinit(allocator);
    }

    pub fn getByClass(self: ObjectGroup, class: []const u8) ?Object {
        for (self.objects.items) |object| {
            if (object.class) |object_class| {
                if (std.mem.eql(u8, object_class, class)) {
                    return object;
                }
            }
        }
        return null;
    }

    pub fn get(self: ObjectGroup, name: []const u8) ?Object {
        for (self.objects.items) |object| {
            if (std.mem.eql(u8, object.name, name)) {
                return object;
            }
        }
        return null;
    }
};
pub const ImageLayer = struct {};
pub const Group = struct {};

pub const LayerContent = union(enum) {
    tile_layer: TileLayer,
    object_group: ObjectGroup,
    image_layer: ImageLayer,
    group: Group,

    pub fn fromJson(allocator: Allocator, json_layer: Layer.JsonLayer) !LayerContent {
        switch (json_layer.type) {
            .tilelayer => {
                return .{
                    .tile_layer = try TileLayer.fromJson(allocator, json_layer),
                };
            },
            else => return .{ .object_group = try ObjectGroup.fromJson(allocator, json_layer) },
        }
    }

    pub fn deinit(self: *LayerContent, allocator: Allocator) void {
        switch (self.*) {
            .tile_layer => |*layer| {
                layer.deinit(allocator);
            },
            .object_group => |*group| {
                group.deinit(allocator);
            },
            else => {},
        }
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#chunk
pub const Chunk = struct {
    data: []u32,
    height: u32,
    width: u32,
    x: u32,
    y: u32,

    /// https://doc.mapeditor.org/en/stable/reference/json-map-format/#chunk
    pub const JsonChunk = struct {
        /// Array of unsigned int (GIDs) or base64-encoded data
        data: EncodedData,
        height: u32,
        width: u32,
        x: u32,
        y: u32,

        const EncodedData = union(Layer.JsonLayer.Encoding) {
            csv: []u32,
            base64: []const u8,
        };

        pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
            var chunk: JsonChunk = .{
                .height = try innerParseFromValue(u32, allocator, source.object.get("height").?, options),
                .width = try innerParseFromValue(u32, allocator, source.object.get("width").?, options),
                .x = try innerParseFromValue(u32, allocator, source.object.get("x").?, options),
                .y = try innerParseFromValue(u32, allocator, source.object.get("y").?, options),
                .data = undefined,
            };

            if (source.object.get("data")) |data| {
                if (data == .array) {
                    chunk.data = .{ .csv = try innerParseFromValue([]u32, allocator, data, options) };
                }
                if (data == .string) {
                    chunk.data = .{ .base64 = try innerParseFromValue([]const u8, allocator, data, options) };
                }
            }
            return chunk;
        }
    };

    pub fn fromJson(allocator: Allocator, json_chunk: JsonChunk, compression: Compression) !Chunk {
        var arena_state = std.heap.ArenaAllocator.init(allocator);
        defer arena_state.deinit();
        const arena = arena_state.allocator();

        const data: []u32 = try allocator.dupe(
            u32,
            set_data: {
                switch (json_chunk.data) {
                    .csv => break :set_data json_chunk.data.csv,
                    .base64 => {
                        const base64_data = parseBase64Data(arena, json_chunk.data.base64, json_chunk.width * json_chunk.height, compression);

                        break :set_data base64_data;
                    },
                }
            },
        );

        return .{
            .x = json_chunk.x,
            .y = json_chunk.y,
            .width = json_chunk.width,
            .height = json_chunk.height,

            .data = data,
        };
    }

    pub fn deinit(self: *Chunk, allocator: Allocator) void {
        allocator.free(self.data);
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#object
pub const Object = struct {
    gid: ?u32 = null,
    height: f32,
    id: u32,
    name: []const u8,
    point: ?bool = null,
    polygon: ?[]Point = null,
    polyline: ?[]Point = null,
    properties: ?[]Property = null,
    rotation: f32,
    template: ?[]const u8 = null,
    text: ?Text = null,
    class: ?[]const u8 = null,
    visible: bool,
    width: f32,
    x: f32,
    y: f32,

    type: Type,

    pub const Type = enum {
        rectangle,
        ellipse,
        polygon,
        polyline,
        tile,
        text,
    };

    pub fn fromJson(allocator: Allocator, json_object: JsonObject) !Object {
        const object: Object = .{
            .gid = json_object.gid,
            .height = json_object.height,
            .id = json_object.id,
            .name = try allocator.dupe(u8, json_object.name),
            .point = json_object.point,
            .class = if (json_object.type) |class| try allocator.dupe(u8, class) else null,
            .rotation = json_object.rotation,
            .visible = json_object.visible,
            .width = json_object.width,
            .x = json_object.x,
            .y = json_object.y,

            .type = set_type: {
                if (json_object.gid) |_| {
                    break :set_type .tile;
                }
                if (json_object.ellipse) |_| {
                    break :set_type .ellipse;
                }
                if (json_object.polygon) |_| {
                    break :set_type .polygon;
                }
                if (json_object.polyline) |_| {
                    break :set_type .polyline;
                }
                if (json_object.text) |_| {
                    break :set_type .text;
                }
                break :set_type .rectangle;
            },
        };
        return object;
    }

    pub fn deinit(self: *Object, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.class) |class| allocator.free(class);
    }

    const JsonObject = struct {
        ellipse: ?bool = null,
        gid: ?u32 = null,
        height: f32,
        id: u32,
        name: []const u8,
        point: ?bool = null,
        polygon: ?[]Point = null,
        polyline: ?[]Point = null,
        properties: ?[]Property = null,
        rotation: f32,
        template: ?[]const u8 = null,
        text: ?Text = null,
        type: ?[]const u8 = null,
        visible: bool,
        width: f32,
        x: f32,
        y: f32,
    };
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#point
pub const Point = struct {
    x: f32,
    y: f32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#text
pub const Text = struct {
    bold: ?bool = null,
    color: ?[]const u8 = null,
    fontfamily: []const u8 = "sans-serif",
    halign: enum { center, right, justify, left } = .left,
    italic: bool = false,
    kerning: bool = true,
    pixelsize: u32 = 16,
    strikeout: bool = false,
    text: []const u8,
    underline: bool = false,
    valign: enum { center, bottom, top } = .top,
    wrap: bool = false,
};

// Decode base64 data (and optionally decompress) into a slice of u32 Global Tile Ids allocated on the heap, caller owns slice
fn parseBase64Data(allocator: Allocator, base64_data: []const u8, size: usize, compression: Compression) []u32 {
    // var arena = std.heap.ArenaAllocator.init(allocator);
    // defer arena.deinit();
    // const arena_allocator = arena.allocator();

    const decoded_size = base64_decoder.calcSizeForSlice(base64_data) catch @panic("Unable to decode base64 data");
    var decoded = allocator.alloc(u8, decoded_size) catch @panic("OOM");
    defer allocator.free(decoded);

    base64_decoder.decode(decoded, base64_data) catch @panic("Unable to decode base64 data");

    const data = allocator.alloc(u32, size) catch @panic("OOM");

    const alignment = @alignOf(u32);

    if (compression != .none)
        decoded = decompress(allocator, decoded, compression);

    if (size * alignment != decoded.len)
        @panic("data size does not match Layer dimensions");

    for (data, 0..) |*tile, i| {
        const tile_index = i * alignment;
        const end = tile_index + alignment;
        tile.* = std.mem.readInt(u32, decoded[tile_index..end][0..alignment], .little);
    }

    return data;
}

// caller owns returned slice
fn decompress(allocator: Allocator, compressed: []const u8, compression: Compression) []u8 {
    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();

    var compressed_reader: std.Io.Reader = .fixed(compressed);

    return switch (compression) {
        .gzip => {
            var decompresser: std.compress.flate.Decompress = .init(&compressed_reader, .gzip, &.{});
            _ = decompresser.reader.streamRemaining(&out.writer) catch @panic("Unable to decompress gzip");

            return out.toOwnedSlice() catch @panic("OOM");
        },
        .zlib => {
            var decompresser: std.compress.flate.Decompress = .init(&compressed_reader, .zlib, &.{});
            _ = decompresser.reader.streamRemaining(&out.writer) catch @panic("Unable to decompress zlib");

            return out.toOwnedSlice() catch @panic("OOM");
        },
        .zstd => {
            var decompresser: std.compress.zstd.Decompress = .init(&compressed_reader, &.{}, .{});

            _ = decompresser.reader.streamRemaining(&out.writer) catch @panic("Unable to decompress zstd");

            return out.toOwnedSlice() catch @panic("OOM");
        },
        .none => return @constCast(compressed),
    };
}

const tmz = @import("root.zig");
const Color = tmz.Color;
const Property = tmz.Property;

const std = @import("std");
const base64_decoder = std.base64.standard.Decoder;
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;
const innerParseFromValue = std.json.innerParseFromValue;
const expectEqual = std.testing.expectEqual;
