const std = @import("std");
const parser = @import("parser.zig");
const ASTNode = parser.ASTNode;

pub const Interpreter = struct {
    root: *ASTNode,
    pub fn new(root: *ASTNode) Interpreter {
        return Interpreter{
            .root = root,
        };
    }
    pub fn interpret(self: *Interpreter) u64 {
        return self.visit(self.root);
    }
    fn visit(self: *Interpreter, node: *ASTNode) u64 {
        switch (node.*) {
            .Number => |number| {
                return number;
            },
            .BinOp => |bin| {
                const left = self.visit(bin.left);
                const right = self.visit(bin.right);
                return switch (bin.op) {
                    .Add => left + right,
                    .Sub => left - right,
                    .Mul => left * right,
                    .Div => left / right,
                };
            },
        }
    }
};
test "interpreter" {
    const Lexer = @import("lexer.zig").Lexer;
    const Parser = @import("parser.zig").Parser;
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
