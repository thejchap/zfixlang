const std = @import("std");
const lexer = @import("lexer.zig");
const interpreter = @import("interpreter.zig");
const parser = @import("parser.zig");
const smol = @import("smol.zig");
const T = lexer.TokenKind;
const Lexer = lexer.Lexer;
const Parser = parser.Parser;
const Interpreter = interpreter.Interpreter;
/// evaluate input source code from command line arg
pub fn main() void {
    if (std.os.argv.len < 2) {
        std.debug.print("usage: {s} <source>\n", .{std.os.argv[0]});
        return;
    }
    const raw = std.os.argv[1];
    const source = std.mem.span(raw);
    const doSmol = true;
    const result = if (doSmol) smol.eval(source) else big(source);
    const stdout = std.io.getStdOut().writer();
    // for pretty printing ast if we do that
    var ws = std.json.writeStream(stdout, .{ .whitespace = .indent_2 });
    defer ws.deinit();
    ws.print("{d}\n", .{result}) catch unreachable;
}
/// actually do whole shebang - lex, create ast, interpret
fn big(source: []const u8) u64 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var lexr = Lexer.new(source, allocator);
    defer lexr.deinit();
    lexr.scanTokens();
    var parsr = Parser.new(lexr.tokens.items, allocator);
    const root = parsr.parse();
    defer parsr.deinit(root);
    var interp = Interpreter.new(root);
    return interp.interpret();
}
test {
    _ = @import("lexer.zig");
    _ = @import("interpreter.zig");
    _ = @import("parser.zig");
    _ = @import("smol.zig");
    // this call apparently depends on control flow so wasn't picking up everything
    // on every run (depending on the smol flag).
    // looks like importing explicitly here fixes it but didnt look too much
    @import("std").testing.refAllDeclsRecursive(@This());
}
