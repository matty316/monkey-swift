//
//  vm.swift
//  monkey
//
//  Created by Matthew Reed on 12/3/24.
//

let stackSize = 2048

enum VMError: Error {
    case General, StackOverflow
}

class VM {
    var constants: [Object]
    var instructions: Instructions
    
    var stack: [Object]
    var sp: Int
    
    var stackTop: Object? {
        if sp == 0 {
            return nil
        }
        
        return stack[sp-1]
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
            let op = OpCode(rawValue: instructions[ip])
            
            switch op {
            case .Constant:
                let constIndex = Code.readUInt16(ins: Array(instructions[(ip+1)...]))
                ip += 2
                let err = push(constants[Int(constIndex)])
                if let err = err {
                    return err
                }
            case .Add:
                guard let right = pop() as? Integer, let left = pop() as? Integer else {
                    return VMError.General
                }
                let leftVal = left.value
                let rightVal = right.value
                let res = leftVal + rightVal
                push(Integer(value: res))
            default: break
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
    
    func pop() -> Object {
        let o = stack[sp-1]
        sp -= 1
        return o
    }
}
