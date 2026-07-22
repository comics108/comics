//
//  MahabharataRequestManager.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 09/10/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//	Server documentation:
//		http://comics.dev.ironwaterstudio.com/help
//

import Foundation
import UIKit

enum HostUrl {
    case host(url: String)
}

extension HostUrl {
    static let production: HostUrl = .host(url: "https://app.mbharata.com")
    static let test: HostUrl = .host(url: "https://new.mbharata.com")
    static let test1: HostUrl = .host(url: "https://new-noproxy.mbharata.com:10823/")
    static let dev: HostUrl = .host(url: "https://dev.mbharata.com/")
}

final class MahabharataRequestManager: RequestManager {
    
    typealias RequestErrorBlock = (RequestError) -> Void
    
    enum RequestErrorCode: Int {
        case success = 0
        case error = 1
        case invalidInputData = 2
        case recordNotFound = 3
        case recordAlreadyExists = 4
        case needToLogin = 5
        case upgradeRequired = 6
        case undefined = 7
        
        init(value: Int?) {
            guard let value = value, 0..<RequestErrorCode.undefined.rawValue ~= value else {
                self = .undefined
                return
            }
            self = RequestErrorCode(rawValue: value)!
        }
    }
    
    //	static let kHostUrl: String = "http://comics.dev.ironwaterstudio.com"
    static let hostUrl: HostUrl = .test
    static var kHostUrl: String {
        switch hostUrl {
        case .host(let url):
            return url
        }
    }
    static let kServerUrl: String = kHostUrl + "/api/"
    
    static func absoluteURL(relativeUrl: String) -> String {
        return MahabharataRequestManager.kHostUrl + relativeUrl
    }
    
    // Token that is returned by Auth/UpdateDevice and added as header value for every request
    private static var _token: String?
    static var token: String? {
        get {
            var result: String?
            DispatchManager.synchronized(self) {
                result = _token
            }
            return result
        }
        set {
            DispatchManager.synchronized(self) {
                _token = newValue
            }
        }
    }
    
    override func supportedResponseCodes() -> Set<Int> {
        return [
            200,	// Get ok
            201,	// Post ok
            401,
            500
        ]
    }
    
    override func expectedMimeTypes() -> Set<String> {
        var expectedMimeTypes = super.expectedMimeTypes()
        expectedMimeTypes.insert("image/jpeg")
        return expectedMimeTypes
    }
    
    override func processReceivedData(_ responseObj: Any, with state: RequestManagerState) -> Any {
        guard let jsonDataDic = responseObj as? [String: Any] else { return responseObj }
        
        if jsonDataDic.keys.count == 0 {
            return [:]
        }
        
        let message = jsonDataDic["message"] as? String
        let code = jsonDataDic["code"] as? Int
        let data = jsonDataDic["data"]
        
        if code ?? 0 == 0, let data = data {
            return data
        }
        
        let error = RequestError()
        error.isSuccess = false
        error.data = data
        error.msg = message
        error.code = code!
        
        return error
    }
    
    //	override class func process(_ reqMan: RequestManager, errorState err: RequestError) -> RequestError {
    //		let appDelegate = UIApplication.shared.delegate as? AppDelegate
    //		//appDelegate?.handleNeedToUpgrade()
    //		
    //		// downgrade logic
    //		if let error = err.error,
    //			let userInfo = error._userInfo as? [String: Any],
    //			let statusCode = userInfo["statusCode"] as? Int,
    //			statusCode == RequestErrorCode.upgradeRequired.rawValue {
    //				err.isHandled = true
    //				appDelegate?.handleNeedToUpgrade()
    //				
    //				return err
    //		} else {
    //			return super.process(reqMan, errorState: err)
    //		}
    //	}
    
    private static func runRequest(requestMethodUrl: String,
                                   method: String,
                                   params: Any,
                                   cacheType: CacheType,
                                   contextKey: AnyHashable?,
                                   successBlock: @escaping CacheRequestSuccessBlock,
                                   errorBlock: @escaping RequestErrorBlock) -> Self? {
        let urlString = kHostUrl + "/api/" + requestMethodUrl
        
        var headers: [String: String] = ["Content-Type": "application/json"]
        if let token = self.token {
            headers["Authorization"] = "Mahabharata \(token)"
        }
        
        headers["accept-language"] = LocalizationManager.shared.currentlanguage(.device)
        print("##### \(headers["accept-language"] ?? "")")
        
        let configQueue: DispatchQueue? = self.sharedConfiguration.queue
        return performRequest(
            absoluteUrl: urlString,
            method: method,
            headerParams: headers,
            parameters: params as AnyObject,
            contextKey: contextKey,
            cacheType: cacheType,
            success: { (data: Any, isFromCache: Bool) in
                DispatchManager.perform(on: configQueue) { successBlock(data, isFromCache) }
            },
            error: { (error: RequestError) in
                
                //Case when update device has not finished before first request call (and when server changed too)
                if error.code == RequestErrorCode.needToLogin.rawValue {
                    //Retry to get token
                    MahabharataRequestManager.updateDevice(deviceID: UIDevice.uniqueAppId!,
                                                           localTime: Date().timeIntervalSince1970,
                                                           success: { (serverToken: String?) in
                        
                        if let token = serverToken {
                            print("updated token after auth error: ", token)
                            Settings.shared.token = token
                            self.token = token
                            
                            //Update token for headers
                            var headers: [String: String] = ["Content-Type": "application/json"]
                            headers["Authorization"] = "Mahabharata \(token)"
                            
                            headers["accept-language"] = LocalizationManager.shared.currentlanguage(.device)
                            print("##### \(headers["accept-language"] ?? "")")
                            
                            MahabharataRequestManager.performRequest(
                                absoluteUrl: urlString,
                                method: method,
                                headerParams: headers,
                                parameters: params as AnyObject,
                                contextKey: contextKey,
                                cacheType: cacheType,
                                success: { (data: Any, isFromCache: Bool) in
                                    DispatchManager.perform(on: configQueue) { successBlock(data, isFromCache) }
                                },
                                error: { (error1: RequestError) in
                                    DispatchManager.perform(on: configQueue) { errorBlock(error1) }
                                })
                        } else {
                            DispatchManager.perform(on: configQueue) { errorBlock(error) }
                        }
                    },
                                                           error: { (error: RequestError) in
                        print(error)
                    })
                } else {
                    DispatchManager.perform(on: configQueue) { errorBlock(error) }
                }
            })
    }
    
    //TODO: check for caching details
    private static func runGet(requestMethodUrl: String,
                               params: Any,
                               useCacheOnError: Bool,
                               contextKey: AnyHashable?,
                               successBlock: @escaping CacheRequestSuccessBlock,
                               errorBlock: @escaping RequestErrorBlock) -> Self? {
        
        return self.runRequest(requestMethodUrl: requestMethodUrl,
                               method: "GET",
                               params: params,
                               cacheType: useCacheOnError ? .offline : .none,
                               contextKey: contextKey,
                               successBlock: successBlock,
                               errorBlock: errorBlock)
    }
    
    private static func runPost(requestMethodUrl: String,
                                params: Any,
                                useCacheOnError: Bool,
                                contextKey: AnyHashable?,
                                successBlock: @escaping CacheRequestSuccessBlock,
                                errorBlock: @escaping RequestErrorBlock) -> Self? {
        
        return self.runRequest(requestMethodUrl: requestMethodUrl,
                               method: "POST",
                               params: params,
                               cacheType: useCacheOnError ? .offline : .none,
                               contextKey: contextKey,
                               successBlock: successBlock,
                               errorBlock: errorBlock)
    }
    
    
    // MARK: - Tokens
    
    @discardableResult
    static func updateDevice(deviceID: String, localTime: TimeInterval, success: @escaping (String?) -> (), error: RequestErrorBlock? = nil) -> Self? {
        return runPost(requestMethodUrl: "Auth/UpdateDevice",
                       params: ["deviceId": deviceID, "localTime": localTime],
                       useCacheOnError: false,
                       contextKey: nil,
                       successBlock: { responseDict, _ in
            if let responseDict = responseDict as? [String: Any], let token = responseDict["token"] as? String {
                success(token)
            } else {
                success(nil)
            }
        },
                       errorBlock: { (err: RequestError) in
            error?(err)
        })
    }
    
    @discardableResult
    static func updatePushToken(with token: String, success: @escaping () -> (), error: @escaping RequestErrorBlock) -> Self? {
        return runPost(requestMethodUrl: "Auth/UpdatePushToken",
                       params: ["token": token],
                       useCacheOnError: false,
                       contextKey: nil,
                       successBlock: { _,_ in success() },
                       errorBlock: { (err: RequestError) in
            error(err)
        })
    }
    
    // MARK: - Data
    
    @discardableResult
    static func getSeasons(context: AnyHashable? = nil, success: @escaping ([Season]) -> Void, error: @escaping RequestErrorBlock) -> Self? {
        return self.runPost(requestMethodUrl: "Data/Seasons",
                            params: [:],
                            useCacheOnError: false,
                            contextKey: context,
                            successBlock: { (dataObj: Any, isFromCache: Bool) in
            let seasons: [Season] = (try? Season.array(dataObj)) ?? []
            success(seasons)
        },
                            errorBlock: { (err: RequestError) in
            error(err)
        })
    }
    
    @discardableResult
    static func getPuzzles(context: AnyHashable? = nil, success: @escaping ([Puzzle]) -> Void, error: @escaping RequestErrorBlock) -> Self? {
        return self.runPost(requestMethodUrl: "Data/Puzzles",
                            params: [:],
                            useCacheOnError: false,
                            contextKey: context,
                            successBlock: { (dataObj: Any, isFromCache: Bool) in
            let puzzles: [Puzzle] = (try? Puzzle.array(dataObj)) ?? []
            success(puzzles)
        },
                            errorBlock: { (err) in
            error(err)
        })
    }
    
    
    @discardableResult
    static func getQuotes(context: AnyHashable? = nil, success: @escaping ([Quote]) -> Void, error: @escaping RequestErrorBlock) -> Self? {
        return self.runPost(requestMethodUrl: "Data/Quotes",
                            params: [:],
                            useCacheOnError: false,
                            contextKey: context,
                            successBlock: { (dataObj: Any, isFromCache: Bool) in
            let quotes: [Quote] = (try? Quote.array(dataObj)) ?? []
            success(quotes)
        },
                            errorBlock: { (err) in
            error(err)
        })
    }
    
    @discardableResult
    static func getMusic(context: AnyHashable? = nil, success: @escaping ([Music]) -> Void, error: @escaping RequestErrorBlock) -> Self? {
        return self.runPost(requestMethodUrl: "Data/Music",
                            params: [:],
                            useCacheOnError: false,
                            contextKey: context,
                            successBlock: { (dataObj: Any, isFromCache: Bool) in
            let music: [Music] = (try? Music.array(dataObj)) ?? []
            success(music)
        },
                            errorBlock: { (err) in
            error(err)
        })
    }
    
    // MARK: - cache paths for different types of resources
    static func cachePath(_ object: Any) -> String? {
        //TODO: if implement caching for data other than images add e.g.
        if let season = object as? Season {
            return "/Seasons/\(season.id)/"
        } else if let episode = object as? Episode {
            return "/Episodes/\(episode.id)/"
        } else if let quote = object as? Quote {
            return "/Quotes/\(quote.id)/"
        } else if let music = object as? Music {
            return "/Music/\(music.id)/"
        } else if let imageURL = object as? String {
            return imageURL.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        }
        
        return nil
    }
    
    /**
     Download image async by url. If url is empty or download error occurs, default image is loaded instead
     Params:
     @param [imageURL]
     Relative URL of image on serverURL
     @param [defaultImageName]
     Name/relative path of default image to display on imageURL is empty/not loaded
     @param [cachePath]
     Optional relative to docs dir path for stored downloaded image; if ends with / image name of cached copy is autogenerated. If nil, do not use cache.
     @param [context]
     Context key or empty string to cancel all context requests.
     @returns
     MigrationRequestManager instance
     */
    @discardableResult
    static func downloadImage(_ imageUrl: String?,
                              defaultImageName: String?,
                              cachePath: String? = nil,
                              context: AnyHashable?,
                              success: @escaping (UIImage?) -> Void,
                              error: RequestErrorBlock? = nil) -> MahabharataRequestManager? {
        
        //		print("downloadImage: \(imageUrl ?? "")")
        guard let imageUrl = imageUrl, !String.isNilOrWhiteSpace(imageUrl) else {
            success(defaultImageName != nil ? UIImage(named: defaultImageName ?? "") : nil)
            return nil
        }
        
        return MahabharataRequestManager.downloadImage(
            imageUrl: MahabharataRequestManager.absoluteURL(relativeUrl: imageUrl),
            method: "GET",
            parameters: nil,
            contextKey: context,
            cacheType: .staticAlways,
            cachePath: cachePath,
            path: nil,
            success: { (image: Any) in
                DispatchQueue.main.async {
                    if let img = image as? UIImage {
                        //Success
                        success(img)
                    }
                    else {
                        success(defaultImageName != nil ? UIImage(named: defaultImageName ?? "") : nil)
                    }
                }
            }, progress: nil,
            error: { (err: RequestError) in
                DispatchQueue.main.async {
                    if let error = error {
                        error(err)
                    }
                    
                    success(defaultImageName != nil ? UIImage(named: defaultImageName ?? "") : nil)
                }
            })
    }
}
