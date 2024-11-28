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
        while true {
            print(prompt, terminator: "")
            
            guard let input = readLine(strippingNewline: true) else {
                return
            }
            let p = Parser(lexer: Lexer(input: input))
            let prog = p.parseProgram()
            if !p.errors.isEmpty {
                printErrors(p.errors)
                continue
            }
            print(prog.string())
        }
    }
    
    static func printErrors(_ errors: [String]) {
        print(errors.joined(separator: "/n"))
    }
}
