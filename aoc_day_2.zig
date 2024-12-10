const std = @import("std");
const writer = std.io.getStdOut().writer();

const PROBLEM_PART = 2;
const DEBUG = false;

fn debug_print(comptime str: []const u8, args: anytype) void {
    if (DEBUG) writer.print(str, args) catch {};
}

const States = enum { checkFirst, checkSecond, increasing, decreasing, failed };

const LineValidator = struct {
    states: std.ArrayList(States),
    lastNums: std.ArrayList(u32),
    lives: u32,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {
        var self = LineValidator{
            .lastNums = std.ArrayList(u32).init(allocator),
            .states = std.ArrayList(States).init(allocator),
            .lives = PROBLEM_PART,
        };
        try self.lastNums.append(0);
        try self.states.append(States.checkFirst);

        return self;
    }

    fn push(self: *Self, newNum: u32, newState: States) !void {
        debug_print("Push {} {}\n", .{ newNum, newState });
        try self.states.append(newState);
        try self.lastNums.append(newNum);
    }

    fn checkInternal(newNum: u32, lastNum: u32, state: States) States {
        if (state == States.checkFirst) {
            return States.checkSecond;
        } else {
            const diff: u32 = @abs(@as(i32, @intCast(lastNum)) - @as(i32, @intCast(newNum)));
            if (diff < 1 or diff > 3) return States.failed;

            if (state == States.checkSecond) {
                return if (newNum > lastNum) States.increasing else States.decreasing;
            } else if (state == States.increasing and newNum > lastNum) {
                return States.increasing;
            } else if (state == States.decreasing and newNum < lastNum) {
                return States.decreasing;
            } else {
                return States.failed;
            }
        }
    }

    fn check(self: *Self, newNum: u32, lookaheadOpt: ?u32) !bool {
        debug_print("check {},{?}\n", .{ newNum, lookaheadOpt });
        const state = self.states.pop();
        const lastNum = self.lastNums.pop();

        const newState = checkInternal(newNum, lastNum, state);
        if (newState == States.failed) {
            debug_print("fail\n", .{});
            self.lives -= 1;
            if (self.lives == 0) {
                try self.push(newNum, States.failed);
                debug_print("dead\n", .{});
                return false;
            }

            var checkState = States.checkFirst;
            if (self.states.getLastOrNull()) |stateTwoBack| {
                const lastTwoBack = self.lastNums.getLast();
                checkState = checkInternal(newNum, lastTwoBack, stateTwoBack);
            }

            if (checkState == States.failed) {
                //Can't skip last, have to skip current
                try self.push(lastNum, state);
            } else {
                // Can skip last; will current work for the next?
                if (lookaheadOpt) |lookahead| {
                    const stateLookahead = checkInternal(lookahead, lastNum, state);
                    if (stateLookahead != States.failed) {
                        //Use newNum with what its state is if we skip last
                        try self.push(newNum, checkState);
                    } else {
                        //This one won't work with the next and won't work with last
                        try self.push(newNum, States.failed);
                    }
                } else {
                    //No lookahead means this is the last number
                    try self.push(newNum, checkState);
                }
            }
        } else {
            if (state != States.checkFirst) {
                try self.push(lastNum, state);
            }
            try self.push(newNum, newState);
        }
        debug_print("success\n", .{});
        return true;
        //return false;
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

        var lineValidator = try LineValidator.init(allocator);

        while (numbers.next()) |num| {
            const parsedNum: u32 = try std.fmt.parseUnsigned(u32, num, 10);
            var lookahead: ?u32 = null;
            if (numbers.peek()) |l| {
                lookahead = try std.fmt.parseUnsigned(u32, l, 10);
            }
            if (!(try lineValidator.check(parsedNum, lookahead))) {
                break;
            }
        }
        if (lineValidator.states.getLast() != States.failed) {
            count += 1;
            try writer.print("Good: ", .{});
        } else {
            try writer.print("Bad: ", .{});
        }
        try writer.print("{s}\n", .{line});
    }
    try writer.print("{}\n", .{count});
}
