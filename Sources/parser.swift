//
//  parser.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

class Parser {
    let lexer: Lexer
    var curToken: Token
    var peekToken: Token
    var errors = [String]()
  
    typealias PrefixParseFn = () -> Expression
    typealias InfixParseFn = (Expression) -> Expression
    
    var prefixParseFns: [TokenType: PrefixParseFn] = [:]
    var infixParseFns: [TokenType: InfixParseFn] = [:]
    
    enum Precedence: Int {
        case lowest = 0
        case equals = 1
        case lessGreater = 2
        case sum = 3
        case product = 4
        case prefix = 5
        case call = 6
    }
    
    init(lexer: Lexer) {
        self.lexer = lexer
        self.curToken = lexer.nextToken()
        self.peekToken = lexer.nextToken()
        
        self.prefixParseFns[.IDENT] = parseIdent
    }
    
    private func nextToken() {
        curToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    func parseProgram() -> Program {
        var stmts = [Statement]()
        while curToken.tokenType != .EOF {
            if let stmt = parseStmt() {
                stmts.append(stmt)
            }
            nextToken()
        }
        return Program(statements: stmts)
    }
    
    private func parseStmt() -> Statement? {
        switch curToken.tokenType {
        case .LET: return parseLetStmt()
        case .RETURN: return parseReturnStmt()
        default: return parseExpressionStmt()
        }
    }
    
    private func parseLetStmt() -> LetStatement? {
        let currentToken = curToken
        guard expectPeek(t: .IDENT) else {
            return nil
        }
        
        let name = Identifier(token: curToken, value: curToken.literal)
        
        guard expectPeek(t: .ASSIGN) else {
            return nil
        }
        
        while !curTokenIs(t: .SEMICOLON) {
            nextToken()
        }
        
        return LetStatement(token: currentToken, name: name, value: name)
    }
    
    private func parseReturnStmt() -> ReturnStatement {
        let currentToken = curToken
        nextToken()
        
        while !curTokenIs(t: .SEMICOLON) {
            nextToken()
        }
        return ReturnStatement(token: currentToken, value: Identifier(token: currentToken, value: ""))
    }
    
    private func parseExpressionStmt() -> ExpressionStatement {
        let currentToken = curToken
        let expression = parseExpression(.lowest)
        if peekTokenIs(t: .SEMICOLON) {
            nextToken()
        }
        return ExpressionStatement(token: currentToken, expression: expression)
    }
    
    private func parseExpression(_ precedence: Precedence) -> Expression? {
        guard let prefix = prefixParseFns[curToken.tokenType] else {
            return nil
        }
        let left = prefix()
        return left
    }
    
    private func parseIdent() -> Expression {
        return Identifier(token: curToken, value: curToken.literal)
    }
    
    private func curTokenIs(t: TokenType) -> Bool {
        return t == curToken.tokenType
    }
    
    private func peekTokenIs(t: TokenType) -> Bool {
        return t == peekToken.tokenType
    }
    
    private func expectPeek(t: TokenType) -> Bool {
        if peekTokenIs(t: t) {
            nextToken()
            return true
        } else {
            peekError(t: t)
            return false
        }
    }
    
    private func peekError(t: TokenType) {
        let msg = "expected next token to be \(t), got \(peekToken.tokenType)"
        print(msg)
        errors.append(msg)
    }
}
