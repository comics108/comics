//
//  AppDelegate.swift
//  Mahabharata
//
//  Created by Roman Developer on 9/22/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import FacebookCore
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	enum pushType: Int {
		case none, quotes, comics, /*puzzle,*/ music
	}
	
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		//Controllers
		self.window = UIWindow(frame: UIScreen.main.bounds)
	
		//Initialize Facebook SDK
		ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

		//Initialize Firebase analytics
		FirebaseApp.configure()

		LocalizationManager.shared.defaultLanguageCode = "en"
		print("device: \(LocalizationManager.shared.currentlanguage(.device)), bundle:\(LocalizationManager.shared.currentlanguage(.bundle))")
		
		if !Settings.shared.initialized {
			//Set language of comics at first start of application
			let language: Settings.Language = LocalizationManager.shared.currentlanguage(.device) == "ru" ? .russian : .english
			Settings.shared.language = language
			Settings.shared.initialized = true
		}
		
		//Set the old token, since its valid to use it for request
		MahabharataRequestManager.token = Settings.shared.token
		
		//Remove all unfinished downlads & download info; stored download info does not allow to restart download
		clearUnfinishedDownloads()
		
//		RequestManager.sharedConfiguration.queue = DispatchQueue.global()
		
		if Settings.shared.token != nil {
			//Already have server token
			self.showInterface()
		} else {
			//Show splash until token not recieved (to avoid black screen when no internet at first start)
			self.window!.rootViewController = SplashViewController()
			self.window!.makeKeyAndVisible()
		}

		MahabharataRequestManager.updateDevice(deviceID: UIDevice.uniqueDeviceId!,
		                                     localTime: Date().timeIntervalSince1970,
		                                     success: { [weak self] (serverToken: String?) in
												guard let strongSelf = self else { return }
												
												if let token = serverToken {
													let tokenWasNil = Settings.shared.token == nil
													Settings.shared.token = token
													MahabharataRequestManager.token = token
													
													if tokenWasNil {
														strongSelf.showInterface()
													}
													
													// Try to register for notifications
													strongSelf.registerForPushNotifications()
												}
		},
		                                     error: { (error: RequestError) in
												print(error)
		})
		
		//Purchases
		InAppPurchaseManager.shared.registerForPaymentTransactions()
		
		return true
	}
	
	func clearUnfinishedDownloads() {
		//Stop infinished downloads, if applicationWillTerminate not called
		BackgroundDownloader.shared.cancelAll()
		
		//Remove all download info
		let defaults = UserDefaults.standard
		let keys = defaults.dictionaryRepresentation().keys
		for key in keys {
			if key.starts(with: MusicState.kMusicStateKey) || key.starts(with: EpisodeState.kEpisodeStateKey) {
				let data = UserDefaults.standard.object(forKey: key) as! Data?
				
				if key.starts(with: EpisodeState.kEpisodeStateKey) {
					if let data = data,
						let episodeState = NSKeyedUnarchiver.unarchiveObject(with: data) as? EpisodeState {
						
						episodeState.downloadInfo = nil
						
						//If unpacking was not finished, reset downloaded flag, because files cannot be used
						if episodeState.isUnpacking {
							episodeState.isUnpacking = false
							episodeState.isDownloaded = false
						}
						episodeState.save()
					}
				} else {
					if let data = data,
						let musicState = NSKeyedUnarchiver.unarchiveObject(with: data) as? MusicState {
						
						musicState.downloadInfo = nil
						musicState.save()
					}
				}
			}
		}
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		
		//Activate Facebook events
		AppEvents.activateApp()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		
		//Purchases
		InAppPurchaseManager.shared.unregisterForPaymentTransactions()
		
		//Stop infinished downloads
		BackgroundDownloader.shared.cancelAll()
	}
	
	//Is required for deferred deep linking to work correctly
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		return ApplicationDelegate.shared.application(
			app,
			open: url,
			options: options
		)
	}
	
	// MARK: - Push notifications
	
	func registerForPushNotifications() {
		UNUserNotificationCenter.current()
			.requestAuthorization(options: [.alert, .sound, .badge]) {
				[weak self] granted, error in
				
				print("Permission granted: \(granted)")
				guard granted else { return }
				self?.getNotificationSettings()
		}
	}
	
	func getNotificationSettings() {
	  UNUserNotificationCenter.current().getNotificationSettings { settings in
		print("Notification settings: \(settings)")
		  guard settings.authorizationStatus == .authorized else { return }
		  DispatchQueue.main.async {
			UIApplication.shared.registerForRemoteNotifications()
		  }
	  }
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		let oldToken = Settings.shared.pushToken
		
		if oldToken == nil || (oldToken != nil && oldToken! != token) {
			MahabharataRequestManager.updatePushToken(with: token,
													success: {
														DispatchQueue.main.async {
															Settings.shared.pushToken = token
														}
			},
													error: { (err) in
														DispatchQueue.main.async {
															Settings.shared.pushToken = nil
														}
			})
		}
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		Settings.shared.pushToken = nil
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		self.handlePushNotification(userInfo, needNavigate: application.applicationState != .active)
	}
	
	func handlePushNotification(_ userInfo: [AnyHashable : Any]?, needNavigate: Bool) {
		
		guard let userInfo = userInfo else { return	}
		
		if let data = userInfo["data"] as? [String: Any],
			let type = data["type"] as? Int,
			let tab = pushType(rawValue: type) {
			
			if needNavigate, 
				let tabBarController = self.window!.rootViewController as? UITabBarController {
				
				switch tab {
				case .comics:
					tabBarController.selectedIndex = 0
				case .quotes:
					tabBarController.selectedIndex = 1
//				case .puzzle:
//					tabBarController.selectedIndex = 2
				case .music:
//					tabBarController.selectedIndex = 3
					tabBarController.selectedIndex = 2
				default:
					tabBarController.selectedIndex = 0
				}
			}
		}
	}
}

extension AppDelegate {

    func showInterface() {
        UINavigationBar.appearance(
            tintColor: .yellow1,
            barColor: .maroon1,
            font: UIFont.regular(ofSize: 18)
        )
        UITabBar.appearance(
            tintColor: .white,
            unselectedTintColor: .inactiveYellow,
            barColor: .maroon1,
            font: UIFont.regular(ofSize: 18)
        )
        let rootViewController = SeasonsViewController()
        rootViewController.seasonsCache = SeasonsCacher()
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.backgroundColor = .maroon1
        window?.makeKeyAndVisible()
    }
}
