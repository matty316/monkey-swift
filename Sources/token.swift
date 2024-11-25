//
//  token.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

enum TokenType: String {
    case ILLEGAL
    case EOF
    
    case INT = "int"
    case IDENT
    
    case ASSIGN = "="
    case PLUS = "+"
    case MINUS = "-"
    case BANG = "!"
    case ASTERISK = "*"
    case SLASH = "/"
    case LT = "<"
    case GT = ">"
    
    case EQ = "=="
    case NOT_EQ = "!="
    
    case COMMA = ","
    case SEMICOLON = ";"
    
    case LPAREN = "("
    case RPAREN = ")"
    case LBRACE = "{"
    case RBRACE = "}"
    
    case FUNCTION = "fn"
    case LET = "let"
    case TRUE = "true"
    case FALSE = "false"
    case IF = "if"
    case ELSE = "else"
    case RETURN = "return"
}

struct Token {
    let tokenType: TokenType
    let literal: String
    
    init(tokenType: TokenType, literal: String? = nil) {
        self.tokenType = tokenType
        self.literal = literal ?? tokenType.rawValue
    }
}
