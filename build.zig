pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const coverage = b.option(bool, "coverage", "Generate a coverage report with kcov") orelse false;
    const coverage_requested = coverage and b.graph.host.result.os.tag == .linux;

    const mod = b.addModule("tmz", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/tests.zig"),
            .target = target,
            .imports = &.{
                .{ .name = "tmz", .module = mod },
            },
        }),
    });

    if (coverage_requested) {
        mod_tests.use_llvm = true;
        tests.use_llvm = true;
    }

    const run_mod_tests = b.addRunArtifact(mod_tests);
    const run_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_tests.step);

    if (coverage_requested) {
        var run_test_steps: std.ArrayList(*std.Build.Step.Run) = .empty;
        run_test_steps.append(b.allocator, run_mod_tests) catch @panic("OOM");
        run_test_steps.append(b.allocator, run_tests) catch @panic("OOM");

        const kcov_bin = b.findProgram(&.{"kcov"}, &.{}) catch "kcov";

        const merge_step = std.Build.Step.Run.create(b, "merge coverage");
        merge_step.addArgs(&.{ kcov_bin, "--merge" });
        merge_step.rename_step_with_output_arg = false;
        const merged_coverage_output = merge_step.addOutputFileArg(".");

        for (run_test_steps.items) |step| {
            step.setName(b.fmt("{s} (collect coverage)", .{step.step.name}));

            // prepend the kcov exec args
            const argv = step.argv.toOwnedSlice(b.allocator) catch @panic("OOM");
            step.addArgs(&.{ kcov_bin, "--collect-only" });
            step.addPrefixedDirectoryArg("--include-pattern=", b.path("src"));
            merge_step.addDirectoryArg(step.addOutputFileArg(step.producer.?.name));
            step.argv.appendSlice(b.allocator, argv) catch @panic("OOM");
        }

        const install_coverage = b.addInstallDirectory(.{
            .source_dir = merged_coverage_output,
            .install_dir = .{ .custom = "coverage" },
            .install_subdir = "",
        });
        test_step.dependOn(&install_coverage.step);
    }
}

const std = @import("std");
