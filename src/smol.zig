const std = @import("std");
/// match number
fn number(source: []const u8, index: *usize) u64 {
    var num: u64 = 0;
    while (std.ascii.isDigit(source[index.*])) {
        num = num * 10 + (source[index.*] - '0');
        if (index.* >= source.len - 1) {
            break;
        }
        index.* += 1;
    }
    return num;
}
/// match binop
fn binop(source: []const u8, index: *usize) u64 {
    if (source[index.*] != '(') {
        std.debug.panic("expected '('", .{});
    }
    index.* += 1; // skip (
    const op = source[index.*]; // get operator
    index.* += 1; // on to operands
    const left = expression(source, index);
    const right = expression(source, index);
    index.* += 1; // skip )
    switch (op) {
        '+' => return left + right,
        '-' => return left - right,
        '*' => return left * right,
        '/' => return left / right,
        else => std.debug.panic("unknown operator: {c}", .{op}),
    }
}
/// match expression
fn expression(source: []const u8, index: *usize) u64 {
    if (source[index.*] == ' ') {
        index.* += 1; // skip whitespace
        return expression(source, index);
    }
    if (std.ascii.isDigit(source[index.*])) {
        return number(source, index);
    }
    return binop(source, index);
}
/// smaller simpler interpreter - just one pass and indexes in to the
/// source string instead of tokenizing and creating an ast
pub fn eval(source: []const u8) u64 {
    var index: usize = 0;
    return expression(source, &index);
}
test "smol number" {
    const result = eval("10");
    try std.testing.expectEqual(result, 10);
}
test "smol addition" {
    const result = eval("(+ 10 20)");
    try std.testing.expectEqual(result, 30);
}
test "smol nested" {
    const result = eval("(+ (* 2 2) (* 2 2))");
    try std.testing.expectEqual(result, 8);
}
test "readme" {
    const result = eval("(* 2 (+ 42 1))");
    try std.testing.expectEqual(result, 86);
}
//unsigned at the moment
//test "negative" {
//    const result = eval("(- -10 20)");
//    try std.testing.expectEqual(result, -30);
//}
