//
//  UIColor+Hex.swift
//  UIKit+Extension
//
//  Created by Denis on 1 Nov 2016.
//  Updated by Olga Zhegulo on 9 Jul 2018.
//  Copyright © 2016 IronWaterStudio. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
	
	convenience init(hexString: String) {
		var rgbValue: UInt32 = 0
		
		let scanner = Scanner(string: hexString)
		/// Bypass '#' character
		scanner.scanLocation = 1
		scanner.scanHexInt32(&rgbValue)
		
		self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
				  green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
				  blue: CGFloat(rgbValue & 0xFF) / 255.0,
				  alpha: 1.0)
	}	
}
