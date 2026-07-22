//
//  Season+Extension.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 13.08.2020.
//  Copyright © 2020 Iron Water Studio. All rights reserved.
//

import Foundation

extension Season {
	private enum Constants {
		static let seasonPurchasedKey = "SeasonPurchasedKey"
	}
	
	enum NotificationConstants {
		/// Key of object in userInfo for generating Notification
		static let userInfoIdKey = "id"
	}

	var shouldPurchase: Bool {
		return !String.isNilOrWhiteSpace(product)
	}

	/// Property stored in UserDefaults
	var isPurchased: Bool {
		get {
			return UserDefaults.standard.bool(forKey: "\(Constants.seasonPurchasedKey)-\(id)")
		}
		
		set {
			UserDefaults.standard.set(newValue, forKey: "\(Constants.seasonPurchasedKey)-\(id)")
			UserDefaults.standard.synchronize()
		}
	}
	
	/// Title for buy season button
	func getBuyTitle() -> String {
		if shouldPurchase {
			return isPurchased ? Local("Season.Bought") : String.localizedStringWithFormat(Local("Season.BuyBook"), price)
		} else {
			return ""
		}
	}
	
	/// Mark season purchased permanently. Use instead of season.isPurchased = true for clearer understanding code
	static func markPurchased(_ id: Int, purchased: Bool = true) {
		UserDefaults.standard.set(purchased, forKey: "\(Constants.seasonPurchasedKey)-\(id)")
		UserDefaults.standard.synchronize()
	}
	
	static func isPurchased(_ id: Int) -> Bool {
		UserDefaults.standard.bool(forKey: "\(Constants.seasonPurchasedKey)-\(id)")
	}
}
