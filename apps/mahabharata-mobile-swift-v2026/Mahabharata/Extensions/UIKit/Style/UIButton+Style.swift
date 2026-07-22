//
//  UIButton+Style.swift
//  UIKit+Extension
//
//  Created by Mikhail Kulichkov on 26 Jun 2017.
//  Updated by Vasiliy Ursu on 20 Feb 2019.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//		20 Feb 2019. Vasiliy Ursu:
//			* added button type .system by default
//

import UIKit

extension UIButton {
	private static let kImageHighlitedPostfix: String = "_pressed"
	
	// TODO: add new  signature for combine target + selector args (closure)
    convenience init(target: Any? = nil,
                     selector: Selector?,
					 type: UIButton.ButtonType = .system,
                     title: String = "",
                     size: CGFloat = 16.0,
                     color: UIColor = .black,
                     iconName: String? = nil,
                     bkgName: String? = nil) {
		self.init(type: type)
        
        self.titleLabel?.font = UIFont.systemFont(ofSize: size)
        self.setTitleColor(color, for: .normal)
		
		if let icon = iconName {
        	self.setImage(UIImage(named: icon), for: .normal)
		}
        
        // Setting capinsets of background
		var bkgImage: UIImage?
		var bkgImageHighlighted: UIImage?
		if let bkgImageName = bkgName {
       		bkgImage = UIImage(named: bkgImageName)
			bkgImageHighlighted = UIImage(named: bkgImageName + UIButton.kImageHighlitedPostfix)
		}
		
        // Counting insets for resizing image
        var capInsets = UIEdgeInsets.zero
        if let notNilImage = bkgImage {
            let halfWidth = CGFloat(Int(notNilImage.size.width / 2))
            let halfHeight = CGFloat(Int(notNilImage.size.height / 2))
            capInsets = UIEdgeInsets(top: halfHeight - 1.0, left: halfWidth - 1.0, bottom: halfHeight - 1.0, right: halfWidth - 1.0)
        }
		if let bkgImage = bkgImage {
        	self.setBackgroundImage(bkgImage.resizableImage(withCapInsets: capInsets), for: .normal)
		}
		if let bkgImageHighlighted = bkgImageHighlighted {
        	self.setBackgroundImage(bkgImageHighlighted.resizableImage(withCapInsets: capInsets), for: .highlighted)
		}
        
        if let selector = selector {
            self.addTarget(target, action: selector, for: .touchUpInside)
        }
        self.setTitle(title, for: .normal)
    }
	
	// MARK: - Constructors

	static func colored(target: Any, selector: Selector, bkgColor: UIColor) -> UIButton {
		//return UIButton(target: target, selector: selector).bkgImage(ImageManager.solid(color: bkgColor, size: CGSize(width: 1.0, height: 1.0)), for: .normal)
		return UIButton(target: target, selector: selector).background(bkgColor)
	}
	
//	static func hyperlink(target: Any, selector: Selector, title: String = "" , size: CGFloat = 20.0, color: UIColor = .black) -> UIButton {
//		return UIButton(target: target, selector: selector, color: color).apply {
//			let underlineAttributes: [String: Any] = [
//				NSFontAttributeName : UIFont.systemFont(ofSize: 16),
//				NSForegroundColorAttributeName : UIColor.white,
//				NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue
//			]
//			$0.setAttributedTitle(NSMutableAttributedString(string: title, attributes: underlineAttributes), for: .normal)
//			$0.alpha = 0.5
//		}
//	}
	
	static func hyperlink(target: Any, selector: Selector, title: String = "" , font: UIFont = UIFont.systemFont(ofSize: 20.0), color: UIColor = .black) -> UIButton {
		return UIButton(target: target, selector: selector, color: color).apply {
			#if swift(>=4.0)
			let underlineAttributes: [NSAttributedString.Key: Any] = [
					.font: font,
					.foregroundColor: color,
					.underlineStyle: NSUnderlineStyle.single.rawValue
				]
			#else
				let underlineAttributes: [String: Any] = [
					NSFontAttributeName: font,
					NSForegroundColorAttributeName: color,
					NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle
				]
			#endif
			
			$0.setAttributedTitle(NSMutableAttributedString(string: title, attributes: underlineAttributes), for: .normal)
		}
	}
	
    // MARK: - Experimental
	
	@discardableResult
	func tag(_ tag: Int) -> Self {
		self.tag = tag
		return self
	}
	
	@discardableResult
	func background(_ image: UIImage, for state: UIControl.State = .normal) -> Self {
		self.setBackgroundImage(image, for: state)
		return self
	}
	
	@discardableResult
	func foreground(_ image: UIImage, for state: UIControl.State = .normal) -> Self {
		self.setImage(image, for: state)
		return self
	}
	
	@discardableResult
	func title(_ title: String?, for state: UIControl.State = .normal) -> Self {
		self.setTitle(title, for: state)
		return self
	}
	
	@discardableResult
	func font(_ font: UIFont, size: CGFloat? = nil) -> Self {
		self.titleLabel?.font = size != nil ? font.withSize(size!) : font
		return self
	}
	
	@discardableResult
	func font(_ name: String,_ size: CGFloat) -> Self {
		self.titleLabel?.font = UIFont(name: name, size: size)
		return self
	}
	
    @discardableResult
    func titleSize(_ size: CGFloat) -> Self {
        if let fontName = self.titleLabel?.font.fontName {
            self.titleLabel?.font = UIFont(name: fontName, size: size)
        } else {
            self.titleLabel?.font = UIFont.systemFont(ofSize: size)
        }
        return self
    }
    
    @discardableResult
	func color(_ color: UIColor, for state: UIControl.State = .normal) -> Self {
        self.setTitleColor(color, for: state)
        return self
    }
    
    @discardableResult
    func isEnabled(_ enabled: Bool) -> Self {
        self.isEnabled = enabled
        return self
    }
    
	@discardableResult
	func apply(_ styleActions: (UIButton) -> ()...) -> UIButton {
		let actionsArray = Array(styleActions)
		self.apply(actionsArray)
		return self
	}
	
}
