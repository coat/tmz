/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#object
pub const Object = struct {
    gid: ?u32 = null,
    height: f32,
    id: u32,
    name: []const u8,
    point: ?bool = null,
    polygon: ?[]Point = null,
    polyline: ?[]Point = null,
    properties: std.StringHashMapUnmanaged(Property),
    rotation: f32,
    template: ?[]const u8 = null,
    text: ?Text = null,
    class: ?[]const u8 = null,
    visible: bool,
    width: f32,
    x: f32,
    y: f32,

    type: Type,

    pub const Type = enum {
        rectangle,
        ellipse,
        polygon,
        polyline,
        tile,
        text,
    };

    pub fn fromJson(allocator: Allocator, json_obj: JsonObject) !Object {
        var properties: std.StringHashMapUnmanaged(Property) = .empty;
        var json_object = json_obj;

        if (json_object.template) |template| {
            var arena = std.heap.ArenaAllocator.init(allocator);
            defer arena.deinit();
            const arena_allocator = arena.allocator();

            const file = try std.fs.cwd().openFile(template, .{});
            defer file.close();

            var reader: std.fs.File.Reader = .initStreaming(file, &.{});

            var out: std.Io.Writer.Allocating = .init(arena_allocator);
            defer out.deinit();

            _ = try reader.interface.streamRemaining(&out.writer);

            const json = try out.toOwnedSlice();

            const parsed_value = try std.json.parseFromSliceLeaky(std.json.Value, arena_allocator, json, .{ .ignore_unknown_fields = true });
            const json_template = try std.json.parseFromValueLeaky(JsonObject.Template, arena_allocator, parsed_value, .{ .ignore_unknown_fields = true });

            const json_template_object = json_template.object;

            if (json_template_object.properties) |props| {
                for (props) |property| {
                    const prop = try Property.fromJson(allocator, property);
                    try properties.put(allocator, prop.name, prop);
                }
            }
            json_object.applyTemplate(json_template_object);
        }

        if (json_object.properties) |props| {
            for (props) |property| {
                const prop = try Property.fromJson(allocator, property);
                if (properties.fetchRemove(prop.name)) |entry| {
                    var old = entry.value;
                    old.deinit(allocator);
                }
                try properties.put(allocator, prop.name, prop);
            }
        }

        const object: Object = .{
            .gid = json_object.gid,
            .height = json_object.height.?,
            .id = json_object.id.?,
            .name = try allocator.dupe(u8, json_object.name.?),
            .point = json_object.point,
            .class = if (json_object.type) |class| try allocator.dupe(u8, class) else null,
            .rotation = json_object.rotation.?,
            .visible = json_object.visible.?,
            .width = json_object.width.?,
            .x = json_object.x.?,
            .y = json_object.y.?,
            .properties = properties,

            .type = set_type: {
                if (json_object.gid) |_| {
                    break :set_type .tile;
                }
                if (json_object.ellipse) |_| {
                    break :set_type .ellipse;
                }
                if (json_object.polygon) |_| {
                    break :set_type .polygon;
                }
                if (json_object.polyline) |_| {
                    break :set_type .polyline;
                }
                if (json_object.text) |_| {
                    break :set_type .text;
                }
                break :set_type .rectangle;
            },
        };

        return object;
    }

    pub fn deinit(self: *Object, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.class) |class| allocator.free(class);

        var properties_it = self.properties.valueIterator();
        while (properties_it.next()) |value_ptr| {
            value_ptr.*.deinit(allocator);
        }
        self.properties.deinit(allocator);
    }

    pub const JsonObject = struct {
        pub const Template = struct {
            object: JsonObject,
            type: ?[]const u8,
        };

        ellipse: ?bool = null,
        gid: ?u32 = null,
        height: ?f32 = null,
        id: ?u32 = null,
        name: ?[]const u8 = null,
        opacity: ?f32 = null,
        point: ?bool = null,
        polygon: ?[]Point = null,
        polyline: ?[]Point = null,
        properties: ?[]Property = null,
        rotation: ?f32 = null,
        template: ?[]const u8 = null,
        text: ?Text = null,
        type: ?[]const u8 = null,
        visible: ?bool = null,
        width: ?f32 = null,
        x: ?f32 = null,
        y: ?f32 = null,

        pub fn applyTemplate(self: *JsonObject, template: JsonObject) void {
            self.ellipse = self.ellipse orelse template.ellipse;
            self.id = self.id orelse template.id;
            self.gid = self.gid orelse template.gid;
            self.height = self.height orelse template.height;
            self.opacity = self.opacity orelse template.opacity;
            self.point = self.point orelse template.point;
            self.polygon = self.polygon orelse template.polygon;
            self.polyline = self.polyline orelse template.polyline;
            self.rotation = self.rotation orelse template.rotation;
            self.text = self.text orelse template.text;
            self.type = self.type orelse template.type;
            self.visible = self.visible orelse template.visible;
            self.width = self.width orelse template.width;
        }
    };
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#point
pub const Point = struct {
    x: f32,
    y: f32,
};

/// https://doc.mapeditor.org/en/stable/reference/json-map-format/#text
pub const Text = struct {
    bold: ?bool = null,
    color: ?[]const u8 = null,
    fontfamily: []const u8 = "sans-serif",
    halign: enum { center, right, justify, left } = .left,
    italic: bool = false,
    kerning: bool = true,
    pixelsize: u32 = 16,
    strikeout: bool = false,
    text: []const u8,
    underline: bool = false,
    valign: enum { center, bottom, top } = .top,
    wrap: bool = false,
};

const Property = @import("root.zig").Property;

const std = @import("std");
const Allocator = std.mem.Allocator;
