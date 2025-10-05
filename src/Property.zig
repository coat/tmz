/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#property
name: []const u8,
property_type: ?[]const u8,
type: Type = .string,
value: Value,

const Type = enum { string, int, float, bool, color, file };
const Value = union(enum) {
    string: []const u8,
    int: u32,
    float: f32,
    bool: bool,
    color: Color,
    file: []const u8,
};

pub fn fromJson(allocator: Allocator, property: Property) !Property {
    const value: Value = switch (property.value) {
        .string => .{ .string = try allocator.dupe(u8, property.value.string) },
        .file => .{ .file = try allocator.dupe(u8, property.value.file) },
        else => property.value,
    };

    return .{
        .name = try allocator.dupe(u8, property.name),
        .property_type = if (property.property_type) |pt| try allocator.dupe(u8, pt) else null,
        .type = property.type,
        .value = value,
    };
}

pub fn deinit(self: *Property, allocator: Allocator) void {
    allocator.free(self.name);
    if (self.property_type) |pt| allocator.free(pt);
    switch (self.type) {
        .string => allocator.free(self.value.string),
        .file => allocator.free(self.value.file),
        else => {},
    }
}

pub fn jsonParseFromValue(allocator: Allocator, source: std.json.Value, options: ParseOptions) !Property {
    const property_type = try innerParseFromValue(Type, allocator, source.object.get("type").?, options);

    const value = source.object.get("value") orelse return error.UnexpectedToken;
    return .{
        .name = try innerParseFromValue([]const u8, allocator, source.object.get("name").?, options),
        .property_type = if (source.object.get("propertytype")) |s| try innerParseFromValue([]const u8, allocator, s, options) else null,

        .type = property_type,

        .value = switch (property_type) {
            .string => .{ .string = try innerParseFromValue([]const u8, allocator, value, options) },
            .int => .{ .int = try innerParseFromValue(u32, allocator, value, options) },
            .float => .{ .float = try innerParseFromValue(f32, allocator, value, options) },
            .bool => .{ .bool = try innerParseFromValue(bool, allocator, value, options) },
            .color => .{ .color = try innerParseFromValue(Color, allocator, value, options) },
            .file => .{ .file = try innerParseFromValue([]const u8, allocator, value, options) },
        },
    };
}

const Property = @This();

const std = @import("std");
const ParseOptions = std.json.ParseOptions;
const innerParseFromValue = std.json.innerParseFromValue;
const Allocator = std.mem.Allocator;

const tmz = @import("root.zig");
const Color = tmz.Color;
