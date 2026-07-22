//
//  GradientView.swift
//  GradientView
//
//  Created by Olga Zhegulo on Feb 20 2019.
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//  Based on: EstelColorMaster
//
//  Dependencies:
//      system: UIKit
//

import UIKit

class GradientView: UIView {
	public enum GradientDirection : Int {
		case horizontal
		case vertical
	}

	/// List of colors
	var colors: [UIColor] = [] {
		didSet {
			if let gl = layer as? CAGradientLayer {
				gl.colors = colors.map() { $0.cgColor }
				self.setNeedsDisplay()
			}
		}
	}
	
	/// Gradients from left to right, from top to bottom
	init(colors: [UIColor], direction: GradientDirection = .horizontal, frame: CGRect = .zero) {
		super.init(frame: frame)
		
		let gl = layer as! CAGradientLayer
		if direction == .horizontal {
			gl.startPoint = CGPoint(x: 0, y: 0)
			gl.endPoint = CGPoint(x: 1, y: 1)
		} else {
			gl.startPoint = CGPoint(x: 0, y: 0)
			gl.endPoint = CGPoint(x: 0, y: 1)
		}
		gl.colors = colors.map() { $0.cgColor }
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// https://stackoverflow.com/questions/24351102/how-do-you-override-layerclass-in-swift
	// https://medium.com/@abhimuralidharan/method-swizzling-in-ios-swift-1f38edaf984f
	// https://www.iosdev.recipes/uiview/apis-you-forgot-layerclass-maskView-and-uitintadjustmentmode/
	// https://dzone.com/articles/calayer-and-auto-layout-with-swift-1
	override public class var layerClass: AnyClass {
		get {
			return CAGradientLayer.self
		}
	}
}
