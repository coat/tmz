/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#layer
pub const Layer = struct {
    /// `tilelayer` only.
    chunks: ?[]Chunk = null,
    class: ?[]const u8 = null,
    /// `tilelayer` only.
    compression: ?Compression = null,
    /// Array of unsigned int (GIDs)
    /// `tilelayer` only.
    data: ?[]u32 = null,
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
    layers: ?[]Layer = null,
    /// Whether layer is locked in the editor
    locked: bool = false,
    name: []const u8,
    /// `objectgroup` only.
    objects: ?[]Object = null,
    /// Horizontal layer offset in pixels
    offset_x: f32 = 0,
    /// Vertical layer offset in pixels
    offset_y: f32 = 0,
    opacity: f32,
    parallax_x: f32 = 1,
    parallax_y: f32 = 1,
    properties: ?std.StringHashMap(Property) = null,
    /// `imagelayer` only
    repeat_x: ?bool = null,
    /// `imagelayer` only
    repeat_y: ?bool = null,
    /// X coordinate where layer content starts (for infinite maps)
    start_x: ?i32 = null,
    /// Y coordinate where layer content starts (for infinite maps)
    start_y: ?i32 = null,
    /// Hex-formatted tint color (#RRGGBB or #AARRGGBB) that is multiplied with any graphics drawn by this layer or any child layers
    tint_color: ?[]const u8 = null,
    /// `imagelayer` only
    transparent_color: ?[]const u8 = null,
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

    pub const Compression = enum {
        none,
        zlib,
        gzip,
        zstd,

        pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
            _ = allocator;
            _ = options;
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

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        var layer = try jsonParser(@This(), allocator, source, options);

        if (source.object.get("properties")) |props| {
            const properties = try std.json.innerParseFromValue([]Property, allocator, props, .{});
            layer.properties = std.StringHashMap(Property).init(allocator);
            for (properties) |property| {
                try layer.properties.?.put(property.name, property);
            }
        }

        if (layer.type == .tilelayer) {
            if (layer.chunks) |chunks| {
                for (chunks) |*chunk| {
                    const chunk_size: usize = chunk.width * chunk.height;
                    if (layer.encoding == .base64) {
                        chunk.data = .{ .csv = parseBase64Data(allocator, chunk.data.base64, chunk_size, layer.compression orelse .none) };
                    }
                }
            }
            if (source.object.get("data")) |data| {
                if (layer.encoding == .csv) {
                    layer.data = try std.json.parseFromValueLeaky([]u32, allocator, data, options);
                } else {
                    const base64_data = try std.json.parseFromValueLeaky([]const u8, allocator, data, options);
                    const layer_size: usize = (layer.width orelse 0) * (layer.height orelse 0);

                    layer.data = parseBase64Data(allocator, base64_data, layer_size, layer.compression orelse .none);
                }
            }
        }
        return layer;
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#chunk
pub const Chunk = struct {
    /// Array of unsigned int (GIDs) or base64-encoded data
    data: EncodedData,
    height: u32,
    width: u32,
    x: u32,
    y: u32,

    const EncodedData = union(Layer.Encoding) {
        csv: []const u32,
        base64: []const u8,
    };

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        var chunk = try jsonParser(@This(), allocator, source, options);

        if (source.object.get("data")) |data| {
            switch (data) {
                .array => {
                    chunk.data = .{ .csv = try std.json.parseFromValueLeaky([]const u32, allocator, data, options) };
                },
                .string => {
                    chunk.data = .{ .base64 = try std.json.parseFromValueLeaky([]const u8, allocator, data, options) };
                },
                else => return error.UnexpectedToken,
            }
        }
        return chunk;
    }
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#object
pub const Object = struct {
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

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#point
pub const Point = struct {
    x: f32,
    y: f32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#text
pub const Text = struct {
    bold: bool,
    color: []const u8,
    font_family: []const u8 = "sans-serif",
    h_align: enum { center, right, justify, left } = .left,
    italic: bool = false,
    kerning: bool = true,
    pixel_size: usize = 16,
    strikeout: bool = false,
    text: []const u8,
    underline: bool = false,
    v_align: enum { center, bottom, top } = .top,
    wrap: bool = false,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        return try jsonParser(@This(), allocator, source, options);
    }
};

// Decode base64 data (and optionally decompress) into a slice of u32 Global Tile Ids allocated on the heap, caller owns slice
fn parseBase64Data(allocator: Allocator, base64_data: []const u8, size: usize, compression: Layer.Compression) []u32 {
    const decoded_size = base64_decoder.calcSizeForSlice(base64_data) catch @panic("Unable to decode base64 data");
    var decoded = allocator.alloc(u8, decoded_size) catch @panic("OOM");
    defer allocator.free(decoded);

    base64_decoder.decode(decoded, base64_data) catch @panic("Unable to decode base64 data");

    const data = allocator.alloc(u32, size) catch @panic("OOM");

    const alignment = @alignOf(u32);

    if (compression != .none)
        decoded = decompress(allocator, decoded, size, compression);

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
fn decompress(allocator: Allocator, compressed: []const u8, size: usize, compression: Layer.Compression) []u8 {
    const decompressed = allocator.alloc(u8, size * @alignOf(u32)) catch @panic("OOM");
    var decompressed_buf = std.io.fixedBufferStream(decompressed);
    var compressed_buf = std.io.fixedBufferStream(compressed);

    return switch (compression) {
        .gzip => {
            std.compress.gzip.decompress(compressed_buf.reader(), decompressed_buf.writer()) catch @panic("Unable to decompress gzip");
            return decompressed;
        },
        .zlib => {
            std.compress.zlib.decompress(compressed_buf.reader(), decompressed_buf.writer()) catch @panic("Unable to decompress zlib");
            return decompressed;
        },
        .zstd => {
            const window_buffer = allocator.alloc(u8, std.compress.zstd.DecompressorOptions.default_window_buffer_len) catch @panic("OOM");
            defer allocator.free(window_buffer);

            var zstd_stream = std.compress.zstd.decompressor(compressed_buf.reader(), .{ .window_buffer = window_buffer });
            _ = zstd_stream.reader().readAll(decompressed) catch @panic("Unable to decompress zstd");

            return decompressed;
        },
        .none => unreachable,
    };
}

test "Layer" {
    const allocator = std.testing.allocator;

    const json = @embedFile("test/object_layer.json");

    const parsed_layer = try std.json.parseFromSlice(Value, allocator, json, .{ .ignore_unknown_fields = true });
    defer parsed_layer.deinit();
    const managed_layer = try std.json.parseFromValue(Layer, allocator, parsed_layer.value, .{ .ignore_unknown_fields = true });
    defer managed_layer.deinit();
    const layer = managed_layer.value;

    const properties = layer.properties.?;
    var iterator = properties.iterator();
    while (iterator.next()) |entry| {
        try std.testing.expectEqualStrings("custom", entry.value_ptr.name);
    }

    try expectEqual(Layer.DrawOrder.topdown, layer.draw_order);
}

const Property = @import("property.zig").Property;
const jsonParser = @import("tmz.zig").jsonParser;

const std = @import("std");
const base64_decoder = std.base64.standard.Decoder;
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
