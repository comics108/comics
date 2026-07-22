//
//  RequestManager+UserAgent.swift
//  RequestManager+UserAgent
//
//  Created by Stanislav.Grinberg on 30/03/2018.
//	Updated by Andrey Kozlov on 17 Dec 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
// 	Changes history:
// 		17 Dec 2018. Andrey Kozlov:
//			* added UIApplication+Extension
//			* change appVersion
//

import UIKit

extension BaseRequestManager: UserAgentProtocol {
	
	/** PackageName/AppVersion (model; os_name os_version)
	- Example: "ru.pikabu.android/1.4.7 (MI 5; Android 6.0.1)"
	- Example: "ru.tomatopizza.tomato/1.0.0 (iPhone X; iOS 11)", "ru.tomatopizza.terminal/2.1.0 (iPhone 8; iOS 11)"
	*/
	func getUserAgent() -> String {
		let packageName = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as! String
		let appVersion: String = UIApplication.appVersion ?? ""
		return "\(packageName)/\(appVersion) (\(UIDevice.deviceName); iOS \(UIDevice.iOSVersion))"
	}
	
}
