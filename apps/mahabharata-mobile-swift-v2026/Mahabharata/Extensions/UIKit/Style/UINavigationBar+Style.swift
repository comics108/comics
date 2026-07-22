//
//  UINavigationBar+Style.swift
//  UIKit+Extension
//
//  Created by Stanislav Grinberg on 14 Jul 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UINavigationBar {
	
	 // MARK: - Experimental
	
	@discardableResult
	static func appearance(tintColor: UIColor = .white, barColor: UIColor = .blue, font: UIFont? = nil, action: ((UINavigationBar) -> ())? = nil) -> UINavigationBar {
		let appearance = UINavigationBar.appearance()
		
		// Default appearance...
		appearance.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
		appearance.shadowImage = UIImage()
		appearance.isTranslucent = false
		appearance.clipsToBounds = false
		appearance.tintColor = tintColor
		appearance.barTintColor = barColor
		appearance.backgroundColor = barColor
		
		#if swift(>=4.0)
		var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: tintColor]
			if let font = font {
				attributes[.font] = font
			}
		#else
			var attributes: [String: Any] = [NSForegroundColorAttributeName: tintColor]
			if let font = font {
				attributes[NSFontAttributeName] = font
			}
		#endif
		
		appearance.titleTextAttributes = attributes
		
		if let action = action {
			action(appearance)
		}
		
		return appearance
	}
	
	
    @discardableResult
    func apply(action: (UINavigationBar) -> ()) -> UINavigationBar {
        action(self)
        return self
    }
    
}

