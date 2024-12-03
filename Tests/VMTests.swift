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
    
    func runVmTests(test: VmTestCase) throws {
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
        
        let stackElem = vm.stackTop!
        testExpObj(exp: test.exp, actual: stackElem)
    }
    
    func testExpObj(exp: Any, actual: Object) {
        switch exp {
        case let exp as Int:
            testIntegerObj(exp: exp, actual: actual)
        default:
            break
        }
    }
    
    @Test(arguments: [
        VmTestCase(input: "1", exp: 1),
        VmTestCase(input: "2", exp: 2),
        VmTestCase(input: "1 + 2", exp: 3)
    ])
    func testIntArithmetic(test: VmTestCase) throws {
        try runVmTests(test: test)
    }
}

