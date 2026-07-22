//
//  Message.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 06/03/18.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import Foundation

class Message : NSObject {
	static let kMessageDataKey = "data"
	
	open class var identifier: String {
		//NOTE: String(describing: type(of: self)) return parent type identifier, but code below gives child class identifier
		return (NSStringFromClass(self) as NSString).components(separatedBy: ".").last!
	}
	
	open class func messageFromNotification(_ notification: Notification) -> Message? {
		let result = notification.userInfo?[kMessageDataKey] as? Message
		return result
	}
	
	func notificationForObject(_ object: Any?) -> Notification {
		let result = Notification(name: Notification.Name(rawValue: type(of: self).identifier), object: object, userInfo: [Message.kMessageDataKey : self])
		return result
	}
}
