const std = @import("std");

const lexer = @import("lexer.zig");
const T = lexer.TokenKind;
const parser = @import("parser.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const raw_source = std.os.argv[1];
    const source = std.mem.span(raw_source);
    var lex = lexer.lex(source, allocator);
    defer lex.deinit();
    const tree = parser.parse(lex.tokens.items, allocator);
    defer tree.deinit();
    std.debug.print("{any}\n", .{tree});
}

test "lex" {
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

test "parse" {
    var lex = lexer.lex("(+ (* 2 2) 1)", std.testing.allocator);
    defer lex.deinit();
    const result = parser.parse(lex.tokens.items, std.testing.allocator);
    defer result.deinit();
    try std.testing.expectEqual(T.PLUS, result.op.kind);
    try std.testing.expectEqual(T.STAR, result.lhs.binop.op.kind);
    try std.testing.expectEqual(2, result.lhs.binop.lhs.literal);
    try std.testing.expectEqual(2, result.lhs.binop.rhs.literal);
    try std.testing.expectEqual(1, result.rhs.literal);
}
