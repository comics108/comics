//
//  CacheManager.swift
//  CacheManager
//
//  Created by Stanislav Grinberg on 19 May 2017.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Dependencies:
//      system: UIKit
//      custom: Dispatch, String+Extension
//      github:
//

import UIKit

let kCacheManagerPListFileName = "CacheManager.plist"

let kMaxImageMemoryCacheSize: Int = 40

let defaultDirectory = "CacheManager"

class CacheManager {
	
	static let defaultTimeoutInterval: TimeInterval = 86400 // 24*60*60 seconds
	
	// + (instancetype)currentCache __deprecated; // Renamed to globalCache
	static let globalCache = CacheManager()
	
	let directory: String

	// TODO: rename to cache timeout interval and allow set as global setting ([CacheManager globalCache].cacheTimeoutInterval = 86400 ~ 24*60*60 seconds)
	var timeoutInterval: TimeInterval = CacheManager.defaultTimeoutInterval // Default is 1 day
	
	// кэш, который хранится в файловой системе и сохраняется с помощью FileManager
	var cacheInfoQueue: DispatchQueue?
	
	var frozenCacheInfoQueue: DispatchQueue?
	var diskQueue: DispatchQueue?
	var cacheInfo: [String: Any]?
	var needsSave: Bool?
	
	var frozenCacheInfo: [String: Any]?
	var memoryCache = [String: Any]()
	
	@inline(__always)
	func cachePath(for directory: String, key: String) -> String {
		return (directory as NSString).appendingPathComponent(key)
	}
	
	@inline(__always)
	func cachePath(for directory: String, key: String, section: String) -> String {
		var fullPath: String = ""
		if section.count > 0 {
			fullPath = ((directory as NSString).appendingPathComponent(section) as NSString).appendingPathComponent(key)
		} else {
			fullPath = (directory as NSString).appendingPathComponent(key)
		}
		
		return fullPath
	}
	
	let CHECK_FOR_CACHE_MANAGER_PLIST: (String) -> (Bool) = {
		$0 != kCacheManagerPListFileName
	}
	
	convenience init() {
		var cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
//		let oldCachesDirectory = (cachesDirectory as NSString).appendingPathComponent((ProcessInfo.processInfo.processName as NSString).appendingPathComponent(defaultDirectory))
//
//		if FileManager.default.fileExists(atPath: oldCachesDirectory) {
//			try! FileManager.default.removeItem(atPath: oldCachesDirectory)
//		}
		
		cachesDirectory = (cachesDirectory as NSString).appendingPathComponent((Bundle.main.bundleIdentifier! as NSString).appendingPathComponent(defaultDirectory))
		
		self.init(cacheDirectory: cachesDirectory)
	}
	
	// Opitionally create a different CacheManager instance with it's own cache directory
	init(cacheDirectory: String) {
		cacheInfoQueue = DispatchQueue(label: "cachemanager.info", qos: .userInitiated)
		frozenCacheInfoQueue = DispatchQueue(label: "cachemanager.info.frozen", qos: .userInitiated)
		diskQueue = DispatchQueue(label: "cachemanager.disk", qos: .background)
	
		directory = cacheDirectory
		
		cacheInfo = NSDictionary(contentsOfFile: cachePath(for: directory, key: kCacheManagerPListFileName)) as? [String: Any]
		
		if cacheInfo == nil {
			cacheInfo = [String: Any]()
		}
		
		let fm = FileManager.default
		try? fm.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
		
		let now = Date().timeIntervalSinceReferenceDate
		var removedkeys: [String] = [String]()

		for (key, value) in cacheInfo! {
			if let val = value as? Date, val.timeIntervalSinceReferenceDate <= now {
				do {
					try fm.removeItem(atPath: cachePath(for: directory, key: key))
					removedkeys.append(key)
				} catch { }
			}
		}
		
		for key in removedkeys {
			cacheInfo!.removeValue(forKey: key)
		}
		
		frozenCacheInfo = cacheInfo
		timeoutInterval = CacheManager.defaultTimeoutInterval
		
		NotificationCenter.default.addObserver(self, selector: #selector(memoryWarningReceived), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
	}
	
	private func checkForCacheManagerPlist(_ key: String) {
		
	}
	
	func buildAbsolutePath(relativePath: String?) -> String {
		guard let rp = relativePath, rp.count > 0 else { return directory }
		
		// Check that relativePath is absolute path
		if rp.lowercased().hasPrefix(directory) {
			return rp
		}
		
		let result = (directory as NSString).appendingPathComponent(rp)
		
		if rp.hasSuffix("/") {
			return "\(result)/"
		}
		
		return result
	}
	
	// MARK: - NSNotification handlers
	
	@objc
	private func memoryWarningReceived(_ notification: Notification) {
		// Clear memory cache
		memoryCache.removeAll()
	}
	
	// MARK: - Methods
	
	func clearCache() {
		cacheInfoQueue?.sync {
			if let cacheInfo = self.cacheInfo {
				for (key, _) in cacheInfo {
					let path = self.cachePath(for: self.directory, key: key)
					if FileManager.default.fileExists(atPath: path) {
						do {
							try FileManager.default.removeItem(atPath: path)
						} catch {
							print(error.localizedDescription)
						}
					}
				}
			}
			
			self.cacheInfo?.removeAll()
			
			self.frozenCacheInfoQueue?.sync {
				self.frozenCacheInfo = self.cacheInfo
			}
			
			self.setNeedsSave()
		}
	}
	
	@discardableResult
	func removeCache(for key: String, in section: String) -> Bool {
		guard CHECK_FOR_CACHE_MANAGER_PLIST(key) else { return false }
		var isRemoved: Bool = false
		diskQueue?.async {
			let path = self.cachePath(for: self.directory, key: key, section: section)
			if FileManager.default.fileExists(atPath: path) {
				do {
					try FileManager.default.removeItem(atPath: path)
					isRemoved = true
				} catch {
					print(error.localizedDescription)
				}
			} else {
				isRemoved = true
			}
		}
		setCacheTimeoutInterval(0, for: key, in: section)
		return isRemoved
	}
	
	func removeCache(forPath filePath: String) {
		let (key, section) = extractKeyAndSection(from: filePath)
		
		if key.isEmpty && section.isEmpty { return }
		
		removeCache(for: key, in: section)
	}
	
	func hasCache(for key: String, in section: String) -> Bool {
		guard let date: Date = self.date(for: key, in: section) else { return false }
		
		if date <= Date() {
			return false
		}
		
		return FileManager.default.fileExists(atPath: cachePath(for: directory, key: key, section: section))
	}
	
	func hasCache(forPath filePath: String?) -> Bool {
		guard let filePath = filePath else { return false }
		
		let (key, section) = extractKeyAndSection(from: filePath)
		
		if key.isEmpty && section.isEmpty { return false }
		
		return hasCache(for: key, in: section)
	}
	
	func extractKeyAndSection(from filePath: String) -> (String, String) {
		let trimmedFilePath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
		
		// Имя файла находится начиная с позиции range.location + 1
		let lastSlashIndex: Int = trimmedFilePath.lastIndex(of: "/")
		
		if lastSlashIndex == -1 { return ("", "") }
		
		let key = trimmedFilePath.substringFrom(lastSlashIndex + 1)
		let section = trimmedFilePath.substringTo(lastSlashIndex)
		
		return (key, section)
	}
	
	func date(for key: String, in section: String) -> Date? {
		guard key.count > 0 else { return nil }
		
		var date: Date?
		let keyString: String = section.count > 0 ? "\(section)/\(key)" : key
		frozenCacheInfoQueue?.sync { [unowned self] in
			date = self.frozenCacheInfo?[keyString] as? Date
		}
		
		return date
	}
	
	func allKeys() -> [String]? {
		var keys: [String]?
		frozenCacheInfoQueue?.sync { [unowned self] in
			if let frozenCacheInfoDic = self.frozenCacheInfo {
				for key in frozenCacheInfoDic.keys {
					keys?.append(key)
				}
			}
		}
		
		return keys
	}
	
	func setCacheTimeoutInterval(_ timeoutInterval: TimeInterval, for key: String, in section: String) {
		let date: Date? = timeoutInterval > 0 ? Date(timeIntervalSinceNow: timeoutInterval) : nil
		let keyString: String = section.count > 0 ? "\(section)/\(key)" : key
		// Temporarily store in the frozen state for quick reads
		frozenCacheInfoQueue?.sync {
			var info = self.frozenCacheInfo
			
			/*
			if let date = date {
			info[keyString] = date
			} else {
			info[keyString] = nil
			}
			*/
			
			info?[keyString] = date
			self.frozenCacheInfo = info
		}
		
		// Save the final copy (this may be blocked by other operations)
		cacheInfoQueue?.async {
			self.cacheInfo?[keyString] = date
			
			self.frozenCacheInfoQueue?.sync {
				self.frozenCacheInfo = self.cacheInfo
			}
			
			self.setNeedsSave()
		}
	}
	
	private func setNeedsSave() {
		DispatchManager.synchronized(self) {
			if let needsSave = self.needsSave, needsSave { return }
			self.needsSave = true
			
			// Strange behavior is taken from EGOCACHE
			// We give some time to complete a write operation
			let delayInSeconds = 0.5
			cacheInfoQueue?.asyncAfter(deadline: .now() + delayInSeconds) {
				if let needsSave = self.needsSave, !needsSave { return }
				(self.cacheInfo as NSDictionary?)?.write(toFile: self.cachePath(for: self.directory, key: kCacheManagerPListFileName), atomically: true)
				self.needsSave = false
			}
		}
	}
	
	// MARK: - Copy file methods
	
	@discardableResult
	func copyFilePath(_ filePath: String, as key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) -> Bool {
		var isCopied: Bool = false
		diskQueue?.async {
			if FileManager.default.fileExists(atPath: filePath) {
				do {
					try FileManager.default.copyItem(atPath: filePath, toPath: self.cachePath(for: self.directory, key: key, section: section))
					isCopied = true
				} catch {
					print(error.localizedDescription)
				}
			} else {
				isCopied = true
			}
		}
		setCacheTimeoutInterval(timeoutInterval, for: key, in: section)
		return isCopied
	}
	
	// MARK: - Data methods
	
	func data(for key: String, in section: String) -> Data? {
		var data: Data? = nil
		if hasCache(for: key, in: section) {
			do {
				data = try NSData(contentsOfFile: cachePath(for: directory, key: key, section: section), options: []) as Data
			} catch {
				print(error.localizedDescription)
			}
		}
		return data
	}
	
	func setData(_ data: Data, for key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		guard CHECK_FOR_CACHE_MANAGER_PLIST(key) else { return }
		
		let cachePath: String = self.cachePath(for: directory, key: key, section: section)
		diskQueue?.async {
			let directoryPath = (cachePath as NSString).deletingLastPathComponent
			var isDirectory: ObjCBool = ObjCBool(false)
			let isDirectoryExist = FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory)
			// Create directory if needed
			if !isDirectoryExist || !isDirectory.boolValue {
				do {
					try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
				} catch {
					print("Directory with path: \(directoryPath) was not created; an error occured: \(error as NSError)")
				}
			}
			// Write cached data to file
			do {
				try (data as NSData).write(toFile: cachePath, options: [.atomic])
			} catch {
				print("Writing CacheManager data to file: \(cachePath)  didn't complete;\nan error occured: \(error as NSError)")
			}
		}
		
		setCacheTimeoutInterval(timeoutInterval, for: key, in: section)
	}
	
	func string(for key: String, in section: String) -> String? {
		if let data = self.data(for: key, in: section) {
			return String(data: data, encoding: .utf8)
		}
		
		return nil
	}
	
	func setString(_ aString: String, for key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		if let data = aString.data(using: .utf8) {
			setData(data, for: key, in: section, timeoutInterval: timeoutInterval)
		}
	}
	
	// MARK: - Image methods
	
	func image(for key: String, in section: String) -> UIImage? {
		// TODO: Surpress any unarchiving exceptions and continue with nil, but now in swift unarchiveObject no throws function and we cant use do-try-cactch statement for handling error.
		return NSKeyedUnarchiver.unarchiveObject(withFile: cachePath(for: directory, key: key, section: section)) as? UIImage
	}
	
	func setImage(_ image: UIImage, for key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		// Using NSKeyedArchiver preserves all information such as scale, orientation, and the proper image format instead of saving everything as pngs
		setData(NSKeyedArchiver.archivedData(withRootObject: image), for: key, in: section)
	}
	
	func plist(for key: String, in section: String) -> Data? {
		guard let plistData = self.data(for: key, in: section) else { return nil }
		
		let result: Data?
		do {
			result = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? Data
		} catch {
			return nil
		}
		
		return result
	}
	
	func setPlist(_ plistObj: AnyObject, for key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		// Binary plists are used over XML for better performance
		var plistData: Data?
		do {
			plistData = try PropertyListSerialization.data(fromPropertyList: plistObj, format: .binary, options: 0)
		} catch { }
		
		if let data = plistData {
			self.setData(data, for: key, in: section, timeoutInterval: timeoutInterval)
		}
	}

	// MARK: - Object methods
	
	func object(for key: String, in section: String) -> (AnyObject & NSCoding)? {
		if hasCache(for: key, in: section), let data = self.data(for: key, in: section) {
			return NSKeyedUnarchiver.unarchiveObject(with: data) as? AnyObject & NSCoding
		}
		
		return nil
	}
	
	func setObject(_ obj: AnyObject, for key: String, in section: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		setData(NSKeyedArchiver.archivedData(withRootObject: obj), for: key, in: section, timeoutInterval: timeoutInterval)
	}
	
	func object(forPath path: String) -> (AnyObject & NSCoding)? {
		let (key, section) = extractKeyAndSection(from: path)
		return object(for: key, in: section)
	}
	
	func setObject(_ obj: AnyObject, forPath path: String, timeoutInterval: TimeInterval = defaultTimeoutInterval) {
		let (key, section) = extractKeyAndSection(from: path)
		setObject(obj, for: key, in: section, timeoutInterval: timeoutInterval)
	}
	
	// MARK: - Memory cache
	func setObjectInMemory(_ obj: AnyObject, for key: String) {
		DispatchManager.synchronized(self) {
			if
				self.memoryCache.count >= kMaxImageMemoryCacheSize,
				let keyForDelete: String = self.memoryCache.keys.first {
				self.memoryCache[keyForDelete] = nil
			}
			self.memoryCache[key] = obj
		}
	}
	
	func objectInMemory(for key: String?) -> Any? {
		var obj: Any?
		DispatchManager.synchronized(self) {
			if let key = key {
				obj = self.memoryCache[key]
			}
		}
		
		return obj
	}
	
	/// Clear image cache
	/// - number of images that stored in cache
	func clearMemoryCache() -> Int {
		var numberOfCachedImages: Int = 0
		DispatchManager.synchronized(self) {
			numberOfCachedImages = self.memoryCache.count
			self.memoryCache.removeAll()
		}
		
		return numberOfCachedImages
	}

}
