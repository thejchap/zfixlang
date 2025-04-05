const std = @import("std");

const lexer = @import("lexer.zig");
const T = lexer.TokenKind;
const Token = lexer.Token;

pub const BinOp = struct {
    op: Token,
    lhs: *Expression,
    rhs: *Expression,
    allocator: std.mem.Allocator,
    pub fn deinit(self: *BinOp) void {
        self.lhs.deinit();
        self.rhs.deinit();
        self.allocator.destroy(self.lhs);
        self.allocator.destroy(self.rhs);
        self.allocator.destroy(self);
    }
};
pub const ExprType = enum {
    binop,
    literal,
};
pub const Expression = union(ExprType) {
    binop: *BinOp,
    literal: u64,
    pub fn deinit(self: Expression) void {
        switch (self) {
            .binop => |*bop| {
                bop.*.deinit();
            },
            .literal => {},
        }
    }
};
const Parser = struct {
    tokens: []Token,
    current: usize,
    allocator: std.mem.Allocator,
    fn new(tokens: []Token, allocator: std.mem.Allocator) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
            .allocator = allocator,
        };
    }
    fn parse(self: *Parser) *BinOp {
        return self.binop();
    }
    fn binop(self: *Parser) *BinOp {
        const bop = self.allocator.create(BinOp) catch unreachable;
        errdefer self.allocator.destroy(bop);
        _ = self.chomp(T.LPAREN);
        const op = self.operator();
        const lhs = self.expression();
        const rhs = self.expression();
        _ = self.chomp(T.RPAREN);
        bop.* = BinOp{
            .op = op,
            .lhs = lhs,
            .rhs = rhs,
            .allocator = self.allocator,
        };
        return bop;
    }
    fn expression(self: *Parser) *Expression {
        const expr = self.allocator.create(Expression) catch unreachable;
        errdefer self.allocator.destroy(expr);
        if (self.matchToken(T.INT)) {
            const prev = self.previous();
            const literal = switch (prev.kind) {
                T.INT => prev.literal.?,
                else => std.debug.panic("expression failed", .{}),
            };
            expr.* = Expression{
                .literal = literal,
            };
        } else {
            expr.* = Expression{
                .binop = self.binop(),
            };
        }
        return expr;
    }
    fn operator(self: *Parser) Token {
        if (self.matchToken(T.PLUS)) {
            return self.previous();
        } else if (self.matchToken(T.MINUS)) {
            return self.previous();
        } else if (self.matchToken(T.STAR)) {
            return self.previous();
        } else if (self.matchToken(T.SLASH)) {
            return self.previous();
        }
        std.debug.panic("operator failed", .{});
    }
    fn matchToken(self: *Parser, kind: T) bool {
        if (self.check(kind)) {
            _ = self.advance();
            return true;
        }
        return false;
    }
    fn check(self: *Parser, kind: T) bool {
        if (self.isAtEnd()) {
            return false;
        }
        return self.peek().kind == kind;
    }
    fn advance(self: *Parser) Token {
        if (!self.isAtEnd()) {
            self.current += 1;
        }
        return self.previous();
    }
    fn isAtEnd(self: *Parser) bool {
        return self.peek().kind == T.EOF;
    }
    fn previous(self: *Parser) Token {
        return self.tokens[self.current - 1];
    }
    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }
    fn chomp(self: *Parser, kind: T) Token {
        if (self.check(kind)) {
            return self.advance();
        }
        std.debug.panic("chomp failed", .{});
    }
};

pub fn parse(tokens: []Token, allocator: std.mem.Allocator) *BinOp {
    var parser = Parser.new(tokens, allocator);
    return parser.parse();
}
