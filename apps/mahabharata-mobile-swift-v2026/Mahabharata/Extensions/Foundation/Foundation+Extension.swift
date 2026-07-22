//
//  Foundation+Extension.swift
//  Foundation+Extension
//
//  Created by vasiliyursu on 20 Jun 2018.
//	Updated by Andrey Kozlov on 19 Feb 2019.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//
//  Changes history:
//		21 Jun 2018. Stanislav Grinberg:
//			* new parsing era started.
// 		22 Jun 2018. Stanislav Grinberg:
//			* array rewrite with generics
//			* apply current number decimal separator before parse Double and Float with string.
//		29 Jun 2018. Stanislav Grinberg:
//			* removed String extension for conforming Error protocol (use this extension with String extension)
//			* handling NSNull objects in array methods.
//		02 Jul 2018. Stanislav Grinberg:
//			* changed parse methods for Double, Float and Bool types. Fixed issue with parse types when received string.
//		19 Feb 2019. Andrey Kozlov:
//			* added new parameter 'formatter: NumberFormatter' to parse methods for Float, Double, Bool extensions
//

import Foundation

extension Int {
	/*
	init(_ data: Any?, _ val:Int? = nil) throws {
		guard let data = data else {
			print("Int value is not possible to null")
			throw "Int value is not possible to null"
		}
		if data is Int {
			self.init(data as! Int)
		}
		else if let value = try Int((data as? AnyObject)!.description) {
			self.init(value)
		}
	
		else if data is String {
			self.init(data as! String)
		}
		else
			self.init(val ?? Int())
	}
	*/
	/*
	static func parseReq1(_ data: Any?, _ val:Int = Int()) throws -> Int {
		guard let data = data else {
			// v1 or
			//throw "Int value is not possible to null"
			// or v2
			return val
		}
		if data is Int {
			return data as! Int
		}
		else if let value = Int((data as AnyObject).description) {
			return Int(value)
		}
		else if data is String  {
			guard let value = Int(data as! String) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		}
		return val
	}
	*/
	
	//parseReq2
	static func parse(_ data: Any?, _ val: Int = Int()) throws -> Int {
		guard let value = try? parse(data, optional: val) else {
			throw "Int default value is not possible to null"
		}
		return value 
	}
	
	// Не должно быть такой штуки т.к. nil отсекается до вызова парсинга by condition: json["id"] != nil
	// 	guard let id:Int = json["id"] != nil ? json["id"] as? Int : Int() else
	/*
	static func parse(_ data: Any?, optional val: Int? = nil) throws -> Int? {
		guard let data = data else {
			return val
		}
		if data is Int {
			return data as? Int
		} else if let value = Int((data as AnyObject).description) {
			return Int(value)
		} else if data is String {
			guard let value = Int(data as! String) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		}
		return val
	}
	*/
	/*
	static func parse(_ data: Any?, optional val: Int? = nil) throws -> Int? {
		guard let data = data else {
			return val
		}
		if let data = data as? Int {
			return data
		} else if let data = (data as AnyObject).description {
			guard let value = Int(data) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		} else if let data = data as? String {
			guard let value = Int(data) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		}
		return val
	}
	*/
	
	// Попытка распарсить через AnyObject.description должна быть самой последней, потому что это общий способ, который заблокирует оставшиеся частные случаи.
	// Обрабатываем NSNull как тип данных и как строку "null".
	static func parse(_ data: Any?, optional val: Int? = nil) throws -> Int? {
		guard let data = data else {
			return val
		}
		if let data = data as? Int {
			return data
		} else if data is NSNull {
			return val
		} else if let data = data as? String {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			guard let value = Int(data) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		} else if let data = (data as AnyObject).description {
			guard let value = Int(data) else {
				print("Int value is not compatible type")
				throw "Int value is not compatible type"
			}
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [Int]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		
		return array.compactMap { try! Int.parse($0) }
	}
}

extension Double {
	
	static func parse(_ data: Any?, _ val: Double = Double(), formatter: NumberFormatter? = nil) throws -> Double {
		guard let value = try? parse(data, optional: val, formatter: formatter) else {
			throw "Double default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: Double? = nil, formatter: NumberFormatter? = nil) throws -> Double? {
		guard let data = data else {
			return val
		}
		if let data = data as? Double {
			return data
		} else if data is NSNull {
			return val
		} else if var data = data as? String {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			
			let formatter = formatter ?? NumberFormatter()
			data = data.replacingOccurrences(of: ",", with: formatter.decimalSeparator).replacingOccurrences(of: ".", with: formatter.decimalSeparator)
			guard let value: NSNumber = formatter.number(from: data) else {
				print("Float value is not compatible type")
				throw "Float value is not compatible type"
			}
			
			return value.doubleValue
		} else if let data = (data as AnyObject).description {
			guard let value = Double(data) else {
				print("Double value is not compatible type")
				throw "Double value is not compatible type"
			}
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [Double]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Double.parse($0) }
	}
}

extension Float {
	
	static func parse(_ data: Any?, _ val: Float = Float(), formatter: NumberFormatter? = nil) throws -> Float {
		guard let value = try? parse(data, optional: val, formatter: formatter) else {
			throw "Float default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: Float? = nil, formatter: NumberFormatter? = nil) throws -> Float? {
		guard let data = data else {
			return val
		}
		if let data = data as? Float {
			return data
		} else if data is NSNull {
			return val
		} else if var data = data as? String {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			
			let formatter = formatter ?? NumberFormatter()
			data = data.replacingOccurrences(of: ",", with: formatter.decimalSeparator).replacingOccurrences(of: ".", with: formatter.decimalSeparator)
			guard let value: NSNumber = formatter.number(from: data) else {
				print("Float value is not compatible type")
				throw "Float value is not compatible type"
			}
			
			return value.floatValue
		} else if let data = (data as AnyObject).description {
			guard let value = Float(data) else {
				print("Float value is not compatible type")
				throw "Float value is not compatible type"
			}
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [Float]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Float.parse($0) }
	}
}

extension String {
	
	static func parse(_ data: Any?, _ val: String = String()) throws -> String {
		guard let value = try? parse(data, optional: val) else {
			throw "String default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: String? = nil) throws -> String? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? String {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			return data
		} else if let value = (data as AnyObject).description {
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [String]? {
		guard data != nil else { return nil }
		
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! String.parse($0) }
	}
}
/*
extension Array {
	
	static func parse(_ data: Any?, _ val: [Any] = []) throws -> [Any] {
		guard let value = try? parse(data, optional: val) else {
			throw "Array default value is not possible to null"
		}
		return value ?? val
	}
	
	static func parse(_ data: Any?, optional val: [Any]? = nil) throws -> [Any]? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? String, data.isEmpty || data.lowercased() == "null" {
			return val
		} else if let value = data as? [Any] {
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [[Any]]? {
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Array.parse($0) }
	}
}
*/
extension Array {
	
	static func parse<T>(_ data: Any?, _ val: [T] = []) throws -> [T] {
		guard let value = try? parse(data, optional: val) else {
			throw "Array default value is not possible to null"
		}
		return value 
	}
	
	static func parse<T>(_ data: Any?, optional val: [T]? = nil) throws -> [T]? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? String, data.isEmpty || data.lowercased() == "null" {
			return val
		} else if let value = data as? [T] {
			return value
		}
		return val
	}
	
	static func array<T>(_ data: Any?) throws -> [[T]]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Array.parse($0) }
	}
}

// see: https://stackoverflow.com/a/31734969
// extension Dictionary where Key: String, Value: AnyObject { }
extension Dictionary {
	//typealias Element = (Key, Value)
	
	static func parse(_ data: Any?, _ val: [String: Any] = [:]) throws -> [String: Any] {
		guard let value = try? parse(data, optional: val) else {
			throw "Dictionary default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: [String: Any]? = nil) throws -> [String: Any]? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? String, data.isEmpty || data.lowercased() == "null" {
			return val
		} else if let value = data as? [String: Any] {
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [[String: Any]]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Dictionary.parse($0) }
	}
}

extension NSNumber {
	
	static func parse(_ data: Any?, _ val: NSNumber = NSNumber()) throws -> NSNumber {
		guard let value = try? parse(data, optional: val) else {
			throw "NSNumber default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: NSNumber? = nil) throws -> NSNumber? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? String, data.isEmpty || data.lowercased() == "null" {
			return val
		} else if let value = data as? NSNumber {
			return value
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [NSNumber]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! NSNumber.parse($0) }
	}
}

extension Date {
	
	static func parse(_ data: Any?, _ val: Date = Date()) throws -> Date {
		guard let value = try? parse(data, optional: val) else {
			throw "Date default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: Date? = nil) throws -> Date? {
		guard let data = data else {
			return val
		}
		if data is NSNull {
			return val
		} else if let data = data as? TimeInterval {
			return Date(timeIntervalSince1970: data)
		} else if let data = data as? Float {
			return Date(timeIntervalSince1970: Double(data))
		} else if let data = data as? Int {
			return Date(timeIntervalSince1970: Double(data))
		} else if let data = data as? String {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: data)) {
				guard let timeInterval = try? Double.parse(data) else {
					throw "Invalid represantation of date in unix time format"
				}
				// TODO: check that date will be in GMT
				return Date(timeIntervalSince1970: timeInterval)
			} else {
				// https://stackoverflow.com/a/28016692
				let formatter = DateFormatter()
				formatter.calendar = Calendar(identifier: .iso8601)
				formatter.locale = Locale(identifier: "en_US_POSIX")
				formatter.timeZone = TimeZone(secondsFromGMT: 0)
				formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
				// TODO: check that date will be in GMT
				return formatter.date(from: data) ?? val
			}
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [Date]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Date.parse($0) }
	}
}

extension Bool {
	
	static func parse(_ data: Any?, _ val: Bool = Bool(), formatter: NumberFormatter? = nil) throws -> Bool {
		guard let value = try? parse(data, optional: val, formatter: formatter) else {
			throw "Bool default value is not possible to null"
		}
		return value 
	}
	
	static func parse(_ data: Any?, optional val: Bool? = nil, formatter: NumberFormatter? = nil) throws -> Bool? {
		guard let data = data else {
			return val
		}
		if data is Bool {
			return data as? Bool
		} else if data is NSNull {
			return val
		} else if let data = data as? String ?? (data as AnyObject).description {
			if data.isEmpty || data.lowercased() == "null" {
				return val
			}
			if let value = Bool(data) {
				return value
			}
			
			let formatter = formatter ?? NumberFormatter()
			if let number = formatter.number(from: data) {
				return number.boolValue
			}
		}
		return val
	}
	
	static func array(_ data: Any?) throws -> [Bool]? {
		if data is NSNull { return nil }
		
		guard let array = data as? [Any] else {
			throw "Field \"data\" is not array type"
		}
		return array.compactMap { try! Bool.parse($0) }
	}
}
