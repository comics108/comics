//
//  NetworkConnectionManager.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 25 Jul 2017.
//  Updated by Vasiliy Ursu on 20 Nov 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//        20 Nov 2018. Vasiliy Ursu:
//			* Removed Reachibility.swift file and replaced with NetworkReachabilityManager.
//          * Added file NetworkReachabilityManager.swift from Alamofire library
//				WARNING: because NetworkReachabilityManager is third party library, need to use NetworkConnectionManager methods to check internet connection. Otherwise will be needed big changes in target project/workspace.
//			* All methods in NetworkConnectionManagerDelegate now is required.
//
//  References:
//		https://stackoverflow.com/questions/25623272/how-to-use-scnetworkreachability-in-swift/25623647
//      https://github.com/Alamofire/Alamofire/blob/master/Source/NetworkReachabilityManager.swift
//

import Foundation

protocol NetworkConnectionManagerDelegate: class {
	func networkConnectionStateDidChanged(_ hasConnection: Bool)
}

extension Notification.Name {
	public static let NetworkConnectionManagerConnectionStateChanged = Notification.Name("NetworkConnectionManagerConnectionStateChanged")
}

class NetworkConnectionManager: NSObject {
	// MARK: - Singleton
	static let shared = NetworkConnectionManager()
	
	// MARK: - Internals
	
	var networkReachabilityManager: NetworkReachabilityManager?
	
	weak var delegate: NetworkConnectionManagerDelegate?

	override init() {
		super.init()
		
		networkReachabilityManager = NetworkReachabilityManager()
		if let networkReachabilityManager = networkReachabilityManager {
			networkReachabilityManager.listener = { [weak self] (status: NetworkReachabilityManager.NetworkReachabilityStatus) in
				guard let self = self else { return }
				self.updateReachabilityStatus()
			}
			networkReachabilityManager.startListening()
		}
		
		updateReachabilityStatus()
	}
	
	deinit {
		networkReachabilityManager?.stopListening()
		networkReachabilityManager = nil
	}
	
	/// Notify all subscribers about current status
	private func updateReachabilityStatus(status: NetworkReachabilityManager.NetworkReachabilityStatus? = nil) {
		guard let networkReachabilityManager = networkReachabilityManager else { return }
		//let hasInternet = networkReachabilityManager.networkReachabilityStatus == .reachable(.ethernetOrWiFi)
		let hasInternet = networkReachabilityManager.isReachable
		
		let notification = Notification(name: .NetworkConnectionManagerConnectionStateChanged, object: self, userInfo: nil)
		NotificationCenter.default.post(notification)
		
		delegate?.networkConnectionStateDidChanged(hasInternet)
	}
	
	func isInternetAvailable() -> Bool {
		guard let networkReachabilityManager = networkReachabilityManager else { return false}
		return networkReachabilityManager.isReachable
	}
	
	// Instance methods are for the cases when there's no 'shared' instance at the time of calling static methods
	
	func add(_ subscriber: Any, selector: Selector) {
		NotificationCenter.default.addObserver(subscriber, selector: selector, name: .NetworkConnectionManagerConnectionStateChanged, object: nil)
	}
	
	func remove(_ subscriber: Any) {
		NotificationCenter.default.removeObserver(subscriber, name: .NetworkConnectionManagerConnectionStateChanged, object: nil)
	}
	
	static func add(_ subscriber: Any, selector: Selector) {
		shared.add(subscriber, selector: selector)
	}
	
	static func remove(_ subscriber: Any) {
		shared.remove(subscriber)
	}
	
}
