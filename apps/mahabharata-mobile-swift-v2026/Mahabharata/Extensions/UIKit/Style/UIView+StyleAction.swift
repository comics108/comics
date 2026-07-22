//
//  UIView+StyleAction.swift
//  UIKit+Extension
//
//  Created by Mikhail Kulichkov on 30 Jun 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

// FIXME: Find a way to provide type in call-time for anonymous untyped closures as parameters
extension UIView {
	
    convenience init(_ color: UIColor) {
        self.init()
        self.background(color)
    }
    
	func addSubviews(_ views: UIView...) {
		views.forEach(addSubview)
	}
	
	// MARK: - Experimental
	
	@discardableResult
	func background(_ color: UIColor) -> Self {
		self.backgroundColor = color
		return self
	}
	
	@discardableResult
	func isHidden(_ hide: Bool) -> Self {
		self.isHidden = hide
		return self
	}
	
	@discardableResult
	func contentMode(_ mode: UIView.ContentMode) -> Self {
		self.contentMode = mode
		return self
	}

	@discardableResult
	func alpha(_ value: CGFloat) -> Self {
		self.alpha = value
		return self
	}
	
	@discardableResult
	func clip(_ enabled: Bool = true) -> Self {
		self.clipsToBounds = enabled
		return self
	}
	
	@discardableResult
	func corners(_ radius: CGFloat) -> Self {
		self.layer.cornerRadius = radius
		return self
	}
	
	@discardableResult
	func shadowRasterize(_ value: Bool) -> Self {
		self.layer.shouldRasterize = value
		return self
	}
	
	@discardableResult
	func gradient(frame: CGRect, startColor: UIColor, finishColor: UIColor) -> Self {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [startColor.cgColor, finishColor.cgColor]
		gradientLayer.bounds = frame
		
		self.layer.addSublayer(gradientLayer)
		
		return self
	}
	
	@discardableResult
	func borderColor(_ color: UIColor, width: CGFloat = 1.0) -> Self {
		if self.layer.borderWidth == 0 {
			self.layer.borderWidth = width
		}
		
		self.layer.borderColor = color.cgColor
		return self
	}
	
    @discardableResult
    func apply<T>(_ styleActions: [(T) -> ()]) -> T {
        for action in styleActions {
            action(self as! T)
        }
        return self as! T
    }
	
}
    
