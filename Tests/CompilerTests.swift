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
                         expInstructions: [Code.make(op: .Constant, operands: 0),
                                           Code.make(op: .Constant, operands: 1),
                                           Code.make(op: .Add)])])
    func testIntegerArithmetic(tests: CompilerTestCase) {
        runCompilerTests(tests: tests)
    }
    
    
    
    func runCompilerTests(tests: CompilerTestCase) {
        let prog = parse(input: tests.input)
        let compiler = Compiler()
        
        #expect(compiler.compile(node: prog) == nil)
        let bytecode = compiler.bytecode
        testInstructions(exp: tests.expInstructions, instructions: bytecode.instructions)
        testConstants(exp: tests.expConstants, constants: bytecode.constants)
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
}
