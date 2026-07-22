//
//  KeyChainError.swift
//  KeyChain
//
//  Created by Stanislav Grinberg on 07 Jun 2018.
//  Updated by Vasiliy Ursu on 15 Oct 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//
// 	Changes history:
// 		07 Jun 2018. Stanislav Grinberg:
//			* Created KeyChainError.
//		15 Oct 2018. Vasiliy Ursu:
//			* Changed syntax to swift like format + some optimizations.
//

import Foundation

class KeyChainError: Error {
	
	let message: String
	let osStatus: Int32?
	
	// MARK: - Init
	
	init(message: String, osStatus: Int32?) {
		self.message = message
		self.osStatus = osStatus
	}
	
}

extension NSError {
	
	convenience init(_ error: KeyChainError) {
		var infoDict: [String: Any] = ["message": error.message]
		infoDict["osStatus"] = error.osStatus
		self.init(domain: "", code: Int(error.osStatus ?? Int32(-1)), userInfo: infoDict)
	}

	static func keyChainError(_ error: KeyChainError) -> NSError {
		return NSError(error)
	}
	
}
