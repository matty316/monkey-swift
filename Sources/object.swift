//
//  object.swift
//  monkey
//
//  Created by Matthew Reed on 11/28/24.
//

enum ObjectType: String {
    case Integer, Boolean, Null, ReturnValue, Error, Function
}

protocol Object {
    var objectType: ObjectType { get }
    func inspect() -> String
}

struct Integer: Object {
    let objectType: ObjectType = .Integer
    let value: Int
    func inspect() -> String {
        "\(value)"
    }
}

struct Boolean: Object {
    let value: Bool
    var objectType: ObjectType = .Boolean
    func inspect() -> String {
        "\(value)"
    }
}

struct Null: Object {
    var objectType: ObjectType = .Null
    func inspect() -> String {
        "null"
    }
}

struct ReturnValue: Object {
    let value: Object
    var objectType: ObjectType = .ReturnValue
    func inspect() -> String {
        value.inspect()
    }
}

struct ErrorObject: Object {
    let msg: String
    var objectType: ObjectType = .Error
    func inspect() -> String {
        "Error: \(msg)"
    }
}

class Env {
    private var store = [String: Object]()
    private var outer: Env?
    
    init() {
        self.outer = nil
    }
    
    init(outer: Env) {
        self.outer = outer
    }

    func get(name: String) -> Object? {
        var val = store[name]
        if val == nil {
            val = outer?.store[name]
        }
        return val
    }
    
    @discardableResult
    func set(name: String, val: Object) -> Object {
        store[name] = val
        return val
    }
}

struct Function: Object {
    let params: [Identifier]
    let body: BlockStatement
    let env: Env
    
    var objectType: ObjectType = .Function
    func inspect() -> String {
        let paramsString = params.map { $0.value }.joined(separator: ", ")
        return "fn(\(paramsString)) {\n\(body.string())\n}"
    }
}
