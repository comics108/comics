//
//  UIFont+Style.swift
//  UIKit+Extension
//
//  Created by Stanislav Grinberg on 19 Jul 2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIFont {
	
	// MARK: - Extensions
	
	/*
	open class func systemFont(ofSize fontSize: CGFloat) -> UIFont
	open class func boldSystemFont(ofSize fontSize: CGFloat) -> UIFont
	open class func italicSystemFont(ofSize fontSize: CGFloat) -> UIFont
	*/
	static func printAll() {
		for name in UIFont.familyNames {
			print(name, UIFont.fontNames(forFamilyName: name))
		}
	}
	
	// MARK: Experimental

	// TODO: uncomment this block and implement font creation by types for your project
//	open func regular(ofSize fontSize: CGFloat) -> UIFont? {
//		return UIFont.systemFont(ofSize: fontSize)
//	}
//	
//	open func bold(ofSize fontSize: CGFloat) -> UIFont? {
//		return UIFont.boldSystemFont(ofSize: fontSize)
//	}
//	
//	open func italic(ofSize fontSize: CGFloat) -> UIFont? {
//		return UIFont.italicSystemFont(ofSize: fontSize)
//	}

}
