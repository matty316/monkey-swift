//
//  evaluator.swift
//  monkey
//
//  Created by Matthew Reed on 11/28/24.
//

struct Evaluator {
    static let TRUE = Boolean(value: true)
    static let FALSE = Boolean(value: false)
    static let NULL = Null()
    
    static func eval(node: Node?, env: Env) -> Object {
        switch node {
        case let program as Program:
            return evalProgram(program, env: env)
        case let exprStmt as ExpressionStatement:
            return eval(node: exprStmt.expression, env: env)
        case let integerLit as IntegerLiteral:
            return Integer(value: integerLit.value)
        case let boolLit as BooleanExpression:
            return nativeBoolToObj(input: boolLit.value)
        case let prefixExp as PrefixExpression:
            let right = eval(node: prefixExp.right, env: env)
            if isError(right) {
                return right
            }
            return evalPrefix(prefixExp.op, right)
        case let infixExp as InfixExpression:
            let left = eval(node: infixExp.left, env: env)
            if isError(left) {
                return left
            }
            let right = eval(node: infixExp.right, env: env)
            if isError(right) {
                return right
            }
            return evalInfix(infixExp.op, left, right)
        case let blockStmt as BlockStatement:
            return evalBlock(blockStmt, env: env)
        case let ifExpr as IfExpression:
            return evalIfExpr(ifExpr, env: env)
        case let returnStmt as ReturnStatement:
            let val = eval(node: returnStmt.value, env: env)
            if isError(val) {
                return val
            }
            return ReturnValue(value: val)
        case let letStmt as LetStatement:
            let val = eval(node: letStmt.value, env: env)
            if isError(val) {
                return val
            }
            return env.set(name: letStmt.name.value, val: val)
        case let ident as Identifier:
            return evalIdent(ident, env)
        case let fn as FunctionLiteral:
            let params = fn.params
            let body = fn.body
            return Function(params: params, body: body, env: env)
        case let call as CallExpression:
            let fn = eval(node: call.function, env: env)
            if isError(fn) {
                return fn
            }
            let args = evalExprs(call.arguments, env)
            if args.count == 1 && isError(args[0]) {
                return args[0]
            }
            
            return applyFn(fn, args)
        case let str as StringLiteral:
            return StringObject(value: str.value)
        default: return NULL
        }
    }
    
    static func evalProgram(_ program: Program, env: Env) -> Object {
        var result: Object = NULL
        for stmt in program.statements {
            result = eval(node: stmt, env: env)
            
            if let result = result as? ReturnValue {
                return result.value
            } else if let result = result as? ErrorObject {
                return result
            }
        }
        return result
    }
    
    static func evalBlock(_ block: BlockStatement, env: Env) -> Object {
        var result: Object = NULL
        for stmt in block.statements {
            result = eval(node: stmt, env: env)
            
            if result.objectType == .ReturnValue || result.objectType == .Error {
                return result
            }
        }
        return result
    }
    
    static func evalPrefix(_ op: String, _ right: Object) -> Object {
        switch op {
        case "-": return evalMinus(right)
        case "!": return evalBang(right)
        default: return newError(format: "unknown operator: %@ %@", op, right.objectType.rawValue)
        }
    }
    
    static func evalMinus(_ right: Object) -> Object {
        guard let right = right as? Integer else {
            return newError(format: "unknown operator: -%@", right.objectType.rawValue)
        }
        
        let val = right.value
        return Integer(value: -val)
    }
    
    static func evalBang(_ right: Object) -> Object {
        switch right {
        case let boolean as Boolean: return boolean.value ? FALSE : TRUE
        case is Null: return TRUE
        default: return FALSE
        }
    }
    
    static func evalInfix(_ op: String, _ left: Object, _ right: Object) -> Object {
        if let left = left as? Integer, let right = right as? Integer {
            return evalIntInfix(op, left, right)
        } else if let left = left as? Boolean, let right = right as? Boolean {
            if op == "==" {
                return nativeBoolToObj(input: left.value == right.value)
            } else if op == "!=" {
                return nativeBoolToObj(input: left.value != right.value)
            }
        } else if left.objectType != right.objectType {
            return newError(format: "type mismatch: %@ %@ %@", left.objectType.rawValue, op, right.objectType.rawValue)
        } else if left.objectType == .String && right.objectType == .String {
            return evalStringInfix(op, left, right)
        }
        return newError(format: "unknown operator: %@ %@ %@", left.objectType.rawValue, op, right.objectType.rawValue)
    }
    
    static func evalIntInfix(_ op: String, _ left: Integer, _ right: Integer) -> Object {
        switch op {
        case "+": return Integer(value: left.value + right.value)
        case "-": return Integer(value: left.value - right.value)
        case "*": return Integer(value: left.value * right.value)
        case "/": return Integer(value: left.value / right.value)
        case "<": return Boolean(value: left.value < right.value)
        case ">": return Boolean(value: left.value > right.value)
        case "==": return Boolean(value: left.value == right.value)
        case "!=": return Boolean(value: left.value != right.value)
        default: return newError(format: "unknown operator: %@ %@ %@", left.objectType.rawValue, op, right.objectType.rawValue)
        }
    }
    
    static func nativeBoolToObj(input: Bool) -> Boolean {
        input ? TRUE : FALSE
    }
    
    static func evalIfExpr(_ expr: IfExpression, env: Env) -> Object {
        let condition = eval(node: expr.condition, env: env)
        if isError(condition) {
            return condition
        }
        if isTruthy(condition) {
            return eval(node: expr.consequence, env: env)
        } else if expr.alternative != nil {
            return eval(node: expr.alternative, env: env)
        } else {
            return NULL
        }
    }
    
    static func isTruthy(_ obj: Object) -> Bool {
        switch obj {
        case let boolean as Boolean: return boolean.value
        case is Null: return false
        default: return true
        }
    }
    
    static func newError(format: String, _ a: any CVarArg...) -> ErrorObject {
        return ErrorObject(msg: String(format: format, a))
    }
    
    static func isError(_ obj: Object) -> Bool {
        obj.objectType == .Error
    }
    
    static func evalIdent(_ ident: Identifier, _ env: Env) -> Object {
        guard let val = env.get(name: ident.value) else {
            return newError(format: "identifier not found: %@", ident.value)
        }
        
        return val
    }
    
    static func evalExprs(_ args: [Expression], _ env: Env) -> [Object] {
        var result = [Object]()
        
        for arg in args {
            let eval = eval(node: arg, env: env)
            if isError(eval) {
                return [eval]
            }
            result.append(eval)
        }
        
        return result
    }
    
    static func applyFn(_ fn: Object, _ args: [Object]) -> Object {
        guard let fn = fn as? Function else {
            return newError(format: "not a function: %@", fn.objectType.rawValue)
        }
        
        let extendedEnv = extendFnEnv(fn, args)
        let eval = eval(node: fn.body, env: extendedEnv)
        return unwrapReturnValue(eval)
    }
    
    static func extendFnEnv(_ fn: Function, _ args: [Object]) -> Env {
        let env = Env(outer: fn.env)
        for (i, param) in fn.params.enumerated() {
            env.set(name: param.value, val: args[i])
        }
        
        return env
    }
    
    static func unwrapReturnValue(_ obj: Object) -> Object {
        if let returnVal = obj as? ReturnValue {
            return returnVal.value
        }
        
        return obj
    }
    
    static func evalStringInfix(_ op: String, _ left: Object, _ right: Object) -> Object {
        guard let left = left as? StringObject, let right = right as? StringObject, op == "+" else {
            return newError(format: "unknown operator: %@ %@ %@", left.objectType.rawValue, op, right.objectType.rawValue)
        }
        
        return StringObject(value: left.value + right.value)			
    }
}
