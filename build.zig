const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("tmz", .{ .root_source_file = b.path("src/tmz.zig") });

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/tmz.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "tmz",
        .root_module = lib_mod,
    });

    b.installArtifact(lib);

    const unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
