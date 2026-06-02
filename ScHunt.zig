const std = @import("std");
const Io = std.Io;
const logger = @import("Android/logger.zig");
const scanner = @import("Android/scanner.zig");

fn threadLoop() void {
    const allocator = std.heap.c_allocator;
    var threaded = Io.Threaded.init(allocator, .{});
    const io = threaded.io();

    const delay = Io.Clock.Duration{
        .raw = .{ .nanoseconds = 15 * std.time.ns_per_s },
        .clock = .awake,
    };

    while (true) {
        scanner.runScan(io, allocator) catch |err| {
            logger.logFmt(logger.err, allocator, "[ ERROR  ]: {s}", .{@errorName(err)});
        };
        Io.Clock.Duration.sleep(delay, io) catch {};
    }
}

export fn JNI_OnLoad(vm: *anyopaque, res: ?*anyopaque) callconv(.c) i32 {
    _ = vm;
    _ = res;

    const thread = std.Thread.spawn(.{}, threadLoop, .{}) catch return -1;
    thread.detach();

    logger.log(logger.info, "SCHunt - By FMZNkdv");
    return 0x00010006;
}
