//
//  UIView+ActivityIndicator2.swift
//  Tomato
//
//  Created by Konstantin Oznobikhin on 13/05/16.
//  Copyright © 2016 IronWaterStudio. All rights reserved.
//
//      11 Mar 2019 by Ilya Udovenko:
//      * Add inline and overlap activity mode, custom view instead activity indicator, offset

import UIKit

private var kActivityLock = 0
private var kActivityIndicatorView = 0
private var kActivityIndicatorViewCount = 0

public extension UIView {
    enum ActivityMode {
        //window
        //case overlay
        //superview/parent
        case overlap
        //subview/child
        case inline
    }
    
	private var activityLock: NSObject {
		get {
			let obj = objc_getAssociatedObject(self, &kActivityLock) as? NSObject
			if let obj = obj {
				return obj
			}
			
			let lock = NSObject()
			objc_setAssociatedObject(self, &kActivityLock, lock, .OBJC_ASSOCIATION_RETAIN)
			
			return lock
		}
	}
	
	private var activityView: UIView? {
		get {
			return objc_getAssociatedObject(self, &kActivityIndicatorView) as? UIView
		}
		set {
			objc_setAssociatedObject(self, &kActivityIndicatorView, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	private var activityViewCount: Int {
		get {
			let value = objc_getAssociatedObject(self, &kActivityIndicatorViewCount) as? Int
			if let value = value {
				return value
			}
			
			return 0
		}
		set {
			objc_setAssociatedObject(self, &kActivityIndicatorViewCount, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
	
	func hideActivityIndicator() {
		objc_sync_enter(self.activityLock)
		defer {
			objc_sync_exit(self.activityLock)
		}
		
		var count = self.activityViewCount;
		if count > 0 {
			count -= 1
		}

		self.activityViewCount = count

		if count == 0 {
			self.activityView?.removeFromSuperview()
			self.activityView = nil
		}
	}

    @discardableResult
	func showActivityIndicator(
        _ showActivity: Bool = true,
        activityMode: ActivityMode = .inline,
        view: UIView? = nil,
        style activityStyle: UIActivityIndicatorView.Style = .gray,
        color: UIColor?,
        activityColor: UIColor = .clear,
        bkgColor: UIColor = .white,
        offset: CGPoint = CGPoint(x: 0, y: 0)) -> UIView? {
        
        objc_sync_enter(self.activityLock)
        defer {
            objc_sync_exit(self.activityLock)
        }
        
        let count = self.activityViewCount
        self.activityViewCount = count + 1
        if count > 0 {
            return nil
        }
        
        // ActivityView
        let activityView = UIView()
        
        activityView.alpha = 1.0
        activityView.backgroundColor = bkgColor
        
        let parent: UIView = activityMode == .overlap ? superview ?? self : self
        parent.addSubview(activityView)
        if showActivity {
            // GrayView: small gray square besides activity
            if activityColor != .clear {
                let sizeGrayView: CGFloat = 62.0
                
                let grayView = UIView()
                grayView.alpha = 0.35
                grayView.backgroundColor = activityColor
                grayView.layer.cornerRadius = 15.0
                grayView.layer.masksToBounds = true
            
                activityView.addSubview(grayView)
                activateConstraints(
                    grayView.height(sizeGrayView).width(sizeGrayView).centerX(offset.x).centerY(offset.y)
                )
            }
            
            // ActivityIndicatorView
            if let view = view {
                activityView.addSubview(view)
                activateConstraints(
                    activityView.edges().center(),
                    view.centerX(offset.x).centerY(offset.y)
                )
            } else {
                let activity = UIActivityIndicatorView(style: activityStyle)
                activityView.addSubview(activity)
                if let color = color {
                    activity.color = color
                }
                
                activity.startAnimating()
                activityView.addSubview(activity)
                
                activateConstraints(
                    activityView.edges().center(to: self),
                    activity.centerX(offset.x).centerY(offset.y)
                    )
            }
        }
        
        // current ActivityView
        self.activityView = activityView
        return activityView
    }
}
