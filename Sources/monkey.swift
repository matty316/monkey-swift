//
//  monkey.swift
//  monkey
//
//  Created by Matthew Reed on 11/24/24.
//

import Foundation
import ArgumentParser

@main
struct Monkey: ParsableCommand {
    func run() throws {
        try REPL.start()
    }
}

