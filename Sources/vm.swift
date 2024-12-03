//
//  vm.swift
//  monkey
//
//  Created by Matthew Reed on 12/3/24.
//

let stackSize = 2048

enum VMError: Error {
    case General, StackOverflow, UnsupportedBinaryOp, UnimplementedOp, UnknownIntOperator
}

class VM {
    var constants: [Object]
    var instructions: Instructions
    
    var stack: [Object]
    var sp: Int
    
    var lastPoppedStackElem: Object {
        stack[sp]
    }
    
    init(bytecode: Bytecode) {
        self.instructions = bytecode.instructions
        self.constants = bytecode.constants
        self.stack = Array<Object>(repeating: NULL, count: stackSize)
        self.sp = 0
    }
    
    func run() -> VMError? {
        var ip = 0
        while ip < instructions.count {
            guard let op = OpCode(rawValue: instructions[ip]) else {
                return VMError.UnimplementedOp
            }
            
            switch op {
            case .Constant:
                let constIndex = Code.readUInt16(ins: Array(instructions[(ip+1)...]))
                ip += 2
                let err = push(constants[Int(constIndex)])
                if let err = err {
                    return err
                }
            case .Add, .Sub, .Mul, .Div:
                let err = executeBinary(op: op)
                if let err = err {
                    return err
                }
            case .Pop:
                pop()
            case .True:
                let err = push(TRUE)
                if let err = err {
                    return err
                }
            case .False:
                let err = push(FALSE)
                if let err = err {
                    return err
                }
            }
            ip += 1
        }
        
        return nil
    }
    
    @discardableResult
    func push(_ o: Object) -> VMError? {
        if sp >= stackSize {
            return VMError.StackOverflow
        }
        
        stack[sp] = o
        sp += 1
        
        return nil
    }
    
    func executeBinary(op: OpCode) -> VMError? {
        if let right = pop() as? Integer, let left = pop() as? Integer {
            let leftVal = left.value
            let rightVal = right.value
            return executeBinaryIntegerOp(op: op, leftVal: leftVal, rightVal: rightVal)
        }
        return VMError.UnsupportedBinaryOp
    }
    
    func executeBinaryIntegerOp(op: OpCode, leftVal: Int, rightVal: Int) -> VMError? {
        switch op {
        case .Add:
            return push(Integer(value: leftVal + rightVal))
        case .Sub:
            return push(Integer(value: leftVal - rightVal))
        case .Mul:
            return push(Integer(value: leftVal * rightVal))
        case .Div:
            return push(Integer(value: leftVal / rightVal))
        default:
            return VMError.UnknownIntOperator
        }
    }
    
    @discardableResult
    func pop() -> Object {
        let o = stack[sp-1]
        sp -= 1
        return o
    }
}
