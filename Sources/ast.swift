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
    func statementNode()
}

protocol Expression: Node {
    func expressionNode()
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
    
    func statementNode() {}
    
    func tokenLiteral() -> String {
        token.literal
    }
    
    func string() -> String {
        "\(tokenLiteral()) \(name.string()) = \(value.string());"
    }
}

struct Identifier: Expression {
    let token: Token
    let value: String
    
    func expressionNode() {}
    
    func tokenLiteral() -> String {
        token.literal
    }
    
    func string() -> String {
        value
    }
}

struct ReturnStatement: Statement {
    let token: Token
    let value: Expression
    
    func statementNode() {}
    func tokenLiteral() -> String {
        token.literal
    }
    func string() -> String {
        "\(tokenLiteral()) \(value.string());"
    }
}

struct ExpressionStatement: Statement {
    let token: Token
    let expression: Expression?
    
    func statementNode() {}
    func tokenLiteral() -> String {
        token.literal
    }
    func string() -> String {
        expression?.string() ?? ""
    }
}

