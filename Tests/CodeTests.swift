//
//  CodeTests.swift
//  monkey
//
//  Created by Matthew Reed on 12/1/24.
//

import Testing
@testable import monkey

struct CodeTests {
    @Test(arguments: [
        (OpCode.Constant, [65534], [OpCode.Constant.rawValue, 255, 254]),
        (OpCode.Add, [], [OpCode.Add.rawValue])
    ])
    func testMake(input: (op: OpCode, operands: [Int], exp: [UInt8])) {
        let op = input.op
        let operands = input.operands
        let exp = input.exp
        
        let instruction = Code.make(op: op, operands: operands)
        for (i, b) in exp.enumerated() {
            #expect(instruction[i] == b)
        }
    }
    
    @Test func testInstructionString() {
        let instructions = [
            Code.make(op: .Add),
            Code.make(op: .Constant, operands: 2),
            Code.make(op: .Constant, operands: 65535)
        ]
        
        let exp = """
0000 OpAdd
0001 OpConstant 2
0004 OpConstant 65535

"""
        var concatted = Instructions()
        for ins in instructions {
            concatted.append(contentsOf: ins)
        }
        #expect(concatted.string() == exp)
    }
    
    @Test(arguments: [
        (OpCode.Constant, [65535], 2)
    ])
    func testReadOperands(tests: (OpCode, [Int], Int)) {
        let op = tests.0
        let operands = tests.1
        let bytesRead = tests.2
        
        let instruction = Code.make(op: op, operands: operands)
        let def = Code.lookup(op: op)!
        
        let (operandsRead, n) = Code.readOperands(def: def, ins: Array(instruction[1...]))
        #expect(n == bytesRead)
        
        for (i, want) in operands.enumerated() {
            #expect(operandsRead[i] == want)
        }
    }
}
