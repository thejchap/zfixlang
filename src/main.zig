const std = @import("std");

const lexer = @import("lexer.zig");
const parser = @import("parser.zig");
const token = @import("token.zig");
const T = token.TokenKind;

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const raw_source = std.os.argv[1];
    const source = std.mem.span(raw_source);
    var lex = lexer.lex(source, allocator);
    defer lex.deinit();
    const tree = parser.parse(lex.tokens.items);
    std.debug.print("{any}\n", .{tree});
}

test "(+ 1 1)" {
    var lex = lexer.lex("(+ 1 1)", std.testing.allocator);
    defer lex.deinit();
    const result = parser.parse(lex.tokens.items);
    const expected = parser.BinOp{
        .op = token.Token{
            .kind = T.PLUS,
            .lexeme = "+",
            .literal = null,
            .line = 1,
        },
        .lhs = &parser.Expression{
            .literal = 1,
        },
        .rhs = &parser.Expression{
            .literal = 1,
        },
    };
    try std.testing.expectEqual(expected.op.kind, result.op.kind);
}

test "lex ()+-*/42" {
    var l = lexer.lex("()+-*/42", std.testing.allocator);
    var tokenKinds = std.ArrayList(T).init(std.testing.allocator);
    defer l.deinit();
    defer tokenKinds.deinit();
    for (l.tokens.items) |tok| {
        try tokenKinds.append(tok.kind);
    }
    try std.testing.expectEqualSlices(T, &[_]T{
        T.LPAREN,
        T.RPAREN,
        T.PLUS,
        T.MINUS,
        T.STAR,
        T.SLASH,
        T.INT,
        T.EOF,
    }, tokenKinds.items);
    try std.testing.expectEqual(42, l.tokens.items[6].literal);
}
