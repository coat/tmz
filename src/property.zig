/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#property
pub const Property = struct {
    name: []const u8,
    property_type: ?[]const u8,
    type: enum { string, int, float, bool, color, file } = .string,
    value: union(enum) {
        string: []const u8,
        int: u32,
        float: f32,
        bool: bool,
        color: Color,
        file: []const u8,
    },

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: ParseOptions) !Property {
        var property = try tmz.jsonParser(Property, allocator, source, options);
        const value = source.object.get("value") orelse return error.UnexpectedToken;
        property.value = switch (property.type) {
            .string => .{ .string = try std.json.innerParseFromValue([]const u8, allocator, value, options) },
            .int => .{ .int = try std.json.innerParseFromValue(u32, allocator, value, options) },
            .float => .{ .float = try std.json.innerParseFromValue(f32, allocator, value, options) },
            .bool => .{ .bool = try std.json.innerParseFromValue(bool, allocator, value, options) },
            .color => .{ .color = try std.json.innerParseFromValue(Color, allocator, value, options) },
            .file => .{ .file = try std.json.innerParseFromValue([]const u8, allocator, value, options) },
        };

        return property;
    }
};

test "Property is parsed correctly" {
    const properties_json = @embedFile("test/properties.json");

    const parsed_value = try std.json.parseFromSlice(Value, std.testing.allocator, properties_json, .{ .ignore_unknown_fields = true });
    defer parsed_value.deinit();
    const managed_properties = try std.json.parseFromValue([]Property, std.testing.allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
    defer managed_properties.deinit();

    const properties = managed_properties.value;
    const string_prop = properties[0];
    try std.testing.expectEqualStrings("name", string_prop.name);
    try std.testing.expectEqual(.string, string_prop.type);
    try std.testing.expectEqualStrings("game", string_prop.value.string);

    const int_prop = properties[1];
    try std.testing.expectEqualStrings("width", int_prop.name);
    try std.testing.expectEqual(.int, int_prop.type);
    try std.testing.expectEqual(640, int_prop.value.int);

    const float_prop = properties[2];
    try std.testing.expectEqualStrings("scale", float_prop.name);
    try std.testing.expectEqual(.float, float_prop.type);
    try std.testing.expectEqual(1.5, float_prop.value.float);

    const color_prop = properties[3];
    try std.testing.expectEqualStrings("bg", color_prop.name);
    try std.testing.expectEqual(.color, color_prop.type);
    try std.testing.expectEqual(Color{ .a = 0xff, .r = 0xa0, .g = 0xb0, .b = 0xc0 }, color_prop.value.color);

    const bool_prop = properties[4];
    try std.testing.expectEqualStrings("fullscreen", bool_prop.name);
    try std.testing.expectEqual(.bool, bool_prop.type);
    try std.testing.expectEqual(true, bool_prop.value.bool);

    const file_prop = properties[5];
    try std.testing.expectEqualStrings("splashscreen", file_prop.name);
    try std.testing.expectEqual(.file, file_prop.type);
    try std.testing.expectEqualStrings("splashscreen.png", file_prop.value.file);
}

const std = @import("std");
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;
const Allocator = std.mem.Allocator;

const tmz = @import("tmz.zig");
const Color = tmz.Color;
