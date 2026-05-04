test "object template: instance overrides template fields and properties" {
    try changeTestDir();
    const allocator = std.testing.allocator;

    var map = try Map.initFromFile(std.testing.io, allocator, "map_template_override.tmj");
    defer map.deinit(allocator);

    const obj = map.findObject("override_test").?;

    // width: instance 150 overrides template 200
    try expectEqual(150.0, obj.width);
    // height: not in instance, inherited from template (50)
    try expectEqual(50.0, obj.height);
    // rotation: not in instance, inherited from template (45.0)
    try expectEqual(45.0, obj.rotation);
    // visible: instance true overrides template false
    try expectEqual(true, obj.visible);
    // name: instance overrides template "base"
    try expectEqualStrings("override_test", obj.name);
    try expectEqual(.rectangle, obj.type);

    // shared_key: instance "from_instance" wins over template "from_template"
    const shared = obj.properties.get("shared_key").?;
    try expectEqual(.string, shared.type);
    try expectEqualStrings("from_instance", shared.value.string);

    // template_only: flows through from template (no instance override)
    const tmpl_only = obj.properties.get("template_only").?;
    try expectEqual(.int, tmpl_only.type);
    try expectEqual(99, tmpl_only.value.int);

    try expectEqual(2, obj.properties.size);
}

const tmz = @import("tmz");
const Map = tmz.Map;
const changeTestDir = @import("tests.zig").changeTestDir;
const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;
