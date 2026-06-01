const std = @import("std");

extern "c" fn __android_log_print(prio: i32, tag: [*:0]const u8, fmt: [*:0]const u8, ...) i32;

pub const info = 4;
pub const err = 6;
const TAG = "ScHunt";

pub fn log(prio: i32, message: []const u8) void {
    _ = __android_log_print(prio, TAG, "%s", message.ptr);
}

pub fn logFmt(prio: i32, allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) void {
    const m = std.fmt.allocPrint(allocator, fmt, args) catch return;
    defer allocator.free(m);
    _ = __android_log_print(prio, TAG, "%s", m.ptr);
}
