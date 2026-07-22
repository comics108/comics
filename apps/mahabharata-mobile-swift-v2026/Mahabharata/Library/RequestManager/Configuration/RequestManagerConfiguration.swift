//
//  RequestManagerConfiguration.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 28 Apr 2017.
//  Updated by Andrey Kozlov on 10 Dec 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//		27 Nov 2018. Vasiliy Ursu:
//			* added using enums + defaults (extra demo + explanation for using selected way)
//		03 Dec 2018. Andrey Kozlov:
//			* added useRawData flag
//		10 Dec 2018. Andrey Kozlov:
//			* remove settings
//			* rename instance from defaults to sharedDefaults
//

import Foundation

final class RequestManagerConfiguration {
	// This way doen't allow to use inline declaration like:
	//		private static var defaultSettings: [Constants: Any] = {
	//			return [
	//				 .timeoutInterval: TimeInterval(240),
	/*
	// Apple uses constants by performance tips (used in AccountIdentity) ~ this way more preferred for the case when not need to use string value, otherwise when enum will be used Constants.timeoutInterval.rawValue
	struct Constants {
	static let timeoutInterval = "requestTimeoutInterval"
	static let retriesCount = "requestRetriesCount"
	static let autoConnect = "autoConnect"
	static let repeatAlerts = "repeatAlerts"
	static let offlineModeSupport = "offlineModeSupport"
	static let autoStart = "autoStart"
	static let isSequential = "isSequential"
	static let queue = "queue"
	}
	*/
	
	// This solution doesn't approved for this case, because we need use enum Constants as dictionary keys and it does't implement Hashable
	/*
	enum Constants {
	static let timeoutInterval: String = "requestTimeoutInterval"
	static let retriesCount: String = "requestRetriesCount"
	static let autoConnect: String = "autoConnect"
	static let repeatAlerts: String = "repeatAlerts"
	static let offlineModeSupport: String = "offlineModeSupport"
	static let autoStart: String = "autoStart"
	static let isSequential: String = "isSequential"
	static let queue: String = "queue"
	static let useRawData: String = "useRawData"
	}
	*/
	
	// Our way, because we need use enum Constants as dictionary keys and it does't implement Hashable
	public enum Constants: String {
		case timeoutInterval = "requestTimeoutInterval"
		case retriesCount = "requestRetriesCount"
		case autoConnect = "autoConnect"
		case repeatAlerts = "repeatAlerts"
		case offlineModeSupport = "offlineModeSupport"
		case autoStart = "autoStart"
		case isSequential = "isSequential"
		case queue = "queue"
		case useRawData = "useRawData"
	}
	
	//v0 ~ research
	/*
	// used in UIKit+Style extension's
	struct Defaults {
	static var timeoutInterval: TimeInterval =  TimeInterval(240)
	static var retriesCount: Int = 3
	static var autoConnect: Bool = true
	static var repeatAlerts: Bool = true
	static var offlineModeSupport: Bool = false
	static var autoStart: Bool = true
	static var isSequential: Bool = false
	static var queue: DispatchQueue = DispatchQueue.main
	}
	*/
	
	//v1
	/*
	struct Defaults {
	var timeoutInterval: TimeInterval =  TimeInterval(240)
	var retriesCount: Int = 3
	var autoConnect: Bool = true
	var repeatAlerts: Bool = true
	var offlineModeSupport: Bool = false
	var autoStart: Bool = true
	var isSequential: Bool = false
	var queue: DispatchQueue = DispatchQueue.main
	}
	
	//static var sharedDefaults: Defaults = Defaults()
	static let defaults: Defaults = Defaults()
	
	// v-A
	/*
	var defaults: Defaults {
	RequestManagerConfiguration.sharedDefaults.repeatAlerts = true
	return Defaults()
	}
	*/
	// v-B
	var defaults: Defaults = Defaults()
	//TASK:
	//	need to prevent following:
	//		RequestManagerConfiguration.sharedDefaults = RequestManagerConfiguration.Defaults()
	//
	// 	and allow only:
	//		RequestManagerConfiguration.sharedDefaults.repeatAlerts = true
	//
	*/
	
	//Defaults PROBLEM:
	// 	SHOULD ALLOW!
	//		RequestManagerConfiguration.defaults.repeatAlerts = true
	// 	SHOULD PREVENT!
	//		RequestManagerConfiguration.defaults = RequestManagerConfiguration.Defaults()
	//
	//v2 (SOLVED) ~ Defaults declared as class instead of struct because we need to have syntax:
	//		RequestManagerConfiguration.Defaults.repeatAlerts = true
	
	final class Defaults {
		var timeoutInterval: TimeInterval = TimeInterval(240)
		var retriesCount: Int = 3
		var autoConnect: Bool = true
		var repeatAlerts: Bool = true
		var offlineModeSupport: Bool = false
		var autoStart: Bool = true
		var isSequential: Bool = false
		var queue: DispatchQueue? = DispatchQueue.main
		var useRawData: Bool = false
		
		fileprivate var settings: [Constants: Any]  {
			get {
				var dict: [Constants: Any] = [
					.timeoutInterval: timeoutInterval,
					.retriesCount: retriesCount,
					.autoConnect: autoConnect,
					.repeatAlerts: repeatAlerts,
					.offlineModeSupport: offlineModeSupport,
					.autoStart:  autoStart,
					.isSequential: isSequential,
					.useRawData: useRawData
				]
				if let queue = queue { dict[.queue] = queue }
				return dict
			}
		}
		
		init(settings: [Constants: Any]? = nil) {
			if let settings = settings {
				if let value = settings[.timeoutInterval] as? TimeInterval { timeoutInterval = value }
				if let value = settings[.retriesCount] as? Int { retriesCount = value }
				if let value = settings[.autoConnect] as? Bool { autoConnect = value }
				if let value = settings[.repeatAlerts] as? Bool { repeatAlerts = value }
				if let value = settings[.offlineModeSupport] as? Bool { offlineModeSupport = value }
				if let value = settings[.autoStart] as? Bool { autoStart = value }
				if let value = settings[.isSequential] as? Bool { isSequential = value }
				if let value = settings[.queue] as? DispatchQueue { queue = value }
				if let value = settings[.useRawData] as? Bool { useRawData = value }
			}
		}
	}
	
	//static var sharedDefaults: Defaults = Defaults()
	// Static property, can be changed fields, but should not be re-assigned!
	static let sharedDefaults: Defaults = Defaults()
	// Instance property (will be initialized from init method)
	var defaults: Defaults
	
	/// Timeout interval in seconds (should be more or equals than 240, otherwise will be ignored)
	/// @warning Default value is @b 240.
	var timeoutInterval: TimeInterval {
		get {
			return defaults.timeoutInterval
		}
		set {
			defaults.timeoutInterval = newValue
		}
	}
	
	/// Count of times that should request manager restarted while waiting solving server response error.
	/// When retriesCount < 2 then ALWAYS would be performed at least one retry when internet connection will be restored. Otherwise will be used counter of retries.
	/// @warning Default value is @b 3.
	var retriesCount: Int {
		get {
			return defaults.retriesCount
		}
		set {
			defaults.retriesCount = newValue
		}
	}
	
	/// This flag indicates that when network connection lost and when when it become alive, then request will be re-performed(RE-CONNECTed).
	/// @warning This method is not the same as autoStart param for network connection. Default value is @b true.
	var autoConnect: Bool  {
		get {
			return defaults.autoConnect
		}
		set {
			defaults.autoConnect = newValue
		}
	}
	
	/// This flag indicates that alerts (e.g. network error alerts) should be showed repeatly or single time.
	/// @warning This property should be used to manage repeating error alerts. Default value is @b true.
	var repeatAlerts: Bool {
		get {
			return defaults.repeatAlerts
		}
		set {
			defaults.repeatAlerts = newValue
		}
	}
	
	/// This flag indicates that errorBlock should be call when isConnectionError occured to provide ability to show offline mode data.
	/// But when connection will be restored then successBlock will be call.
	/// @warning When this flag specified then can be both errorBlock and successBlock called sequently. Default value is @b false.
	var offlineModeSupport: Bool {
		get {
			return defaults.offlineModeSupport
		}
		set {
			defaults.offlineModeSupport = newValue
		}
	}
	
	/// This flag indicates that performing connection should start immediately
	var autoStart: Bool {
		get {
			return defaults.autoStart
		}
		set {
			defaults.autoStart = newValue
		}
	}
	
	/// This flag indicates that we use sequential data access, i.e. each next portion of NSData will not contains previous buffered array of NSData and success block will not be used to received final data or used to complete manual buffering; by default this value is NO and it means that in result success block we will received final buffered NSData
	/// When is true  then we don't store received data in buffer and use direct transfer data to external storage (e.g. file or DB)
	var isSequential: Bool {
		get {
			return defaults.isSequential
		}
		set {
			defaults.isSequential = newValue
		}
	}
	
	/// If that queue is specified success and error bloks will performed on it.
	/// - Note: To achieve this goal we should setup RequestManager.sharedConfiguration.queue and specify here DispatchQueue.global(), otherwise - will be used main queue (DispatchQueue.main). But all requests processing logic ALWAYS will be performed in RequestManager 'internal queue'!
	/// - Warning: When you not needed use depended queries and long time post processing (after processRecieveData) then you should not configure queue parameter.
	var queue: DispatchQueue? {
		get {
			return defaults.queue
		}
		set {
			defaults.queue = newValue
		}
	}
	
	/// Flag indicates that not need to perform processReceivedData(_ responseObj: Any, with state: RequestManagerState) and data should be returned as plain Data/NSData response from server
	var useRawData: Bool {
		get {
			return defaults.useRawData
		}
		set {
			defaults.useRawData = newValue
		}
	}
	
	// MARK: - Init methods
	
	init(defaults: Defaults) {
		//self.init(settings: defaults.settings)
		self.defaults = defaults
	}
	
	convenience init(settings: [Constants: Any]) {
		let settings = type(of: self).sharedDefaults.settings.merging(settings, uniquingKeysWith: { (_, new) in new })
		let defaults = Defaults(settings: settings)
		self.init(defaults: defaults)
	}
	
	convenience init() {
		self.init(settings: type(of: self).sharedDefaults.settings)
	}
	
	convenience init(configuration: RequestManagerConfiguration) {
		self.init(settings: configuration.defaults.settings)
	}
	
	// MARK: - Experemental
	
	@discardableResult
	func timeoutInterval(_ val: TimeInterval) -> Self {
		defaults.timeoutInterval = val
		return self
	}
	
	@discardableResult
	func retriesCount(_ val: Int) -> Self {
		defaults.retriesCount = val
		return self
	}
	
	@discardableResult
	func autoConnect(_ val: Bool) -> Self {
		defaults.autoConnect = val
		return self
	}
	
	@discardableResult
	func repeatAlerts(_ val: Bool) -> Self {
		defaults.repeatAlerts = val
		return self
	}
	
	@discardableResult
	func offlineModeSupport(_ val: Bool) -> Self {
		defaults.offlineModeSupport = val
		return self
	}
	
	@discardableResult
	func autoStart(_ val: Bool) -> Self {
		defaults.autoStart = val
		return self
	}
	
	@discardableResult
	func isSequential(_ val: Bool) -> Self {
		defaults.isSequential = val
		return self
	}
	
	@discardableResult
	func queue(_ val: DispatchQueue?) -> Self {
		defaults.queue = val
		return self
	}
	
	@discardableResult
	func useRawData(_ val: Bool) -> Self {
		defaults.useRawData = val
		return self
	}
	
	@discardableResult
	func copy() -> RequestManagerConfiguration {
		return RequestManagerConfiguration(configuration: self)
	}
}
