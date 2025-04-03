const std = @import("std");

const lexer = @import("lexer.zig");
const token = @import("token.zig");
const T = token.TokenKind;
const Token = token.Token;

pub const BinOp = struct {
    op: Token,
    lhs: *const Expression,
    rhs: *const Expression,
};
pub const Expression = union(enum) {
    binop: BinOp,
    literal: u64,
};
const Parser = struct {
    tokens: []Token,
    current: usize,
    fn new(tokens: []Token) Parser {
        return Parser{
            .tokens = tokens,
            .current = 0,
        };
    }
    fn parse(self: *Parser) BinOp {
        return self.binop();
    }
    fn binop(self: *Parser) BinOp {
        _ = self.chomp(T.LPAREN);
        const op = self.operator();
        const lhs = self.expression();
        const rhs = self.expression();
        _ = self.chomp(T.RPAREN);
        return BinOp{
            .op = op,
            .lhs = lhs,
            .rhs = rhs,
        };
    }
    fn expression(self: *Parser) *const Expression {
        if (self.matchToken(T.INT)) {
            const prev = self.previous();
            const literal = switch (prev.kind) {
                T.INT => prev.literal.?,
                else => std.debug.panic("expression failed", .{}),
            };
            return &Expression{ .literal = literal };
        }
        return &Expression{
            .binop = self.binop(),
        };
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

pub fn parse(tokens: []Token) BinOp {
    var parser = Parser.new(tokens);
    return parser.parse();
}
