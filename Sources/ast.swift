//
//  ast.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

protocol Node {
    var token: Token { get }
    func tokenLiteral() -> String
    func string() -> String
}

extension Node {
    func tokenLiteral() -> String { token.literal }
}

protocol Statement: Node {
    func statementNode()
}

extension Statement {
    func statementNode() {}
}

protocol Expression: Node {
    func expressionNode()
}

extension Expression {
    func expressionNode() {}
}

struct Program {
    
    let statements: [Statement]
    
    func tokenLiteral() -> String {
        guard !statements.isEmpty else { return "" }
        
        return statements[0].tokenLiteral()
    }
    
    func string() -> String {
        statements
            .map { $0.string() }
            .joined()
    }
}

struct LetStatement: Statement {
    let token: Token
    let name: Identifier
    let value: Expression
    func string() -> String {
        "\(tokenLiteral()) \(name.string()) = \(value.string());"
    }
}

struct Identifier: Expression {
    let token: Token
    let value: String
    func string() -> String {
        value
    }
}

struct ReturnStatement: Statement {
    let token: Token
    let value: Expression
    func string() -> String {
        "\(tokenLiteral()) \(value.string());"
    }
}

struct ExpressionStatement: Statement {
    let token: Token
    let expression: Expression?
    func string() -> String {
        expression?.string() ?? ""
    }
}

struct IntegerLiteral: Expression {
    let token: Token
    let value: Int
    
    
    func string() -> String {
        token.literal
    }
}

struct PrefixExpression: Expression {
    let token: Token
    let op: String
    let right: Expression
    func string() -> String {
        "(\(op)\(right.string()))"
    }
}

struct InfixExpression: Expression {
    let token: Token
    let left: Expression
    let op: String
    let right: Expression
    func string() -> String {
        "(\(left.string()) \(op) \(right.string()))"
    }
}

struct BooleanExpression: Expression {
    let token: Token
    let value: Bool
    func string() -> String {
        token.literal
    }
}

struct IfExpression: Expression {
    let token: Token
    let condition: Expression
    let consequence: BlockStatement
    let alternative: BlockStatement?
    func string() -> String {
        var string = "if \(condition.string()) \(consequence.string())"
        if let alternative = alternative {
            string.append("else \(alternative.string())")
        }
        return string
    }
}

struct BlockStatement: Statement {
    let token: Token
    let statements: [Statement]
    
    func string() -> String {
        statements.map { $0.string() }.joined()
    }
}

struct FunctionLiteral: Expression {
    let token: Token
    let params: [Identifier]
    let body: BlockStatement
    
    func string() -> String {
        var string = ""
        
        let paramsString = params.map { $0.string() }.joined(separator: ", ")
        string.append(tokenLiteral())
        string.append("(")
        string.append(paramsString)
        string.append(") ")
        string.append(body.string())
        
        return string
    }
}

struct CallExpression: Expression {
    let token: Token
    let function: Expression
    let arguments: [Expression]
    
    func string() -> String {
        let args = arguments.map { $0.string() }.joined(separator: ", ")
        return "\(function.string())(\(args))"
    }
}
