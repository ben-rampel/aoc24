const std = @import("std");
const ArrayList = std.ArrayList;

const ivec2 = struct {
    x: i32,
    y: i32,

    fn init(x: i32, y: i32) ivec2 {
        return ivec2{ .x = x, .y = y };
    }

    fn dot(self: ivec2, other: ivec2) i32 {
        return self.x * other.x + self.y * other.y;
    }

    fn add(self: ivec2, other: ivec2) ivec2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    fn mul(self: ivec2, scalar: i32) ivec2 {
        return .{ .x = self.x * scalar, .y = self.y * scalar };
    }
};

const Ray = struct {
    origin: ivec2,
    direction: ivec2,

    fn iterate(self: Ray, t: i32) ivec2 {
        return self.origin.add(self.direction.mul(t));
    }
};

const xmas = "XMAS";

fn print(str: anytype) void {
    std.io.getStdOut().writer().print("{}\n", .{str}) catch {};
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    const input = try std.io.getStdIn().readToEndAlloc(alloc, 256 * 1000);

    const width: u32 = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);
    //const rows: u32 = input.len / (cols+1);
    const offsets = [3]i32{ -1, 0, 1 };

    var candidates = ArrayList(Ray).init(alloc);
    var c: u32 = 0;
    for (input, 0..) |char, n| {
        const x = @as(i32, @intCast(n % width));
        const y = @as(i32, @intCast(n / width));
        if (char == xmas[0]) {
            c += 1;
            for (offsets) |i| {
                for (offsets) |j| {
                    const s = j * @as(i32, @intCast(width)) + i + @as(i32, @intCast(n));
                    if (s >= 0 and s < input.len and input[@intCast(s)] == xmas[1]) {
                        try candidates.append(Ray{ .origin = ivec2.init(x, y), .direction = ivec2.init(i, j) });
                    }
                }
            }
        }
    }
    var solutionCount: u32 = 0;
    rayLoop: for (candidates.items) |ray| {
        for (2..4) |i| {
            const s = ray.iterate(@as(i32, @intCast(i)));
            const idx: i32 = s.dot(ivec2.init(1, @intCast(width)));
            if (idx < 0 or idx >= input.len or input[@intCast(idx)] != xmas[i]) continue :rayLoop;
        }
        solutionCount += 1;
    }
    //part1
    try std.io.getStdOut().writer().print("{}\n", .{solutionCount});

    try part2(input, width);
}

pub fn part2(input: []const u8, width: u32) !void {
    var solutions: u32 = 0;
    for (input, 0..) |char, n| {
        if (char == 'A') {
            var mas: u32 = 0;
            for (0..2) |i| {
                const side = (-1 + 2 * @as(i32, @intCast(i)));
                const left = @as(i32, @intCast(n - 1)) - side * @as(i32, @intCast(width));
                const right = @as(i32, @intCast(n + 1)) + side * @as(i32, @intCast(width));
                if (left >= 0 and left < input.len and right >= 0 and right < input.len) {
                    if (input[@intCast(left)] == 'M' and input[@intCast(right)] == 'S') mas += 1;
                    if (input[@intCast(left)] == 'S' and input[@intCast(right)] == 'M') mas += 1;
                }
            }
            if (mas == 2) solutions += 1;
        }
    }
    print(solutions);
}
