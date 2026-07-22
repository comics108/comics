//
//  UIColor+Style.swift
//  UIKit+Extension
//
//  Created by Alexander Popov on 07 Jun 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIColor {
	
	// MARK: - Extensions
	
	func components() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
		var r :CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		self.getRed(&r, green: &g, blue: &b, alpha: &a)
		
		return (r, g, b, a)
	}
	
	// MARK: - Constructors
	
	static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) -> UIColor {
		return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
	}
	
	// MARK: - Experimental
	
	@discardableResult
	func red(_ red: CGFloat) -> UIColor {
		let parts = components()
		
		return UIColor(red: red / 255.0,  green: parts.green, blue: parts.blue, alpha: parts.alpha)
	}
	
	@discardableResult
	func green(_ green: CGFloat) -> UIColor {
		let parts = components()
		
		return UIColor(red: parts.red, green: green / 255.0, blue: parts.blue, alpha: parts.alpha)
	}
	
	@discardableResult
	func blue(_ blue: CGFloat) -> UIColor {
		let parts = components()
		
		return UIColor(red: parts.red, green: parts.green, blue: blue / 255.0, alpha: parts.alpha)
	}
	
	@discardableResult
	func alpha(_ alpha: CGFloat) -> UIColor {
		let parts = components()
		
		return UIColor(red: parts.red, green: parts.green, blue: parts.blue, alpha: alpha)
	}
	
	// create brush with pattern image
	@discardableResult
	func pattern(_ image: UIImage) -> UIColor {
		return UIColor(patternImage: image)
	}
	
	// create brush with pattern image
	@discardableResult
	func pattern(imageName: String) -> UIColor? {
		guard let img = UIImage(named: imageName) else { return nil }
		
		return UIColor(patternImage: img)
	}

}
