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
test {
    @import("std").testing.refAllDeclsRecursive(@This());
}
