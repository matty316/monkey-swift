//
//  LexerTests.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

import Testing
@testable import monkey

struct LexerTest {

    @Test func testNextToken() async throws {
        let input = """
let five = 5;
let ten = 10;

let add = fn(x, y) {
    x + y
};

let result = add(five, ten);

!-/*5;

5 < 10 > 5

if (5 < 10) {
    return true;
} else {
    return false;
}

10 == 10;
10 != 9;
"""
        let tests = [
            Token(tokenType: .LET),
            Token(tokenType: .IDENT, literal: "five"),
            Token(tokenType: .ASSIGN),
            Token(tokenType: .INT, literal: "5"),
            Token(tokenType: .SEMICOLON),Token(tokenType: .LET),
            Token(tokenType: .IDENT, literal: "ten"),
            Token(tokenType: .ASSIGN),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .LET),
            Token(tokenType: .IDENT, literal: "add"),
            Token(tokenType: .ASSIGN),
            Token(tokenType: .FUNCTION),
            Token(tokenType: .LPAREN),
            Token(tokenType: .IDENT, literal: "x"),
            Token(tokenType: .COMMA),
            Token(tokenType: .IDENT, literal: "y"),
            Token(tokenType: .RPAREN),
            Token(tokenType: .LBRACE),
            Token(tokenType: .IDENT, literal: "x"),
            Token(tokenType: .PLUS),
            Token(tokenType: .IDENT, literal: "y"),
            Token(tokenType: .RBRACE),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .LET),
            Token(tokenType: .IDENT, literal: "result"),
            Token(tokenType: .ASSIGN),
            Token(tokenType: .IDENT, literal: "add"),
            Token(tokenType: .LPAREN),
            Token(tokenType: .IDENT, literal: "five"),
            Token(tokenType: .COMMA),
            Token(tokenType: .IDENT, literal: "ten"),
            Token(tokenType: .RPAREN),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .BANG),
            Token(tokenType: .MINUS),
            Token(tokenType: .SLASH),
            Token(tokenType: .ASTERISK),
            Token(tokenType: .INT, literal: "5"),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .INT, literal: "5"),
            Token(tokenType: .LT),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .GT),
            Token(tokenType: .INT, literal: "5"),
            Token(tokenType: .IF),
            Token(tokenType: .LPAREN),
            Token(tokenType: .INT, literal: "5"),
            Token(tokenType: .LT),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .RPAREN),
            Token(tokenType: .LBRACE),
            Token(tokenType: .RETURN),
            Token(tokenType: .TRUE),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .RBRACE),
            Token(tokenType: .ELSE),
            Token(tokenType: .LBRACE),
            Token(tokenType: .RETURN),
            Token(tokenType: .FALSE),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .RBRACE),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .EQ),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .INT, literal: "10"),
            Token(tokenType: .NOT_EQ),
            Token(tokenType: .INT, literal: "9"),
            Token(tokenType: .SEMICOLON),
            Token(tokenType: .EOF)
        ]
        let l = Lexer(input: input)
    
        for (i, token) in tests.enumerated() {
            let tok = l.nextToken()
            #expect(token.tokenType == tok.tokenType, "expected \(token) got \(tok) at \(i)")
            #expect(token.literal == tok.literal, "expected \(token) got \(tok) at \(i)")
        }
    }
}
