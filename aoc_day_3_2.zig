const std = @import("std");

fn write(comptime str: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(str, args) catch {};
}

const Token = struct {
    const Type = enum { garbage, mul, openP, number, comma, closeP, enable, disable };

    type: Type,
    data: u32,
};

const ParsedMul = struct {
    multiplicand: u32,
    multiplier: u32,
};

const magicStrings = [_][]const u8{ "mul", "do()", "don't()" };
const typeForString = [_]Token.Type{ Token.Type.mul, Token.Type.enable, Token.Type.disable };

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
                for (magicStrings, 0..) |str, n| {
                    if (self.head + str.len <= self.input.len and
                        std.mem.eql(u8, self.input[self.head .. self.head + str.len], str))
                    {
                        self.head += @intCast(str.len);
                        return Token{ .type = typeForString[n], .data = 0 };
                    }
                }
                self.head += 1;
                return Token{ .type = Token.Type.garbage, .data = 0 };
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

const parseState = enum { start, mul, op, multiplicand, comma, multiplier, cl, disabled };
const tokenForState = [_]Token.Type{ Token.Type.mul, Token.Type.openP, Token.Type.number, Token.Type.comma, Token.Type.number, Token.Type.closeP, Token.Type.garbage, Token.Type.enable };

const Parser = struct {
    tokens: std.ArrayList(Token),

    fn init(tokens: std.ArrayList(Token)) Parser {
        return Parser{ .tokens = tokens };
    }

    fn process(self: @This()) !std.ArrayList(ParsedMul) {
        var state = parseState.start;
        var current = ParsedMul{ .multiplicand = 0, .multiplier = 0 };
        var parsedResults = std.ArrayList(ParsedMul).init(alloc);

        for (self.tokens.items) |nextToken| {
            if (nextToken.type == Token.Type.enable) {
                state = parseState.start;
            } else if (nextToken.type == Token.Type.disable) {
                state = parseState.disabled;
            } else if (state != parseState.disabled) {
                if (nextToken.type != tokenForState[@intFromEnum(state)]) {
                    state = parseState.start;
                } else {
                    state = @enumFromInt(@intFromEnum(state) + 1);
                    if (state == parseState.multiplier) {
                        current.multiplier = nextToken.data;
                    } else if (state == parseState.multiplicand) {
                        current.multiplicand = nextToken.data;
                    } else if (state == parseState.cl) {
                        try parsedResults.append(current);
                        state = parseState.start;
                    }
                }
            }
        }

        return parsedResults;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    alloc = gpa.allocator();

    const input = try std.io.getStdIn().readToEndAlloc(alloc, 256 * 1000);
    defer alloc.free(input);

    var lexer = Lexer.init(input);
    const tokens = try lexer.process();
    defer tokens.deinit();

    const parser = Parser.init(tokens);
    const parsedMuls = try parser.process();
    defer parsedMuls.deinit();

    var finalResult: u32 = 0;
    for (parsedMuls.items) |mul| {
        finalResult += mul.multiplier * mul.multiplicand;
    }

    write("{}\n", .{finalResult});
}
