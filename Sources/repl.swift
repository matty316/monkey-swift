//
//  repl.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

import Foundation

struct REPL {
    static let prompt = ">> "
    
    static func start() throws {
        print(prompt, terminator: "")
        let input = readLine(strippingNewline: true)
        
        guard let input = input else {
            return
        }
        
        let l = Lexer(input: input)
        
        var tok = l.nextToken()
        while tok.tokenType != .EOF {
            print(tok)
            tok = l.nextToken()
        }
    }
}
