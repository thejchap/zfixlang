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
    /// TODO
    pub fn interpret() u64 {
        return 5;
    }
};
