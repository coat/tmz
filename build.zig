const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("tmz", .{ .root_source_file = b.path("src/tmz.zig") });

    const tmz = b.addStaticLibrary(.{
        .name = "tmz",
        .root_source_file = b.path("src/tmz.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(tmz);

    const game = b.addExecutable(.{
        .name = "foo",
        .root_source_file = b.path("examples/game/game.zig"),
        .target = target,
        .optimize = optimize,
    });
    game.root_module.addImport("tmz", b.modules.get("tmz").?);
    b.installArtifact(game);
    const run_cmd = b.addRunArtifact(game);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the example game");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tmz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
