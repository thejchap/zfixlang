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
