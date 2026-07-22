//
//  AnalyticsCustomEvents.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 28/10/2019.
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//

import Foundation

struct AnalyticsCustomEvents {
	//Each struct is categroy of events
	struct Episode {
		//in_app_purchase - автоматическое
		
		//Восстановление покупок restore_purchases product_ids
		static let restorePurchases = "restore purchases"

		//download_episode episode_name
		static let download = "download_episode"
		
		//update_episode episode_name old_version new_version
		static let update = "update_episode"
		
		//delete_episode episode_name
		static let Delete = "delete_episode"

		//Открыт эпизод select_content episode_name
		static let open = "open_episode"
		
		//Выход с экрана эпизода exit_episode episode_name scroll_percent
		static let exit = "exit_episode"
		
		//Переход к следующему go_to_next_episode episode_name
		static let goToNext  = "go_to_next_episode"
		
		//share_episode episode_name
		static let share = "share_episode"
	}

	struct Quote {
		//share_quote
		static let share = "share_quote"
	}
	
	struct Language {
		//Изменение языка комикса change_language language
		static let changeLanguage = "change_language"
	}
	
	struct Sound {
		static let selectMusic = "select_music"
	}
}

struct AnalyticsParameters {
	//For episode* and sound*
	static let name = "name"
	
	//For exit_episode
	static let scrollPercent = "scroll_percent"
	
	//For episode_update
	static let oldVersion = "old_version"
	static let newVersion = "new_version"
	
	//For change_language
	static let language = "language"
	
	//For restore_purchases
	static let productIds = "product_ids"
}
