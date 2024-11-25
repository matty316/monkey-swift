//
//  lexer.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

import Foundation

class Lexer {
    let input: String
    var position: String.Index
    var readPosition: String.Index
    var ch: Character
    
    let keywords: [String: TokenType] = [
        "fn": .FUNCTION,
        "let": .LET,
        "true": .TRUE,
        "false": .FALSE,
        "if": .IF,
        "else": .ELSE,
        "return": .RETURN
    ]
    
    init(input: String) {
        self.input = input
        self.position = input.startIndex
        self.readPosition = input.startIndex
        self.ch = input[input.startIndex]
        self.readChar()
    }
    
    func readChar() {
        position = readPosition

        if readPosition == input.endIndex {
            ch = "\0"
        } else {
            ch = input[readPosition]
            readPosition = input.index(after: readPosition)
        }
    }
    
    func nextToken() -> Token {
        let tok: Token
        
        skipWhitespace()
        
        switch ch {
        case "=":
            if peekChar() == "=" {
                readChar()
                tok = Token(tokenType: .EQ)
            } else {
                tok = Token(tokenType: .ASSIGN)
            }
        case ";": tok = Token(tokenType: .SEMICOLON)
        case "(": tok = Token(tokenType: .LPAREN)
        case ")": tok = Token(tokenType: .RPAREN)
        case ",": tok = Token(tokenType: .COMMA)
        case "+": tok = Token(tokenType: .PLUS)
        case "{": tok = Token(tokenType: .LBRACE)
        case "}": tok = Token(tokenType: .RBRACE)
        case "-": tok = Token(tokenType: .MINUS)
        case "!":
            if peekChar() == "=" {
                readChar()
                tok = Token(tokenType: .NOT_EQ)
            } else {
                tok = Token(tokenType: .BANG)
            }
        case "/": tok = Token(tokenType: .SLASH)
        case "*": tok = Token(tokenType: .ASTERISK)
        case "<": tok = Token(tokenType: .LT)
        case ">": tok = Token(tokenType: .GT)
        case "\0": tok = Token(tokenType: .EOF)
        default:
            if isLetter(ch) {
                let literal = readIdentifier()
                let tokenType = lookupIdent(literal)
                tok = Token(tokenType: tokenType, literal: literal)
                return tok
            } else if isDigit(ch) {
                let tokenType = TokenType.INT
                let literal = readNumber()
                tok = Token(tokenType: tokenType, literal: literal)
                return tok
            } else {
                tok = Token(tokenType: .ILLEGAL)
            }
        }
        
        readChar()
        return tok
    }
    
    private func isLetter(_ ch: Character) -> Bool {
        return ch.isLetter || ch == "_"
    }
    
    private func isDigit(_ ch: Character) -> Bool {
        return ch.isNumber
    }
    
    private func readIdentifier() -> String {
        let start = position
        while isLetter(ch) {
            readChar()
        }
        
        return String(input[start..<position])
    }
    
    private func lookupIdent(_ ident: String) -> TokenType {
        guard let tokenType = keywords[ident] else {
            return .IDENT
        }
        return tokenType
    }
    
    private func skipWhitespace() {
        while ch == " " || ch == "\t" || ch == "\n" || ch == "\r" {
            readChar()
        }
    }
    
    private func readNumber() -> String {
        let start = position
        while isDigit(ch) {
            readChar()
        }
        return String(input[start..<position])
    }
    
    private func peekChar() -> Character {
        if readPosition == input.endIndex {
            return "\0"
        } else {
            return input[readPosition]
        }
    }
}
