const std = @import("std");

pub fn main() void {
    var buf: [std.math.pow(usize, 2, 13)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const al = fba.allocator();
    var arl = std.ArrayList(u8).init(al);
    var namebuf: [std.posix.HOST_NAME_MAX]u8 = undefined;

    const user = std.posix.getenv("USER") orelse "???";
    arl.appendSlice(user) catch unreachable;
    arl.append('@') catch unreachable;
    const hn = std.posix.gethostname(&namebuf) catch unreachable;
    arl.appendSlice(hn) catch unreachable;

    const git = getGit(al);
    if (git) |g| {
        arl.append(' ') catch unreachable;
        arl.appendSlice(" (") catch unreachable;
        arl.appendSlice(g) catch unreachable;
        arl.append(')') catch unreachable;
    }

    const status = std.posix.getenv("STATUS") orelse "";
    if (status.len > 0 and !std.mem.eql(u8, status, "0")) {
        arl.append(' ') catch unreachable;
        arl.appendSlice(status) catch unreachable;
    }

    arl.append('\n') catch unreachable;

    var outb: [256]u8 = undefined;
    const o = std.fs.cwd().realpath(".", &outb) catch unreachable;
    const spath = shortenPath(o);
    arl.appendSlice(spath) catch unreachable;

    arl.appendSlice("\n> ") catch unreachable;
    const out = std.io.getStdOut().writer();
    out.writeAll(arl.items) catch unreachable;
}

// WE OWN PATH NOW!!!!
fn shortenPath(path: []u8) []const u8 {
    const home = std.posix.getenv("HOME") orelse return path;
    const res = std.mem.startsWith(u8, path, home);
    if (res) {
        path[home.len - 1] = '~';
        return path[home.len - 1 ..];
    }
    return path;
}

fn getGit(al: std.mem.Allocator) ?[]const u8 {
    const cwdp = std.fs.cwd().realpathAlloc(al, ".") catch return null;
    const dir = findDirUpwards(al, cwdp, ".git") orelse {
        return null;
    };

    const fileConts = dir.readFileAlloc(al, "HEAD", 100000) catch {
        return null;
    };
    var split = std.mem.split(u8, fileConts, "/");
    var last: []const u8 = undefined;
    while (split.next()) |s| {
        last = s;
    }
    return last[0 .. last.len - 1];
}

test "mini test" {
    const al = std.testing.allocator;
    const path = "/Users/deniztelci/Documents/Repos";
    // const path = "/Users/deniztelci/Documents/Repos/ez1/zig-out/bin";
    // const path = try std.fs.cwd().realpathAlloc(al, ".");
    // defer al.free(path);
    const cwd = try std.fs.openDirAbsolute(path, .{});
    const stat = cwd.stat();
    std.debug.print("{s} {any}\n{any}\n", .{ path, cwd, stat });

    const res = findDirUpwards(al, path, ".git");
    if (res) |r| {
        const p = try r.realpathAlloc(al, ".");
        defer al.free(p);
        std.debug.print("{s}\n", .{p});
    }
    std.debug.print("{any}\n", .{res});
}
fn findDirUpwards(al: std.mem.Allocator, startPath: []const u8, name: []const u8) ?std.fs.Dir {
    const dir = std.fs.openDirAbsolute(startPath, .{}) catch return null;
    const stat = dir.stat() catch return null;
    const target = dir.openDir(name, .{});
    if (target) |t| return t else |_| {}
    if (stat.inode == 2) {
        return null;
    }
    const path = dir.realpathAlloc(al, "..") catch return null;
    defer al.free(path);
    return findDirUpwards(al, path, name);
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
