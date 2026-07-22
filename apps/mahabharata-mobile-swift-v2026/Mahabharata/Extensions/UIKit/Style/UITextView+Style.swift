//
//  UITextField+Style.swift
//  UIKit+Extension
//
//  Created by Ilya Udovenko on 07 Sep 2018.
//
//  Copyright © 2017 Iron Water Studio. All rights reserved.

import UIKit

extension UITextView {
    struct Defaults {
        static var textColor: UIColor = .black
        static var textSize: CGFloat = 16.0
        static var borderWidth: CGFloat = 1
        static var alphaComponent: CGFloat = 0.5
    }
    
    convenience init(size: CGFloat = Defaults.textSize,
                     color: UIColor = Defaults.textColor) {
        self.init()
        if Defaults.borderWidth > 0 {
//            self.borderStyle = .line
            self.layer.borderWidth = Defaults.borderWidth
        }
        else {
//            self.borderStyle = .none
            self.layer.borderWidth = 0
        }
        self.font = UIFont.systemFont(ofSize: size)
        self.textColor = color
    }
    
    // MARK: - Experimental
	
    @discardableResult
    func color(_ color: UIColor) -> UITextView {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func keyboard(_ keyboardType: UIKeyboardType) -> UITextView {
        self.keyboardType = keyboardType
        return self
    }
    
    @discardableResult
    func secured(_ secured: Bool) -> UITextView {
        self.isSecureTextEntry = secured
        return self
    }
    
//    @discardableResult
//    func boarderStyle( _ borderStyle: UITextBorderStyle) -> UITextView {
//        self.borderStyle = borderStyle
//        return self
//    }
    
    @discardableResult
    func font(_ font: UIFont) -> UITextView {
        self.font = font
        return self
    }
    
    @discardableResult
    func capitalization(_ capitalization: UITextAutocapitalizationType) -> UITextView {
        self.autocapitalizationType = capitalization
        return self
    }
    
//    @discardableResult
//    func clearButton(_ mode: UITextFieldViewMode) -> Self {
//        self.clearButtonMode = mode
//        return self
//    }
    
    @discardableResult
    func apply(_ styleActions: (UITextView) -> ()...) -> UITextView {
        let actionsArray = Array(styleActions)
        self.apply(actionsArray)
        return self
    }
}
