pub const Property = @import("property.zig").Property;

pub const Tileset = tileset.Tileset;
pub const Tile = tileset.Tile;
pub const loadTilesetFromSlice = Tileset.initFromSlice;
pub const loadTilesetFromFile = Tileset.initFromFile;

pub const Color = packed struct(u32) {
    a: u8 = 0,
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: Value, _: ParseOptions) !@This() {
        return try parseColor(source.string);
    }
};

// parses a Hex-formatted color (#RRGGBB or #AARRGGBB) string and returns
// a Color. If no alpha channel value specified, defaults to 0
fn parseColor(color_string: []const u8) !Color {
    if (color_string.len > 9 or color_string.len < 6) return error.UnexpectedToken;
    // buffer for the color_string stripped of '#'
    var hex_color: [8]u8 = @splat(0);
    // buffer for actual bytes parsed
    var color: [4]u8 = @splat(0);

    _ = std.mem.replace(u8, color_string, "#", "", &hex_color);
    // Handle strings with no alpha color defined
    if (color_string.len < 8) {
        // use same buffers for 32-bit color, but just use 6 bytes ascii and
        // 3 bytes for actual values
        _ = std.fmt.hexToBytes(color[1..4], hex_color[0..6]) catch return error.UnexpectedToken;
    } else {
        _ = std.fmt.hexToBytes(&color, &hex_color) catch return error.UnexpectedToken;
    }
    return std.mem.bytesToValue(Color, &color);
}

test "Color is parsed from string" {
    const full_color = "#ccaaffee";
    const expected_full_color: Color = .{
        .a = 0xcc,
        .r = 0xaa,
        .g = 0xff,
        .b = 0xee,
    };

    try std.testing.expectEqual(expected_full_color, try parseColor(full_color));

    const no_alpha_color = "#bbaadd";
    const expected_no_alpha_color: Color = .{
        .a = 0,
        .r = 0xbb,
        .g = 0xaa,
        .b = 0xdd,
    };

    try std.testing.expectEqual(expected_no_alpha_color, try parseColor(no_alpha_color));

    const weird_color = "#DeaDBeeF";
    const expected_weird_color: Color = .{
        .a = 0xde,
        .r = 0xad,
        .g = 0xbe,
        .b = 0xef,
    };

    try std.testing.expectEqual(expected_weird_color, try parseColor(weird_color));

    try std.testing.expectError(error.UnexpectedToken, parseColor("##bbaabbee"));
}

// converts masheduppropertynames to Zig style snake_case field names and
// ignores data, value and properties so they can be handled later
pub fn jsonParser(T: type, allocator: Allocator, source: Value, options: ParseOptions) !T {
    var t: T = undefined;

    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime eql(u8, field.name, "data") or eql(u8, field.name, "value") or eql(u8, field.name, "properties")) continue;

        const size = comptime std.mem.replacementSize(u8, field.name, "_", "");
        var tiled_name: [size]u8 = undefined;
        _ = std.mem.replace(u8, field.name, "_", "", &tiled_name);

        const source_field = source.object.get(&tiled_name);
        if (source_field) |s| {
            @field(t, field.name) = try std.json.innerParseFromValue(field.type, allocator, s, options);
        } else {
            if (field.default_value_ptr) |val| {
                @field(t, field.name) = @as(*align(1) const field.type, @ptrCast(val)).*;
            }
        }
    }

    return t;
}

const TestJson = struct {
    property_id: u8 = 0,
    data: u8,
    value: u8,

    pub fn jsonParseFromValue(allocator: Allocator, source: Value, options: std.json.ParseOptions) !@This() {
        return try jsonParser(@This(), allocator, source, options);
    }
};

test "jsonParser works" {
    const test_json =
        \\{
        \\  "propertyid": 9,
        \\  "data": 8,
        \\  "value": 7
        \\}
    ;
    const parsed_value = try std.json.parseFromSlice(Value, std.testing.allocator, test_json, .{});
    defer parsed_value.deinit();

    const parsed_json = try std.json.parseFromValue(TestJson, std.testing.allocator, parsed_value.value, .{});
    defer parsed_json.deinit();

    // Property names are "converted" to snake_case
    try std.testing.expectEqual(9, parsed_json.value.property_id);

    // `data` and `value` fields are ignored
    try std.testing.expectEqual(0xaa, parsed_json.value.data);
    try std.testing.expectEqual(0xaa, parsed_json.value.value);
}
test {
    std.testing.refAllDeclsRecursive(@This());
}

const std = @import("std");
const eql = std.mem.eql;
const Allocator = std.mem.Allocator;
const ParseOptions = std.json.ParseOptions;
const Value = std.json.Value;

const tileset = @import("tileset.zig");
const layer = @import("layer.zig");
