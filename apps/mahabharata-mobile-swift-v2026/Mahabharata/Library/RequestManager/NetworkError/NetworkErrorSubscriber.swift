//
//  NetworkErrorSubscriber.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 25/07/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import Foundation

final class NetworkErrorSubscriber {
	
	typealias ResultBlock = () -> ()
	
	let target: NSObject
	let requestError: RequestError
	let success: ResultBlock
	let cancel: ResultBlock
	
	init(target: NSObject, requestError: RequestError, success: @escaping ResultBlock, cancel: @escaping ResultBlock) {
		self.target = target
		self.requestError = requestError
		self.success = success
		self.cancel = cancel
	}
	
}
