test "Property is parsed correctly" {
    const allocator = std.testing.allocator;
    const properties_json = @embedFile("properties.json");

    const parsed_value = try std.json.parseFromSlice(std.json.Value, allocator, properties_json, .{ .ignore_unknown_fields = true });
    defer parsed_value.deinit();
    const managed_properties = try std.json.parseFromValue([]Property, allocator, parsed_value.value, .{ .ignore_unknown_fields = true });
    defer managed_properties.deinit();

    const json_properties = managed_properties.value;

    var properties: std.ArrayList(Property) = .empty;
    for (json_properties) |prop| {
        try properties.append(allocator, try Property.fromJson(allocator, prop));
    }
    defer {
        for (properties.items) |*p| p.deinit(allocator);
        properties.deinit(allocator);
    }

    const string_prop = properties.items[0];
    try expectEqualStrings("name", string_prop.name);
    try expectEqual(.string, string_prop.type);
    try expectEqualStrings("game", string_prop.value.string);

    const int_prop = properties.items[1];
    try expectEqualStrings("width", int_prop.name);
    try expectEqual(.int, int_prop.type);
    try expectEqual(640, int_prop.value.int);

    const float_prop = properties.items[2];
    try expectEqualStrings("scale", float_prop.name);
    try expectEqual(.float, float_prop.type);
    try expectEqual(1.5, float_prop.value.float);

    const color_prop = properties.items[3];
    try expectEqualStrings("bg", color_prop.name);
    try expectEqual(.color, color_prop.type);
    try expectEqual(Color{ .a = 0xff, .r = 0xa0, .g = 0xb0, .b = 0xc0 }, color_prop.value.color);

    const bool_prop = properties.items[4];
    try expectEqualStrings("fullscreen", bool_prop.name);
    try expectEqual(.bool, bool_prop.type);
    try expectEqual(true, bool_prop.value.bool);

    const file_prop = properties.items[5];
    try expectEqualStrings("splashscreen", file_prop.name);
    try expectEqual(.file, file_prop.type);
    try expectEqualStrings("splashscreen.png", file_prop.value.file);
}

const tmz = @import("tmz");
const Property = tmz.Property;
const Color = tmz.Color;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
