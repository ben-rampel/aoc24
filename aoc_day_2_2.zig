const std = @import("std");
const writer = std.io.getStdOut().writer();

const ArrayList = std.ArrayList;

const LevelState = enum { checkFirst, checkSecond, asc, desc, failed };

const LevelValidator = struct {
    allocator: std.mem.Allocator,
    lists: ArrayList(ArrayList(u32)),

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .lists = std.ArrayList(ArrayList(u32)).init(allocator),
        };
    }

    fn getState(newNum: u32, lastNum: u32, state: LevelState) LevelState {
        if (state == LevelState.checkFirst) {
            return LevelState.checkSecond;
        } else {
            const diff: u32 = @abs(@as(i32, @intCast(lastNum)) - @as(i32, @intCast(newNum)));
            if (diff < 1 or diff > 3) return LevelState.failed;

            if (state == LevelState.checkSecond) {
                return if (newNum > lastNum) LevelState.asc else LevelState.desc;
            } else if (state == LevelState.asc and newNum > lastNum) {
                return LevelState.asc;
            } else if (state == LevelState.desc and newNum < lastNum) {
                return LevelState.desc;
            } else {
                return LevelState.failed;
            }
        }
    }

    fn checkOne(list: ArrayList(u32), failIdx: *u32) bool {
        var state = LevelState.checkFirst;
        var lastnum: u32 = 0;

        for (list.items, 0..) |level, n| {
            state = getState(level, lastnum, state);
            if (state == LevelState.failed) {
                failIdx.* = @intCast(n);
                return false;
            }
            lastnum = level;
        }
        return true;
    }

    fn removeOne(self: @This(), list: ArrayList(u32), idx: u32) ArrayList(u32) {
        var result = ArrayList(u32).init(self.allocator);
        for (list.items, 0..) |i, n| {
            if (n != idx) result.append(i) catch {};
        }
        return result;
    }

    fn check(self: @This()) bool {
        var list_stack = self.lists;
        defer for (list_stack.items, 0..) |list, n| {
            if (n != 0) list.deinit();
        };

        var lives: u32 = 2;

        while (list_stack.popOrNull()) |list| {
            var failIdx: u32 = undefined;
            if (checkOne(list, &failIdx)) {
                return true;
            } else {
                if (lives > 1) {
                    lives -= 1;
                    var lookback = failIdx;
                    while (lookback + 2 >= failIdx) {
                        list_stack.append(self.removeOne(list, @intCast(lookback))) catch {};
                        if (lookback > 0) {
                            lookback -= 1;
                        } else {
                            break;
                        }
                    }
                }
            }
        }
        return false;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = try std.io.getStdIn().readToEndAlloc(allocator, 256 * 1000);

    var count: u32 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) break;

        var numbers = std.mem.splitScalar(u8, line, ' ');
        var parsedLine = ArrayList(u32).init(allocator);
        defer parsedLine.deinit();

        while (numbers.next()) |num| {
            try parsedLine.append(try std.fmt.parseUnsigned(u32, num, 10));
        }

        var lineValidator = LevelValidator.init(allocator);
        try lineValidator.lists.append(parsedLine);

        if (lineValidator.check()) {
            count += 1;
        }
    }
    try writer.print("{}\n", .{count});
}
