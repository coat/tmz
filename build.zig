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

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tmz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
