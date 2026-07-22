//
//  UIButton+Style+Mahabharata.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 16/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

extension UIButton {
	static func languageButton() -> UIButton {
		UIButton(type: .custom)
			.color(.rgba(245,223,184,0.3)).color(.yellow1, for: .selected)
			.font(UIFont.semibold(ofSize: 16)).background(.clear)
	}
	
	static func greenButton() -> UIButton {
		UIButton(.darkGreen)
            .font(UIFont.semibold(ofSize: 11))
            .color(.white)
            .borderColor(.yellow1)
            .corners(4)
            .clip()
	}
}
