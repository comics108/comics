//
//  UIDevice+Identifier.swift
//  UIDeviceExtension
//
//  Created by Mikhail Kulichkov on 07 Aug 2017.
//	Updated by Vasiliy Ursu on 15 oct 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
// 	Changes history:
// 		25 Jun 2018. Stanislav Grinberg:
//			* Updated KeyChain library
//			* More short property names: uniqueDeviceVendorId -> uniqueVendorId, uniqueDeviceAppID -> uniqueDeviceId
//			* Added uniqueAppId
//		15 Oct 2018. Vasiliy Ursu:
//			* Updated keychan methods using.
//

import UIKit

extension UIDevice {
	
	// Если мы удалим все приложения одного вендора, то при следующей установке аппа будет сгенерирован новый.
	// Если мы переустановим какое либо приложение вендора, то у всех приложений вендора будет обновлен VendorId.
	static var uniqueVendorId: String? {
		get {
			return UIDevice.current.identifierForVendor?.uuidString
		}
	}
	
	/**
	- Warning: If Bundle Identifier was changed new unique key will be created
	*/
	static var uniqueDeviceId: String? {
		get {
			// Get bundleID
			if let bundleID = Bundle.main.bundleIdentifier {
				// Try to get AppUUID data from KeyChain
				if let uuidData = try? KeyChain.searchCopyMatching(for: bundleID) {
					// If there is AppUUID data, get it
					if let uuidString = String(data: uuidData, encoding: .unicode), !uuidString.isEmpty {
						return uuidString
					}
				} else {
					let uuidString = UUID().uuidString
					if let uuidData = uuidString.data(using: .unicode) {
						// If there's no AppUUID data, create it and get it
						if let isCreated: Bool = try? KeyChain.create(uuidData, for: bundleID), isCreated {
							return uuidString
						}
					}
				}
			}
			return nil
		}
	}
	
	/**
	- Warning: If Bundle Identifier was changed new unique key will be created
	*/
	static var uniqueAppId: String? {
		get {
			// Get bundleID
			if let bundleID = Bundle.main.bundleIdentifier {
				// Try to get AppUUID data from UserDefaults
				if let uuidString = UserDefaults.standard.object(forKey: bundleID) as? String, !uuidString.isEmpty {
					return uuidString
				} else {
					// If there's no AppUUID, create it and get it
					let uuidString = UUID().uuidString
					UserDefaults.standard.set(uuidString, forKey: bundleID)
					if UserDefaults.standard.synchronize() {
						return self.uniqueAppId
					}
				}
			}
			return nil
		}
	}
	
	/**
	- Warning: If Bundle Identifier was changed new unique key will be created
	*/
	/*
	static var uniqueDeviceCrossAppID: String? {
		get {
			// Get bundleID
			if let bundleID = Bundle.main.bundleIdentifier {
				// Try to get AppUUID data from KeyChain
				if let uuidData = KeyChain.searchKeychainCopyMatching(for: bundleID) {
					// If there is AppUUID data, get it
					if let uuidString = String(data: uuidData, encoding: .unicode), uuidString.count > 0 {
						return uuidString
					}
				} else if let uuidData = uniqueDeviceVendorID?.data(using: .unicode) {
					// If there's no AppUUID data, create it and get it
					if KeyChain.createKeychainValue(uuidData, forIdentifier: bundleID) {
						return self.uniqueDeviceCrossAppID
					}
				}
			}
			return nil
		}
	}
	*/
}
