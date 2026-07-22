//
//  UIFont+Style+Mahabharata.swift
//  Mahabharata
//
//  Created by Roman Developer on 7/19/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIFont {

	//Proxima Nova
	//["ProximaNova-Light", "ProximaNova-Semibold", "ProximaNovaT-Thin", "ProximaNova-Bold", "ProximaNova-Regular"]
	
	static func light(ofSize size: CGFloat) -> UIFont {
		return UIFont(name: "ProximaNova-Light", size: size)!
	}
	
	static func semibold(ofSize size: CGFloat) -> UIFont {
		return UIFont(name: "ProximaNova-Semibold", size: size)!
	}
	
	static func thin(ofSize size: CGFloat) -> UIFont {
		return UIFont(name: "ProximaNovaT-Thin", size: size)!
	}
	
	static func bold(ofSize size: CGFloat) -> UIFont {
		return UIFont(name: "ProximaNova-Bold", size: size)!
	}
	
	static func regular(ofSize size: CGFloat) -> UIFont {
		return UIFont(name: "ProximaNova-Regular", size: size)!
	}
}
