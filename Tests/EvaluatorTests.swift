//
//  EvaluatorTests.swift
//  monkey
//
//  Created by Matthew Reed on 11/28/24.
//

import Testing
@testable import monkey

struct EvaluatorTests {
    func testEval(input: String)-> Object? {
        let p = Parser(lexer: Lexer(input: input))
        let program = p.parseProgram()
        let env = Env()
        return Evaluator.eval(node: program, env: env)
    }
    
    func testIntegerObject(obj: Object?, exp: Int) {
        let res = obj as! Integer
        #expect(res.value == exp)
    }
    
    func testBooleanObject(obj: Object?, exp: Bool) {
        let res = obj as! Boolean
        #expect(res.value == exp)
    }
    
    func testNullObject(obj: Object?) {
        #expect(obj?.objectType == .Null)
    }
    
    @Test(arguments: zip(["5",
                          "10",
                          "-5",
                          "-10",
                          "5 + 5 + 5 + 5 - 10",
                          "2 * 2 * 2 * 2 * 2",
                          "-50 + 100 + -50",
                          "5 * 2 + 10",
                          "5 + 2 * 10",
                          "20 + 2 * -10",
                          "50 / 2 * 2 + 10",
                          "2 * (5  + 10)",
                          "3 * 3 * 3 + 10",
                          "3 * (3 * 3) + 10",
                          "(5 + 10 * 2 + 15 / 3) * 2 + -10"],
                         [5, 10, -5, -10, 10, 32, 0, 20, 25, 0, 60, 30, 37, 37, 50]))
    func testEvalIntegerExpression(input: String, exp: Int) {
        let res = testEval(input: input)
        testIntegerObject(obj: res, exp: exp)
    }
    
    @Test(arguments: zip(["true",
                          "false",
                          "1 < 2",
                          "1 > 2",
                          "1 < 1",
                          "1 > 1",
                          "1 == 1",
                          "1 != 1",
                          "1 == 2",
                          "1 != 2",
                          "true == true",
                          "false == false",
                          "true == false",
                          "true != false",
                          "false != true",
                          "(1 < 2) == true",
                          "(1 < 2) == false",
                          "(1 > 2) == true",
                          "(1 > 2) == false"],
                         [true,
                          false,
                          true,
                          false,
                          false,
                          false,
                          true,
                          false,
                          false,
                          true,
                          true,
                          true,
                          false,
                          true,
                          true,
                          true,
                          false,
                          false,
                          true]))
    func testEvalBooleanExpression(input: String, exp: Bool) {
        let res = testEval(input: input)
        testBooleanObject(obj: res, exp: exp)
    }
    
    @Test(arguments: zip(["!true", "!false", "!5", "!!true", "!!false", "!!5"],
                         [false, true, false, true, false, true]))
    func testBang(input: String, exp: Bool) {
        let res = testEval(input: input)
        testBooleanObject(obj: res, exp: exp)
    }
    
    @Test(arguments: zip([
        "if (true) { 10 }",
        "if (false) { 10 }",
        "if (1) { 10 }",
        "if (1 < 2) { 10 }",
        "if (1 > 2) { 10 }",
        "if (1 > 2) { 10 } else { 20 }",
        "if (1 < 2) { 10 } else { 20 }"
    ],[
        10,
        nil,
        10,
        10,
        nil,
        20,
        10
    ]))
    func testIfElseExpr(input: String, exp: Int?) {
        let eval = testEval(input: input)
        if let exp = exp {
            testIntegerObject(obj: eval, exp: exp)
        } else {
            testNullObject(obj: eval)
        }
    }
    
    @Test(arguments: zip([
        "return 10;",
        "return 10; 9;",
        "return 2 * 5; 9;",
        "9; return 2 * 5; 9;",
        """
if (10 > 1) {
    if (10 > 1) {
        return 10;
    }
    return 1;
}
"""
    ], [10, 10, 10, 10, 10]))
    func testReturnStatement(input: String, exp: Int) {
        let eval = testEval(input: input)
        testIntegerObject(obj: eval, exp: exp)
    }
    
    @Test(arguments: zip([
        "5 + true",
        "5 + true; 5;",
        "-true",
        "true + false",
        "5; true + false; 5",
        "if (10 > 1) { true + false }",
        """
if (10 > 1) {
    if (10 > 1) {
        return true + false;
    }
    return 1
}
""",
        "foobar",
        """
"Hello" - "World"        
""",
    ], [
        "type mismatch: Integer + Boolean",
        "type mismatch: Integer + Boolean",
        "unknown operator: -Boolean",
        "unknown operator: Boolean + Boolean",
        "unknown operator: Boolean + Boolean",
        "unknown operator: Boolean + Boolean",
        "unknown operator: Boolean + Boolean",
        "identifier not found: foobar",
        "unknown operator: String - String"
    ]))
    func testErrorHandling(input: String, exp: String) async throws {
        let eval = testEval(input: input)
        let errObj = eval as! ErrorObject
        #expect(errObj.msg == exp)
    }
    
    @Test(arguments: zip(["let a = 5;",
                          "let a = 5 * 5; a;",
                          "let a = 5; let b = a; b;",
                          "let a = 5; let b = a; let c = a + b + 5; c;"],
                         [5, 25, 5, 15]))
    func testLetStatements(input: String, exp: Int) {
        testIntegerObject(obj: testEval(input: input), exp: exp)
    }
    
    @Test(arguments: zip(["fn(x) { x + 2; }"], ["(x + 2)"]))
    func testFunction(input: String, exp: String) {
        let eval = testEval(input: input)
        let fn = eval as! Function
        #expect(fn.params.count == 1)
        #expect(fn.params[0].string() == "x")
        #expect(fn.body.string() == exp)
    }
    
    @Test(arguments: zip([
        "let identity = fn(x) { x; }; identity(5);",
        "let identity = fn(x) { return x; }; identity(5);",
        "let double = fn(x) { x * 2; }; double(5);",
        "let add = fn(x, y) { x + y; }; add(5, 5);",
        "let add = fn(x, y) { x + y; }; add(add(5, 5), add(5, 5));",
        "fn (x) { x; }(5)"], [5, 5, 10, 10, 20, 5]))
    func testFnApplication(input: String, exp: Int) {
        testIntegerObject(obj: testEval(input: input), exp: exp)
    }
    
    @Test func testClosures() {
        let input = """
let newAdder = fn(x) {
    fn(y) { x + y };
};

let addTwo = newAdder(2);
addTwo(2);
"""
        
        testIntegerObject(obj: testEval(input: input), exp: 4)
    }
    
    @Test func testStringLiteral() {
        let input = "\"Hello World!\""
        let str = testEval(input: input) as! StringObject
        #expect(str.value == "Hello World!")
    }
    
    @Test func testStringConcat() {
        let input = """
"Hello" + " " + "World!"
"""
        let str = testEval(input: input) as! StringObject
        #expect(str.value == "Hello World!")
    }
}
