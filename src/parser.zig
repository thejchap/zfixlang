const std = @import("std");

const lexer = @import("lexer.zig");
const T = lexer.TokenKind;
const Token = lexer.Token;

/// just 2 node types - numbers and binary operations
pub const ASTNodeType = enum {
    Number,
    BinOp,
};
/// basic allowed operators
pub const Operator = enum {
    Add,
    Sub,
    Mul,
    Div,
};
/// abstract syntax tree node returned by the parser
pub const ASTNode = union(ASTNodeType) {
    /// can either be a number
    Number: u64,
    /// ...or a binary operation
    BinOp: struct {
        /// operator of the binary operation
        op: Operator,
        /// left operand of the binary operation
        left: *ASTNode,
        /// right operand of the binary operation
        right: *ASTNode,
    },
    pub fn deinit(self: *ASTNode, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .Number => {},
            .BinOp => |binop| {
                binop.left.deinit(allocator);
                binop.right.deinit(allocator);
            },
        }
        allocator.destroy(self);
    }
};
pub const Parser = struct {
    /// list of input tokens
    tokens: []Token,
    /// index of the current token being processed
    current: usize,
    /// allocator used to allocate AST nodes
    allocator: std.mem.Allocator,
    /// initializes the parser with the given tokens and allocator
    pub fn new(tokens: []Token, allocator: std.mem.Allocator) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
            .allocator = allocator,
        };
    }
    /// entrypoint for parsing the input tokens. match an expression
    pub fn parse(self: *Parser) *ASTNode {
        return self.expression();
    }
    /// match a number, or a binary operation
    fn expression(self: *Parser) *ASTNode {
        if (self.matchToken(T.INT)) {
            return self.number();
        }
        return self.binop();
    }
    /// match a number
    fn number(self: *Parser) *ASTNode {
        const num = self.allocator.create(ASTNode) catch unreachable;
        errdefer self.allocator.destroy(num);
        const prev = self.previous();
        num.* = ASTNode{
            .Number = switch (prev.kind) {
                .INT => prev.literal.?,
                else => unreachable,
            },
        };
        return num;
    }
    /// match a binary operation
    fn binop(self: *Parser) *ASTNode {
        const bop = self.allocator.create(ASTNode) catch unreachable;
        errdefer self.allocator.destroy(bop);
        _ = self.chomp(T.LPAREN);
        const op = self.operator();
        const left = self.expression();
        const right = self.expression();
        _ = self.chomp(T.RPAREN);
        bop.* = ASTNode{
            .BinOp = .{
                .op = op,
                .left = left,
                .right = right,
            },
        };
        return bop;
    }
    /// match an operator
    fn operator(self: *Parser) Operator {
        if (self.matchToken(T.PLUS)) {
            return Operator.Add;
        }
        if (self.matchToken(T.MINUS)) {
            return Operator.Sub;
        }
        if (self.matchToken(T.STAR)) {
            return Operator.Mul;
        }
        if (self.matchToken(T.SLASH)) {
            return Operator.Div;
        }
        unreachable;
    }
    /// match a token and advance the parser
    fn matchToken(self: *Parser, kind: T) bool {
        if (self.check(kind)) {
            _ = self.advance();
            return true;
        }
        return false;
    }
    /// check if the current token is of the given kind
    fn check(self: *Parser, kind: T) bool {
        if (self.isAtEnd()) {
            return false;
        }
        return self.peek().kind == kind;
    }
    /// advance the parser and return the previous token
    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) {
            self.current += 1;
        }
        return self.previous();
    }
    /// at EOF
    fn isAtEnd(self: *Parser) bool {
        return self.peek().kind == T.EOF;
    }
    /// return the previous token
    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }
    /// get the current token
    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }
    /// eat a token and advance the parser
    fn chomp(self: *Parser, kind: T) Token {
        if (self.check(kind)) {
            return self.advance();
        }
        unreachable;
    }
    pub fn deinit(self: *Parser, root: *ASTNode) void {
        root.deinit(self.allocator);
    }
};
test "parser" {
    const Lexer = @import("lexer.zig").Lexer;
    var lex = Lexer.new("(+ (* 2 2) 1)", std.testing.allocator);
    defer lex.deinit();
    lex.scanTokens();
    var parsr = Parser.new(lex.tokens.items, std.testing.allocator);
    const root = parsr.parse();
    defer parsr.deinit(root);
    try std.testing.expectEqual(Operator.Add, root.BinOp.op);
    try std.testing.expectEqual(Operator.Mul, root.BinOp.left.BinOp.op);
    try std.testing.expectEqual(2, root.BinOp.left.BinOp.left.Number);
    try std.testing.expectEqual(2, root.BinOp.left.BinOp.right.Number);
    try std.testing.expectEqual(1, root.BinOp.right.Number);
}
