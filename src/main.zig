const std = @import("std");

pub fn main() void {
    var buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hn = std.posix.gethostname(&buf) catch unreachable;
    const out = std.io.getStdOut().writer();
    const user = std.posix.getenv("USER") orelse unreachable;
    out.writeAll(user) catch unreachable;
    out.writeAll("@") catch unreachable;
    out.writeAll(hn) catch unreachable;
    out.writeAll(" ") catch unreachable;
    var outb: [256]u8 = undefined;
    const o = std.fs.cwd().realpath(".", &outb) catch unreachable;
    out.writeAll(o) catch unreachable;
    out.writeAll("\n> ") catch unreachable;
}

fn mut(comptime s: []const u8) [s.len]u8 {
    var buf: [s.len]u8 = undefined;
    for (s, 0..) |c, i| {
        buf[i] = c;
    }
    return buf;
}

fn cat(comptime a: []const u8, comptime b: []const u8) []const u8 {
    var buf: [a.len + b.len]u8 = undefined;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        buf[i] = a[i];
    }
    var k: usize = 0;
    while (k < b.len) {
        buf[i] = b[k];
        i += 1;
        k += 1;
    }
    const out = buf;
    return &out;
}
