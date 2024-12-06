//
//  VMTests.swift
//  monkey
//
//  Created by Matthew Reed on 12/2/24.
//

import Testing
@testable import monkey

struct VmTests {
    struct VmTestCase: @unchecked Sendable {
        let input: String
        let exp: Any
    }
    
    func parse(input: String) -> Program {
        return Parser(lexer: Lexer(input: input)).parseProgram()
    }
    
    func testIntegerObj(exp: Int, actual: Object) {
        let intObj = actual as! Integer
        #expect(exp == intObj.value)
    }
    
    func runVmTest(test: VmTestCase) throws {
        let program = parse(input: test.input)
        let comp = Compiler()
        
        let compErr = comp.compile(node: program)
        if let err = compErr {
            throw err
        }
        
        let vm = VM(bytecode: comp.bytecode)
        
        let vmErr = vm.run()
        if let err = vmErr {
            throw err
        }
        
        let stackElem = vm.lastPoppedStackElem
        testExpObj(exp: test.exp, actual: stackElem)
    }
    
    func testExpObj(exp: Any, actual: Object) {
        switch exp {
        case let exp as Int:
            testIntegerObj(exp: exp, actual: actual)
        case let exp as Bool:
            testBoolObj(exp: exp, actual: actual)
        default:
            break
        }
    }
    
    func testBoolObj(exp: Bool, actual: Object) {
        let boolean = actual as! Boolean
        #expect(exp == boolean.value)
    }
    
    @Test(arguments: [
        test("1", 1),
        test("2", 2),
        test("1 + 2", 3),
        test("1 - 2", -1),
        test("1 * 2", 2),
        test("4 / 2", 2),
        test("50 / 2 * 2 + 10 -5", 55),
        test("5 + 5 + 5 + 5 - 10", 10),
        test("2 * 2 * 2 * 2 * 2", 32),
        test("5 * 2 + 10", 20),
        test("5 + 2 * 10", 25),
        test("5 * (2 + 10)", 60),
        test("-5", -5),
        test("-10", -10),
        test("-50 + 100 + -50", 0),
        test("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50)
    ])
    func testIntArithmetic(test: VmTestCase) throws {
        try runVmTest(test: test)
    }
    
    @Test(arguments: [
        test("true", true),
        test("false", false),
        test("1 < 2", true),
        test("1 > 2", false),
        test("1 < 1", false),
        test("1 > 1", false),
        test("1 == 1", true),
        test("1 != 1", false),
        test("1 == 2", false),
        test("1 != 2", true),
        test("true == true", true),
        test("false == false", true),
        test("true == false", false),
        test("true != false", true),
        test("false != true", true),
        test("(1 < 2) == true", true),
        test("(1 < 2) == false", false),
        test("(1 > 2) == true", false),
        test("(1 > 2) == false", true),
        test("!true", false),
        test("!false", true),
        test("!5", false),
        test("!!true", true),
        test("!!false", false),
        test("!!5", true)
    ])
    func testBooleanExpr(test: VmTestCase) throws {
        try runVmTest(test: test)
    }
    
    static func test(_ input: String, _ exp: Any) -> VmTestCase {
        VmTestCase(input: input, exp: exp)
    }
}

