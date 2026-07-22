//
//  InAppError.swift
//	InAppPurchaseManager
//
//	Based on:
//  	EstelColorMaster
//
//  Created by Roman Developer on 11/15/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import StoreKit

class InAppError {

	let transaction: SKPaymentTransaction?
	private let err: Error?
	var askToBuy: Bool
	var isCanceled: Bool
	var message: String?
	
	init(_ transaction: SKPaymentTransaction?, error: Error? = nil, message: String? = nil) {
		self.transaction = transaction
		self.err = error
		self.askToBuy = false
		self.isCanceled = false
		self.message = message
	}
	
	var error: Error? {
		return self.err ?? self.transaction?.error
	}
}

extension InAppError: CustomStringConvertible {
	var description: String {
		return [
			"Transaction: \(String(describing: transaction))",
			"Err: \(String(describing: error))",
			"AskToBuy: \(askToBuy)",
			"IsCanceled: \(isCanceled)",
			"Message: \(message ?? "")"
			].joined(separator: ", ")
	}
}
