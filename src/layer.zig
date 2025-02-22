/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#layer
pub const Layer = struct {
    /// `objectgroup` only.
    draw_order: ?DrawOrder = .topdown,
    /// Incremental ID - unique across all layers
    id: u32,
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
    type: Type,
    visible: bool,
    /// Horizontal layer offset in tiles. Always 0.
    x: i32 = 0,
    /// Vertical layer offset in tiles. Always 0.
    y: i32 = 0,

    pub const DrawOrder = enum { topdown, index };
    pub const Encoding = enum { csv, base64 };
    pub const Type = enum { tilelayer, objectgroup, imagelayer, group };

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !@This() {
        var layer = try jsonParser(@This(), allocator, source, options);

        if (source.object.get("properties")) |props| {
            const properties = try std.json.innerParseFromValue([]Property, allocator, props, .{});
            layer.properties = std.StringHashMap(Property).init(allocator);
            for (properties) |property| {
                try layer.properties.?.put(property.name, property);
            }
        }

        return layer;
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
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;
