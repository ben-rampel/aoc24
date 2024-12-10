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
    std.mem.sort(i32, data.leftList, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, data.rightList, {}, comptime std.sort.asc(i32));

    var totalDistance: u32 = 0;
    for (0..data.count) |i| {
        totalDistance += @abs(data.rightList[i] - data.leftList[i]);
    }

    try std.io.getStdOut().writer().print("{}\n", .{totalDistance});
}

const NumberCount = packed struct {
    number: u20,
    count: u12,
};

fn compareByKey(_: void, a: u20, b: NumberCount) std.math.Order {
    return std.math.order(a, b.number);
}

//Original
fn _part2(data: *const ParsedPuzzleInput, allocator: *const std.mem.Allocator) !void {
    var numberCounts = try std.ArrayList(NumberCount).initCapacity(allocator.*, data.count);
    defer numberCounts.clearAndFree();

    //std.mem.sort(i32, data.rightList, {}, comptime std.sort.asc(i32));

    var countIdx: ?u32 = null;
    for (data.rightList) |num| {
        if (countIdx != null and numberCounts.items[countIdx.?].number == num) {
            numberCounts.items[countIdx.?].count += 1;
        } else {
            try numberCounts.append(NumberCount{ .number = @intCast(num), .count = 1 });
            if (countIdx == null) countIdx = 0 else countIdx.? += 1;
        }
    }

    var similarityScore: u64 = 0;
    for (data.leftList) |num| {
        const idx =
            std.sort.binarySearch(NumberCount, @as(u20, @intCast(num)), numberCounts.items, {}, compareByKey);
        if (idx != null) {
            similarityScore += numberCounts.items[idx.?].count * @as(u32, @intCast(num));
        }
    }

    try std.io.getStdOut().writer().print("{}\n", .{similarityScore});
}

//Inspired by Mr. Byrd
fn part2(data: *const ParsedPuzzleInput) !void {
    var leftPointer: u32 = 0;
    var rightPointer: u32 = 0;

    var similarityScore: u32 = 0;
    while (leftPointer != data.count and rightPointer != data.count) {
        const val: i32 = data.leftList[leftPointer];
        var count: u32 = 0;
        while (rightPointer != data.count and data.rightList[rightPointer] < val) {
            rightPointer += 1;
        }
        while (rightPointer != data.count and data.rightList[rightPointer] == val) {
            count += 1;
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

    try part1(&data);
    try part2(&data);
}
