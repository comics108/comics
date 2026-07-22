//
//  UIApplication+Extension.swift
//  UIApplication+Extension
//
//  Created by Ilya Udovenko on 04 Dec 2018.
//  Updated by Olga Zhegulo on 27 Dec 2018.
//
//  Changes history:
//		26 Dec 2018. Vasiliy Ursu:
//			* Added appName method.
//		27 Dec 2018. Olga Zhegulo:
//			* fix openUrl(...): use completion inside.
//
//	Dependencies:
//
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
// For SFSafatiViewController
import SafariServices

extension UIApplication {
	
	typealias OpenUrlBlock = (Bool) -> ()
	
	private enum Constants {
		static let versionKey: String = "CFBundleShortVersionString"
		static let buildKey: String = String(kCFBundleVersionKey)
	}
	
	// MARK: - Build & Version
	
	static var appName: String? {
		if let appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String, appName.count > 0 {
			return appName
		} else if let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String, appName.count > 0 {
			return appName
		}  else if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String, appName.count > 0 {
			return appName
		}
		return nil
	}
	
	static var appVersion: String? {
		return Bundle.main.object(forInfoDictionaryKey: Constants.versionKey) as? String
	}
	
	static var appBuild: String? {
		return Bundle.main.object(forInfoDictionaryKey: Constants.buildKey) as? String
	}
	
	// MARK: - Settings & URL
	
	static func openUrl(_ url: URL, controller vc: UIViewController? = nil, completion: OpenUrlBlock? = nil) {
		if #available(iOS 10.0, *) {
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url, options: [:], completionHandler: completion)
			} else if let vc = vc {
				let svc = SFSafariViewController(url: url)
				svc.present(vc, animated: true, completion: { completion?(true) })
			}
		} else {
			// Fallback on earlier versions
			if UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.openURL(url)
				completion?(true)
			} else if let vc = vc {
				let svc = SFSafariViewController(url: url)
				svc.present(vc, animated: true, completion: { completion?(false) })
			}
		}
	}
	
	/// Checking that we can open Application Settings
	static func canOpenSettings() -> Bool {
		if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
			return true
		}
		return false
	}
	
	/// Check and try open Application Settings
	static func openSettings(completion: OpenUrlBlock? = nil) {
		if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
			if #available(iOS 10.0, *) {
				// iOS 10 specific stuff here
				UIApplication.shared.open(settingsUrl, options: [:], completionHandler: completion)
			} else {
				// non iOS 10 stuff here
				let openUrlResult = UIApplication.shared.openURL(settingsUrl)
				if let completion = completion {
					completion(openUrlResult)
				}
			}
		}
	}
	
	// MARK: - Navigation
	
	static func topViewController(_ rootViewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
		if let presentedVC = rootViewController?.presentedViewController {
			return self.topViewController(presentedVC)
		} else if let navVC = rootViewController as? UINavigationController {
			if navVC.viewControllers.count > 0 {
				if let topVC = navVC.topViewController {
					return self.topViewController(topVC)
				}
			}
		} else if let tabVC = rootViewController as? UITabBarController {
			if let count = tabVC.viewControllers?.count, count > 0 {
				if let selectedVC = tabVC.selectedViewController {
					return self.topViewController(selectedVC)
				}
			}
		} else if let splitVC = rootViewController as? UISplitViewController {
			if let lastVC = splitVC.viewControllers.last {
				return self.topViewController(lastVC)
			}
		}
		return rootViewController
	}
}


