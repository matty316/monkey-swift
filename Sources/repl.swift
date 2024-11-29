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
            let env = Env()
            guard let input = readLine(strippingNewline: true) else {
                return
            }
            let p = Parser(lexer: Lexer(input: input))
            let prog = p.parseProgram()
            if !p.errors.isEmpty {
                printErrors(p.errors)
                continue
            }
            let evaluated = Evaluator.eval(node: prog, env: env)
            
            print(evaluated.inspect())
        }
    }
    
    static func printErrors(_ errors: [String]) {
        print(errors.joined(separator: "/n"))
    }
}
