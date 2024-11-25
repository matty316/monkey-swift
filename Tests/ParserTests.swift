//
//  ParserTests.swift
//  monkey
//
//  Created by Matthew Reed on 11/25/24.
//

import Testing
@testable import monkey

struct ParserTests {
    @Test func testLetStatement() async throws {
        let input = """
let x = 5;
let y = 10;
let foobar = 838383;
"""
        
        let parser = Parser(lexer: Lexer(input: input))
        
        let program = parser.parseProgram()
        checkParserErrors(parser)
        
        try #require(program.statements.count == 3)
        
        let tests: [String] = ["x", "y", "foobar"]
        
        for (i, t) in tests.enumerated() {
            let stmt = program.statements[i]
            #expect(stmt.tokenLiteral() == "let")
            let letStmt = stmt as! LetStatement
            #expect(letStmt.name.value == t)
            #expect(letStmt.name.tokenLiteral() == t)
        }
    }
    
    func checkParserErrors(_ p: Parser) {
        #expect(p.errors.count == 0)
        if !p.errors.isEmpty {
            for e in p.errors {
                print(e)
            }
        }
    }
    
    @Test func testReturnStatement() async throws {
        let input = """
return 5;
return 10;
return 993322;
"""
        
        let p = Parser(lexer: Lexer(input: input))
        
        let program = p.parseProgram()
        checkParserErrors(p)
        
        try #require(program.statements.count == 3)
        
        for stmt in program.statements {
            let returnStmt = stmt as! ReturnStatement
            #expect(returnStmt.tokenLiteral() == "return")
        }
    }
    
    @Test func testString() async throws {
        let program = Program(statements: [
            LetStatement(token: Token(tokenType: .LET), name: Identifier(token: Token(tokenType: .IDENT, literal: "myVar"), value: "myVar"), value: Identifier(token: Token(tokenType: .IDENT, literal: "anotherVar"), value: "anotherVar"))
        ])
        
        #expect(program.string() == "let myVar = anotherVar;")
    }
    
    @Test func testIndentifierExpression() throws {
        let input = "foobar;"
        
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        try #require(prog.statements.count == 1)
        let stmt = prog.statements[0] as! ExpressionStatement
        let expr = stmt.expression as! Identifier
        #expect(expr.tokenLiteral() == "foobar")
        #expect(expr.value == "foobar")
    }
}
