//
//  object.swift
//  monkey
//
//  Created by Matthew Reed on 11/28/24.
//

enum ObjectType: String {
    case Integer, Boolean, Null, ReturnValue, Error, Function, String, Builtin, Array, Hash
}

protocol Object {
    var objectType: ObjectType { get }
    func inspect() -> String
}

// I know i could just use hashable but i wanna stay close to the book
protocol HashKeyable {
    var hashKey: HashKey { get }
}

struct Integer: Object, HashKeyable {
    let objectType: ObjectType = .Integer
    let value: Int
    var hashKey: HashKey {
        HashKey(objectType: objectType, value: value)
    }
    func inspect() -> String {
        "\(value)"
    }
}

struct Boolean: Object, HashKeyable {
    let value: Bool
    var objectType: ObjectType = .Boolean
    var hashKey: HashKey {
        HashKey(objectType: objectType, value: value ? 1 : 0)
    }
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

struct StringObject: Object, HashKeyable {
    let value: String
    var hashKey: HashKey {
        var hasher = Hasher()
        hasher.combine(value)
        return HashKey(objectType: objectType, value: hasher.finalize())
    }
    var objectType: ObjectType = .String
    func inspect() -> String { value }
}

typealias BuiltinFunction = ([Object]) -> Object

struct Builtin: Object {
    let fn: BuiltinFunction
    var objectType: ObjectType = .Builtin
    func inspect() -> String {
        return "builtin function"
    }
}

struct ArrayObject: Object {
    let elements: [Object]
    var objectType: ObjectType = .Array
    func inspect() -> String {
        "[\(elements.map{ $0.inspect() }.joined(separator: ", "))]"
    }
}

struct HashKey: Hashable {
    let objectType: ObjectType
    let value: Int
}

struct HashPair {
    let key: Object
    let value: Object
}

struct Hash: Object {
    let pairs: [HashKey: HashPair]
    var objectType: ObjectType = .Hash
    func inspect() -> String {
        let pairsString = pairs
            .map { "\($0.value.key.inspect()): \($0.value.value.inspect())" }
            .joined(separator: ", ")
        return "{\(pairsString)}"
    }
}

let TRUE = Boolean(value: true)
let FALSE = Boolean(value: false)
let NULL = Null()
