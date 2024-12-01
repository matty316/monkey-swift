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
    
    typealias PrefixParseFn = () -> Expression?
    typealias InfixParseFn = (Expression?) -> Expression?
    
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
        case index = 7
    }
    
    let precedences: [TokenType: Precedence] = [
        .EQ: .equals,
        .NOT_EQ: .equals,
        .LT: .lessGreater,
        .GT: .lessGreater,
        .PLUS: .sum,
        .MINUS: .sum,
        .SLASH: .product,
        .ASTERISK: .product,
        .LPAREN: .call,
        .LBRACKET: .index
    ]
    
    init(lexer: Lexer) {
        self.lexer = lexer
        self.curToken = lexer.nextToken()
        self.peekToken = lexer.nextToken()
        
        self.prefixParseFns[.IDENT] = parseIdent
        self.prefixParseFns[.INT] = parseIntegerLiteral
        self.prefixParseFns[.BANG] = parsePrefixExpression
        self.prefixParseFns[.MINUS] = parsePrefixExpression
        self.prefixParseFns[.TRUE] = parseBoolean
        self.prefixParseFns[.FALSE] = parseBoolean
        self.prefixParseFns[.LPAREN] = parseGroupedExpression
        self.prefixParseFns[.IF] = parseIfExpression
        self.prefixParseFns[.FUNCTION] = parseFunctionLiteral
        self.prefixParseFns[.STRING] = parseString
        self.prefixParseFns[.LBRACKET] = parseArrayLiteral
        self.prefixParseFns[.LBRACE] = parseHashLiteral
        
        self.infixParseFns[.PLUS] = parseInfixExpression(expr:)
        self.infixParseFns[.MINUS] = parseInfixExpression(expr:)
        self.infixParseFns[.SLASH] = parseInfixExpression(expr:)
        self.infixParseFns[.ASTERISK] = parseInfixExpression(expr:)
        self.infixParseFns[.EQ] = parseInfixExpression(expr:)
        self.infixParseFns[.NOT_EQ] = parseInfixExpression(expr:)
        self.infixParseFns[.LT] = parseInfixExpression(expr:)
        self.infixParseFns[.GT] = parseInfixExpression(expr:)
        self.infixParseFns[.LPAREN] = parseCallExpression(expr:)
        self.infixParseFns[.LBRACKET] = parseIndexExpression(expr:)
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
        
        nextToken()
        
        guard let val = parseExpression(.lowest) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        if peekTokenIs(t: .SEMICOLON) {
            nextToken()
        }
        
        return LetStatement(token: currentToken, name: name, value: val)
    }
    
    private func parseReturnStmt() -> ReturnStatement? {
        let currentToken = curToken
        nextToken()
        
        guard let val = parseExpression(.lowest) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        if peekTokenIs(t: .SEMICOLON) {
            nextToken()
        }
        
        return ReturnStatement(token: currentToken, value: val)
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
            noPrefixParseFnError(t: curToken.tokenType)
            return nil
        }
        var left = prefix()
        
        while !peekTokenIs(t: .SEMICOLON) && precedence.rawValue < peekPrecedence().rawValue {
            guard let infix = infixParseFns[peekToken.tokenType] else {
                return left
            }
            
            nextToken()
            left = infix(left)
        }
        
        return left
    }
    
    private func parseIdent() -> Expression {
        return Identifier(token: curToken, value: curToken.literal)
    }
    
    private func parseIntegerLiteral() -> Expression? {
        let current = curToken
        
        guard let val = Int(current.literal) else {
            peekError(t: .INT)
            return nil
        }
        
        return IntegerLiteral(token: current, value: val)
    }
    
    private func parsePrefixExpression() -> Expression? {
        let token = curToken
        let op = curToken.literal
        
        nextToken()
        
        guard let right = parseExpression(.prefix) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        return PrefixExpression(token: token, op: op, right: right)
    }
    
    private func parseInfixExpression(expr: Expression?) -> Expression? {
        let token = curToken
        let op = curToken.literal
        guard let left = expr else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        let prec = curPrecedence()
        nextToken()
        guard let right = parseExpression(prec) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        return InfixExpression(token: token, left: left, op: op, right: right)
    }
    
    private func parseBoolean() -> Expression {
        return BooleanExpression(token: curToken, value: curTokenIs(t: .TRUE))
    }
    
    private func parseString() -> Expression {
        return StringLiteral(token: curToken, value: curToken.literal)
    }
    
    private func parseGroupedExpression() -> Expression? {
        nextToken()
        
        let expr = parseExpression(.lowest)
        
        if !expectPeek(t: .RPAREN) {
            return nil
        }
        
        return expr
    }
    
    private func parseIfExpression() -> Expression? {
        let token = curToken
        
        guard expectPeek(t: .LPAREN) else {
            return nil
        }
        
        nextToken()
        guard let condition = parseExpression(.lowest) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        guard expectPeek(t: .RPAREN) else {
            return nil
        }
        
        guard expectPeek(t: .LBRACE) else {
            return nil
        }
        
        let consequence = parseBlockStmt()
        
        var alt: BlockStatement? = nil
        if peekTokenIs(t: .ELSE) {
            nextToken()
            
            guard expectPeek(t: .LBRACE) else {
                return nil
            }
            
            alt = parseBlockStmt()
        }
        
        return IfExpression(token: token, condition: condition, consequence: consequence, alternative: alt)
    }
    
    private func parseBlockStmt() -> BlockStatement {
        let token = curToken
        var stmts = [Statement]()
        
        nextToken()
        
        while !curTokenIs(t: .RBRACE) && !curTokenIs(t: .EOF) {
            if let stmt = parseStmt() {
                stmts.append(stmt)
            }
            nextToken()
        }
        
        return BlockStatement(token: token, statements: stmts)
    }
    
    private func parseFunctionLiteral() -> Expression? {
        let token = curToken
        guard expectPeek(t: .LPAREN) else { return nil }
        guard let params = parseFunctionParams() else {
            peekError(t: curToken.tokenType)
            return nil
        }
        guard expectPeek(t: .LBRACE) else { return nil }
        let body = parseBlockStmt()
        return FunctionLiteral(token: token, params: params, body: body)
    }
    
    private func parseFunctionParams() -> [Identifier]? {
        var params = [Identifier]()
        
        if peekTokenIs(t: .RPAREN) {
            nextToken()
            return params
        }
        
        nextToken()
        let ident = Identifier(token: curToken, value: curToken.literal)
        params.append(ident)
        
        while peekTokenIs(t: .COMMA) {
            nextToken()
            nextToken()
            let ident = Identifier(token: curToken, value: curToken.literal)
            params.append(ident)
        }
        
        guard expectPeek(t: .RPAREN) else { return nil }
        
        return params
    }
    
    private func parseCallExpression(expr: Expression?) -> Expression? {
        let token = curToken
        guard let expr = expr, let args = parseExpressionList(.RPAREN) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        return CallExpression(token: token, function: expr, arguments: args)
    }
    
    private func noPrefixParseFnError(t: TokenType) {
        let msg = "no prefix parse function found for \(t)"
        print(msg)
        errors.append(msg)
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
    
    private func peekPrecedence() -> Precedence {
        guard let p = precedences[peekToken.tokenType] else {
            return .lowest
        }
        return p
    }
    
    private func curPrecedence() -> Precedence {
        guard let p = precedences[curToken.tokenType] else {
            return .lowest
        }
        return p
    }
    
    private func parseArrayLiteral() -> Expression? {
        let token = curToken
        guard let elements = parseExpressionList(.RBRACKET) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        return ArrayLiteral(token: token, elements: elements)
    }
    
    private func parseExpressionList(_ end: TokenType) -> [Expression]? {
        var list = [Expression]()
        
        if peekTokenIs(t: end) {
            nextToken()
            return list
        }
        
        nextToken()
        guard let expr = parseExpression(.lowest) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        list.append(expr)
        
        while peekTokenIs(t: .COMMA) {
            nextToken()
            nextToken()
            guard let expr = parseExpression(.lowest) else {
                peekError(t: curToken.tokenType)
                return nil
            }
            list.append(expr)
        }
        
        guard expectPeek(t: end) else {
            return nil
        }
        
        return list
    }
    
    private func parseIndexExpression(expr: Expression?) -> Expression? {
        guard let expr = expr else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        let token = curToken
        
        nextToken()
        guard let index = parseExpression(.lowest) else {
            peekError(t: curToken.tokenType)
            return nil
        }
        
        guard expectPeek(t: .RBRACKET) else {
            return nil
        }
        
        return IndexExpression(token: token, left: expr, index: index)
    }
    
    private func parseHashLiteral() -> Expression? {
        let token = curToken
        var pairs = [(Expression, Expression)]()
        while !peekTokenIs(t: .RBRACE) {
            nextToken()
            guard let key = parseExpression(.lowest) else {
                peekError(t: curToken.tokenType)
                return nil
            }
            
            guard expectPeek(t: .COLON) else {
                return nil
            }
            
            nextToken()
            
            guard let value = parseExpression(.lowest) else {
                peekError(t: curToken.tokenType)
                return nil
            }
            
            pairs.append((key, value))
            
            if !peekTokenIs(t: .RBRACE) && !expectPeek(t: .COMMA) {
                return nil
            }
        }
        
        guard expectPeek(t: .RBRACE) else {
            return nil
        }
        
        return HashLiteral(token: token, pairs: pairs)
    }
}
