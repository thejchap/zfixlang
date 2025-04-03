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
pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    literal: ?u64,
    line: usize,
};
