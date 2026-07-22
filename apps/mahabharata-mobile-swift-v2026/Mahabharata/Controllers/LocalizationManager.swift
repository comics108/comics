//
//  LocalizationManager.swift
//  Gita
//
//  Created by Olga Zhegulo  on 30/05/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import Foundation

final class LocalizationManager {
	enum LanguagePriority {
		case device
		case bundle
	}
	
	static let shared = LocalizationManager()
	
	var defaultLanguageCode: String = "en"
	
	func currentlanguage(_ priority: LanguagePriority) -> String
	{
		//Priority is language of application
		var currLang: String?
			
		if priority == .bundle {
			//Bundle localization that is corresponding to device language
			currLang = Bundle.main.preferredLocalizations.first
			
			if String.isNilOrEmpty(currLang) {
				currLang = Locale.current.languageCode
			}
		} else {
			//Current device language
			currLang = Locale.current.languageCode
			
			if String.isNilOrEmpty(currLang) {
				currLang = Bundle.main.preferredLocalizations.first
			}
		}

		return currLang ?? defaultLanguageCode
	}
}
