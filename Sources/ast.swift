//
//  ast.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

protocol Node {
    func tokenLiteral() -> String
    func string() -> String
}

protocol Statement: Node {
    var token: Token { get }
    func statementNode()
}

extension Statement {
    func tokenLiteral() -> String { token.literal }
    func statementNode() {}
}

protocol Expression: Node {
    var token: Token { get }
    func expressionNode()
}

extension Expression {
    func tokenLiteral() -> String { token.literal }
    func expressionNode() {}
}

struct Program: Node {
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

struct StringLiteral: Expression {
    let token: Token
    let value: String

    func string() -> String {
        token.literal
    }
}

struct ArrayLiteral: Expression {
    let token: Token
    let elements: [Expression]
    func string() -> String {
        "[\(elements.map {$0.string()}.joined(separator: ", "))]"
    }
}

struct IndexExpression: Expression {
    let token: Token
    let left: Expression
    let index: Expression
    func string() -> String {
        "(\(left.string())[\(index.string())])"
    }
}

struct HashLiteral: Expression {
    let token: Token
    //cant make this a dictionary because Expression is not hashable. will make it a dict in eval stage
    let pairs: [(key: Expression, value: Expression)]
    func string() -> String {
        let pairsString = pairs.map { "\($0.key.string()): \($0.value.string())" }.joined(separator: ", ")
        return "{\(pairsString)}"
    }
}
