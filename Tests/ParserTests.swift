//
//  ParserTests.swift
//  monkey
//
//  Created by Matthew Reed on 11/25/24.
//

import Testing
@testable import monkey

struct ParserTests {
    @Test func testLetStatement() {
        let inputs = ["let x = 5;", "let y = true;", "let foobar = y;"]
        let exps: [(String, Any)] = [("x", 5), ("y", true), ("foobar", "y")]
        for (i, input) in inputs.enumerated() {
            let p = Parser(lexer: Lexer(input: input))
            let program = p.parseProgram()
            checkParserErrors(p)
            #expect(program.statements.count == 1)
            
            let stmt = program.statements[0]
            testLetStatement(stmt: stmt, name: exps[i].0)
            let value = (stmt as! LetStatement).value
            testLiteralExpression(expr: value, val: exps[i].1)
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
        let inputs = ["return 5;", "return true;", "return foobar;"]
        let exps: [Any] = [5, true, "foobar"]
        for (i, input) in inputs.enumerated() {
            
            let p = Parser(lexer: Lexer(input: input))
            
            let program = p.parseProgram()
            checkParserErrors(p)
            
            try #require(program.statements.count == 1)
            let returnStmt = program.statements[0] as! ReturnStatement
            #expect(returnStmt.tokenLiteral() == "return")
            testLiteralExpression(expr: returnStmt.value, val: exps[i])
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
    
    @Test func testIntegerLiteralExpression() throws {
        let input = "5;"
        
        let p = Parser(lexer: Lexer(input: input))
        let program = p.parseProgram()
        checkParserErrors(p)
        
        try #require(program.statements.count == 1)
        
        let stmt = program.statements[0] as! ExpressionStatement
        let lit = stmt.expression as! IntegerLiteral
        #expect(lit.value == 5)
        #expect(lit.tokenLiteral() == "5")
    }
    
    @Test(arguments: zip(["!5;", "-15;"], [("!", 5), ("-", 15)]))
    func testParsePrefixExpression(input: String, exp: (op: String, value: Int)) throws {
        let p = Parser(lexer: Lexer(input: input))
        let program = p.parseProgram()
        checkParserErrors(p)
        try #require(program.statements.count == 1)
        let stmt = program.statements[0] as! ExpressionStatement
        let expr = stmt.expression as! PrefixExpression
        #expect(expr.op == exp.op)
        testIntergerLiteral(expr: expr.right, val: exp.value)
    }
    
    @Test(arguments: zip(["5 + 5;", "5 - 5;", "5 * 5;", "5 / 5;", "5 > 5;", "5 < 5;", " 5 == 5;", "5 != 5;"], [
        (5, "+", 5),
        (5, "-", 5),
        (5, "*", 5),
        (5, "/", 5),
        (5, ">", 5),
        (5, "<", 5),
        (5, "==", 5),
        (5, "!=", 5),
    ]))
    func testParseInfixExpression(input: String, exp: (left: Int, op: String, right: Int)) throws {
        let p = Parser(lexer: Lexer(input: input))
        let program = p.parseProgram()
        checkParserErrors(p)
        try #require(program.statements.count == 1)
        
        let stmt = program.statements.first as! ExpressionStatement
        let expr = stmt.expression as! InfixExpression
        testIntergerLiteral(expr: expr.left, val: exp.left)
        testIntergerLiteral(expr: expr.right, val: exp.right)
        #expect(expr.op == exp.op)
    }
    
    @Test(arguments: zip(
        [
            "-a * b",
            "!-a",
            "a + b + c",
            "a + b - c",
            "a * b * c",
            "a * b / c",
            "a + b / c",
            "a + b * c + d / e - f",
            "3 + 4; -5 * 5",
            "5 > 4 == 3 < 4",
            "5 < 4 != 3 > 4",
            "3 + 4 * 5 == 3 * 1 + 4 * 5",
            "true",
            "false",
            "3 > 5 == false",
            "3 < 5 == true",
            "1 + (2 + 3) + 4",
            "(5 + 5) * 2",
            "2 / (5 + 5)",
            "-(5 + 5)",
            "!(true == true)",
            "a + add(b * c) + d",
            "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
            "add(a + b + c * d / f + g)",
            "a * [1, 2, 3, 4][b * c] * d",
            "add(a * b[2], b[1], 2 * [1, 2][1])"
        ], [
            "((-a) * b)",
            "(!(-a))",
            "((a + b) + c)",
            "((a + b) - c)",
            "((a * b) * c)",
            "((a * b) / c)",
            "(a + (b / c))",
            "(((a + (b * c)) + (d / e)) - f)",
            "(3 + 4)((-5) * 5)",
            "((5 > 4) == (3 < 4))",
            "((5 < 4) != (3 > 4))",
            "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))",
            "true",
            "false",
            "((3 > 5) == false)",
            "((3 < 5) == true)",
            "((1 + (2 + 3)) + 4)",
            "((5 + 5) * 2)",
            "(2 / (5 + 5))",
            "(-(5 + 5))",
            "(!(true == true))",
            "((a + add((b * c))) + d)",
            "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))",
            "add((((a + b) + ((c * d) / f)) + g))",
            "((a * ([1, 2, 3, 4][(b * c)])) * d)",
            "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
        ]
    ))
    func testOpPrecedence(input: String, exp: String) {
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(exp == prog.string())
    }
    
    @Test(arguments: zip(["true;", "false;"], [true, false]))
    func testBooleanExpression(input: String, exp: Bool) throws {
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        try #require(prog.statements.count == 1)
        let stmt = prog.statements.first as! ExpressionStatement
        testLiteralExpression(expr: stmt.expression!, val: exp)
    }
    
    @Test func testIfExpr() throws {
        let input = "if (x < y) { x }"
        
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        try #require(prog.statements.count == 1)
        let ifExpr = (prog.statements[0] as! ExpressionStatement).expression as! IfExpression
        testInfixExpression(expr: ifExpr.condition, left: "x", op: "<", right: "y")
        #expect(ifExpr.consequence.statements.count == 1)
        let consequence = ifExpr.consequence.statements[0] as! ExpressionStatement
        testIdentifier(expr: consequence.expression!, value: "x")
        #expect(ifExpr.alternative == nil)
    }
    
    @Test func testIfElseExpr() throws {
        let input = "if (x < y) { x } else { y }"
        
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        try #require(prog.statements.count == 1)
        let ifExpr = (prog.statements[0] as! ExpressionStatement).expression as! IfExpression
        testInfixExpression(expr: ifExpr.condition, left: "x", op: "<", right: "y")
        #expect(ifExpr.consequence.statements.count == 1)
        let consequence = ifExpr.consequence.statements[0] as! ExpressionStatement
        testIdentifier(expr: consequence.expression!, value: "x")
        
        #expect(ifExpr.alternative?.statements.count == 1)
        let alternative = ifExpr.alternative?.statements[0] as! ExpressionStatement
        testIdentifier(expr: alternative.expression!, value: "y")
    }
    
    @Test func testFunctionLiteral() {
        let input = "fn(x, y) { x + y; }"
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let fnLit = (prog.statements[0] as! ExpressionStatement).expression as! FunctionLiteral
        #expect(fnLit.params.count == 2)
        testLiteralExpression(expr: fnLit.params[0], val: "x")
        testLiteralExpression(expr: fnLit.params[1], val: "y")
        #expect(fnLit.body.statements.count == 1)
        let body = fnLit.body.statements[0] as! ExpressionStatement
        testInfixExpression(expr: body.expression!, left: "x", op: "+", right: "y")
    }
    
    @Test(arguments: zip(["fn() {}", "fn(x) {}", "fn(x, y, z) {}"], [[], ["x"], ["x", "y", "z"]]))
    func testParams(input: String, exp: [String]) {
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        let fnLit = (prog.statements[0] as! ExpressionStatement).expression as! FunctionLiteral
        #expect(fnLit.params.count == exp.count)
        for (i, param) in fnLit.params.enumerated() {
            #expect(param.value == exp[i])
        }
    }
    
    @Test func testCallExpression() {
        let input = "add(1, 2 * 3, 4 + 5);"
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let callExpr = (prog.statements[0] as! ExpressionStatement).expression as! CallExpression
        testIdentifier(expr: callExpr.function, value: "add")
        #expect(callExpr.arguments.count == 3)
        testLiteralExpression(expr: callExpr.arguments[0], val: 1)
        testInfixExpression(expr: callExpr.arguments[1], left: 2, op: "*", right: 3)
        testInfixExpression(expr: callExpr.arguments[2], left: 4, op: "+", right: 5)
    }
    
    @Test func testStringLiteral() {
        let input = "\"hello world\""
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        let stmt = prog.statements[0] as! ExpressionStatement
        let lit = stmt.expression as! StringLiteral
        #expect(lit.value == "hello world")
    }
    
    func testIntergerLiteral(expr: Expression, val: Int) {
        let lit = expr as! IntegerLiteral
        #expect(lit.value == val)
        #expect(lit.tokenLiteral() == String(val))
    }
    
    func testIdentifier(expr: Expression, value: String) {
        let ident = expr as! Identifier
        
        #expect(ident.value == value)
        #expect(ident.tokenLiteral() == value)
    }
    
    func testLiteralExpression(expr: Expression, val: Any) {
        switch val {
        case let intVal as Int: testIntergerLiteral(expr: expr, val: intVal)
        case let stringVal as String: testIdentifier(expr: expr, value: stringVal)
        case let boolVal as Bool: testBool(expr: expr, val: boolVal)
        default: #expect(Bool(false))
        }
    }
    
    func testInfixExpression(expr: Expression, left: Any, op: String, right: Any) {
        let opExp = expr as! InfixExpression
        testLiteralExpression(expr: opExp.left, val: left)
        #expect(opExp.op == op)
        testLiteralExpression(expr: opExp.right, val: right)
    }
    
    func testBool(expr: Expression, val: Bool) {
        let boolExp = expr as! BooleanExpression
        #expect(boolExp.value == val)
        #expect(boolExp.tokenLiteral() == String(val))
    }
    
    func testLetStatement(stmt: Statement, name: String) {
        #expect(stmt.tokenLiteral() == "let")
        let letStmt = stmt as! LetStatement
        #expect(letStmt.name.value == name)
        #expect(letStmt.name.tokenLiteral() == name)
    }
    
    @Test func testParseArray() {
        let input = "[1, 2 * 2, 3 + 3]"
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let stmt = prog.statements[0] as! ExpressionStatement
        let array = stmt.expression as! ArrayLiteral
        #expect(array.elements.count == 3)
        testIntergerLiteral(expr: array.elements[0], val: 1)
        testInfixExpression(expr: array.elements[1], left: 2, op: "*", right: 2)
        testInfixExpression(expr: array.elements[2], left: 3, op: "+", right: 3)
    }
    
    @Test func testParsingIndexExpression() {
        let input = "myArray[1 + 1]"
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let indexExpr = (prog.statements[0] as! ExpressionStatement).expression as! IndexExpression
        testIdentifier(expr: indexExpr.left, value: "myArray")
        testInfixExpression(expr: indexExpr.index, left: 1, op: "+", right: 1)
    }
    
    @Test func testParsingHashLiteral() {
        let input = """
{"one": 1, "two": 2, "three": 3}
"""
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let hash = (prog.statements[0] as! ExpressionStatement).expression as! HashLiteral
        #expect(hash.pairs.count == 3)
        let exp = ["one": 1, "two": 2, "three": 3]
        
        for pair in hash.pairs {
            let key = pair.key as! StringLiteral
            let expVal = exp[key.value]!
            testIntergerLiteral(expr: pair.value, val: expVal)
        }
    }
    
    @Test func testParsingHashLiteralInt() {
        let input = """
{1: 1, 2: 2, 3: 3}
"""
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let hash = (prog.statements[0] as! ExpressionStatement).expression as! HashLiteral
        #expect(hash.pairs.count == 3)
        let exp = [1: 1, 2: 2, 3: 3]
        
        for pair in hash.pairs {
            let key = pair.key as! IntegerLiteral
            let expVal = exp[key.value]!
            testIntergerLiteral(expr: pair.value, val: expVal)
        }
    }
    
    @Test func testParsingHashLiteralBool() {
        let input = """
{true: 1, false: 2}
"""
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let hash = (prog.statements[0] as! ExpressionStatement).expression as! HashLiteral
        #expect(hash.pairs.count == 2)
        let exp = [true: 1, false: 2]
        
        for pair in hash.pairs {
            let key = pair.key as! BooleanExpression
            let expVal = exp[key.value]!
            testIntergerLiteral(expr: pair.value, val: expVal)
        }
    }
    
    @Test func testParsingHashLiteralWithExpression() {
        let input = """
{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}
"""
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        let hash = (prog.statements[0] as! ExpressionStatement).expression as! HashLiteral
        #expect(hash.pairs.count == 3)
        let exp: [String: (Expression) -> ()] = [
            "one": { expr in
                testInfixExpression(expr: expr, left: 0, op: "+", right: 1)
            },
            "two": { expr in
                testInfixExpression(expr: expr, left: 10, op: "-", right: 8)
            },
            "three": { expr in
                testInfixExpression(expr: expr, left: 15, op: "/", right: 5)
            },
        ]
        
        for pair in hash.pairs {
            let literal = pair.key as! StringLiteral
            let testFunc = exp[literal.value]!
            testFunc(pair.value)
        }
    }
    
    @Test func testEmptyHashLiteral() {
        let input = "{}"
        
        let p = Parser(lexer: Lexer(input: input))
        let prog = p.parseProgram()
        checkParserErrors(p)
        
        #expect(prog.statements.count == 1)
        
        let hash = (prog.statements[0] as! ExpressionStatement).expression as! HashLiteral
        #expect(hash.pairs.isEmpty)
    }
}
