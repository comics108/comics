//
//  RequestManager+Download.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 08 Sep 2017.
//  Updated by Andrey Kozlov on 03 Dec 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//
//  Changes history:
//      11 Jul 2018. Olga Zhegulo:
//          * fix for overflow in hash of parameters (request with cache)
//             - replaced += with ^=  in calculateHashForDictionary(_:)
//      12 Jul 2018. Olga Zhegulo.
//          * fix for overflow in hashes of headers and query strings (request with cache)
//             - replaced += with ^= in fileName(for urlComponents: headers: parameters:) -> String
//      13 Jul 2018. Olga Zhegulo:
//          * fix for image scale/size in downloadImage(...)
//      08 Nov 2018. Sergey Vasilyev:
//          * renamed CacheType `static` to staticAlways. Added max-age control case
//      13 Nov 2018. Sergey Vasilyev:
//          * fixed force unwrapping. Added documentation for download method
//      20 Nov 2018. Vasiliy Ursu:
//          * fully updated logic of cache types processing + added correct support of offline modes & restoring connection
//      21 Nov 2018. Andrey Kozlov:
//          * remove downloadImage()
//          * rename download() to performRequest()
//          * transfer all cache methods to RequestManager+Cache
//		03 Dec 2018. Andrey Kozlov:
//			* restored downloadData() (for backward compatibility), added downloadString()
//

import UIKit

extension RequestManager {
    // MARK: - Public methods
    
    /// TODO: possible need to overwrite isSequential property of configuration
	///	When downloaded file and has internet connection problems we can`t provide garanty that by using retries file will be downloaded without errors (i.e. when downloading started and not completed, after retry we continue write to file). Therefore we disabled offline mode and retries in default method configuration.
    @discardableResult
    static func downloadFile(fileUrl: String,
                             method: String,
                             headers: [String: String]? = nil,
							 parameters: AnyObject? = nil,
                             configuration: RequestManagerConfiguration = sharedConfiguration.isSequential(true).retriesCount(0).offlineModeSupport(false),
                             contextKey: AnyHashable?,
                             cacheType: CacheType,
                             cachePath: String?,
                             path: String?,
                             success: CacheRequestSuccessBlock?,
                             progress: RequestProgressBlock?,
                             error: RequestErrorBlock?) -> Self? {
        let configQueue: DispatchQueue? = configuration.queue
        
        return performRequest(absoluteUrl: fileUrl,
                        method: method,
                        headerParams: headers,
                        parameters: parameters,
                        configuration: configuration,
                        contextKey: contextKey,
                        cacheType: cacheType,
                        cachePath: cachePath,
                        path: path,
                        success: { (dataObj: Any, isFromCache: Bool) in
                            DispatchManager.perform(on: configQueue) { success?(dataObj, isFromCache) } },
                        progress: { (bytes: Int, totalBytes: Int, data: Data?) in
                            DispatchManager.perform(on: configQueue) { progress?(bytes, totalBytes, data) } },
                        error: { (err: RequestError) in
                            DispatchManager.perform(on: configQueue) { error?(err) } })
    }
	
	@discardableResult
	static func downloadData(absoluteUrl: String,
							 method: String,
							 headers: [String: String]?,
							 parameters: AnyObject?,
							 configuration: RequestManagerConfiguration = sharedConfiguration.useRawData(true),
							 contextKey: AnyHashable?,
							 cacheType: CacheType,
							 success: CacheRequestGenericSuccessBlock<Data?>?,
							 progress: RequestProgressBlock?,
							 error: RequestErrorBlock?) -> Self? {
		let configQueue: DispatchQueue? = configuration.queue
		
		return performRequest(absoluteUrl: absoluteUrl,
						method: method,
						headerParams: headers,
						parameters: parameters,
						configuration: configuration,
						contextKey: contextKey,
						cacheType: cacheType,
						cachePath: nil,
						path: nil,
						success: { (dataObj: Any, isFromCache: Bool) in
							DispatchManager.perform(on: configQueue) { success?(dataObj as? Data, isFromCache) } },
						progress: { (bytes: Int, totalBytes: Int, data: Data?) in
							DispatchManager.perform(on: configQueue) { progress?(bytes, totalBytes, data) } },
						error: { (err: RequestError) in
							DispatchManager.perform(on: configQueue) { error?(err) } })
	}
	
	static func downloadString(stringUrl: String,
									headers: [String: String]?,
									parameters: AnyObject?,
									configuration: RequestManagerConfiguration = sharedConfiguration.useRawData(true),
									contextKey: AnyHashable?,
									cacheType: CacheType,
									encoding: String.Encoding = .utf8,
									success: CacheRequestGenericSuccessBlock<String?>?,
									progress: RequestProgressBlock?,
									error: RequestErrorBlock?) -> Self? {
		let configQueue: DispatchQueue? = configuration.queue
		
		return performRequest(absoluteUrl: stringUrl,
							  method: "text/plain",
							  headerParams: headers,
							  parameters: parameters,
							  configuration: configuration,
							  contextKey: contextKey,
							  cacheType: cacheType,
							  cachePath: nil,
							  path: nil,
							  success: { (dataObj: Any, isFromCache: Bool) in
								DispatchManager.perform(on: configQueue) {
									if let data = dataObj as? Data {
										let value = String.init(data: data, encoding: encoding)
										success?(value, isFromCache)
									} else if JSONSerialization.isValidJSONObject(dataObj), let data = try? JSONSerialization.data(withJSONObject: dataObj, options: []) {
										let value = String.init(data: data, encoding: encoding)
										success?(value, isFromCache)
									} else {
										success?(String(describing: dataObj), isFromCache)
									}}},
							  progress: progress,
							  error: error)
     }
	
    public static func getFileSize(for url: String,
                                    usePreload: Bool,
                                    contextKey: AnyHashable?,
                                    success: RequestSuccessBlock?,
                                    error: RequestErrorBlock?) -> RequestManager? {
        var reqMan: RequestManager?
        if usePreload {
            // let headers = ["Content-Type" : "application/octet-stream"]
            //            reqMan = performRequest(requestPath: url,
            //                                    configuration: nil,
            //                                    errorDelegate: nil,
            //                                    headers: headers,
            //                                    parameters: nil,
            //                                    method: "GET",
            //                                    contextKey: contextKey,
            //                                    success: nil,
            //                                    progress: { (bytes: Int, totalBytes: Int, data: Data?) in
            //                                        success?(totalBytes as AnyObject)
            //                                        reqMan?.cancelConnection() },
            //                                    error: error)
        } else {
            /*
             if let url = URL(string: url) {
             var request = URLRequest(url: url)
             request.httpMethod = "HEAD"
             
             URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, err: Error?) in
             if let e = err, error != nil {
             let requestErr = RequestError()
             requestErr.error = e as NSError
             error?(requestErr)
             } else {
             success?(response?.expectedContentLength as AnyObject)
             } }
             ).resume()
             }
             */
            reqMan = performRequest(path: url,
                                    method: "HEAD",
                                    headers: nil,
                                    parameters: nil,
                                    errorDelegate: nil,
                                    contextKey: contextKey,
                                    success: { (dataObj: Any) in
                                        //                                        let contentLength = reqMan?.expectedContentLength
                                        //                                        success?(contentLength as AnyObject)
            },
                                    progress: nil,
                                    error: error)
        }
        
        return reqMan
    }
    
}
