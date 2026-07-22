//
//  HashManager.swift
//  HashManager
//
//  Created by Sergey Vasilyev on 06 Nov 2018.
//  Copyright © 2018 Sergey Vasilyev. All rights reserved.
//
//  Dependencies:
//      system: Foundation
//      custom:
//      github:
//

import Foundation

final class HashManager {

    /// This parameter allows ignore system hashing and using custom algorithm if true.
    public static var useCustom: Bool = false
    
    private init() {
    
    }
    
    // MARK: Public methods
    /// The stable hash Int value.
    public static func computeHash(_ value: Any) -> Int {
        let data = createData(value)
        
        let sortedString: String = {
            if let dictStr = (data as? [String: Any])?.jsonString() {
                return dictStr
            }
            if let arrayStr = (data as? [Any])?.jsonString() {
                return arrayStr
            }
            return "\(data)"
        }()
        
        if !useCustom && !canUseSystemHashing() {
            print("HashManager: WARNING! SWIFT_DETERMINISTIC_HASHING environment variable doesn't set to 1!")
            print("HashManager: HashManager will use custom algorithm, but you can set SWIFT_DETERMINISTIC_HASHING env var to 1 for more performance.")
            useCustom = true
        }
        
        if useCustom {
            print("HashManager: Using custom hashing for: \(sortedString)")
            return sortedString.djb2hash
        } else {
            print("HashManager: Using system hashing for: \(sortedString)")
            return sortedString.hashValue
        }
    }
    
    /// The stable hash String value based on computeHash's Int where "-" replaced by "0"
    public static func hashString(_ value: Any) -> String {
        return "\(computeHash(value))".replace("-", withValue: "0")
    }
    
    /// Check if environment variable SWIFT_DETERMINISTIC_HASHING is set to 1.
    public static func canUseSystemHashing() -> Bool {
        // we can use system hashig if SWIFT_DETERMINISTIC_HASHING environment
        // variable set to 1, otherwise hash have random behavior per each App launch
        guard let pointer = getenv("SWIFT_DETERMINISTIC_HASHING"),
            String(cString: pointer) == "1" else {
                return false
        }
        return true
    }
    
    // MARK: Private methods
    // This method create check type of soure value and if needed work as recoursive function.
    // If source type is simple (Int, Double, String etc.) then just return value. Otherwise create dictionary [String: Any].
    private static func createData(_ value: Any) -> Any {
        // For Array and Dictionary every value run createData recursively. This allows to create nested output type.
        // Dictionary.
        if let value = value as? [String:Any] {
            var dict = [String:Any]()
            for (key, value) in value {
                dict[key] = createData(value)
            }
            return dict
        }
        
        // Array
        if let value = value as? [Any] {
            var arr = [Any]()
            for val in value {
                arr.append(createData(val))
            }
            return arr
        }
        
        // Number
        if let value = value as? Int {
            return value
        }
        if let value = value as? Double {
            return value
        }

        // String
        if value is String {
            return value
        }
        
        // Encodable
        if #available(iOS 11.0, *) {
            if let value = value as? Encodable,
                let encoded = value.encode(),
                let jsonObject = try? JSONSerialization.jsonObject(with: encoded, options: []),
                let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys]),
                let jsonStr = String(data: jsonData, encoding: .utf8) {
                return jsonStr
            }
        }
        
        // Other cases
        let mirror = Mirror(reflecting: value)
        let childrens = mirror.children
        var dict = [String:Any]()
        for child in childrens {
            dict["\(child.label ?? "nil")"] = createData(child.value)
        }
        return dict
    }
}

// MARK: Custom hash algoritms
extension String {
    /// Returns a hash value wich computed with bjb2 algorithm
    fileprivate var djb2hash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1)
        }
    }
    
    /// Returns a hash value wich computed with sdbm algorithm
    fileprivate var sdbmhash: Int {
        let unicodeScalars = self.unicodeScalars.map { $0.value }
        return unicodeScalars.reduce(0) {
            Int($1) &+ ($0 << 6) &+ ($0 << 16) - $0
        }
    }
}
