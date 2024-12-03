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
            
            let comp = Compiler()
            let compErr = comp.compile(node: prog)
            if let err = compErr {
                print(err)
                continue
            }
            
            let vm = VM(bytecode: comp.bytecode)
            let vmErr = vm.run()
            if let err = vmErr {
                print(err)
                continue
            }
            let top = vm.stackTop
            
            print(top?.inspect() ?? "")
        }
    }
    
    static func printErrors(_ errors: [String]) {
        print(errors.joined(separator: "/n"))
    }
}
