const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const coverage = b.option(bool, "coverage", "Generate a coverage report with kcov") orelse false;

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

    const run_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    if (coverage) {
        const kcov_bin = b.findProgram(&.{"kcov"}, &.{}) catch "kcov";
        const merge_step = std.Build.Step.Run.create(b, "merge coverage");
        merge_step.addArgs(&.{ kcov_bin, "--merge" });
        merge_step.rename_step_with_output_arg = false;
        const merged_coverage_output = merge_step.addOutputFileArg(".");

        run_tests.setName(b.fmt("{s} (collect coverage)", .{run_tests.step.name}));
        // prepend the kcov exec args
        const argv = run_tests.argv.toOwnedSlice(b.allocator) catch @panic("OOM");
        run_tests.addArgs(&.{ kcov_bin, "--collect-only" });
        run_tests.addPrefixedDirectoryArg("--include-pattern=", b.path("src"));
        merge_step.addDirectoryArg(run_tests.addOutputFileArg(run_tests.producer.?.name));
        run_tests.argv.appendSlice(b.allocator, argv) catch @panic("OOM");

        const install_coverage = b.addInstallDirectory(.{
            .source_dir = merged_coverage_output,
            .install_dir = .{ .custom = "coverage" },
            .install_subdir = "",
        });
        test_step.dependOn(&install_coverage.step);
    }
}
