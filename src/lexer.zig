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

/// simple lexer with a few token types
pub const Lexer = struct {
    /// source code to scan
    source: []const u8,
    /// tokens generated from the source code
    tokens: std.ArrayList(Token),
    ///
    start: usize,
    /// current position in the source code
    current: usize,
    /// current line number
    line: usize,
    /// goes through til EOF and emits tokens
    pub fn scanTokens(self: *Lexer) void {
        while (!self.isAtEnd()) {
            self.start = self.current;
            self.scanToken();
        }
        self.addToken(T.EOF);
    }
    /// emit a single token
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
            else => unreachable,
        }
    }
    /// advance the cursor and return the character at the new position
    fn advance(self: *Lexer) u8 {
        self.current += 1;
        return self.source[self.current - 1];
    }
    /// peek at the next character without advancing the cursor
    fn peek(self: *Lexer) u8 {
        if (self.current >= self.source.len) {
            return 0;
        }
        return self.source[self.current];
    }
    /// convenience method for adding a token with no literal value
    fn addToken(self: *Lexer, kind: T) void {
        return self.addTokenWithLiteral(kind, null);
    }
    /// convenience method for adding a token with a literal value
    fn addTokenWithLiteral(self: *Lexer, kind: T, literal: ?u64) void {
        const tok = Token{
            .kind = kind,
            .lexeme = self.source[self.start..self.current],
            .literal = literal,
            .line = self.line,
        };
        self.tokens.append(tok) catch unreachable;
    }
    /// are we at EOF
    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }
    /// initialize with empty tokens at start
    pub fn new(source: []const u8, alloc: std.mem.Allocator) Lexer {
        return Lexer{
            .source = source,
            .tokens = std.ArrayList(Token).init(alloc),
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }
    /// teardown
    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit();
    }
};
test "lexer" {
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
