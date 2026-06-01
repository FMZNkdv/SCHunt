const std = @import("std");
const Io = std.Io;
const config = @import("../Config/init.zig");
const logger = @import("logger.zig");

pub fn runScan(io: Io, allocator: std.mem.Allocator) !void {
    Io.Dir.createDirAbsolute(io, "/sdcard/Download/ScHunt", .default_dir) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => {},
    };

    var dir = Io.Dir.openDirAbsolute(io, "/data/data/" ++ config.package ++ "/cache", .{ .iterate = true }) catch |e| {
        logger.logFmt(logger.err, allocator, "[ ERR  ]: {s}", .{@errorName(e)});
        return;
    };
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".sc")) {
            const src_p = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ "/data/data/" ++ config.package ++ "/cache", entry.path });
            const dst_p = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ "/sdcard/Download/ScHunt", entry.basename });
            defer {
                allocator.free(src_p);
                allocator.free(dst_p);
            }

            const src_file = Io.Dir.openFileAbsolute(io, src_p, .{}) catch continue;
            defer src_file.close(io);

            const dst_file = Io.Dir.createFileAbsolute(io, dst_p, .{}) catch continue;
            defer dst_file.close(io);

            var buf: [4096]u8 = undefined;
            var offset: u64 = 0;
            while (true) {
                const n = src_file.readPositional(io, &.{buf[0..]}, offset) catch break;
                if (n == 0) break;
                dst_file.writeStreamingAll(io, buf[0..n]) catch break;
                offset += n;
            }

            logger.logFmt(logger.info, allocator, "[ SAVE  ]: {s}", .{entry.basename});
        }
    }
}
