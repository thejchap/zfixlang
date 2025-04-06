const std = @import("std");

const lexer = @import("lexer.zig");
const interpreter = @import("interpreter.zig");
const parser = @import("parser.zig");
const T = lexer.TokenKind;
const Lexer = lexer.Lexer;
const Parser = parser.Parser;
const Interpreter = interpreter.Interpreter;

/// evaluate input source code from command line arg
pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    if (std.os.argv.len < 2) {
        std.debug.print("usage: {s} <source>\n", .{std.os.argv[0]});
        return;
    }
    const raw_source = std.os.argv[1];
    const source = std.mem.span(raw_source);
    var lexr = Lexer.new(source, allocator);
    defer lexr.deinit();
    lexr.scanTokens();
    var parsr = Parser.new(lexr.tokens.items, allocator);
    const root = parsr.parse();
    defer parsr.deinit(root);
    var interp = Interpreter.new(root);
    const result = interp.interpret();
    const stdout = std.io.getStdOut().writer();
    // pretty print ast
    var ws = std.json.writeStream(
        stdout,
        .{ .whitespace = .indent_2 },
    );
    defer ws.deinit();
    ws.print("{d}\n", .{result}) catch unreachable;
}

test "lex" {
    var l = Lexer.new("()+-*/42", std.testing.allocator);
    defer l.deinit();
    l.scanTokens();
    var tokenKinds = std.ArrayList(T).init(std.testing.allocator);
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
    var lex = Lexer.new("(+ (* 2 2) 1)", std.testing.allocator);
    defer lex.deinit();
    lex.scanTokens();
    var parsr = Parser.new(lex.tokens.items, std.testing.allocator);
    const root = parsr.parse();
    defer parsr.deinit(root);
    try std.testing.expectEqual(parser.Operator.Add, root.BinOp.op);
    try std.testing.expectEqual(parser.Operator.Mul, root.BinOp.left.BinOp.op);
    try std.testing.expectEqual(2, root.BinOp.left.BinOp.left.Number);
    try std.testing.expectEqual(2, root.BinOp.left.BinOp.right.Number);
    try std.testing.expectEqual(1, root.BinOp.right.Number);
}

test "interpret" {
    const source = "(+ (* 2 2) 1)";
    var lex = Lexer.new(source, std.testing.allocator);
    defer lex.deinit();
    lex.scanTokens();
    var parsr = Parser.new(lex.tokens.items, std.testing.allocator);
    const root = parsr.parse();
    defer parsr.deinit(root);
    var interp = Interpreter.new(root);
    const result = interp.interpret();
    try std.testing.expectEqual(5, result);
}
