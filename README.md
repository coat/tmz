# tmz

A library for parsing [Tiled](https://www.mapeditor.org/) maps.

<table>
<tr>
<td>Zig</td>
<td>C</td>
</tr>
<tr>
<td>

```zig
const std = @import("std");
const tmz = @import("tmz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const map = try tmz.loadMapFromFile(allocator, "map.tmj");
    defer map.deinit();

    std.debug.info("Map size: {} × {}", .{ map.width, map.height });
}
```

</td>
<td>

```c
#include <stdio.h>
#include <tmz.h>

int main(void) {
    tmz_map map;
    tmz_load_map_from_file(&map, "map.tmj")

    printf("Map size: %i x %i\n", map->width, map->height);

    tmz_map_deinit(&map);
    return 0;
}
```

</td>
</tr>
</table>

## Features

Parses Maps and Tilesets in [JSON Format](https://doc.mapeditor.org/en/stable/reference/json-map-format/) - `.tmj`, `.tsj`), and Projects (`.tiled-project`).

## Installation

### Zig

1. Add `tmz` as a dependency in your `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/coat/tmz.zig#main
```

2. Add module to `build.zig`:

```zig
const tmz = b.dependency("tmz", .{ .target = target, .optimize = optimize });

exe.root_module.addImport("tmz", tmz.module("tmz"));
```

### C

If you are using the C API to tmz, see the Build section below.

## Usage

### Maps

```zig
const map = try tmz.loadMap(allocator, @embedFile("map.tmj"));
defer map.deinit(allocator);

std.debug.info("Map size: {} x {}", .{ map.width, map.height });
```

`loadMap` and `loadMapFromFile` expect a [JSON Map Format (.tmj)](https://doc.mapeditor.org/en/stable/reference/json-map-format/#map).

### Tilesets

```zig
const tileset = try tmz.loadTileset(allocator, @embedFile("tileset.tsj"));
defer tileset.deinit(allocator);

if (tileset.name) |name| {
    std.debug.info("Tileset name: {s}", .{ name });
}
```

`loadTileset` and `loadTilesetFromFile` expects a [JSON Map Format Tileset (.tsj)](https://doc.mapeditor.org/en/stable/reference/json-map-format/#tileset).

### Projects

```zig
const project = try tmz.loadProject(allocator, @embedFile("game.tiled-project"));
defer project.deinit();

if (project.properties.get("name")) |name| {
    std.debug.log("Name: {s}", .{ name.string });
}
```

## Building

Building the library requires [Zig 0.13.0](https://ziglang.org/download/#release-0.13.0). To build and run the examples, [SDL 3.2](https://github.com/libsdl-org/SDL/releases/latest) is also required.

`zig build install` will build the full library and output a FHS-compatible directory in zig-out. You can customize the output directory with the --prefix flag.

### Development Environment

#### Nix

If you have Nix installed, simply use the included flake to get an environment with Zig installed:

```sh
nix develop
```

If you have `direnv` installed, run `direnv allow` to automatically load the dev shell when changing into the project directory.
