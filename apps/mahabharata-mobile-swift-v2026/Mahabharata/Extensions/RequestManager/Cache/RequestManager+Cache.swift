//
//  RequestManager+Cache.swift
//  RequestManager
//
//  Created by Stanislav Grinberg on 08 Sep 2017.
//  Updated by Andrey Kozlov on 21 Nov 2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//
//  Changes history:
//      08 Nov 2018. Sergey Vasilyev:
//          * renamed CacheType `static` to staticAlways. Added max-age control case
//      13 Nov 2018. Sergey Vasilyev:
//          * fixed force unwrapping. Added documentation for download method
//          * added using CacheManager
//      20 Nov 2018. Vasiliy Ursu:
//          * fully updated logic of cache types processing + added correct support of offline modes & restoring connection
//      21 Nov 2018. Andrey Kozlov:
//          * remove downloadImage()
//          * added timer scheduler example
//		25 Jan 2019. Olga Zhegulo:
//			* fixed success of performRequest for case of simple types (e.g. Int, String)
//

import UIKit

// Examples of calculatiob cache path's
// 1) absoluteUrl, 2) cachePath, 3) writeToFile
//
// * 1) ... 2) ... 3) ... => fileName = ... , filePath = <CACHE_PATH>|<LOCAL_PATH>/... (fileName)
//
// * host: www.tomato-pizza2.u-sl.ru, relativePath: /image/uploaded/146833193630151.png, query: a=b&1=2
//
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/146833193630151.png?a=b&1=2" 2) cachePath = "Avatars/150/avatar_50.png" 3) writeToFile = "/Files/"
//    => fileName = "avatar_50.png", filePath = "Avatars/150/avatar_50.png"
//
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/146833193630151.png?a=b&1=2" 2) cachePath = <"Avatars/150/">|<"/"> 3) writeToFile = "/Files/"
//    => fileName = "146833193630151.png", filePath = "Avatars/150/146833193630151.png"
// *
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/146833193630151.png?a=b&1=2" 2) cachePath = <"">|<nil> 3) writeToFile = "/Files/"
//    => fileName = "146833193630151.png", filePath = "ApplicationDirectory/Documents/Files/146833193630151.png"
// *
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/146833193630151.png?a=b&1=2" 2) cachePath = "Avatars/150/avatar_50.png" 3) writeToFile = nil
//    => fileName = "avatar_50.png", filePath = "Avatars/150/avatar_50.png"
// *
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/" 2) cachePath = <"Avatars/150/">|<"/"> 3) writeToFile = nil
//    => fileName = "<HASH>("www.tomato-pizza2.u-sl.ru")_<HASH>("/image/uploaded/146833193630151.png")_<HASH>("a=b&1=2")", filePath = "Avatars/150/<HASH>("www.tomato-pizza2.u-sl.ru")_<HASH>("/image/uploaded/146833193630151.png")_<HASH>("a=b&1=2")"
// *
// * 1) absoluteUrl = @"http://www.tomato-pizza2.u-sl.ru/image/uploaded/146833193630151.png?a=b&1=2" 2) cachePath = <"">|<nil> 3) writeToFile = nil
//    => fileName = nil    , filePath = nil
// *

extension RequestManager {
    /// Режим кэширования
    enum CacheType {
        /// Без кеширования
        case none
        /// `static` Данные всегда тянутся с кэша, пока не истек период (полагается на max-age в Cache-control в заголовке)
        case staticAlways
        /// Данные тянет из кеша, но делается запрос к серверу с датой (берем unix time дату в записи кэша на клиенте cachedFileAttributes[FileAttributeKey.creationDate])
        case dynamic
        /// При отсутствии инета, данные подтянутся из кеша
        case offline
        /// Два раза вызывается блок success, первый из кеша, второй с сервера
        case smart
        /// Нет и никогда не будет режима когда нет интернета и данные взялись из кэша, а когда интернет появился - сами взялись из интернета (этот режим программируется ВСЕГДА вручную!!!)
        //case fantasy
    }
    
    typealias CacheRequestSuccessBlock = (Any, Bool) -> ()
	typealias CacheRequestGenericSuccessBlock<T> = (T, Bool) -> ()

    private static let fileQueue = DispatchQueue(label: "RequestManagerExtensionFileQueue")
    
    /**
     Download method.
     
     - When cachePath is specified then he will have priority vs path (when cachePath is not contains fileName then it will be extracted from absoluteUrl, otherwise - generated).
     - When cachePath is empty and path is specified then it be used (when path is not contains fileName then it will be extracted from absoluteUrl, otherwise - generated).
     - When both cachePath and path is empty then data will not be cached and stored in file.
     
     - Note: If we have cachePath we will not write to file!
     
     If cachePath or path will be specified like "/some" or "some" directory will not be created and file "some" may be overwritten.
     
     - Parameter absoluteUrl: An String of absolute url.
     - Parameter method: Request method.
     - Parameter headerParams: Header parameters of request.
     - Parameter parameters: Parameters of request.
     - Parameter configuration: Configuration of Request Manager for request. Default is sharedConfiguration.
     - Parameter contextKey: Context key for connection cancellation.
     
     - Parameter cacheType: Cache setting. Cache type for using Cache Manager.
     - Parameter cachePath: Cache setting. Relative to cahceDir path.
     - Parameter path: Cache setting. Relative to docs dir path.
     
     - Parameter success: Success block.
     - Parameter progress: Progress block.
     - Parameter error: Error block.
     
     - Returns: Returns instance of self.
     */
    @discardableResult
    static func performRequest(absoluteUrl: String,
                               method: String,
                               headerParams: [String: String]? = nil,
                               parameters: Any?,
                               configuration: RequestManagerConfiguration = sharedConfiguration,
                               contextKey: AnyHashable? = nil,
                               cacheType: CacheType,
                               cachePath: String? = nil,
                               path: String? = nil,
                               success: CacheRequestSuccessBlock?,
                               progress: RequestProgressBlock? = nil,
                               error: RequestErrorBlock?) -> Self? {
        
        if self == RequestManager.self {
            NSException(
                name: .internalInconsistencyException,
                reason: "Need to call this method from local RequestManager (<ProjectName>RequestManager)",
                userInfo: nil).raise()
        }
        
        if configuration.isSequential && cacheType != .none {
            print("WARNING: When specified file path and caching mode then two files will be created in cache and documents directories!\nUsing path param assume that data can have big size and caching + process object in memory is not expected.")
            NSException(
                name: .internalInconsistencyException,
                reason: "When specified file path and caching mode then two files will be created in cache and documents directories!\nUsing path param assume that data can have big size and caching + process object in memory is not expected.",
                userInfo: nil).raise()
        }
        
        let localConfig = RequestManagerConfiguration(configuration: configuration)
        localConfig.autoStart = true
        localConfig.retriesCount = 0
        localConfig.isSequential = !(path ?? "").isEmpty
        //localConfig.queue = (localConfig.isSequential || cacheType != .none) ? fileQueue : nil
        if localConfig.isSequential || cacheType != .none {
            localConfig.queue = fileQueue
        }
        
        /* TODO: replace with short syntax
         let localConfig = configuration.copy().autoStart(true).retriesCount(0).isSequential(path != nil && !path!.isEmpty)
         localConfig.queue = (localConfig.isSequential || cacheType != .none) ? fileQueue : nil
         */
        
        // Build file path
        var filePath: String?
        if cacheType != .none {
            filePath = buildCachePath(for: absoluteUrl, path: cachePath, headers: headerParams, parameters: parameters)
        } else if let path = path, !path.isEmpty {
            filePath = buildCachePath(for: absoluteUrl, path: path, headers: headerParams, parameters: parameters)
        }
        
        let cacheMan: CacheManager? = cacheType != .none ? CacheManager.globalCache : nil
        
        var successPerfomed = false
        // If we already have cached file then return it
        if (cacheType == .staticAlways || cacheType == .smart), let cacheMan = cacheMan, cacheMan.hasCache(forPath: filePath) {
            var resultObj: AnyObject? = nil
            if localConfig.isSequential {
                let absoluteFilePath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                resultObj = absoluteFilePath.appendingPathComponent(filePath!) as AnyObject
            } else {
                resultObj = cacheMan.object(forPath: filePath!)
            }
            
            if let cachedObject = resultObj {
                successPerfomed = true
                success?(cachedObject, true)
                
                // When data already present in cache then return it, otherwise - need to request new data
                if cacheType == .staticAlways {
                    return nil
                }
            }
        }
        
        // Create file if needed and open it for writing only when writeToFile = true
        var file: FileHandle?
        if localConfig.isSequential {
            DispatchManager.perform(on: fileQueue) { file = self.createFile(with: filePath!) }
        }
        
        // Update headers
        var headers: [String: String] = headerParams ?? [:]
        if cacheType == .dynamic, let cacheMan = cacheMan, cacheMan.hasCache(forPath: filePath), let cachedFileAttributes = try? FileManager.default.attributesOfItem(atPath: cacheMan.buildAbsolutePath(relativePath: filePath)) {
            headers["If-Modified-Since"] = htmlDateString(for: cachedFileAttributes[FileAttributeKey.creationDate] as? Date)
        }
        
        // Для автоматического выведения типа, который будет равен Self
        var reqMan = self.init(errorDelegate: nil, contextKey: "", configuration: localConfig)
        reqMan = performRequest(path: absoluteUrl,
                                method: method,
                                headers: headers,
                                parameters: parameters,
                                configuration: localConfig,
                                contextKey: contextKey,
                                success: { (data: Any?) in
                                    //print(absoluteUrl)
                                    var resultObj: AnyObject? = nil
                                    
                                    // Флаг, используемый как признак, что данные не изменились - важно для If-Modified-Since, .dynamic
                                    var isEmpty: Bool = false
                                    // When .dynamic + server returned empty collection then return data from cache and mark it as cached
                                    var isFromCache = false
                                    
                                    if !localConfig.isSequential {
                                        if let obj = data as? [String: Any] {
                                            resultObj = obj as AnyObject
                                            isEmpty = obj.keys.count == 0
                                        } else if let obj = data as? [Any] {
                                            resultObj = obj as AnyObject
                                            isEmpty = obj.count == 0
                                        } else if let obj = data as? Data {
											// Always, when some NSData/Data and else, when image downloaded, then it will be saved as .png/.jpeg file with plain NSData/Data, i.e. not PNG/JPEG representation
                                            resultObj = obj as AnyObject
                                            isEmpty = obj.count == 0
										} else if let obj = data {
											resultObj = obj as AnyObject
											isEmpty = !(obj is String) ? String(describing: obj).count == 0 : false
										} else {
                                            isEmpty = false
                                        }
                                        
                                        // Cache (store in cache) data when it needed
                                        if cacheType != .none, let cacheMan = cacheMan {
                                            if !isEmpty, let cacheData = resultObj {
                                                cacheMan.setObject(cacheData, forPath: filePath!)
                                            }
                                            
                                            if isEmpty, let cachedObject = cacheMan.object(forPath: filePath!) {
                                                resultObj = cachedObject
                                                isFromCache = true
                                                // When data is not modified then try to return from cache
                                                //print("not modified received")
                                            }
                                        }
                                        
                                    } else {
                                        file?.closeFile()
                                        let absoluteFilePath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                                        
                                        resultObj = absoluteFilePath.appendingPathComponent(filePath!) as AnyObject
                                        isFromCache = false
                                    }
                                    // .dynamic не может придти сюда из error блока, т.к. если попал туда - то он стопает обработку
                                    /*
                                     // Если .dynamic возвращал в error блоке данные то ничего не делаем
                                     if !(cacheType == .dynamic && successPerfomed) {
                                     success?(resultObj as Any, isFromCache)
                                     }
                                     */
                                    success?(resultObj as Any, isFromCache) },
                                progress: { (bytes: Int, totalBytes: Int, data: Data?) in
                                    if localConfig.isSequential {
                                        if let data = data, data.count > 0 {
                                            //print("write portion, bytes: \(bytes), totalBytes: \(totalBytes)")
                                            file?.write(data)
                                        }
                                    }
                                    progress?(bytes, totalBytes, data) },
                                error: { (err: RequestError) in
                                    if err.isConnectionError, cacheType != .none, let cacheMan = cacheMan, cacheMan.hasCache(forPath: filePath) {
                                        var resultObj: AnyObject? = nil
                                        if localConfig.isSequential {
                                            let absoluteFilePath: NSString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                                            resultObj = absoluteFilePath.appendingPathComponent(filePath!) as AnyObject
                                        } else {
                                            resultObj = cacheMan.object(forPath: filePath!)
                                        }
                                        
                                        //Note: .smart может работать также как и .offline (по аналогии с Android) если для в сочетании со .smart указать autoConnect = false НО ТОЛЬКО ДЛЯ СЛУЧАЯ ОТСУТСТВИЯ ИНТЕРНЕТА!
                                        if let cachedResult = resultObj {
                                            // если необходимо чтобы в smart если есть даные в кэше один раз отрабатывал блок - то задаем в конфигурации autoConnect = false
                                            switch cacheType {
                                            case .smart:
                                                if !err.isHandled {
                                                    // Mark that exception already handled in error block
                                                    err.isHandled = true
                                                    // When success block with cached data is not invoked then call it
                                                    if !successPerfomed {
                                                        successPerfomed = true
                                                        success?(cachedResult as Any, true)
                                                    }
                                                }
                                                // When it's internet connection or waiting internet disabled -> then mark to stop processing re-tries, handling errors & waiting network connection
                                                if err.isConnectionError && !localConfig.autoConnect {
                                                    err.stopProcessing = true
                                                }
                                                return
                                            case .dynamic:
                                                // Mark that exception already handled in error block
                                                err.isHandled = true
                                                if !successPerfomed {
                                                    successPerfomed = true
                                                    success?(cachedResult as Any, true)
                                                }
                                                // ? если .dynamic в случае ошибки должен остановить запрос и ожидание сети то возвращаем данные с кэша и stopProcessing = true
                                                err.stopProcessing = true
                                                return
                                            case .staticAlways:
                                                // Mark that exception already handled in error block
                                                err.isHandled = true
                                                // When success block with cached data is not invoked then call it
                                                if !successPerfomed {
                                                    successPerfomed = true
                                                    success?(cachedResult as Any, true)
                                                }
                                                // Mark to stop processing re-tries, handling errors & waiting network connection
                                                err.stopProcessing = true
                                                return
                                            case .offline:
                                                // Mark that exception already handled in error block
                                                err.isHandled = true
                                                success?(cachedResult as Any, true)
                                                // When it's internert connection -> then mark to stop processing re-tries, handling errors & waiting network connection
                                                if err.isConnectionError {
                                                    err.stopProcessing = true
                                                }
                                                return
                                            default:
                                                error?(err)
                                                return
                                            }
                                        }
                                    }
                                    // Otherwise always call error block ~ as standard behaviour
                                    error?(err) })
        return reqMan
    }
    
    @discardableResult
    static func performRequest(absoluteUrl: String,
                               method: String,
                               headers: [String: String]?,
                               parameters: AnyObject?,
                               configuration: RequestManagerConfiguration = sharedConfiguration,
                               contextKey: AnyHashable?,
                               cacheType: CacheType,
                               //timeInterval: TimeInterval? = nil,
        success: CacheRequestSuccessBlock?,
        progress: RequestProgressBlock?,
        error: RequestErrorBlock?) -> Self? {
        let configQueue: DispatchQueue? = configuration.queue
        
        //var timer: Timer? = nil
        //var refreshed = false
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
                                /*
                                 if let timeInterval = timeInterval {
                                 	if isFromCache {
										timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { (timer: Timer) in
                                 			if !refreshed {
                                 				DispatchManager.perform(on: configQueue) { success?(dataObj, isFromCache) }
                                 			}
                                 		})
                                 	} else {
                                 		timer?.invalidate()
                                 		refreshed = true
                                 		DispatchManager.perform(on: configQueue) { success?(dataObj, isFromCache) }
                                 	}
                                 }
                                 else {*/
									DispatchManager.perform(on: configQueue) { success?(dataObj, isFromCache) }
                                /*} */},
                              progress: { (bytes: Int, totalBytes: Int, data: Data?) in
                                DispatchManager.perform(on: configQueue) { progress?(bytes, totalBytes, data) } },
                              error: { (err: RequestError) in
                                DispatchManager.perform(on: configQueue) { error?(err) } })
    }
    
    // MARK: - Private methods
    
    private static func buildCacheFileName(for urlComponents: URLComponents, headers: [String: String]?, parameters: Any?) -> String {
        var result: [String] = []
        result.append(urlComponents.url!.lastPathComponent)
        if let headers = headers {
            result.append(headers.hashString)
        }
        if let queryItems = urlComponents.queryItems {
            result.append(queryItems.hashString)
        }
        if let parameters = parameters {
            result.append(HashManager.hashString(parameters))
        }
        return result.joined(separator: "_")
    }
    
    private static func buildCachePath(for url: String, path: String?, headers: [String: String]?, parameters: Any?) -> String? {
        if let path = path, !path.hasSuffix("/") {
            return path
        }
        
        let urlComponents = URLComponents(string: url)!
        let fileName = self.buildCacheFileName(for: urlComponents, headers: headers, parameters: parameters)
        
        if let path = path, !path.isEmpty {
            return (path as NSString).appendingPathComponent(fileName)
        } else {
            let urlPath = urlComponents.path
			let directory = String(urlPath.prefix(upTo: urlPath.index(before: urlPath.reversed().firstIndex(of: "/")!.base)))
            if let urlHost = urlComponents.url?.host as NSString? {
                return (urlHost.appendingPathComponent(directory) as NSString).appendingPathComponent(fileName)
            }
        }
        return nil
    }
    
    private static func cache(absoluteUrl: String,
                              headerParams: [String: String]? = nil,
                              parameters: Any?,
                              cachePath: String? = nil) -> (AnyObject & NSCoding)? {
        if let filePath = buildCachePath(for: absoluteUrl,
                                         path: cachePath,
                                         headers: headerParams,
                                         parameters: parameters
            ) {
            return cache(for: filePath)
        }
        return nil
    }
    
    private static func cache(for filePath: String) -> (AnyObject & NSCoding)? {
        let cacheMan: CacheManager = CacheManager.globalCache
        return cacheMan.object(forPath: filePath)
    }
    
    static func remove(cached path: String) {
        CacheManager.globalCache.removeCache(forPath: path)
    }
    
    /// Creates file with all path parts/directories. When file already exists then erases it and returns file handle.
    //private static func createFile(with filePath: String) -> FileHandle? {
    private static func createFile(with filePath: String) -> FileHandle? {
        let fileManager: FileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(filePath)
        
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
            
            let fileCreated: Bool = fileManager.createFile(atPath: path, contents: nil, attributes: nil)
            if !fileCreated {
                NSException(name: .internalInconsistencyException, reason: "Error creating file: \(path)", userInfo: nil).raise()
            }
        }
        
        let fileHandle = FileHandle(forWritingAtPath: path)
        
        // Clean previous data in file
        fileHandle?.truncateFile(atOffset: 0)
        
        return fileHandle
    }
    
    private static func htmlDateString(for date: Date?) -> String {
        guard let date = date else { return "" }
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.timeZone = TimeZone(abbreviation: "GMT")
        df.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        
        return df.string(from: date)
    }
}
