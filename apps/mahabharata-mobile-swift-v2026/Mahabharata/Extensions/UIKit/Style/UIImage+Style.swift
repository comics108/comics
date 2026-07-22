//
//  UIImage+Style.swift
//  UIKit+Extension
//
//  Created by Stanislav Grinberg on 20 Jul 2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIImage {
	
	// MARK: - Constructors
	
	@discardableResult
	static func adjusted(name: String, suffix: String? = nil) -> UIImage? {
		let height = Int(max(UIScreen.main.nativeBounds.height, UIScreen.main.nativeBounds.width) / UIScreen.main.scale)
		let result: UIImage?
		
		// Suffixes @2x and @3x removed manually because imageNamed know what scale we needed
		switch height {
		case 480:
			result = UIImage(named: name)
		case 568, 667, 736, 812:
			result = UIImage(named: "\(name)-\(height)h")
		default:
			result = UIImage(named: name)
		}
		
		return result ?? UIImage(named: "\(name)\(suffix ?? "")")
	}
	
	// MARK: - Experimental
	
}
