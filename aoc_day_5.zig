const std = @import("std");

const ArrayList = std.ArrayList;

fn print(comptime str: []const u8, o: anytype) void {
    std.io.getStdOut().writer().print(str, .{o}) catch {};
}

const NumStatus = enum {
    none,
    seen,
    dependent,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const input = try std.io.getStdIn().readToEndAlloc(alloc, 256 * 1000);
    defer alloc.free(input);

    var lines = std.mem.splitScalar(u8, input, '\n');
    var dependencies: [100]ArrayList(u8) = undefined;
    for (&dependencies) |*arr| {
        arr.* = ArrayList(u8).init(alloc);
    }

    while (lines.next()) |line| {
        if (line.len == 0) break;
        print("{s}\n", line);
        var nums = std.mem.splitScalar(u8, line, '|');
        const src: u8 = try std.fmt.parseUnsigned(u8, nums.next().?, 10);
        const dst: u8 = try std.fmt.parseUnsigned(u8, nums.next().?, 10);
        try dependencies[dst].append(src);
    }

    var middleSum: u32 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;
        print("{s}\n", line);
        var nums = std.mem.splitScalar(u8, line, ',');
        var seen = std.mem.zeroes([100]NumStatus);
        var validLine = true;
        var numList = ArrayList(u32).init(alloc);
        while (nums.next()) |numStr| {
            const numParsed = try std.fmt.parseUnsigned(u32, numStr, 10);
            try numList.append(numParsed);
            if (seen[numParsed] == NumStatus.dependent) {
                validLine = false;
                break;
            }
            for (dependencies[numParsed].items) |dep| {
                if (seen[dep] != NumStatus.seen) seen[dep] = NumStatus.dependent;
            }
            seen[numParsed] = NumStatus.seen;
        }
        if (validLine) {
            middleSum += numList.items[numList.items.len / 2];
        }
    }
    print("{}\n", middleSum);
}