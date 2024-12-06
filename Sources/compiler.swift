//
//  compiler.swift
//  monkey
//
//  Created by Matthew Reed on 12/1/24.
//

enum CompilerError: Error {
    case General, UnknownOperator
}

class Compiler {
    var instructions = Instructions()
    var constants = [Object]()
    
    func compile(node: Node?) -> CompilerError? {
        switch node {
        case let prog as Program:
            for stmt in prog.statements {
                let err = compile(node: stmt)
                if err != nil {
                    return err
                }
            }
        case let exprStmt as ExpressionStatement:
            let err = compile(node: exprStmt.expression)
            if err != nil {
                return err
            }
            emit(op: .Pop)
        case let infixExpr as InfixExpression:
            if infixExpr.op == "<" {
                var err = compile(node: infixExpr.right)
                if err != nil {
                    return err
                }
                
                err = compile(node: infixExpr.left)
                if err != nil {
                    return err
                }
                emit(op: .GreaterThan)
                return nil
            }
            
            var err = compile(node: infixExpr.left)
            if err != nil {
                return err
            }
            
            err = compile(node: infixExpr.right)
            if err != nil {
                return err
            }
            
            switch infixExpr.op {
            case "+":
                emit(op: .Add)
            case "-":
                emit(op: .Sub)
            case "*":
                emit(op: .Mul)
            case "/":
                emit(op: .Div)
            case ">":
                emit(op: .GreaterThan)
            case "==":
                emit(op: .Equal)
            case "!=":
                emit(op: .NotEqual)
            default:
                return CompilerError.UnknownOperator
            }
        case let intLit as IntegerLiteral:
            let integer = Integer(value: intLit.value)
            emit(op: .Constant, operands: addConstant(obj: integer))
        case let boolean as BooleanExpression:
            emit(op: boolean.value ? .True : .False)
        case let prefixExpr as PrefixExpression:
            let err = compile(node: prefixExpr.right)
            if let err = err {
                return err
            }
            switch prefixExpr.op {
            case "!":
                emit(op: .Bang)
            case "-":
                emit(op: .Minus)
            default:
                return CompilerError.UnknownOperator
            }
        default: return nil
        }
        return nil
    }
    
    var bytecode: Bytecode {
        Bytecode(instructions: instructions, constants: constants)
    }
    
    func addConstant(obj: Object) -> Int {
        constants.append(obj)
        return constants.count - 1
    }
    
    @discardableResult
    func emit(op: OpCode, operands: Int...) -> Int {
        let ins = Code.make(op: op, operands)
        let pos = addInstruction(ins)
        return pos
    }
    
    func addInstruction(_ ins: [UInt8]) -> Int {
        let posNewInstruction = instructions.count
        instructions.append(contentsOf: ins)
        return posNewInstruction
    }
}

struct Bytecode {
    let instructions: Instructions
    let constants: [Object]
}
