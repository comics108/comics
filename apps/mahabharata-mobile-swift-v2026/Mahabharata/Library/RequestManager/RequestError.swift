//
//  RequestError.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 28 Apr 2017.
//	Updated by Andrey Kozlov on 06 Feb 2019.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//		04 Oct 2018. Olga Zhegulo:
//			* Changed convenience init to allow optional params.
//		26 Nov 2018. Vasiliy Ursu:
//			* NSError extension for isConnectionError flag calculation
//		06 Feb 2019. Andrey Kozlov:
//			* added extra isConnectionError handled based on NSError
//

import Foundation

class RequestError: NSObject, Error {
 	/// Received NSURLResponse
	var response: URLResponse?
	
	/// Received NSError instance
	var error: NSError?
	
	/// Deep error
	var innerError: RequestError?
	
	/// Deepest error
	var innerErrorDepthLevel: Int {
		get {
			return 1 + (innerError == nil ? 0 : innerError!.innerErrorDepthLevel)
		}
	}
	
	/// Internal error code (see OperationResultCode enum).
 	/// @warning @b OperationResultCode enum can be ovewritten by overriding @b getNeedToReloginResponseCodes method.
	var code: Int

 	/// Request params
	// TODO: Replace to URLRequest
	var params: Any? //AnyObject?
	
	/// Extended error data (i.e. list of error codes, localized project messages & etc.).
 	/// This field is not used by request manager or logic and system error handling.
	var errorDataEx: AnyObject?

	/// System/server error text, that can be used for debug goals (when NSError is not present and need to specify error text manually).
 	/// When need manualy separate error messages for same error types then can be used errorDataEx field.
	var msg: String?
 
	/// Received data from server Response
	var data: Any?
	
 	/// Flag indicated that no errors occured while executing query
	var isSuccess: Bool
 
	/// Flag indicates that re-login required
	var needToRelogin: Bool
	
	/// Flag indicates that this type of error is connection error (not Auth/Login error)
	var isConnectionError: Bool

	/// Flag indicates that user interaction (showing alerts, panels & etc.) by error was handled and not needed next processing (??? stopProcessing???)
 	/// I.e. in this case not needed process error next, manually or automatically + not need to show alerts in NetwokErrorManager.
    ///
    /// From code in reqMan: Mark error is handled to prevent retry-sending same requests
	var isHandled: Bool
	
 	/// Flag indicates that need to stop request processing & error handling  (when this flag is set then errorBlock will never be called)
 	/// I.e. error block should not be called!!!
	var stopProcessing: Bool
	
	init(response: URLResponse?, error: NSError?, code: Int, params: Any?, errorDataEx: AnyObject?, msg: String?, data: Any?, isSuccess: Bool, needToRelogin: Bool, isConnectionError: Bool, isHandled: Bool, stopProcessing: Bool) {
		self.response = response
		self.error = error
		self.code = code
		self.params = params
		self.errorDataEx = errorDataEx
		self.msg = msg
		self.data = data
		self.isSuccess = isSuccess
		self.needToRelogin = needToRelogin
		self.isConnectionError = isConnectionError || (error?.isConnectionError ?? false)
		self.isHandled = isHandled
		self.stopProcessing = stopProcessing
	}
	
	convenience override init() {
		self.init(
			response: nil,
			error: nil,
			code: 0,
			params: nil,
			errorDataEx: nil,
			msg: nil,
			data: nil,
			isSuccess: false,
			needToRelogin: false,
			isConnectionError: false,
			isHandled: false,
			stopProcessing: false
		)
	}
	
	convenience init(error: RequestError) {
		self.init(
			response: error.response,
			error: error.error,
			code: error.code,
			params: error.params,
			errorDataEx: error.errorDataEx,
			msg: error.msg,
			data: error.data,
			isSuccess: error.isSuccess,
			needToRelogin: error.needToRelogin,
			isConnectionError: error.isConnectionError,
			isHandled: error.isHandled,
			stopProcessing: error.stopProcessing
		)
	}
	
	convenience init(code: Int, msg: String?, data: Any?) {
		self.init(
			response: nil,
			error: nil,
			code: code,
			params: nil,
			errorDataEx: nil,
			msg: msg,
			data: data,
			isSuccess: false,
			needToRelogin: false,
			isConnectionError: false,
			isHandled: false,
			stopProcessing: false
		)
	}
	
	override var description: String {
		let responseString: String = response?.url?.absoluteString ?? ""
		
		var str = "Request error: url=\(responseString), code=\(code), params=\(params ?? "" as AnyObject), message=\(msg ?? ""), data=\(data ?? "" as AnyObject), isSuccess=\(isSuccess), needToRelogin=\(needToRelogin), isConnectionError=\(isConnectionError), isHandled=\(isHandled), stopProcessing = \(stopProcessing)"
		
		if let error = self.error {
			str += "error=\(error)"
		}
		
		return RequestError.unescapeString(str)
	}
	
	/// Magic lost function ~ should be places in String+Html or String+Encoding extension
	static func unescapeString(_ str: String) -> String {
		let esc1 = str.replacingOccurrences(of: "\\u", with: "\\U")
		let esc2 = esc1.replacingOccurrences(of: "\"", with: "\\\"")
		let quoted = "\"".appending(esc2).appending("\"")
		
		if let data = quoted.data(using: .utf8) {
			let unesc = try? PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.ReadOptions(rawValue: 0), format: nil)
			return unesc as? String ?? ""
		}
		return ""
	}
}

extension NSError {
	var isConnectionError: Bool {
        print("🚩🚩🚩Connection error \(code)")
        print(self)
		return false ||
			self.code == NSURLErrorTimedOut ||
			//self.code == NSURLErrorUnsupportedURL ||
			//NSURLErrorCannotFindHost can be occured when have not internet connection
			//self.code == NSURLErrorCannotFindHost ||
			//self.code == NSURLErrorCannotConnectToHost ||
			//self.code == NSURLErrorDNSLookupFailed ||
			
			//self.code == NSURLErrorHTTPTooManyRedirects ||
			
			//self.code == NSURLErrorResourceUnavailable ||
			
			self.code == NSURLErrorNetworkConnectionLost ||
			self.code == NSURLErrorNotConnectedToInternet
        
//        Ошибка при сворачивании приложения во время запроса и возвращении в него до истечения таймаута
//        || self.code == 53
//        https://forums.developer.apple.com/thread/111150
//        https://forums.developer.apple.com/thread/106838
	}
}
