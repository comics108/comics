//
//  GradientButton.swift
//  GradientView
//
//  Created by Olga Zhegulo on Feb 20 2019.
//  Based on: Neftmagistral
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//
//  Dependencies:
//      system: UIKit
//

import UIKit

class GradientButton: UIButton {
	
	var colors: [UIColor] = [] {
		didSet {
			gradientView.colors = colors
		}
	}
	
	private let gradientView: GradientView
	
	init(colors: [UIColor], direction: GradientView.GradientDirection = .horizontal, frame: CGRect = .zero) {
		
		self.gradientView = GradientView(colors: colors, direction: direction, frame: frame)
		super.init(frame: frame)
		
		self.addSubviews(gradientView)
		self.sendSubviewToBack(gradientView)
		gradientView.isUserInteractionEnabled = false

		activateConstraints(
			gradientView.edges()
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.gradientView = GradientView(colors: [.clear])
		super.init(coder: aDecoder)
	}
}
