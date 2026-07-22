//
//  UIBarButtonItem+Style.swift
//  UIKit+Extension
//
//  Created by Stanislav Grinberg on 19 Jul 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
	
	// MARK: - Experimental

	@discardableResult
    static func appearance(imageName: String? = "", action: ((UIBarButtonItem) -> ())? = nil) -> UIBarButtonItem {
		let appearance = UIBarButtonItem.appearance()
		
		// Default appearance...
		appearance.setBackButtonTitlePositionAdjustment(UIOffset(horizontal: 0, vertical: -1000), for: .default)
        
        if let imageName = imageName, let image = UIImage(named: imageName) {
            let bkgImage = image.resizableImage(withCapInsets: UIEdgeInsets(top: 0.0, left: image.size.width - 1.0, bottom: 0.0, right: 0.0))
            appearance.setBackButtonBackgroundImage(bkgImage, for: .normal, barMetrics: .default)
        }
        
        action?(appearance)
        
		return appearance
	}
	
	@discardableResult
	func apply(action: (UIBarButtonItem) -> ()) -> UIBarButtonItem {
		action(self)
		return self
	}
    
//	@discardableResult
//	func image(_ image: UIImage) -> Self {
//		let bkgImage = image.resizableImage(withCapInsets: UIEdgeInsets(top: 0.0, left: image.size.width - 1.0, bottom: 0.0, right: 0.0))
//		self.setBackButtonBackgroundImage(bkgImage, for: .normal, barMetrics: .default)
//		return self
//	}

}
