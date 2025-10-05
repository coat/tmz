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
    //
    const object_group = layer.content.object_group;
    //
    try expectEqual(5, object_group.objects.items.len);
    // {
    //     const object = object_group.getByClass("hello").?;
    //     try expectEqual(1, object.id);
    // }
    //
    // {
    //     const object = object_group.get("polygon").?;
    //     try expectEqual(8, object.id);
    // }
}

const tmz = @import("tmz");
const Layer = tmz.Layer;

const std = @import("std");
const expectEqual = std.testing.expectEqual;
