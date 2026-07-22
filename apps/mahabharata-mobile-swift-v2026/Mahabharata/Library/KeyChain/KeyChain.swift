//
//  KeyChain.swift
//  KeyChain
//
//  Created by Stanislav Grinberg on 21 Nov 2016.
//  Updated by Andrey Kozlov on 10 Dec 2018.
//  Copyright © 2018 IronWaterStudio. All rights reserved.
//
// 	Changes history:
// 		07 Jun 2018. Stanislav Grinberg:
//			* Added KeyChainError.
//		04 Sep 2018. Alexander Popov:
//			* Fixed background access bug.
//		15 Oct 2018. Vasiliy Ursu:
//			* Changed syntax to swift like format + some optimizations.
//		29 Nov 2018. Vasiliy Ursu:
//			* discardableResult and returning result for all methods
//		10	Dec 2018. Andrey Kozlov:
//			* fix logic bug in searchCopyMatching()
//

import Foundation
import Security

/**
To allow accessibility keychain in background & locked mode need to set KeyChain.Defaults.AccessibleAlways or KeyChain.Defaults.AccessibleAfterFirstUnlock flag
*/
final class KeyChain {
	// Extra attributes, see possible problems: https://github.com/yankodimitrov/SwiftKeychain/issues/13
	struct Defaults {
		// This should allow keychain data to be accessible in background + locked mode
		// Example - constant logout in Gulfstream project because access token was not available in background mode.
		static var AccessibleAlways: Bool = true
		static var AccessibleAfterFirstUnlock: Bool = false
	}
	
	@discardableResult
	static private func buildSearchParams(for identifier: String, with params: [String: Any]? = nil) -> [String: Any] {
		let encodedIdentifier = identifier.data(using: .utf8) ?? Data()
		var searchParams: [String: Any] = [
			String(kSecClass): String(kSecClassGenericPassword),
			String(kSecAttrGeneric): encodedIdentifier,
			String(kSecAttrAccount): encodedIdentifier,
			String(kSecAttrService): Bundle.main.bundleIdentifier ?? ""
		]
		if (Defaults.AccessibleAlways) {
			searchParams[String(kSecAttrAccessible)] = kSecAttrAccessibleAlways
		}
		else if (Defaults.AccessibleAfterFirstUnlock) {
			searchParams[String(kSecAttrAccessible)] = kSecAttrAccessibleAfterFirstUnlock
		}
		
		if let params = params {
			// Mark that second dictionary have priority when both dictionaries will have same keys
			return searchParams.merging(params) { (_ /*first*/, second) in second }
		}
		return searchParams
	}
	
	@discardableResult
	static func searchCopyMatching(for identifier: String) throws -> Data? {
		// Add search attributes + search return types
		let searchParams = buildSearchParams(for: identifier, with: [String(kSecMatchLimit): String(kSecMatchLimitOne), String(kSecReturnData): kCFBooleanTrue])
		
		var result: CFTypeRef?
		let status = SecItemCopyMatching(searchParams as CFDictionary, &result)
		if status != errSecSuccess {
			if status != errSecItemNotFound {
				throw KeyChainError(message: "Error searching KeyChain value: \(identifier)", osStatus: status)
			} else {
				return nil
			}
		}
		return result as? Data
	}
	
	@discardableResult
	static func create(_ value: Data, for identifier: String) throws -> Bool {
		let searchParams = buildSearchParams(for: identifier, with: [String(kSecValueData): value])
		
		var result: CFTypeRef?
		var status: OSStatus = SecItemAdd(searchParams as CFDictionary, &result)
		if status == errSecDuplicateItem { // errSecDuplicateItem = -25299
			try delete(for: identifier)
			status = SecItemAdd(searchParams as CFDictionary, nil)
		}
		if status != errSecSuccess {
			throw KeyChainError(message: "Error creating KeyChain value: \(identifier)", osStatus: status)
		}
		return true
	}
	
	@discardableResult
	static func update(_ value: Data, for identifier: String) throws -> Bool {
		let searchParams = buildSearchParams(for: identifier)
		let updateParams: [String: Any] = [String(kSecValueData): value]
		
		let status: OSStatus = SecItemUpdate(searchParams as CFDictionary, updateParams as CFDictionary)
		if status != errSecSuccess {
			throw KeyChainError(message: "Error updating KeyChain value: \(identifier)", osStatus: status)
		}
		return true
	}
	
	@discardableResult
	static func delete(for identifier: String) throws -> Bool {
		var searchParams = buildSearchParams(for: identifier)
		searchParams.removeValue(forKey: String(kSecAttrAccessible))
		
		let status: OSStatus = SecItemDelete(searchParams as CFDictionary)
		if status != errSecSuccess && status != errSecItemNotFound { //errSecItemNotFound = -25299
			throw KeyChainError(message: "Error deleting KeyChain value: \(identifier)", osStatus: status)
		}
		return true
	}
}
