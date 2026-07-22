//
//  UILabel+Style.swift
//  UIKit+Extension
//
//  Created by Mikhail Kulichkov on 20 Jun 2017.
//  Updated by Ilya Udovenko on 07 Sep 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//		07 Sep 2018. Ilya Udovenko.
//		7 Dec 2018. Olga Zhegulo:
//			* added setAttributedText() method
//		27 Dec 2018. Olga Zhegulo:
//			* renamed setAttributedText() to attributedText() method
//

import UIKit

extension UILabel {
	
    convenience init(_ text: String,
                     size: CGFloat = 16.0,
                     color: UIColor = .black) {
        self.init()
        
        self.text = text
        self.font = UIFont.systemFont(ofSize: size)
        self.textColor = color
        self.lineBreakMode = .byWordWrapping
    }
	
	convenience init(size: CGFloat) {
		self.init()
		self.font = UIFont.systemFont(ofSize: size)
	}
	
	 // MARK: - Constructors
	
	/// When used class name suffix for method then this method will be constructor
	/// NOTE: But class name suffix can be omitted, because jQuery way methods is instance methods, but constructor - is class mehtod
	/// NOTE: using class method instead of static method allow us to override it in inherited class.
	class func multiline(_ text: String = "", size: CGFloat = 16.0, color: UIColor = .black) -> UILabel {
		let label = UILabel(text, size: size, color: color)
		label.numberOfLines = 0
		return label
	}
	
	//TODO: WTF? should be jQuery way methods
	// MARK: - Extensions
	/*
	func setTextWhileKeepingAttributes(string: String) {
		if let newAttributedText = self.attributedText {
			let mutableAttributedText = newAttributedText.mutableCopy() as! NSMutableAttributedString
	
			mutableAttributedText.mutableString.setString(string)
	
			self.attributedText = mutableAttributedText as NSAttributedString
		}
	}
	*/
	
    // MARK: - Experimental
	
    @discardableResult
    func text(_ text: String) -> Self {
        self.text = text
        return self
    }
	
	@discardableResult
	func font(_ font: UIFont, size: CGFloat? = nil) -> Self {
		self.font = size != nil ? font.withSize(size!) : font
		return self
	}
	
	@discardableResult
	func font(_ name: String,_ size: CGFloat) -> Self {
		self.font = UIFont(name: name, size: size)
		return self
	}
	
    @discardableResult
    func color(_ color: UIColor) -> Self {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func size(_ textSize: CGFloat) -> Self {
        self.font = UIFont(name: self.font.fontName, size: textSize)
        return self
    }
    
    @discardableResult
    func alignment(_ newTextalignment: NSTextAlignment) -> Self {
        self.textAlignment = newTextalignment
        return self
    }
    
    @discardableResult
    func wrap(_ mode: NSLineBreakMode) -> Self {
        self.lineBreakMode = mode
        return self
    }
    
    @discardableResult
    func lines(_ lines: Int) -> Self {
        self.numberOfLines = lines
        return self
    }
	
	/// When used have method without class name suffix then such method used as jQuery-way method for class instance
	/// When multiline specified without arguments then well be used multiline style with 0 lines.
	@discardableResult
	func multiline(_ multiline: Bool = true, lines: Int = 1) -> Self {
		self.numberOfLines = multiline ? 0 : lines
		return self
	}
	
	@discardableResult
	func attributedText(_ string: String, attributes: [NSAttributedString.Key: Any]) -> Self {
		#if swift(>=4.0)
			self.attributedText = NSAttributedString(string: string, attributes: attributes)
		#else
			self.attributedText = NSAttributedString(string: string, attributes: attributes as [String: Any])
		#endif
		return self
	}

	@discardableResult
	func attributedText(_ attributedString: NSAttributedString) -> Self {
		self.attributedText = attributedString
		return self
	}
	
	@discardableResult
	func lineSpacing(_ spacing: CGFloat) -> Self {
		
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = spacing
		
		#if swift(>=4.0)
		let attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]
		#else
			let attributes: [String: Any] = [NSParagraphStyleAttributeName: paragraphStyle]
		#endif
		
		if let text = self.attributedText?.string, text.count > 0 {
			self.attributedText = NSAttributedString(string: text, attributes: attributes)
		} else {
			self.attributedText = NSAttributedString(string: " ", attributes: attributes)
		}
		
		return self
	}
	
	/*
	@discardableResult
	func size(_ layer: CALayer) -> Self {
		self.layer = layer
		return self
	}
	*/
    @discardableResult
	func apply(_ styleActions: (UILabel) -> ()...) -> UILabel {
		let actionsArray = Array(styleActions)
		self.apply(actionsArray)
		return self
	}
}
