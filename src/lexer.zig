const std = @import("std");

pub const TokenKind = enum {
    LPAREN,
    RPAREN,
    PLUS,
    MINUS,
    STAR,
    SLASH,
    INT,
    EOF,
};
const T = TokenKind;
pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    literal: ?u64,
    line: usize,
};

const Lexer = struct {
    source: []const u8,
    tokens: std.ArrayList(Token),
    start: usize,
    current: usize,
    line: usize,
    fn scanTokens(self: *Lexer) void {
        while (!self.isAtEnd()) {
            self.start = self.current;
            self.scanToken();
        }
        self.addToken(T.EOF);
    }
    fn scanToken(self: *Lexer) void {
        const c = self.advance();
        switch (c) {
            '(' => self.addToken(T.LPAREN),
            ')' => self.addToken(T.RPAREN),
            '+' => self.addToken(T.PLUS),
            '-' => self.addToken(T.MINUS),
            '*' => self.addToken(T.STAR),
            '/' => self.addToken(T.SLASH),
            '0'...'9' => {
                var digit = c - '0';
                while (std.ascii.isDigit(self.peek())) {
                    digit = digit * 10 + (self.advance() - '0');
                }
                self.addTokenWithLiteral(T.INT, digit);
            },
            ' ' => {},
            '\r' => {},
            '\t' => {},
            '\n' => {
                self.line += 1;
            },
            else => {
                std.debug.print("unexpected character: {}\n", .{c});
            },
        }
    }
    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }
    fn peek(self: *Lexer) u8 {
        if (self.current >= self.source.len) {
            return 0;
        }
        return self.source[self.current];
    }
    fn addToken(self: *Lexer, kind: T) void {
        return self.addTokenWithLiteral(kind, null);
    }
    fn addTokenWithLiteral(self: *Lexer, kind: T, literal: ?u64) void {
        const tok = Token{
            .kind = kind,
            .lexeme = self.source[self.start..self.current],
            .literal = literal,
            .line = self.line,
        };
        self.tokens.append(tok) catch unreachable;
    }
    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }
    fn new(source: []const u8, alloc: std.mem.Allocator) Lexer {
        return Lexer{
            .source = source,
            .tokens = std.ArrayList(Token).init(alloc),
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }
    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit();
    }
};
pub fn lex(source: []const u8, allocator: std.mem.Allocator) Lexer {
    var lexer = Lexer.new(source, allocator);
    lexer.scanTokens();
    return lexer;
}
