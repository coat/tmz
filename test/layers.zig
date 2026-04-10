test "object layer" {
    const allocator = std.testing.allocator;

    const json = @embedFile("object_layer.json");

    const parsed_layer = try std.json.parseFromSlice(std.json.Value, allocator, json, .{ .ignore_unknown_fields = true });
    defer parsed_layer.deinit();
    const managed_layer = try std.json.parseFromValue(Layer.JsonLayer, allocator, parsed_layer.value, .{ .ignore_unknown_fields = true });
    defer managed_layer.deinit();
    const json_layer = managed_layer.value;

    const properties = json_layer.properties.?;
    for (properties) |prop| {
        try std.testing.expectEqualStrings("custom", prop.name);
    }

    try expectEqual(Layer.JsonLayer.DrawOrder.topdown, json_layer.draw_order);

    var layer = try Layer.fromJson(allocator, json_layer);
    defer layer.deinit(allocator);

    const object_group = layer.content.object_group;

    try expectEqual(5, object_group.objects.items.len);

    const text_obj = object_group.objects.items[0];
    try expectEqual(.text, text_obj.type);
    const obj_prop = text_obj.properties.get("obj_prop").?;
    try expectEqualStrings("obj_value", obj_prop.value.string);

    const tile_obj = object_group.objects.items[1];
    try expectEqual(.tile, tile_obj.type);

    const ellipse_obj = object_group.objects.items[2];
    try expectEqual(.ellipse, ellipse_obj.type);

    const polygon_obj = object_group.objects.items[3];
    try expectEqual(.polygon, polygon_obj.type);

    const polyline_obj = object_group.objects.items[4];
    try expectEqual(.polyline, polyline_obj.type);

    const by_class = object_group.getByClass("hello").?;
    try expectEqual(1, by_class.id);

    const by_name = object_group.get("polygon").?;
    try expectEqual(8, by_name.id);

    try expectEqual(null, object_group.getByClass("nonexistent"));
    try expectEqual(null, object_group.get("nonexistent"));
}

test "image layer" {
    try changeTestDir();

    const allocator = std.testing.allocator;
    const test_map = @embedFile("map.tmj");

    var map = try tmz.Map.initFromSlice(allocator, test_map);
    defer map.deinit(allocator);

    const layer = map.findLayer("Image Layer 1").?;
    const image_layer = layer.content.image_layer;
    try expectEqualStrings("", image_layer.image);
    try expectEqual(false, image_layer.repeat_x);
    try expectEqual(false, image_layer.repeat_y);
    try expectEqual(null, image_layer.transparent_color);
}

test "Compression parses empty string as none" {
    const source: std.json.Value = .{ .string = "" };
    const compression = try Compression.jsonParseFromValue(std.testing.allocator, source, .{});
    try expectEqual(.none, compression);
}

const tmz = @import("tmz");
const Layer = tmz.Layer;
const Compression = @import("tmz").layer.Compression;

const changeTestDir = @import("tests.zig").changeTestDir;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
