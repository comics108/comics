//
//  UIImageView+Style.swift
//  UIKit+Extension
//
//  Created by Olga Zhegulo on 1 Aug 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//
//  Dependencies:
//  	UIKit

import UIKit

extension UIImageView {
	
	// MARK: - Experemental
	
	/**
	Makes UIImageView the same color as the specified color.
	Based on solution https://bencoding.com/2015/07/30/how-to-tint-an-uiimageview-image/
	- Warning:
	UIImageView image should be set before using this method.
	If you change imageView.image, you should call this method again.
	*/
	@discardableResult
	func tintImageColor(color: UIColor) -> Self {
		if let image = self.image {
			self.image = image.withRenderingMode(.alwaysTemplate)
			self.tintColor = tintColor
		}
		return self
	}
}
