//
//  Foundation+Hash.swift
//  HashManager
//
//  Created by Sergey Vasilyev on 07/11/2018.
//  Copyright © 2018 Sergey Vasilyev. All rights reserved.
//

import Foundation

// MARK: Extensions for Foundation's types
extension String {
    /// The stable hash Int value. Calls HashManager's method.
    var computeHash: Int {
        return HashManager.computeHash(self)
    }
    
    /// The stable hash String value based on computeHash's Int where "-" replaced by "0"
    var hashString: String {
        return HashManager.hashString(self)
    }
}

extension Dictionary {
    /// The stable hash Int value. Calls HashManager's method.
    var computeHash: Int {
        return HashManager.computeHash(self)
    }
    
    /// The stable hash String value based on computeHash's Int where "-" replaced by "0"
    var hashString: String {
        return HashManager.hashString(self)
    }
    
    /// Returns a new string, which is the sorted by key string JSON. Run recursively if Value is other Collection.
    func jsonString(_ sort: Bool = true) -> String? {
		guard let tmp = self as? [String:Any] else {
            return nil
        }
        var keys = [String]()
        for key in tmp.keys {
            keys.append(key)
        }
        if sort { keys.sort { $0 < $1 } }
        var arr: [String] = []
        for key in keys {
            let value = tmp[key]
            if let value = value as? [String:Any] {
                arr.append("\"\(key)\":\(value.jsonString(sort) ?? "")")
            } else if let value = value as? [Any] {
                arr.append("\"\(key)\":\(value.jsonString(sort))")
            } else if let value = value as? Int {
                arr.append("\"\(key)\":\(value)")
            } else if let value = value as? Double {
                arr.append("\"\(key)\":\(value)")
            } else if let value = value as? String {
                arr.append("\"\(key)\":\"\(value)\"")
            } else {
                arr.append("\"\(key)\":\"\(tmp[key] ?? "nil")\"")
            }
        }
        return "{\(arr.joined(separator: ","))}"
    }
}

extension Array {
    /// The stable hash Int value. Calls HashManager's method.
    var computeHash: Int {
        return HashManager.computeHash(self)
    }
    
    /// The stable hash String value based on computeHash's Int where "-" replaced by "0"
    var hashString: String {
        return HashManager.hashString(self)
    }
    
    /// Returns a new string, which is the string JSON. Run recursively if Element is other Collection.
    func jsonString(_ sort: Bool = true) -> String {
        var arr: [String] = []
        for value in self {
            if let value = value as? [String:Any] {
                arr.append(value.jsonString(sort) ?? "")
            } else if let value = value as? [Any] {
                arr.append(value.jsonString(sort))
            } else if let value = value as? Int {
                arr.append("\(value)")
            } else if let value = value as? Double {
                arr.append("\(value)")
            } else if let value = value as? String {
                arr.append("\"\(value)\"")
            } else {
                arr.append("\"\(value)\"")
            }
        }
        return "[\(arr.joined(separator: ","))]"
    }
}

extension Numeric {
    /// The stable hash Int value. Calls HashManager's method.
    var computeHash: Int {
        return HashManager.computeHash(self)
    }
    
    /// The stable hash String value based on computeHash's Int where "-" replaced by "0"
    var hashString: String {
        return HashManager.hashString(self)
    }
}

extension Encodable
{
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
