//
//  GradientView+Extension.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 24/10/2019.
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//

import UIKit

extension GradientView {
	convenience init() {
		self.init(colors: [UIColor.gradientStart, UIColor.gradientEnd], direction: .vertical, frame: .zero)
	}
	
	convenience init(gradientStart: UIColor, gradientEnd: UIColor) {
		self.init(colors: [gradientStart, gradientEnd], direction: .vertical, frame: .zero)
	}
}
