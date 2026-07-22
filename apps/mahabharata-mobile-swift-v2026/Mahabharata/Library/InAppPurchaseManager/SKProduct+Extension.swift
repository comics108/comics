//
//  SKProduct+Extension.swift
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

extension SKProduct {

	var formattedPrice: String {
		
		let numberFormatter = NumberFormatter()
		numberFormatter.formatterBehavior = .behavior10_4
		numberFormatter.numberStyle = .currency
		numberFormatter.locale = self.priceLocale
		
		return numberFormatter.string(from: self.price) ?? ""
	}
}

extension SKProduct {
	open override var description: String {
		return [
			"Product identifier: \(productIdentifier)",
			"Localized title: \(localizedTitle)",
			"Formatted price: \(formattedPrice)"
			].joined(separator: ", ")
	}
}
