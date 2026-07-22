//
//  UITabBar+Style.swift
//  UIKit+Extension
//
//  Created by Stanislav Grinberg on 30 Nov 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UITabBar {
	
	// MARK: - Experimental
	
	@discardableResult
	static func appearance(tintColor: UIColor = .white, unselectedTintColor: UIColor = .gray, barColor: UIColor = .blue, font: UIFont? = nil, action: ((UITabBar) -> ())? = nil) -> UITabBar {
		let appearance = UITabBar.appearance()
		
		// Default appearance...
		//appearance.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
		appearance.shadowImage = UIImage()
		appearance.isTranslucent = false
		appearance.clipsToBounds = false
		appearance.tintColor = tintColor
		appearance.barTintColor = barColor
		appearance.backgroundColor = barColor
		
		if #available(iOS 10.0, *) {
			appearance.unselectedItemTintColor = unselectedTintColor
		}
		
		if let action = action {
			action(appearance)
		}
		
		return appearance
	}
	
	@discardableResult
	func apply(action: (UITabBar) -> ()) -> UITabBar {
		action(self)
		return self
	}
	
}
