const std = @import("std");
const expect = @import("std").testing.expect;

const ParsedPuzzleInput = struct {
    leftList: []i32,
    rightList: []i32,
    count: u64,
};

const NUMBER_LEN = 5;
const WHITESPACE_CNT = 3;
const BUFFER_LIM = 256 * 1000;

fn readInput(allocator: std.mem.Allocator) !ParsedPuzzleInput {
    const file = try std.io.getStdIn().readToEndAlloc(allocator, BUFFER_LIM);
    try expect(file.len > 0);

    const lineSize = 1 + std.mem.indexOfScalar(u8, file, '\n').?;
    try expect(lineSize == 2 * NUMBER_LEN + WHITESPACE_CNT + 1);

    const lineCount: u64 = file.len / lineSize;

    const numAlloc: []i32 = try allocator.alloc(i32, 2 * lineCount);

    const data = ParsedPuzzleInput{ .leftList = numAlloc[0..lineCount], .rightList = numAlloc[lineCount .. 2 * lineCount], .count = lineCount };

    for (0..lineCount) |i| {
        const lineStart = i * lineSize;
        const firstNumEnd = lineStart + NUMBER_LEN;
        const secondNumStart = firstNumEnd + WHITESPACE_CNT;
        const secondNumEnd = secondNumStart + NUMBER_LEN;
        data.leftList[i] =
            try std.fmt.parseInt(i32, file[lineStart..firstNumEnd], 10);
        data.rightList[i] =
            try std.fmt.parseInt(i32, file[secondNumStart..secondNumEnd], 10);
    }

    return data;
}

fn part1(data: *const ParsedPuzzleInput) !void {
    var totalDistance: u32 = 0;
    for (0..data.count) |i| {
        totalDistance += @abs(data.rightList[i] - data.leftList[i]);
    }

    try std.io.getStdOut().writer().print("{}\n", .{totalDistance});
}

fn part2(data: *const ParsedPuzzleInput) !void {
    var leftPointer: u32 = 0;
    var rightPointer: u32 = 0;

    var similarityScore: u32 = 0;
    while (leftPointer != data.count and rightPointer != data.count) {
        const val: i32 = data.leftList[leftPointer];
        var count: u32 = 0;
        while (rightPointer != data.count and data.rightList[rightPointer] <= val) {
            if (data[rightPointer] == val) count += 1;
            rightPointer += 1;
        }
        leftPointer += 1;
        similarityScore += @as(u32, @bitCast(val)) * count;
    }

    try std.io.getStdOut().writer().print("{}\n", .{similarityScore});
}

pub fn main() !void {
    var buffer: [BUFFER_LIM]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const data = try readInput(allocator);
    defer allocator.free(data.leftList);

    std.mem.sort(i32, data.leftList, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, data.rightList, {}, comptime std.sort.asc(i32));

    try part1(&data);
    try part2(&data);
}
