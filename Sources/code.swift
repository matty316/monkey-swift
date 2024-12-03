//
//  code.swift
//  monkey
//
//  Created by Matthew Reed on 12/1/24.
//

import Foundation

typealias Instructions = [UInt8]

enum OpCode: UInt8 {
    case Constant, Add, Pop, Sub, Mul, Div
}

struct Definition {
    let name: String
    let opWidths: [Int]
    
    init(name: String, opWidths: [Int] = []) {
        self.name = name
        self.opWidths = opWidths
    }
}

extension Instructions {
    func string() -> String {
        var out = ""
        var i = 0
        while i < count {
            guard let opCode = OpCode(rawValue: self[i]), let def = Code.lookup(op: opCode) else {
                out.append("ERROR: definition not found for \(self[i])")
                continue
            }
            
            let (operands, read) = Code.readOperands(def: def, ins: Array(self[(i+1)...]))
            
            out.append(String(format: "%04d %@\n", i, fmtIns(def: def, operands: operands)))
                    
            i += 1 + read
        }
        return out
    }
    
    func fmtIns(def: Definition, operands: [Int]) -> String {
        let operandCount = def.opWidths.count
        
        if operands.count != operandCount {
            return String(format: "ERROR: operand len %d does not match defined %d\n", operands.count, operandCount)
        }
        
        switch operandCount {
        case 0:
            return def.name
        case 1:
            return String(format: "%@ %d", def.name, operands[0])
        default: break
        }
        
        return String(format: "ERROR: unhandled operandCount for %@\n", def.name)
    }
}

struct Code {
    static let definitions: [OpCode: Definition] = [
        .Constant: Definition(name: "OpConstant", opWidths: [2]),
        .Add: Definition(name: "OpAdd"),
        .Pop: Definition(name: "OpPop"),
        .Div: Definition(name: "OpDiv"),
        .Sub: Definition(name: "OpSub"),
        .Mul: Definition(name: "OpMul"),
    ]
    
    static func make(op: OpCode, operands: Int...) -> Instructions {
        return make(op: op, operands: operands)
    }
    
    static func make(op: OpCode, operands: [Int]) -> Instructions {
        guard let def = definitions[op] else {
            return Instructions()
        }
        
        var instructionLen = 1
        for w in def.opWidths {
            instructionLen += w
        }
        
        var instruction = Array<UInt8>(repeating: 0, count: instructionLen)
        instruction[0] = op.rawValue
        
        var offset = 1
        for (i, o) in operands.enumerated() {
            let width = def.opWidths[i]
            if width == 2 {
                let u16 = UInt16(o)
                instruction[offset] = UInt8(u16 >> 8)
                instruction[offset + 1] = UInt8(u16 & 0xff)
            }
            offset += width
        }
        return instruction
    }
    
    static func lookup(op: OpCode) -> Definition? {
        guard let def = definitions[op] else {
            return nil
        }
        
        return def
    }
    
    static func readOperands(def: Definition, ins: Instructions) -> ([Int], Int) {
        var operands = Array(repeating: 0, count: def.opWidths.count)
        var offset = 0
        
        for (i, width) in def.opWidths.enumerated() {
            if width == 2 {
                operands[i] = Int(readUInt16(ins: Array(ins[offset...])))
            }
            
            offset += width
        }
        
        return (operands, offset)
    }
    
    static func readUInt16(ins: Instructions) -> UInt16 {
        let first = UInt16(ins[0])
        let second = UInt16(ins[1])
        return first << 8 | second
    }
}

