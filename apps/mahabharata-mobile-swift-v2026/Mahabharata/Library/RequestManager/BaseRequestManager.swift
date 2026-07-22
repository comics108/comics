//
//  BaseRequestManager.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 04 May 2017.
//	Updated by Andrey Kozlov on 03 Dec 2018.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Dependencies:
//      system: UIKit
//      custom: AlertViewExtension, AlertManager, Locker, Dispatch
//      guthub: 
//
//  Changes history:
//		Stanislav Grinberg: fix logic error when processing not login status codes
//			* invalidate timer on the thread it was scheduled on
//			* correct releasing blocks in cases when server is not valid
//			* disabled startConnection method and autoStart property, now autoStart defined in configuration
//			* added queue property to configuration, running success, error and progress blocks in the specified queue,
//			  if queue not specified running queue will be main at default
//		Konstantin Oznobikhin: use NSURLConnectionDataDelegate instead of NSURLConnectionDelegate
//		Denis Morozov:
//			* restored abstract method
//			* add separate thread for NSURLConnection delegate callbacks
//			* add two new properties receivedData(raw bytes) and receivedObjectString(response string)
//		Stanislav Grinberg:
//			* added new helper methods requestUrlString, paramsObjectString
//			* refactored buildRequestBody when not GET request
//			* using packageName instead of appName by build User-Agent
//			* added sequention/file loading logic
//			* Next methods now are static (Class methods):
//				buildRequestBody:withParameters:
//				buildQueryString:withParameters:
//				buildBodyParams:
//		Denis Morozov:
//			* requestThread modified
//		02 Apr 2018. Stanislav Grinberg:
// 			* Added UserAgentProtocol.
//		02 Apr 2018. Mikhail Kulichkov:
//			* requestThreadEntryPoint modified. Solved swift 4.1 strong type checking bug (Thread.init takes nullable object,
//			i.e. corresponding selector must have optional argument: "Any?" instead of "Any")
//		30 May 2018. Stanislav Grinberg:
//			* Ability to configure "User-Agent", "Accept-Encoding", "Content-Type" through headers param in runRequest(...) method
//		19 Jun 2018. Stanislav Grinberg:
//			* BaseRequestManagerDelegate extended by new method requestManager(_:didCanceledWithKey:reason:)
//			* Delegate property became public.
//			* requestManager(_:cookies:url:) commented because not used!
//		25 Jun 2018. Mikhail Kulichkov:
//			* Success and error blocks wrapping methods (wrapSuccess, wrapError) added for using with operations.
//      03 Oct 2018. Sergey Vasilyev:
//          * fixed buildRequestBody method (Added support Any parameter's type + changed condition)
//      10 Oct 2018. Olga Zhegulo:
//          * fixed rmResponse!.mimeType! crash (treated nil response MIME type as "")
//		26 Nov 2018. Vasiliy Ursu:
//			* added [weak self] attributes for performBlock closure, some optimizations + NSError extension
//			* added comments + moved OperationResultCode enum under BaseRequestManager class
//		03 Dec 2018. Andrey Kozlov:
//			* added useRawData flag when it true then processReceivedData will not be performed
//

import UIKit

/// Request manager state wrapper, used as parameter in processing operations to prevent direct access to internal properties of RequestManager
protocol RequestManagerState {
	var statusCode: Int { get }
	var responseHeaders: [String : String] { get }
	var requestURL: String { get }
}

/// Optional protocol, that can be implemented with <ProjectName>RequestManager to override User-Agent request header.
protocol UserAgentProtocol {
	func getUserAgent() -> String
}

@objc
protocol BaseRequestManagerDelegate: NSObjectProtocol {
	//@objc optional func requestManager(_ requestManager: BaseRequestManager, didCookieRecieved cookies: [HTTPCookie], url: String)
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didFinishWithData responseObj: Any /*NSObject?*/)
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didFailWithResponse response: URLResponse)
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didFailWithError error: NSError)
	
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didDataRecieved recieved: Int, with total: Int, with expected: Int)
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didDataSent sent: Int, with total: Int, with expected: Int)
	
	@objc optional func requestManager(_ requestManager: BaseRequestManager, didCanceledWithKey key: AnyHashable, reason: Any?)
}

class BaseRequestManager: NSObject, NSURLConnectionDataDelegate {
	
	/**
	Result codes of request performing. INTERNAL RequestManager codes that used to interpretation results.
	- Note: Available values **success**, **error**, **needToLogin**
	*/
	enum OperationResultCode: Int {
		/// Code indicates that no errors
		case success = 0
		/// Code indicates that some error occured
		case error
		/// Code indicates that need to login error is occured
		case needToLogin
	}
	
	private var path: String!
	private var headers: [String: String]?
	private var parameters: Any?
	private var method: String!
	
	private var cookies: [HTTPCookie]?
	
	private var autoStart: Bool!
	private var isSequential: Bool!
	private var timeoutInterval: TimeInterval!
	private var callbacksQueue: DispatchQueue?
	private var useRawData: Bool!
	
	typealias RequestSuccessBlock = (Any) -> ()
	typealias RequestProgressBlock = (Int, Int, Data?) -> ()
	typealias RequestErrorBlock = (RequestError) -> ()
	
	private var successBlock: RequestSuccessBlock?
	private var progressBlock: RequestProgressBlock?
	private var errorBlock: RequestErrorBlock?
	
	// MARK: - Internal properties
	private var receivedData: Data
	
	// Store length of received data, this property is only usefull for tracking content length of sequential requests
	// since we don't store data for these type of requests in `receivedData`.
	// For not sequential requests the value of this variable equals `receivedData.count`
	private var receivedContentLength: Int
	
	fileprivate var rmRequest: URLRequest?
	private var rmConnection: NSURLConnection?
	fileprivate var rmResponse: HTTPURLResponse?
	
	// MARK: Interruption logic
	private var requestTimeoutTimer: Timer?
	
	// MARK: Synchronization primitives
	private var manualStartCondition: NSCondition!
	
	// MARK: - Debug properties
	
	var requestUrlString: String? {
		return rmRequest?.url?.absoluteString
	}
	
	var paramsObjectString: String? {
		if let bodyData = rmRequest?.httpBody {
			return String(data: bodyData, encoding: .utf8)
		}
		
		return nil
	}
	
	var receivedObjectString: String? {
		return String(data: receivedData, encoding: .utf8)
	}
	
	// MARK: -
	
	override init() {
		receivedData = Data()
		receivedContentLength = 0
		
		super.init()
		
		NotificationCenter.default.addObserver(self, selector: #selector(applicationEnterForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(applicationEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminateNotification), name: .UIApplicationWillTerminate, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	/*
	var delegate: BaseRequestManagerDelegate? {
		return self as? BaseRequestManagerDelegate
	}
	*/
	
	final weak var delegate: BaseRequestManagerDelegate?
	
	// MARK: - Abstract methods
	
	func supportedResponseCodes() -> Set<Int> {
		fatalError("Provide realisation of \(#function) in your subclass")
	}
	
	func needToReloginResponseCodes() -> Set<Int> {
		fatalError("Provide realisation of \(#function) in your subclass")
	}
	
	func expectedMimeTypes() -> Set<String> {
		fatalError("Provide realisation of \(#function) in your subclass")
	}
	
	func processReceivedData(_ responseObj: Any, with state: RequestManagerState) -> Any {
		fatalError("You must override \(#function) in a subclass")
	}
	
	// MARK: - Block methods public method's
	
	// Protected method (used only by children)
	final func runRequest(path: String,
	                      headers: [String: String]?,
	                      parameters: Any?,
	                      method: String,
	                      cookies: [HTTPCookie]?,
	                      autoStart: Bool,
	                      sequential: Bool,
	                      timeoutInterval: TimeInterval,
	                      callbacksQueue: DispatchQueue?,
						  useRawData: Bool,
	                      success: RequestSuccessBlock?,
	                      progress: RequestProgressBlock?,
	                      error: RequestErrorBlock?) {
		
		// Save initial params
		self.path = path
		self.headers = headers
		self.parameters = parameters
		self.method = method
		self.cookies = cookies
		
		self.autoStart = autoStart
		self.isSequential = sequential
		self.timeoutInterval = timeoutInterval
		self.callbacksQueue = callbacksQueue
		self.useRawData = useRawData
		
		// Save blocks
		self.successBlock = success
		self.progressBlock = progress
		self.errorBlock = error
		
		// Create conditional variable only for requests without autoStart
		// to prevent starting connection before we have prepared for request starting
		if !autoStart {
			manualStartCondition = NSCondition()
		}
		
		// Initialize internal properties
		self.receivedContentLength = 0
		self.receivedData = Data()
		
		// Move away from the main thread and create request asynchronously
		perform(#selector(innerRunRequest), on: BaseRequestManager.requestThread, with: nil, waitUntilDone: false)
	}
	
	// This method was created specifically to have ability to be called on our custom thread
	@objc
	private func innerRunRequest() {
		guard let urlComponents = URLComponents(string: path) else {
			if errorBlock != nil {
				performBlock { [weak self] in
					guard let self = self else { return }
					// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
					// пока мы ожидали начала выполнения этого блока
					guard let errorBlock = self.errorBlock else { return }
					
					let err = RequestError()
					err.code = OperationResultCode.error.rawValue
					err.msg = "URL can't be created with passed path string"
					err.isHandled = true
					err.isConnectionError = false
					errorBlock(err)
				}
			}
			return
		}
		
		URLCache.shared.removeAllCachedResponses()
		
		rmRequest = buildURLRequest(for: urlComponents)
		
		if !autoStart {
			// Since this method is called asynchronously there is a possibility that `startConnection` will be called earlier
			// than rmConnection would be created so we use condition variable to wake up sleeping thread when rmConnection is ready to start
			manualStartCondition.lock()
			rmConnection = NSURLConnection(request: rmRequest!, delegate: self, startImmediately: false)
			manualStartCondition.signal()
			manualStartCondition.unlock()
		} else {
			rmConnection = NSURLConnection(request: rmRequest!, delegate: self, startImmediately: false)
            restartConnectionWithTimeout()
		}
	}
	
	func retryRequest() {
		guard let rmRequest = rmRequest else { return }
		
		receivedContentLength = 0
		receivedData.removeAll()
		rmResponse = nil
		
		rmConnection = NSURLConnection(request: rmRequest, delegate: self, startImmediately: false)
		perform(#selector(restartConnectionWithTimeout), on: BaseRequestManager.requestThread, with: nil, waitUntilDone: true, modes: [RunLoop.Mode.common.rawValue])
	}
	
	// MARK: - Request creation
	
	private func buildURLRequest(for urlComponents: URLComponents) -> URLRequest {
		var urlComponents = urlComponents
		
		// If we have a path then url encode it
		if urlComponents.path.count > 1 {
			urlComponents.percentEncodedPath = "/" + urlComponents.path.components(separatedBy: "/").filter { !$0.isEmpty }.map(URLPathEncodedString).joined(separator: "/")
		}
		
		// Build query paramaters for GET/HEAD requests
		let isQuerySupportableMethod = method.caseInsensitiveCompare("GET") == .orderedSame || method.caseInsensitiveCompare("HEAD") == .orderedSame
		if isQuerySupportableMethod, let parameters = parameters as? [String: Any] {
			let parametersQueryString = buildQueryComponentsString(for: parameters)
			
			// If we alredy have any queryItems extract them and apply url encoding to them
			if let initialQueryItems = urlComponents.queryItems {
				let initialQueryParameters = initialQueryItems.reduce(into: [String: String](), { (result, queryItem) in
					result[queryItem.name] = queryItem.value
				})
				
				urlComponents.percentEncodedQuery = buildQueryComponentsString(for: initialQueryParameters) + "&" + parametersQueryString
			} else {
				urlComponents.percentEncodedQuery = parametersQueryString
			}
		}
		
		// Add a little value for timeoutInterval so our custom timer will fire earlier than the system one for the first time
		var urlRequest = URLRequest(url: urlComponents.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: self.timeoutInterval + 5.0)
		urlRequest.httpMethod = method
		
		// Set base headers
		var requestHeaders: [String: String] = headers ?? [:]
		requestHeaders["User-Agent"] = headers?["User-Agent"] ?? userAgent
		
		// Accept-Encoding: identity, gzip
		// 	"identity" - default - no transformation is used
		// 	"gzip" compression is used (this type of compression automatically supported by NSURLConnection and not need to extracting manually)
		// 	"zlib" compression is used
		requestHeaders["Accept-Encoding"] = headers?["Accept-Encoding"] ?? "identity, gzip"
		
		// Create request body for POST/PUT/DELETE requests
		let isBodySupportableRequest = method.caseInsensitiveCompare("POST") == .orderedSame ||
									   method.caseInsensitiveCompare("PUT") == .orderedSame ||
									   // A payload within a DELETE request message has no defined semantics;
									   // sending a payload body on a DELETE request might cause some existing
									   // implementations to reject the request
									   method.caseInsensitiveCompare("DELETE") == .orderedSame
		if isBodySupportableRequest, parameters != nil {
			requestHeaders["Content-Type"] = headers?["Content-Type"] ?? "application/json; charset=utf-8"
			urlRequest.httpBody = buildRequestBody(for: requestHeaders["Content-Type"]!)
			requestHeaders["Content-Length"] = String(describing: urlRequest.httpBody?.count ?? 0)
		}
		
		//urlRequest.allHTTPHeaderFields = headers
		// Set custom headers with extedning existing headers
		for (key, value) in requestHeaders {
			urlRequest.setValue(value, forHTTPHeaderField: key)
		}
		
		// COOKIES: old (not used)
		//			var headers: [String: String]?
		//			if let cookies = availableCookies {
		//				headers = HTTPCookie.requestHeaderFields(with: cookies)
		//				if let headerParameters = headerParams as? [String: String] {
		//					var headersEx = headers!
		//					for (paramName, paramValue) in headerParameters {
		//						headersEx[paramName] = paramValue
		//					}
		//					headers = headersEx
		//				}
		//			}
		//
		//			// set merged headers
		//			rmRequest.allHTTPHeaderFields = headers
		
		return urlRequest
	}
	
	private static var _userAgent: String?
	/// Getting User-Agent like: "ru.pikabu.android/1.4.7 (MI 5; Android 6.0.1)"
	private var userAgent: String {
		if BaseRequestManager._userAgent == nil {
			// self as AnyObject as? fix conditional cast always succeded warning
			if let innerUserAgent = (self as AnyObject as? UserAgentProtocol)?.getUserAgent() {
				BaseRequestManager._userAgent = innerUserAgent
				return innerUserAgent
			} else {
				let packageName = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String ?? ""
				let appVersion: String = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
				// Вручную ставим iOS т.к на iPod UIDevice.current.systemName возвращает iPodOS ("iphone OS")
				let innerUserAgent = "\(packageName)/\(appVersion) (\(UIDevice.current.model); iOS \(UIDevice.current.systemVersion))"
				BaseRequestManager._userAgent = innerUserAgent
				return innerUserAgent
			}
		} else {
			return BaseRequestManager._userAgent ?? ""
		}
	}
	
	/*	private static let userAgent: String = {
		let packageName = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as! String
		let appVersion: String = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
		// Вручную ставим iOS т.к на iPod UIDevice.current.systemName возвращает iPodOS ("iphone OS")
		return "\(packageName)/\(appVersion) (\(UIDevice.current.model); iOS \(UIDevice.current.systemVersion))"
	}()
	*/
	
	private func buildQueryComponentsString(for parameters: [String: Any]) -> String {
		var queryComponents = [String]()
		for (key, value) in parameters {
			let urlEncodedKey = URLQueryEncodedString(from: key)
			
			if let dict = value as? [String: Any] {
				var dictionaryURLEncodedComponents = [String]()
				
				for (innerKey, innerValue) in dict {
					if innerValue is [String: Any] || innerValue is [Any] {
						// We only handle a primitive types for nested dictionaries
						print("WARNING: buildQueryComponentsString supports only primitive types for nested dictionaries")
						continue
					}
					
					let encodedKey = URLQueryEncodedString(from: innerKey)
					let encodedValue = URLQueryEncodedString(from: String(describing: innerValue))
					
					dictionaryURLEncodedComponents.append("\(urlEncodedKey)%5B\(encodedKey)%5D=\(encodedValue)")
				}
				
				queryComponents.append(dictionaryURLEncodedComponents.joined(separator: "&"))
			} else if let arr = value as? [Any] {
				var arrayURLEncodedComponents = [String]()
				
				for innerValue in arr {
					let urlEncodedElement = URLQueryEncodedString(from: String(describing: innerValue))
					arrayURLEncodedComponents.append("\(urlEncodedKey)%5B%5D=\(urlEncodedElement)")
				}
				
				queryComponents.append(arrayURLEncodedComponents.joined(separator: "&"))
			} else {
				let urlEncodedValue = URLQueryEncodedString(from: String(describing: value))
				queryComponents.append("\(urlEncodedKey)=\(urlEncodedValue)")
			}
		}
		return queryComponents.joined(separator: "&")
	}
	
	private func buildRequestBody(for contentType: String) -> Data? {
		var bodyData: Data?
		
		// By specification "application/x-www-form-urlencoded" content type allows only key-value pairs of params (same as for URL parameters), but sometimes servers implemented with errors (like GulfStream) and with this content type can be accepted only value without keys and else condition should be performed
		if contentType.contains("application/x-www-form-urlencoded"), let dictionaryParameters = parameters as? [String: Any] {
			var formStringComponents = [String]()
			for (key, value) in dictionaryParameters {
				let encodedKey = formURLEncodedString(from: key)
				let encodedValue = formURLEncodedString(from: String(describing: value))
				formStringComponents.append("\(encodedKey)=\(encodedValue)")
			}
			bodyData = formStringComponents.joined(separator: "&").data(using: .utf8)
		}
		else if contentType.contains("application/json"), let anyParameters = parameters, JSONSerialization.isValidJSONObject(anyParameters) {
            // Это костыль. Некоторые сервера не хотят обрабатывать запросы, если Content-Type != application/json,
            // поэтому мы вынуждены указывать Content-Type, который не соответсвует содержимому, чтобы сервер успешно обработал наш запрос.
            do {
                bodyData = try JSONSerialization.data(withJSONObject: anyParameters, options: [])
            } catch {
                fatalError("Request parameters should be NSString or NSDictionary. JSONData error: \(error.localizedDescription)")
            }
		} else {
            if let dataParameters = parameters as? Data {
                bodyData = dataParameters
            } else if let stringParameters = parameters as? String {
                bodyData = stringParameters.data(using: .utf8)
            } else if let anyParameters = parameters {
                bodyData = String(describing: anyParameters).data(using: .utf8)
            } else {
                print("Invalid arguments are passed for JSON encoding. Check parameters thar you passed to RequestManager.")
            }
        }
		return bodyData
	}
	
	// MARK: URL Encoding
	
	private static let URLPathAllowedCharacterSet: CharacterSet = {
		var URLPathAllowedCharacterSet = CharacterSet.urlPathAllowed
		URLPathAllowedCharacterSet.remove(charactersIn: ":#[]@!$&'()*+,;=?/")
		return URLPathAllowedCharacterSet
	}()
	
	private func URLPathEncodedString(from string: String) -> String {
		return string.addingPercentEncoding(withAllowedCharacters: BaseRequestManager.URLPathAllowedCharacterSet)!
	}
	
	private static let URLQueryAllowedCharacterSet: CharacterSet = {
		var urlQueryAllowedCharacterSet = CharacterSet.urlQueryAllowed
		urlQueryAllowedCharacterSet.remove(charactersIn: ":#[]@!$&'()*+,;=")
		return urlQueryAllowedCharacterSet
	}()
	
	private func URLQueryEncodedString(from string: String) -> String {
		return string.addingPercentEncoding(withAllowedCharacters: BaseRequestManager.URLQueryAllowedCharacterSet) ?? ""
	}
	
	// MARK: application/x-www-form-urlencoded encoding
	
	private func formURLEncodedString(from string: String) -> String {
		// For algorithm description see: https://www.w3.org/TR/html5/forms.html#application/x-www-form-urlencoded-encoding-algorithm
		var formURLEncodedAllowedCharacterSet = CharacterSet.alphanumerics
		formURLEncodedAllowedCharacterSet.insert(charactersIn: "*-._+")
		return string.replacingOccurrences(of: " ", with: "+").addingPercentEncoding(withAllowedCharacters: formURLEncodedAllowedCharacterSet) ?? ""
	}
	
	// MARK: - Thread/task management
	
	private static let requestThread: Thread = {
		let requestThread = Thread(target: BaseRequestManager.self, selector: #selector(requestThreadEntryPoint), object: nil)
		requestThread.name = "RequestManagerThread"
		requestThread.start()
		
		return requestThread
	}()
	
	// Changed argument "object" type from "Any" to "Any?" to prevent crashing on swift 4.1
	@objc
	private static func requestThreadEntryPoint(_ object: Any?) {
		autoreleasepool {
			let currentRunLoop = RunLoop.current
			currentRunLoop.add(Port(), forMode: RunLoop.Mode(rawValue: RunLoop.Mode.default.rawValue))
			currentRunLoop.run()
		}
	}
	
	// MARK: - Connection management
	
	// New 2017 ~ start logic should be controlled in child classes (not in base ~ i.e. transport layer)
	/**
	Starts request implementation on separate thread.
	
	**Warning**
	
	This method should be used when autostart of connection is disabled
	*/
	func startConnection() {
		guard !autoStart else { return }
		
		manualStartCondition.lock()
		
		while (rmConnection == nil) {
			manualStartCondition.wait()
		}
		
		perform(#selector(restartConnectionWithTimeout), on: BaseRequestManager.requestThread, with: nil, waitUntilDone: false, modes: [RunLoop.Mode.common.rawValue])
		
		manualStartCondition.unlock()
	}
	
	/**
	Cancel current performed connection.
	
	**Warning**
	
	This method user to terminate connection while performing request. When this method called, success & cancellation methods is not fired.
	*/
	func cancelConnection(_ reason: Any? = nil) {
		// Since this method can be called from any thread invalidate timer on the thread it was scheduled on
		perform(#selector(releaseTimeoutTimer), on: BaseRequestManager.requestThread, with: nil, waitUntilDone: true)
		//print("cancel connection with path: \(String(describing: rmConnection?.originalRequest.url?.absoluteString))")
		
		rmConnection?.cancel()
		rmConnection = nil
		
		// Удаляем ссылки на блоки. Это необходимо для случая, когда один из этих блоков поставлен в очередь на исполнение,
		// но в случае отмены мы не хотим, чтобы эти блоки были вызваны
		successBlock = nil
		progressBlock = nil
		errorBlock = nil
	}
	
	@objc
	private func restartConnectionWithTimeout() {
		rmConnection?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.common)
		rmConnection?.start()
		
		requestTimeoutTimer = Timer.scheduledTimer(timeInterval: self.timeoutInterval, target: self, selector: #selector(connectionTimeout), userInfo: nil, repeats: false)
	}
	
	// MARK: - NSURLConnectionDataDelegate
	
	func connection(_ connection: NSURLConnection, willSend request: URLRequest, redirectResponse response: URLResponse?) -> URLRequest? {
		return request
	}
	
	func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
		releaseTimeoutTimer()

		// COOKIES: old (not used)
//		var stringUrl: String = ""
//		if let url = response.url, let scheme = url.scheme, let host = url.host {
//			stringUrl = "\(String(describing: scheme))://\(String(describing: host))"
//		}
//		
//		let baseUrl = URL(string: stringUrl)!
//		
//		// Update coockies if it is available (by updating we will merge existed coockies with new received)
//		let recievedCookies = HTTPCookie.cookies(withResponseHeaderFields: (response as! HTTPURLResponse).allHeaderFields as! [String: String], for: baseUrl)
//		if recievedCookies.count > 0 {
//			if let reqManDelegate: BaseRequestManagerDelegate = tryToGetRequestManagerDelegate() {
//				reqManDelegate.requestManager?(self, didCookieRecieved: recievedCookies, url: stringUrl)
//			}
//		}
		
		guard let httpUrlResponse = response as? HTTPURLResponse else { return }
		
		rmResponse = httpUrlResponse
		
		// If we received unexpected mime type
		let responseMimeType = httpUrlResponse.mimeType ?? ""
		if !expectedMimeTypes().contains(responseMimeType) { // Use empty string for safety reasons
			print("Unexpected mime type received: \"\(responseMimeType)\"")
			rmConnection?.cancel()
			rmConnection = nil
			failWithResponse(rmResponse!)
			return
		}
		
		let statusCode: Int = httpUrlResponse.statusCode
		
		// If we received unsupported response status code
		if !needToReloginResponseCodes().contains(statusCode), !supportedResponseCodes().contains(statusCode) {
			print("Received unsupported response status code: \(statusCode)")
			rmConnection?.cancel()
			rmConnection = nil
			failWithResponse(rmResponse!)
			return
		}
	}
	
	func connection(_ connection: NSURLConnection, didReceive data: Data) {
		// For requests marked as sequential we don't collect arrived data but instead directly provide data chunks to block and delegate
		if !isSequential {
			receivedData.append(data)
		}
		
		receivedContentLength += data.count
		
		// URL upload progress
		if progressBlock != nil {
			let receivedContentLength = self.receivedContentLength
			
			let dataCopy: Data//isSequential ? data : receivedData
			if isSequential {
				dataCopy = data
			} else {
				dataCopy = receivedData
			}
			
			let isCallbackQueueMainQueue = callbacksQueue === DispatchQueue.main
			
			performBlock { [weak self] in
				guard let self = self else { return }
				guard let progressBlock = self.progressBlock else { return }
				
//				print("progressBlock didReceiveData. \(String(describing: self.requestUrlString))")
				
				if isCallbackQueueMainQueue {
					// Т.к main queue - serial queue(в один момент времени исполняется только один блок) мы опускаем блокировку мьютексом
					progressBlock(receivedContentLength, Int(self.rmResponse?.expectedContentLength ?? 0), dataCopy)
				} else {
					// TODO: Сделал на сам рекмэн, т.к не нужно кастить как в случае receivedData
					
					// Блокировка необходима для регулирования порядка исполнения блоков. Благодаря ей мы всегда будем исполнять блоки по порядку
					// даже если он помещается в concurrent queue.
					DispatchManager.synchronized(self) {
						progressBlock(receivedContentLength, Int(self.rmResponse?.expectedContentLength ?? 0), dataCopy)
					}
				}
			}
		}
		
		//>>v1 plain content logic
		delegate?.requestManager?(self, didDataRecieved: data.count, with: receivedContentLength, with: Int(rmResponse?.expectedContentLength ?? 0))
		///<
		
		//>>v2 uncompresion content logic
		/*
		NSMutableData *plainData = nil;
		if ([receivedContentEncoding rangeOfString:@"gzip"].location != NSNotFound)
		{
		// save uncompressed (NSURLConnection automatically uncompresses gzip that configured on the server) gzip content after receiving
		plainData = [[NSMutableData dataWithData:receiveData] retain];
		}
		else if ([receivedContentEncoding rangeOfString:@"deflate"].location != NSNotFound)
		{
		//TODO: save & uncompress zlib (zip lib) content after receiving
		NSMutableData *uncompressedData = ...;
		plainData = [[NSMutableData dataWithData:uncompressedData] retain];
		}
		else
		{
		//TODO: nothing
		plainData = [[NSMutableData dataWithData:receiveData] retain];
		}
		NSUInteger dataSize = [plainData length];
		id<BaseRequestManagerDelegate> reqManDelegate = [self tryToGetRequestManagerDelegate];
		if (reqManDelegate && [(id)reqManDelegate respondsToSelector:@selector(requestManager:didDataRecieved:withTotal:withExpected:)])
		[reqManDelegate requestManager:self didDataRecieved:dataSize withTotal:dataSize withExpected:dataSize];
		*/
		///<
	}
	
	// Used when upload data
	func connection(_ connection: NSURLConnection, didSendBodyData bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite: Int) {
		// TODO: delegate or block
		
		delegate?.requestManager?(self, didDataSent: bytesWritten, with: totalBytesWritten, with: totalBytesExpectedToWrite)
		
		// URL upload progress
		if progressBlock != nil {
			let isCallbackQueueMainQueue = callbacksQueue === DispatchQueue.main
			
			performBlock { [weak self] in
				guard let self = self else { return }
				guard let progressBlock = self.progressBlock else { return }
				
				print("progressBlock didReceiveData")
				
				if isCallbackQueueMainQueue {
					progressBlock(totalBytesWritten, totalBytesExpectedToWrite, nil)
				} else {
					DispatchManager.synchronized(self) {
						progressBlock(totalBytesWritten, totalBytesExpectedToWrite, nil)
					}
				}
			}
		}
	}
	
	func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
		releaseTimeoutTimer()
		
		let err = error as NSError
		//print("connection failed: \(err.localizedDescription)")
		
		if err.code == NSURLErrorTimedOut {
			// TODO: custom handling of connection timeout
			let url = err.userInfo[NSURLErrorFailingURLStringErrorKey] != nil ? err.userInfo[NSURLErrorFailingURLStringErrorKey] : connection.originalRequest.url?.absoluteString
			print("Connection timeout to the URL \(String(describing: url))")
		}
		
		failWithError(err)
	}
	
	func connectionDidFinishLoading(_ connection: NSURLConnection) {
		// Denis Morozov: Передача NULL или пустого обьекта NSData в progressBlock сейчас нигде не используется, поэтому посчитали, что код
		// можно закоментить и возможно удалить позже. Хотя у Васи был кейс, когда 0 означает 100% прогресса и можно закрыть файл,
		// но с другой стороны для этого есть successBlock
		
		//TODO: Need to read isSubsequent flag from local configuration
//		if let progress = progressBlock, isSubsequent {
//			let queue = type(of: self).configuration.queue ?? DispatchQueue.main
//			queue.async {
//				// Check block second time because it can be released while we are switching to main queue (process result in UI)
//				Dispatch.synchronized(self.receivedData! as NSData) {
//					if let receivedData = self.receivedData, receivedData.count > 0 {
//						// We have received last pie of data i.e. total = expectedContentLength
//						print("progressBlock didReceiveData")
//						progress(self.expectedContentLength!, self.expectedContentLength!, receivedData)
//						self.receivedData!.count = 0
//					}
//				}
//				return
//			}
//		}
		
		// json checking
		if let rmResponse = rmResponse, let responseMimeType = rmResponse.mimeType {
			if responseMimeType.hasSuffix("/json") || responseMimeType.hasSuffix("/x-json") {
				do {
					finishWithData(try JSONSerialization.jsonObject(with: receivedData, options: []))
				} catch {
					print("runRequestWithPath jsonData error:  \(error.localizedDescription)")
					failWithResponse(rmResponse)
				}
			} else if responseMimeType.hasPrefix("text/") || responseMimeType.hasSuffix("/text"), let textString = String(data: receivedData, encoding: .utf8) {
				finishWithData(textString)
			} else /*if receivedMimeType == "application/octet-stream" || receivedMimeType.contains("image/")*/ {
				finishWithData(receivedData)
			}
		} else {
			finishWithData(receivedData)
		}
	}
	
	// MARK: - Internal connection methods
	
	@objc
	private func applicationEnterForeground(notification: Notification) {
		// TODO: Feature - Попытка восстановить запрос
	}
	
	@objc
	private func applicationEnterBackground(notification: Notification) {
		// Since this method can be called from any thread, mostly from the main thread, invalidate timer on the thread it was scheduled on
		perform(#selector(releaseTimeoutTimer), on: type(of: self).requestThread, with: nil, waitUntilDone: true)
	}
	
	// Т.к приложение выгружается из памяти, то нет смысла удалять таймер
//	@objc
//	private func applicationWillTerminateNotification(notification: Notification) {
//		// Since this method can be called from any thread, mostly from the main thread, invalidate timer on the thread it was scheduled on
//		perform(#selector(releaseTimeoutTimer), on: type(of: self).requestThread, with: nil, waitUntilDone: true)
//	}
	
	@objc
	private func connectionTimeout(_ timer: Timer) {
		releaseTimeoutTimer()
		
		if NetworkConnectionManager.shared.isInternetAvailable() {
//			print("Connection timeout interruption for URL: \(rmConnection?.originalRequest.url?.absoluteString)")
			rmConnection?.cancel()
			rmConnection = nil
			
			if errorBlock != nil {
				performBlock { [weak self] in
					guard let self = self else { return }
					// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
					// пока мы ожидали начала выполнения этого блока
					guard let errorBlock = self.errorBlock else { return }
					
					let err = RequestError()
					err.params = ["header": self.headers, "body": self.parameters]
					err.isConnectionError = true
					err.code = NSURLErrorTimedOut
					errorBlock(err)
				}
			}
		}
	}
	
	// MARK: - BaseRequestManagerDelegate synonyms(when in inherited class this methods is not implemented)
	
	private func finishWithData(_ dataObj: Any) {
		if let delegate = delegate, delegate.responds(to: #selector(BaseRequestManagerDelegate.requestManager(_:didFinishWithData:))) {
			delegate.requestManager!(self, didFinishWithData: dataObj)
		}
		
		let result = (!isSequential && !useRawData) ? processReceivedData(dataObj, with: self) : dataObj
		
		if let error = result as? RequestError {
			if errorBlock != nil {
				performBlock { [weak self] in
					guard let self = self else { return }
					// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
					// пока мы ожидали начала выполнения этого блока
					guard let errorBlock = self.errorBlock else { return }
					
					error.params = ["header": self.headers, "body": self.parameters]
					error.response = self.rmResponse
					errorBlock(error)
				}
			}
		} else if successBlock != nil {
			performBlock { [weak self] in
				guard let self = self else { return }
				// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
				// пока мы ожидали начала выполнения этого блока
				guard let successBlock = self.successBlock else { return }
				successBlock(result)
			}
		}
	}
	
	private func failWithResponse(_ response: HTTPURLResponse) {
		if let delegate = delegate, delegate.responds(to: #selector(BaseRequestManagerDelegate.requestManager(_:didFailWithResponse:))) {
			delegate.requestManager!(self, didFailWithResponse: response)
		}
		
		guard errorBlock != nil else { return }
		
		let err = RequestError()
		err.params = ["header": headers, "body": parameters]
		err.response = response
		if !expectedMimeTypes().contains(response.mimeType!) {
			err.msg = "\(#function): Unexpected mime type \(response.mimeType!)"
		}
		
		let statusCode: Int = response.statusCode
		
		// Is we have received "Not autorized" error code then process need to login case
		if needToReloginResponseCodes().contains(statusCode) {
			err.isConnectionError = false
			err.needToRelogin = true
			err.errorDataEx = response
			err.msg = "\(#function): Need to relogin with status code \(statusCode)"
		}
		// If we have received error code that can or should be processed on client in error block then mark that eror is not connection error
		else if supportedResponseCodes().contains(statusCode) {
			err.isConnectionError = false
			err.msg = "\(#function): Supported error response with status code \(statusCode)"
		}
		// Otherwise this error with status code >= 400 is connection error
		else {
			err.isConnectionError = false
			err.msg = "\(#function): Connection error with status code \(statusCode)"
		}
		
		if let url = response.url, let host = url.host  {
			err.error = NSError(domain: host, code: statusCode == 404 ? NSURLErrorBadURL : NSURLErrorUnknown, userInfo: ["statusCode": statusCode])
		}
		
		performBlock { [weak self] in
			guard let self = self else { return }
			// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
			// пока мы ожидали начала выполнения этого блока
			guard let errorBlock = self.errorBlock else { return }
			errorBlock(err)
		}
	}
	
	private func failWithError(_ error: NSError) {
		if let delegate = delegate, delegate.responds(to: #selector(BaseRequestManagerDelegate.requestManager(_:didFailWithError:))) {
			delegate.requestManager!(self, didFailWithError: error)
		}
		
		guard errorBlock != nil else { return }
		
		let err = RequestError()
		err.params = ["header": headers, "body": parameters]
		err.isSuccess = false
		err.isConnectionError = error.isConnectionError
		err.error = error
		err.msg = "\(#function): \(error.debugDescription)"
		
		//THIS WILL PRINT FULL REQUEST WITH PARAMS!!!! DO NOT FUCKING DELETE IT!!!
		//print("request url: \(requestUrlString!)")
		//print("request params json: \(paramsObjectString!)")
		
		performBlock { [weak self] in
			guard let self = self else { return }
			// Выполняем дальнейшие действия только после успешного захвата блока, т.к он может уйти из памяти
			// пока мы ожидали начала выполнения этого блока
			guard let errorBlock = self.errorBlock else { return }
			errorBlock(err)
		}
	}
	
	// MARK: - Blocks wrapping
	
	func wrapSuccess(with block: ((RequestSuccessBlock?, Any) -> ())?) {
		let oldSuccessBlock = successBlock
		successBlock = { (data: Any) in
			block?(oldSuccessBlock, data) }
	}
	
	func wrapError(with block: ((RequestErrorBlock?, RequestError) -> ())?) {
		let oldErrorBlock = errorBlock
		errorBlock = { (error: RequestError) in
			block?(oldErrorBlock, error) }
	}
	
	// MARK: - Helpers
	
	@objc
	private func releaseTimeoutTimer() {
		requestTimeoutTimer?.invalidate()
		requestTimeoutTimer = nil
	}
	
	private func performBlock(_ block: @escaping () -> ()) {
		if let callbacksQueue = callbacksQueue {
			callbacksQueue.async {
				block()
			}
		} else {
			block()
		}
	}

}

// MARK: - RequestManagerState

extension BaseRequestManager: RequestManagerState {
	var statusCode: Int {
		return rmResponse?.statusCode ?? 0
	}
	
	var responseHeaders: [String : String] {
		return rmResponse!.allHeaderFields as? [String: String] ?? [String: String]()
	}
	
	var requestURL: String {
		return rmRequest?.url?.absoluteString ?? ""
	}
}
