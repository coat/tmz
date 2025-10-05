pub const Map = @import("Map.zig");
pub const Layer = layer.Layer;
pub const Object = layer.Object;
pub const Tileset = tileset.Tileset;
pub const Tile = tileset.Tile;
pub const Property = @import("Property.zig");

pub const Color = extern struct {
    a: u8 = 0,
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !@This() {
        return try parse(source.string);
    }

    // parses a Hex-formatted color (#RRGGBB or #AARRGGBB) string and returns
    // a Color. If no alpha channel value specified, defaults to 0
    pub fn parse(color_str: []const u8) !Color {
        if (color_str.len > 9 or color_str.len < 6) return error.UnexpectedToken;
        // buffer for the color_string stripped of '#'
        var hex_color: [8]u8 = @splat(0);
        // buffer for actual bytes parsed
        var color: [4]u8 = @splat(0);

        _ = std.mem.replace(u8, color_str, "#", "", &hex_color);
        // Handle strings with no alpha color defined
        if (color_str.len < 8) {
            // use same buffers for 32-bit color, but just use 6 bytes ascii and
            // 3 bytes for actual values
            _ = std.fmt.hexToBytes(color[1..4], hex_color[0..6]) catch return error.UnexpectedToken;
        } else {
            _ = std.fmt.hexToBytes(&color, &hex_color) catch return error.UnexpectedToken;
        }
        return std.mem.bytesToValue(Color, &color);
    }
};

test "Color is parsed from string" {
    const full_color = "#ccaaffee";
    const expected_full_color: Color = .{
        .a = 0xcc,
        .r = 0xaa,
        .g = 0xff,
        .b = 0xee,
    };

    try std.testing.expectEqual(expected_full_color, try Color.parse(full_color));

    const no_alpha_color = "#bbaadd";
    const expected_no_alpha_color: Color = .{
        .a = 0,
        .r = 0xbb,
        .g = 0xaa,
        .b = 0xdd,
    };

    try std.testing.expectEqual(expected_no_alpha_color, try Color.parse(no_alpha_color));

    const weird_color = "#DeaDBeeF";
    const expected_weird_color: Color = .{
        .a = 0xde,
        .r = 0xad,
        .g = 0xbe,
        .b = 0xef,
    };

    try std.testing.expectEqual(expected_weird_color, try Color.parse(weird_color));

    try std.testing.expectError(error.UnexpectedToken, Color.parse("##bbaabbee"));
}

const layer = @import("layer.zig");
const tileset = @import("tileset.zig");

const std = @import("std");
