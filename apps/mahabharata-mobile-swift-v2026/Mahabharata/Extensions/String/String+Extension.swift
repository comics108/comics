//
//  String+Extension.swift
//  String+Extension
//
//  Created by Stanislav Grinberg on 10 Jan 2017.
//  Updated by Stanislav Grinberg on 20 Jun 2018.
//  Copyright © 2018 Stanislav Grinberg. All rights reserved.
//
//  Changes history:
//		07 Jun 2018. Mikhail Kulichkov:
//			* Conforming to Error protocol added to throw simple string error with high perfomance.
//				usage: throw "Error description".
//		20 Jun 2018. Stanislav Grinberg:
//			* Fixed crash when used subscript for empty string.
//		7 Dec 2018. Sergey Vasilyev:
//			* removed swift < 4 support
//		7 Dec 2018. Olga Zhegulo:
//			* added attributed() method
//		10 Dec 2018. Olga Zhegulo:
//			* changed attributed() + discardableResult
//			* added comments
//

import UIKit

extension String: Error {}

extension String {
	
	subscript(i: Int) -> String {
		get {
			if self.isEmpty { return "" }
			return String(self[self.index(self.startIndex, offsetBy: i)])
		}
	}
	
	@discardableResult
	func starts(with str: String, ignoreCase: Bool = true) -> Bool {
		return ignoreCase ? self.lowercased().hasPrefix(str.lowercased()) : self.hasPrefix(str)
	}
	
	@discardableResult
	func index(of str: String, ignoreCase: Bool = true, inverse: Bool = false) -> Int {
		var options: CompareOptions = .literal
		if ignoreCase {
			options.update(with: .caseInsensitive)
		}
		if inverse {
			options.update(with: .backwards)
		}
		
		let range = self.range(of: str, options: options)
		guard let unwrappedRange = range else {
			return -1
		}
		
		return self.distance(from: self.startIndex, to: unwrappedRange.lowerBound)
	}

	@discardableResult
	func lastIndex(of str: String) -> Int {
		return index(of: str, ignoreCase: true, inverse: true)
	}
	
	@discardableResult
	func contains(_ str: String, ignoreCase: Bool = true) -> Bool {
		let range = self.range(of: str, options: ignoreCase ? .caseInsensitive : .literal)
		guard let _ = range else {
			return false
		}

		return true
	}
	
	@discardableResult
	func isEqualToString(_ str: String, ignoreCase: Bool = true) -> Bool {
		return ignoreCase ? self.lowercased() == str.lowercased() : self == str
	}
	
	@discardableResult
	func ends(with str: String, ignoreCase: Bool = true) -> Bool {
		return ignoreCase ? self.lowercased().hasSuffix(str) : self.hasSuffix(str)
	}
	
	@discardableResult
	func firstLetterToLower() -> String {
		let firstCharStr = String(self[self.startIndex])
		let range = self.index(after: self.startIndex)..<self.endIndex
		
		let strWithoutFirstChar = String(self[range])
		
		return self.count < 2 ? self.lowercased() : String(format: "%@%@", firstCharStr.lowercased(), strWithoutFirstChar)
	}
	
	@discardableResult
	func firstLetterToUpper() -> String {
		let firstCharStr = String(self[self.startIndex])
		let range = self.index(after: self.startIndex)..<self.endIndex
		
		let strWithoutFirstChar = String(self[range])
		
		return self.count < 2 ? self.uppercased() : String(format: "%@%@", firstCharStr.uppercased(), strWithoutFirstChar)
	}
	
	@discardableResult
	func padRight(_ cnt: Int, withString str: String = " ") -> String {
		if cnt > 0 {
			let padStr = String(repeating: str, count: cnt)
			return String(format: "%@%@", self, padStr)
		} else {
			return self
		}
	}
	
	@discardableResult
	func padLeft(_ cnt: Int, withString str: String = " ") -> String {
		if cnt > 0 {
			let padStr = String(repeating: str, count: cnt)
			return String(format: "%@%@", padStr, self)
		} else {
			return self
		}
	}
	
	@discardableResult
	func appendLine(_ str: String = "") -> String {
		return self.appendingFormat("%@\r\n", str)
	}
	
	@discardableResult
	func trim() -> String {
		return self.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	@discardableResult
	func trim(with characters: String) -> String {
		return self.trimmingCharacters(in: CharacterSet.init(charactersIn: characters))
	}
	
	@discardableResult
	func replace(_ substring: String, withValue value: String, ignoreCase: Bool = false) -> String {
		return self.replacingOccurrences(of: substring, with: value, options: ignoreCase ? .caseInsensitive : .literal)
	}
	
	@discardableResult
	func replace(_ substring: String, withValue value: String, ignoreCase: Bool = false, replaceAll: Bool = true) -> String {
		if replaceAll {
			return self.replace(substring, withValue: value, ignoreCase: ignoreCase)
		}
		
		//guard let range = self.range(of: substring) else { return self }
		guard let range = self.range(of: substring, options: ignoreCase ? .caseInsensitive : .literal, range: nil, locale: nil) else { return self }
		return replacingCharacters(in: range, with: value)
	}

    @discardableResult
    func fixNewLine() -> String {
        self.replace("\\n", withValue: "\n")
    }

	@discardableResult
	func split(_ separators: [String] , removeSeparators remove: Bool, removeEmptyEntries removeEmpty: Bool) -> [String] {
		var src = self
		var array: [String] = [String]()
		var hasSubstrings = false
		
		repeat {
			hasSubstrings = false
			var minIndex = Int.max
			var minIndexStr: String? = nil
			
			var strIndex: Index? = nil
			for separator in separators {
				guard separator.count > 0 else { continue }
				
				let index = src.index(of: separator)
				if index != -1 {
					hasSubstrings = true
					if index < minIndex {
						minIndex = index
						strIndex = src.index(src.startIndex, offsetBy: index)
						minIndexStr = separator
					}
				}
			}
			
			if minIndexStr != nil  && strIndex != nil {
				var subString = String(src[src.startIndex..<strIndex!])
				
				let subStringTrim = subString.trim()
				if !removeEmpty || subStringTrim.count > 0 {
					array.append(subStringTrim)
				}
				if !remove {
					if !removeEmpty || minIndexStr!.count > 0 {
						array.append(minIndexStr!)
					}
				}
				subString = String(src[src.index(strIndex!, offsetBy: minIndexStr!.count)..<src.endIndex])
				
				src = subString
			} else if src.count > 0 {
				hasSubstrings = true
				if !removeEmpty || src.count > 0 {
					array.append(src)
				}
				src = ""
			}
			
		} while hasSubstrings == true && src.count > 0
		
		return array
	}
	
	@discardableResult
	func matches(for pattern: String) -> Bool {
		do {
			let regEx = try NSRegularExpression(pattern: pattern)
			return regEx.matches(in: self, range: NSRange(location: 0, length: self.count)).count > 0
		} catch let error {
			print("invalid regex: \(error.localizedDescription)")
			return false
		}
	}

	@discardableResult
	func characterAt(_ index: Int) -> String {
		//return self.utf16[String.UTF16Index(encodedOffset: index)]
		return String(self[self.index(self.startIndex, offsetBy: index)])
	}
	
	@discardableResult
	func substring(from: Int, to: Int) -> String {
		let start = index(self.startIndex, offsetBy: from)
		let end = index(self.startIndex, offsetBy: to)

		return String(self[start..<end])
	}
	
	@discardableResult
	func substringTo(_ index: Int) -> String {
		return String(self[self.startIndex..<self.index(self.startIndex, offsetBy: index)])
	}
	
	@discardableResult
	func substringFrom(_ index: Int) -> String {
		return String(self[self.index(self.startIndex, offsetBy: index)..<self.endIndex])
	}
	
	@discardableResult
	func substring(from index: Int, length: Int?) -> String {
		if let length = length {
			let startIndex = index
			let destinationIndex = index + length
			
			if destinationIndex >= self.count {
				return substringFrom(index)
			} else if destinationIndex <= 0 {
				return substringTo(index)
			}
			
			let fromIndex = min(startIndex, destinationIndex)
			let toIndex = max(startIndex, destinationIndex)
			
			return substring(from: fromIndex, to: toIndex)
		} else {
			return substringFrom(index)
		}
	}
	
	@discardableResult
	func isNumber() -> Bool {
		let badCharacters = NSCharacterSet.decimalDigits.inverted
		
		return rangeOfCharacter(from: badCharacters) == nil
	}
	
	@discardableResult
	func plainText() -> String {
		var s = self
		while let r = range(of: "<[^>]+>", options: .regularExpression) {
			s = s.replacingCharacters(in: r, with: "")
		}
		
		return s
	}
	
	
	// MARK: - Text size and dimension
	
	@discardableResult
	public func size(width maxWidth: CGFloat = CGFloat.greatestFiniteMagnitude, height maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude, font: UIFont) -> CGSize {
		let constraintRect = CGSize(width: maxWidth, height: maxHeight)
		
		let attributes: [NSAttributedString.Key: Any] = [.font: font]
		
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
		
		return boundingBox.size
	}
	
	// MARK: - Encoding

	@discardableResult
	func fromBase64() -> String? {
		guard let data = Data(base64Encoded: self) else { return nil }
		
		return String(data: data, encoding: .utf8)
	}
	
	@discardableResult
	func toBase64() -> String {
		return Data(self.utf8).base64EncodedString()
	}
	
	// MARK: - Attributes
	
	/// Create instance of NSAttributedString from current string
	@discardableResult
	func attributed(attributes attrs: [NSAttributedString.Key : Any]? = nil) -> NSMutableAttributedString {
		return NSMutableAttributedString(string: self, attributes: attrs)
	}
	
	// MARK: - Static methods
	
	/**
		Checks if the specified string is nil or an empty string.
		- Parameters:
			- value: the string to be checked.
		- Returns: true if and only if the specified string is nil or empty.
	*/
	static func isNilOrEmpty(_ value: String?) -> Bool {
		if let value = value {
			return value.isEmpty
		}
		return true
	}
	
	static func isNilOrWhiteSpace(_ value: String?) -> Bool {
		if let value = value {
			return value.trim().isEmpty
		}
		return true
	}
	
}
