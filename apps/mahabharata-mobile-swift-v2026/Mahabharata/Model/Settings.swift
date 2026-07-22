//
//  Settings.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 09/10/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

final class Settings {
	enum Language: Int {
		case none = -1, english, russian, indian
		
		private static let codes: [String] = ["en", "ru", "hi"]
		
		var identifier: String {
			return self != .none ? Language.codes[self.rawValue] : String()
		}
	}
	
	private let kToken = "Token"
	private let kLanguage = "Language"
	private let kSoundOff = "SoundOff"
	private let kSubscribed = "Subscribed"
	private let kInitialized = "Initialized"
	private let kPushTokenKey = "PushToken"
	
	static let shared = Settings()
	
	var initialized: Bool {
		get {
			return UserDefaults.standard.bool(forKey: kInitialized)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: kInitialized)
		}
	}
	
	var token: String? {
		get {
			return UserDefaults.standard.object(forKey: kToken) as? String
		}
		set {
			UserDefaults.standard.set(newValue, forKey: kToken)
		}
	}
	
	var language: Language {
		get {
			return Language(rawValue: UserDefaults.standard.integer(forKey: kLanguage)) ?? .english
		}
		set {
			UserDefaults.standard.set(newValue.rawValue, forKey: kLanguage)
		}
	}
	
	//NOTE: create setting such a way that default value does not need initialization
	var soundOff: Bool {
		get {
			return UserDefaults.standard.bool(forKey: kSoundOff)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: kSoundOff)
		}
	}
	
	var subscribed: Bool {
		get {
			return UserDefaults.standard.bool(forKey: kSubscribed)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: kSubscribed)
		}
	}
	
	var pushToken: String? {
		get {
			return UserDefaults.standard.string(forKey: kPushTokenKey)
		}
		set {
			UserDefaults.standard.set(newValue, forKey: kPushTokenKey)
			UserDefaults.standard.synchronize()
		}
	}
}
