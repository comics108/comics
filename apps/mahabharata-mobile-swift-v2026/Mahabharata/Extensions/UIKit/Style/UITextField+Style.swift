//
//  UITextField+Style.swift
//  UIKit+Extension
//
//  Created by Mikhail Kulichkov on 26 Jun 2017.
//  Updated by Ilya Udovenko on 12 Sep 2018.
//
//  Update history:
//      * 07 Sep 2018 by Vasiliy Ursu: added defaults + new placeholder method logic
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

extension UITextField {
	
    struct Defaults {
        static var textColor: UIColor = .black
        static var textSize: CGFloat = 16.0
        static var placeholder: String = ""
        static var borderWidth: CGFloat = 1
        static var alphaComponent: CGFloat = 0.5
    }
    
    convenience init(placeholder: String?,
                     size: CGFloat = Defaults.textSize,
                     color: UIColor = Defaults.textColor) {
        self.init()
        if Defaults.borderWidth > 0 {
            self.borderStyle = .line
            self.layer.borderWidth = Defaults.borderWidth
        }
        else {
            self.borderStyle = .none
            self.layer.borderWidth = 0
        }
        self.font = UIFont.systemFont(ofSize: size)
        self.textColor = color
        self.placeholder(placeholder)
    }
    
    // MARK: - Experimental
    @discardableResult
    func color(_ color: UIColor) -> UITextField {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func placeholderColor(_ color: UIColor) -> Self {
        guard let placeholder = self.attributedPlaceholder?.string else { return self }
        
        #if swift(>=4.0)
		let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        #else
        let attributes: [String: Any] = [NSForegroundColorAttributeName: color]
        #endif
        
        self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
        return self
    }
    
    @discardableResult
    func keyboard(_ keyboardType: UIKeyboardType) -> UITextField {
        self.keyboardType = keyboardType
        return self
    }
    
    @discardableResult
    func secured(_ secured: Bool) -> UITextField {
        self.isSecureTextEntry = secured
        return self
    }
    
    @discardableResult
	func boarderStyle( _ borderStyle: UITextField.BorderStyle) -> UITextField {
        self.borderStyle = borderStyle
        return self
    }
    
    @discardableResult
    func font(_ font: UIFont) -> UITextField {
        self.font = font
        return self
    }
    
    @discardableResult
    func alignment(_ newTextalignment: NSTextAlignment) -> Self {
        self.textAlignment = newTextalignment
        return self
    }
    
    /**
     Setting placeholder text and applyies placeholder color by textColor with using alpha settings.
     - Parameters:
     - text: New placeholder  value. When it is not specified, i.e. nil then previous stored value should be used.
     - Note: When by validation changed text color we can call this method without any arguments and placeholder color will be applied.
     */
    @discardableResult
    func placeholder(_ text: String? = nil) -> UITextField {
        let value = text ?? self.placeholder
        if let value = value {
            let color = self.textColor ?? Defaults.textColor
            #if swift(>=4.0)
			let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color.withAlphaComponent(Defaults.alphaComponent)]
            #else
            let attributes: [String: Any] = [NSForegroundColorAttributeName: color.withAlphaComponent(Defaults.alphaComponent)]
            #endif
            self.attributedPlaceholder = NSAttributedString(string: value, attributes: attributes)
        }
        return self
    }
    
    @discardableResult
    func capitalization(_ capitalization: UITextAutocapitalizationType) -> UITextField {
        self.autocapitalizationType = capitalization
        return self
    }
    
    @discardableResult
	func clearButton(_ mode: UITextField.ViewMode) -> Self {
        self.clearButtonMode = mode
        return self
    }
    
    @discardableResult
    func hideCursor() -> Self {
        self.tintColor = .clear
        return self
    }
    
    @discardableResult
    func apply(_ styleActions: (UITextField) -> ()...) -> UITextField {
        let actionsArray = Array(styleActions)
        self.apply(actionsArray)
        return self
    }
}
