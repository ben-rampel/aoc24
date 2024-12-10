const std = @import("std");

const Token = struct {
    const Type = enum { garbage, mul, openP, number, comma, closeP };

    type: Type,
    data: u32,
};

var alloc: std.mem.Allocator = undefined;

const Lexer = struct {
    input: []u8,
    head: u32,

    fn init(input: []u8) Lexer {
        return Lexer{ .input = input, .head = 0 };
    }

    fn getNext(self: *Lexer) !Token {
        switch (self.input[self.head]) {
            '(' => {
                self.head += 1;
                return Token{ .type = Token.Type.openP, .data = 0 };
            },
            ')' => {
                self.head += 1;
                return Token{ .type = Token.Type.closeP, .data = 0 };
            },
            ',' => {
                self.head += 1;
                return Token{ .type = Token.Type.comma, .data = 0 };
            },
            '0'...'9' => {
                var i = self.head + 1;
                while (i < self.input.len and self.input[i] >= '0' and self.input[i] <= '9') i += 1;
                const parsedNum = try std.fmt.parseUnsigned(u32, self.input[self.head..i], 10);
                self.head = i;
                return Token{ .type = Token.Type.number, .data = parsedNum };
            },
            else => {
                if (self.head + 3 <= self.input.len and std.mem.eql(u8, self.input[self.head .. self.head + 3], "mul")) {
                    self.head += 3;
                    return Token{ .type = Token.Type.mul, .data = 0 };
                } else {
                    self.head += 1;
                    return Token{ .type = Token.Type.garbage, .data = 0 };
                }
            },
        }
    }

    fn process(self: *Lexer) !std.ArrayList(Token) {
        var result = std.ArrayList(Token).init(alloc);
        while (self.head < self.input.len) {
            try result.append(try self.getNext());
        }
        return result;
    }
};

const ParsedMul = struct {
    multiplicand: u32,
    multiplier: u32,
};

const parseState = enum { start, mul, op, multiplicand, comma, multiplier, cl };
const tokenForState = [7]Token.Type{ Token.Type.mul, Token.Type.openP, Token.Type.number, Token.Type.comma, Token.Type.number, Token.Type.closeP, Token.Type.garbage };

fn write(comptime str: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(str, args) catch {};
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    alloc = gpa.allocator();

    const input = try std.io.getStdIn().readToEndAlloc(alloc, 256 * 1000);
    var lexer = Lexer.init(input);
    const tokens = try lexer.process();
    for (tokens.items) |token| {
        write("{}\n", .{token});
    }

    var state = parseState.start;
    var current = ParsedMul{ .multiplicand = 0, .multiplier = 0 };
    var parsedResults = std.ArrayList(ParsedMul).init(alloc);

    for (tokens.items) |nextToken| {
        if (nextToken.type != tokenForState[@intFromEnum(state)]) {
            state = parseState.start;
            continue;
        } else {
            state = @enumFromInt(@intFromEnum(state) + 1);
            if (state == parseState.multiplier) {
                current.multiplier = nextToken.data;
            } else if (state == parseState.multiplicand) {
                current.multiplicand = nextToken.data;
            } else if (state == parseState.cl) {
                try parsedResults.append(current);
                write("{} {}\n", .{ current.multiplier, current.multiplicand });
                state = parseState.start;
            }
        }
    }

    var finalResult: u32 = 0;
    for (parsedResults.items) |mul| {
        finalResult += mul.multiplier * mul.multiplicand;
    }

    write("{}\n", .{finalResult});
}
