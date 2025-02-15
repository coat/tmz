# tmz

A library for parsing [Tiled](https://www.mapeditor.org/) maps.

```zig
const std = @import("std");
const tmz = @import("tmz");

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    const map = try tmz.Map.initFromFile(allocator, "map.tmj");
    defer map.deinit();

    std.debug.info("Map size: {d} × {d}\n", .{ map.width, map.height });
}
```

## Features

Parses Maps and Tilesets in [JSON
Format](https://doc.mapeditor.org/en/stable/reference/json-map-format/) -
`.tmj` and `.tsj`.

## Installation

### Zig

1. Add `tmz` as a dependency in your `build.zig.zon`:

```bash
zig fetch --save git+https://github.com/coat/tmz.zig#main
```

2. Add module to `build.zig`:

```zig
const tmz = b.dependency("tmz", .{ .target = target, .optimize = optimize });

exe.root_module.addImport("tmz", tmz.module("tmz"));
```

## Usage

### Maps (TODO)

```zig
const map = try tmz.Map.initFromFile(allocator, "map.tmj");
defer map.deinit(allocator);

std.debug.info("Map size: {d} x {d}\n", .{ map.width, map.height });

const object = map.getObject("player");
if (object) |player| {
  std.debug.info("Player position: {d},{d}\n", .{ player.x, player.y });
}

const ground_layer = map.getLayer("ground");
if (ground_layer) |layer| {
  for (layer.content.data.items) |gid| {
    if (gid == 0) continue;
    const tile = map.getTile(gid);
    if (tile) |t| {
      drawTile(tile.image, tile.x, tile.y);
    }
  }
}
```

`initFromSlice` and `initFromFile` expect a [JSON Map Format
(.tmj)](https://doc.mapeditor.org/en/stable/reference/json-map-format/#map)
document.

### Tilesets

```zig
const tileset = try tmz.Tileset.initFromSlice(allocator, @embedFile("tileset.tsj"));
defer tileset.deinit(allocator);

if (tileset.name) |name| {
    std.debug.info("Tileset name: {s}", .{ name });
}
```

`initFromSlice` and `initFromFile` expect a [JSON Map Format Tileset
(.tsj)](https://doc.mapeditor.org/en/stable/reference/json-map-format/#tileset)
document.

## Building

Building the library requires [Zig
0.14.0](https://ziglang.org/download/#release-0.14.0). To build and run the
examples (TODO), [SDL 3.2](https://github.com/libsdl-org/SDL/releases/latest)
is also required.

`zig build install` will build the full library and output a FHS-compatible
directory in zig-out. You can customize the output directory with the --prefix
flag.

### Development Environment

#### Nix

If you have Nix installed, simply use the included flake to get an environment
with Zig installed:

```sh
nix develop
```

If you have `direnv` installed, run `direnv allow` to automatically load the
dev shell when changing into the project directory.

## Prior Art

[tmx](https://github.com/baylej/tmx) - portable C library to load TMX maps with
[great documentation](https://libtmx.readthedocs.io/en/latest/) used as
inspiration.

[libtmj](https://github.com/Zer0-One/libtmj) - Another great C library for JSON
formatted Maps and Tilesets
