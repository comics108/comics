//
//  RequestManager+DownloadImage.swift
//  RequestManager+DownloadImage
//
//  Created by Stanislav Grinberg on 23/10/2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//      13 Jul 2018. Olga Zhegulo:
//          * fix for image scale/size in downloadImage(...)
//      15 Aug 2018. Olga Zhegulo:
//		    * implemented return RequestManager instance from downloadImage(...)

import UIKit

extension RequestManager {
    typealias DownloadImageSuccessBlock = (UIImage?) -> ()
	
	/**
	Because image loaded from internet then it should be interpreted as scale based with scale 1.0
	But we can specify scale factor manually and it will be used to interpret image as other scale.
	
	Let's review following case:
		* image loaded from internet have dimension WxH like 320x200px
		* scale specified as 2.0 (i.e. mobile app waiting to received double scaled image)
		* each 2 horizontal & 2 vertica pixels (i.e. 4 pixels) will draw in 1 point of screen and image 320x200px will be present as UIImage 160x100 points.
	
	Note: when need to request from the server image 320x200px that should be interpreted as double-scaled (scale = 2.0) then we need to specify double multiplied size and need to specify scale param = 2.0. I.e. we should request image 640x400px & specify scale = 2.0.
	*/
    @discardableResult
    static func downloadImage(imageUrl: String,
                              method: String,
                              parameters: [String: String]? = nil,
                              configuration: RequestManagerConfiguration = sharedConfiguration,
                              contextKey: AnyHashable?,
                              cacheType: CacheType,
                              cachePath: String?,
                              path: String?,
							  scale: CGFloat? = nil,
                              success: DownloadImageSuccessBlock?,
                              progress: RequestProgressBlock? = nil,
                              error: RequestErrorBlock?) -> Self? {
        let configQueue: DispatchQueue? = configuration.queue
        
        return performRequest(absoluteUrl: imageUrl,
                        method: method,
                        headerParams: nil,
                        parameters: parameters,
                        configuration: configuration,
                        contextKey: contextKey,
                        cacheType: cacheType,
                        cachePath: cachePath,
                        path: path,
                        success: { (dataObj: Any, isFromCache: Bool) in
                            var imageData: Data?
                            // Если пришла строка то картинка находится в файловой системе
                            if isFromCache, let path = dataObj as? String, let url = URL(string: path) {
                                imageData = try? Data(contentsOf: url)
                            } else if let data = dataObj as? Data {
                                imageData = data
                            }
                            
                            var image: UIImage?
                            // Image with data uses scale factor to descrease size of imahe in 2,3 & etc. times
                            // Also we have removed preloading image, that creates GC with size multiplier of scale factor (edited)
							if let imageData = imageData {
								
								// v1
								//image = UIImage(data: imageData/*, scale: UIScreen.main.scale*/)
								
								// v2 double scaling requests support
								if let scale = scale {
									image = UIImage(data: imageData, scale: scale)
								} else {
									// By default will be used scale = 1.0 for internet based images.
									// But when image ends with @2x or @3x scale will taken from image name.
									image = UIImage(data: imageData/*, scale: UIScreen.main.scale*/)
								}
                            }
                            
                            DispatchManager.perform(on: configQueue) { success?(image) } },
                        progress: { (bytes: Int, totalBytes: Int, data: Data?) in
                            DispatchManager.perform(on: configQueue) { progress?(bytes, totalBytes, data) } },
                        error: { (err: RequestError) in
                            DispatchManager.perform(on: configQueue) { error?(err) } })
    }
	
	@discardableResult
	static func downloadImage(url: String?,
							  defaultImageName: String? = nil,
							  contextKey: AnyHashable? = nil,
							  completion: @escaping (UIImage) -> ()) -> Self? {
		var defaultImage = UIImage()
		if let imageName = defaultImageName, let img = UIImage(named: imageName) {
			defaultImage = img
		}
		
		guard let url = url, !url.isEmpty else {
			completion(defaultImage)
			return nil
		}
		
		return downloadImage(imageUrl: url,
							 method: "GET",
							 contextKey: contextKey,
							 cacheType: RequestManager.CacheType.staticAlways,
							 cachePath: nil,
							 path: nil,
							 success: { (dataObj: Any) in
								DispatchQueue.main.async { completion(dataObj as? UIImage ?? defaultImage) } },
							 error: { _ in DispatchQueue.main.async { completion(defaultImage) } })
	}
    
    
}
