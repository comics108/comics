//
//  AlertManager.swift
//  AlertManager
//
//  Created by Mikhail Kulichkov on 19 Apr 2017.
//  Updated by Vasiliy Ursu on 26 Dec 2018
//
//  Changes history:
//		21 Sep 2018. Vasiliy Ursu:
//			* Fixed bug with showing alert when window.rootViewConroller present as UIViewController, i.e. not UITabbarViewConroller or UINavigationController
//		22 Nov 2018. Vasiliy Ursu:
//			* Added preferredStyle option.
//		26 Dec 2018. Vasiliy Ursu:
//			* Added dependency to UIApplication+Extension.
//
//	Dependencies:
//		UIApplication+Extension
//
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit

fileprivate class QueuedAlertController {
	typealias CompletionBlock = () -> ()
	
	let alertController: UIAlertController
	let animated: Bool
	let completionBlock: CompletionBlock?
	
	init(alertController: UIAlertController, animated: Bool, completionBlock: CompletionBlock?) {
		self.alertController = alertController
		self.animated = animated
		self.completionBlock = completionBlock
	}
}


// http://qaru.site/questions/140538/add-image-to-uialertaction-in-uialertcontroller
final class AlertManager {
	
	typealias DismissBlock = (Int) -> ()
	typealias PrepareBlock = (UIAlertController?) -> ()
	typealias CompletionBlock = (UIAlertController?) -> ()
	
    private static let shared = AlertManager()
    
    private var alertQueue = [QueuedAlertController]()
    
    /**
        * Note:
        The first element in buttons always is Cancel
        * Attention: When using UIAlertController alerts wil be shown ordered accending (1 2 3 .. n).
        When using UIAlertView alerts wil be shown backwards (n .. 3 2 1).
    */
    //MARK: - Public
	
	@discardableResult
	static func present(title: String = UIApplication.appName ?? "",
						message: String,
						buttons: [String],
						dismissBlock: @escaping DismissBlock,
						prepareBlock: PrepareBlock? = nil,
						completionBlock: CompletionBlock? = nil,
						preferredStyle: UIAlertController.Style = .alert) -> UIAlertController? {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)

		let dismissControllerBlock = {
			self.abort(animated: true)
		}

		// Default Cancel action
		if buttons.isEmpty {
			let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in dismissControllerBlock() })
			alertController.addAction(actionCancel)
		}

		// Default Cancel will be changed with dismissBlock(0)
		for index in 0..<buttons.count {
			let actionStyle: UIAlertAction.Style = (index == 0) ? .cancel : .default
			let actionButtonTitle = buttons[index]
			let actionDismiss = UIAlertAction(title: actionButtonTitle, style: actionStyle, handler: { _ in
				dismissBlock(index)
				dismissControllerBlock()
			})
			
			alertController.addAction(actionDismiss)
		}

		prepareBlock?(alertController)
		
		performInMainThread {			
			shared.present(alertController, animated: true, completionBlock: {
				completionBlock?(alertController)
			})
		}
		
		return alertController
    }
	
	static func abort(animated: Bool) {
		if let currentAlert = shared.alertQueue.first?.alertController {
			currentAlert.dismiss(animated: animated)
			shared.alertQueue.remove(at: 0)
		}
		
		if shared.alertQueue.count != 0 {
			shared.presentFirstQueuedController()
		}
	}
	
	static func abortAll(animated: Bool) {
		if let currentAlert = self.shared.alertQueue.first?.alertController {
			currentAlert.dismiss(animated: animated)
		}
		
		//FIXME: Remove warning "Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior"
		shared.alertQueue.removeAll()
	}

    //MARK: - Private
	
    private func present(_ alertController: UIAlertController, animated: Bool, completionBlock: QueuedAlertController.CompletionBlock?) {
        let queuedAlertController = QueuedAlertController(alertController: alertController, animated: animated, completionBlock: completionBlock)
        alertQueue.append(queuedAlertController)

        if alertQueue.count == 1 {
            presentFirstQueuedController()
		}
    }
	
    private func presentQueuedAlertController(index: Int) {
        let queuedAlertController = alertQueue[index]
		let window = UIApplication.shared.keyWindow
		//TODO: possible next if .. else .. code can be replaced by using topViewController extension of UIApplication
		// Fixing bug when rootViewController is simple UIViewController (not UINavigationController), see: https://stackoverflow.com/questions/26554894/how-to-present-uialertcontroller-when-not-in-a-view-controller + https://stackoverflow.com/questions/40991450/ios-present-uialertcontroller-on-top-of-everything-regardless-of-the-view-hier/40991509
		if window == nil/* && UIApplication.shared.windows.count > 0*/ {
			/*
			window = UIApplication.shared.windows[0]
			window?.windowLevel = UIWindowLevelAlert + 1
			window?.makeKeyAndVisible()
			*/
			let alertWindow = UIWindow(frame: UIScreen.main.bounds)
			alertWindow.rootViewController = UIViewController()
			alertWindow.windowLevel = UIWindow.Level.alert + 1;
			alertWindow.makeKeyAndVisible()
			alertWindow.rootViewController?.present(queuedAlertController.alertController,
													animated: queuedAlertController.animated,
													completion: queuedAlertController.completionBlock)
		}
		else if let targetVC = UIApplication.topViewController() {
			targetVC.present(queuedAlertController.alertController,
							 animated: queuedAlertController.animated,
							 completion: queuedAlertController.completionBlock)
		}
    }
    
    private func presentFirstQueuedController() {
        presentQueuedAlertController(index: 0)
    }
    
    // MARK: - Helpers
    
    private static func performInMainThread(block: () -> ()) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync {
                block()
            }
        }
    }
	
}

extension UIAlertController {
	
	func addNumericField(_ placeholder: String = "") {
		self.addTextField { (textField: UITextField) in
			textField.placeholder = placeholder
			textField.keyboardType = .numberPad
		}
	}
	
	func addField(_ placeholder: String = "") {
		self.addTextField { (textField: UITextField) in
			textField.placeholder = placeholder
		}
	}
	
}
