//
//  CompilerTests.swift
//  monkey
//
//  Created by Matthew Reed on 12/1/24.
//

import Testing
@testable import monkey

struct CompilerTestCase: @unchecked Sendable {
    let input: String
    let expConstants: [Any]
    let expInstructions: [Instructions]
}

struct CompilerTests {
    @Test(arguments: [
        CompilerTestCase(input: "1 + 2",
                         expConstants: [1, 2],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Constant, 1),
                            Code.make(op: .Add),
                            Code.make(op: .Pop),]),
        CompilerTestCase(input: "1; 2",
                         expConstants: [1, 2],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Pop),
                            Code.make(op: .Constant, 1),
                            Code.make(op: .Pop),]),
        CompilerTestCase(input: "1 - 2",
                         expConstants: [1, 2],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Constant, 1),
                            Code.make(op: .Sub),
                            Code.make(op: .Pop),]),
        CompilerTestCase(input: "1 * 2",
                         expConstants: [1, 2],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Constant, 1),
                            Code.make(op: .Mul),
                            Code.make(op: .Pop),]),
        CompilerTestCase(input: "2 / 1",
                         expConstants: [2, 1],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Constant, 1),
                            Code.make(op: .Div),
                            Code.make(op: .Pop),]),
        CompilerTestCase(input: "-1",
                         expConstants: [1],
                         expInstructions: [
                            Code.make(op: .Constant, 0),
                            Code.make(op: .Minus),
                            Code.make(op: .Pop)])
    ])
    func testIntegerArithmetic(tests: CompilerTestCase) {
        runCompilerTest(test: tests)
    }
    
    @Test(arguments: [
        test("true", [], [Code.make(op: .True), Code.make(op: .Pop)]),
        test("false", [], [Code.make(op: .False), Code.make(op: .Pop)]),
        test("1 > 2", [1, 2], [Code.make(op: .Constant, 0), Code.make(op: .Constant, 1), Code.make(op: .GreaterThan), Code.make(op: .Pop)]),
        test("1 < 2", [2, 1], [Code.make(op: .Constant, 0), Code.make(op: .Constant, 1), Code.make(op: .GreaterThan), Code.make(op: .Pop)]),
        test("1 == 2", [1, 2], [Code.make(op: .Constant, 0), Code.make(op: .Constant, 1), Code.make(op: .Equal), Code.make(op: .Pop)]),
        test("1 != 2", [1, 2], [Code.make(op: .Constant, 0), Code.make(op: .Constant, 1), Code.make(op: .NotEqual), Code.make(op: .Pop)]),
        test("true == false", [], [Code.make(op: .True), Code.make(op: .False), Code.make(op: .Equal), Code.make(op: .Pop)]),
        test("true != false", [], [Code.make(op: .True), Code.make(op: .False), Code.make(op: .NotEqual), Code.make(op: .Pop)]),
        test("!true", [], [Code.make(op: .True), Code.make(op: .Bang), Code.make(op: .Pop)])
    ])
    func testBooleanExpr(test: CompilerTestCase) {
        runCompilerTest(test: test)
    }
    
    func runCompilerTest(test: CompilerTestCase) {
        let prog = parse(input: test.input)
        let compiler = Compiler()
        
        #expect(compiler.compile(node: prog) == nil)
        let bytecode = compiler.bytecode
        testInstructions(exp: test.expInstructions, instructions: bytecode.instructions)
        testConstants(exp: test.expConstants, constants: bytecode.constants)
    }
    
    func parse(input: String) -> Program {
        return Parser(lexer: Lexer(input: input)).parseProgram()
    }
    
    func testInstructions(exp: [Instructions], instructions: Instructions) {
        let concatted = concatInstructions(exp)
        
        #expect(concatted.count == instructions.count)
        
        for (i, ins) in concatted.enumerated() {
            #expect(instructions[i] == ins)
        }
    }
    
    func concatInstructions(_ s: [Instructions]) -> Instructions {
        var out = Instructions()
        
        for ins in s {
            out.append(contentsOf: ins)
        }
        
        return out
    }
    
    func testConstants(exp: [Any], constants: [Object]) {
        #expect(exp.count == constants.count)
        for (i, constant) in constants.enumerated() {
            switch exp[i] {
            case let exp as Int :
                testIntegerObj(exp: exp, actual: constant)
            default: break
            }
        }
    }
    
    func testIntegerObj(exp: Int, actual: Object) {
        let intObj = actual as! Integer
        #expect(exp == intObj.value)
    }
    
    static func test(_ input: String, _ expConstants: [Any], _ expInstructions: [Instructions]) -> CompilerTestCase {
        CompilerTestCase(input: input, expConstants: expConstants, expInstructions: expInstructions)
    }
}
