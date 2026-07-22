//
//  NetworkActivityIndicatorManager.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 17/05/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

/**
`NetworkActivityIndicatorManager` manages the state of the network activity indicator in the status bar. When enabled, it will listen for notifications indicating that a network request operation has started or finished, and start or stop animating the indicator accordingly. The number of active requests is incremented and decremented much like a stack or a semaphore, and the activity indicator will animate so long as that number is greater than zero.

You should enable the shared instance of `NetworkActivityIndicatorManager` when your application finishes launching. In `AppDelegate application:didFinishLaunchingWithOptions:` you can do so with the following code:

[NetworkActivityIndicatorManager sharedManager].enabled = YES;

By setting `isNetworkActivityIndicatorVisible` to `YES` for `sharedManager`, the network activity indicator will show and hide automatically as requests start and finish. You should not ever need to call `incrementActivityCount` or `decrementActivityCount` yourself.

See the Apple Human Interface Guidelines section about the Network Activity Indicator for more information:
http://developer.apple.com/library/iOS/#documentation/UserExperience/Conceptual/MobileHIG/UIElementGuidelines/UIElementGuidelines.html#//apple_ref/doc/uid/TP40006556-CH13-SW44
*/

let kInvisibilityDelay: TimeInterval = 0.17

// TODO: remove inheritance from NSObject
class NetworkActivityIndicatorManager: NSObject {
	
	/// Returns the shared network activity indicator manager object for the system.
	static let shared = NetworkActivityIndicatorManager()
	
	/// A Boolean value indicating whether the manager is enabled.
	/// If YES, the manager will change status bar network activity indicator according to network operation notifications it receives. The default value is NO.
	var enabled: Bool = false
	
	/// A Boolean value indicating whether the network activity indicator is currently displayed in the status bar.
	var isIndicatorVisible: Bool {
		return activityCount > 0
	}
	
	private var _activityCount: Int = 0
	
	private var activityCount: Int {
		get {
			return _activityCount
		}
		set {
			DispatchManager.synchronized(self) {
				_activityCount = newValue
			}
		}
	}
	
	private var visibilityTimer: Timer?
	
	override init() {
		
	}
	
	deinit {
		visibilityTimer?.invalidate()
	}
	
	/// Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
	public func showIndicator() {
		activityCount += 1
		print("showIndicator \(activityCount)")
		DispatchQueue.main.async {
			self.updateVisibilityDelayed()
		}
	}
	
	/// Decrements the number of active network requests. If this number becomes zero before decrementing, this will stop animating the status bar network activity indicator.
	public func hideIndicator() {
		activityCount = max(activityCount - 1, 0)
		print("hideIndicator \(activityCount)")
		DispatchQueue.main.async {
			self.updateVisibilityDelayed()
		}
	}
	
	// MARK: Private methods

	private func updateVisibilityDelayed() {
		if enabled {
			// Delay hiding of activity indicator for a short interval, to avoid flickering
			if !isIndicatorVisible {
				visibilityTimer?.invalidate()
				visibilityTimer = Timer.scheduledTimer(timeInterval: kInvisibilityDelay, target: self, selector: #selector(updateVisibility), userInfo: nil, repeats: false)
				RunLoop.main.add(visibilityTimer!, forMode: .common)
			} else {
				//DispatchQueue.performSelector(onMainThread: #selector(updateVisibility), with: nil, waitUntilDone: false, modes: [RunLoopMode.commonModes.rawValue])
				performSelector(onMainThread: #selector(updateVisibility), with: nil, waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
			}
		}
	}
	
	@objc
	private func updateVisibility() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = isIndicatorVisible
	}
	
}
