const std = @import("std");

pub fn main() void {
    var buf: [std.math.pow(usize, 2, 13)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const al = fba.allocator();
    var arl = std.ArrayList(u8).init(al);
    var namebuf: [std.posix.HOST_NAME_MAX]u8 = undefined;

    const hn = std.posix.gethostname(&namebuf) catch unreachable;
    arl.appendSlice(hn) catch unreachable;
    const user = std.posix.getenv("USER") orelse "???";
    arl.append('@') catch unreachable;
    arl.appendSlice(user) catch unreachable;
    arl.append(' ') catch unreachable;
    var outb: [256]u8 = undefined;
    const o = std.fs.cwd().realpath(".", &outb) catch unreachable;
    arl.appendSlice(o) catch unreachable;
    const status = std.posix.getenv("STATUS") orelse "";
    if (status.len > 0) {
        arl.append(' ') catch unreachable;
        arl.appendSlice(status) catch unreachable;
    }

    // const child = std.process.Child.run(.{
    //     .allocator = al,
    //     .argv = &.{ "git", "branch", "--show-current" },
    // }) catch unreachable;
    // arl.appendSlice(" (") catch unreachable;
    // arl.appendSlice(child.stdout[0 .. child.stdout.len - 1]) catch unreachable;
    // arl.append(')') catch unreachable;

    const git = getGit(al);
    if (git) |g| {
        arl.appendSlice(" (") catch unreachable;
        arl.appendSlice(g) catch unreachable;
        arl.append(')') catch unreachable;
    }

    arl.appendSlice("\n> ") catch unreachable;
    const out = std.io.getStdOut().writer();
    out.writeAll(arl.items) catch unreachable;
}

fn getGit(al: std.mem.Allocator) ?[]const u8 {
    const cwdp = std.fs.cwd().realpathAlloc(al, ".") catch {
        return null;
    };
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

// fn findDirUpwards(startDir: std.fs.Dir, name: []const u8) ?std.fs.Dir {
//     // REMOVE THIS
//     const al = std.heap.page_allocator;
//     const cwd = std.fs.cwd();
//     defer cwd.close();
//     const d = cwd.openDir(name, .{}) catch {
//         const stat = cwd.stat() catch unreachable ;
//         // we are at root and there will be no .git here
//         if (stat.inode == 2) {
//             return null;
//         }
//         const path = cwd.realpathAlloc(al, "..") catch unreachable;
//         return findDirUpwards(startDir: std.fs.Dir, name: []const u8)
//     };
//     return d;
// }

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
    const dir = std.fs.openDirAbsolute(startPath, .{}) catch {
        return null;
    };
    const target = dir.openDir(name, .{});
    if (target) |t| return t else |_| {}
    const path = dir.realpathAlloc(al, "..") catch {
        return null;
    };
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
