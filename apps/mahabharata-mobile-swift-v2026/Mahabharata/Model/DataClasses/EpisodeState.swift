//
//  EpisodeState.swift
//  Mahabharata
//
//  Created by Class Generator by romandeveloper on 2017.
//  Copyright (c) 2017 Iron Water Studio. All rights reserved.
//

import Foundation
import UIKit

class EpisodeState: NSObject, NSCoding {
	let id: Int
	var isPurchased: Bool
	var isDownloaded: Bool
	var isUnpacking: Bool
	var downloadInfo: DownloadInfo?
	var version: Int
	var fileName: String
	var price: String
	var position: CGFloat = 0.0

	init(id: Int, isPurchased: Bool, isDownloaded: Bool, isUnpacking: Bool, downloadInfo: DownloadInfo?, version: Int, fileName: String, price: String, position: CGFloat) {
		self.id = id
		self.isPurchased = isPurchased
		self.isDownloaded = isDownloaded
		self.isUnpacking = isUnpacking
		self.downloadInfo = downloadInfo
		self.version = version
		self.fileName = fileName
		self.price = price
		self.position = position
	}

	convenience override init() {
		self.init(id:Int(), isPurchased:Bool(), isDownloaded:Bool(), isUnpacking:Bool(), downloadInfo:nil, version:Int(), fileName:String(), price:String(), position: 0.0)
	}

	override var description: String {
		return [
			"Id: \(id)",
			"IsPurchased: \(isPurchased)",
			"IsDownloaded: \(isDownloaded)",
			"IsUnpacking: \(isUnpacking)",
			"DownloadInfo: \(String(describing: downloadInfo))",
			"Version: \(version)",
			"FileName: \(fileName)",
			"Price: \(price)",
			"Position: \(position)"
			].joined(separator: ", ")
	}

	// MARK: - NSCoding
	required convenience init?(coder aDecoder: NSCoder) {
		let id = aDecoder.decodeInteger(forKey: "id")
		let isPurchased = aDecoder.decodeBool(forKey: "isPurchased")
		let isDownloaded = aDecoder.decodeBool(forKey: "isDownloaded")
		let isUnpacking = aDecoder.decodeBool(forKey: "isUnpacking")
		let downloadInfo = aDecoder.decodeObject(forKey: "downloadInfo") as? DownloadInfo
		let version = aDecoder.decodeInteger(forKey: "version")
		let fileName = aDecoder.decodeObject(forKey: "fileName") as! String
		let price = aDecoder.decodeObject(forKey: "price") as! String
		let objectPosition = aDecoder.decodeObject(forKey: "position")
		let position: CGFloat = objectPosition != nil ? objectPosition as! CGFloat : 0.0
		self.init(id:id, isPurchased:isPurchased, isDownloaded:isDownloaded, isUnpacking:isUnpacking, downloadInfo:downloadInfo, version:version, fileName:fileName, price:price, position:position)
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.id, forKey:"id")
		aCoder.encode(self.isPurchased, forKey:"isPurchased")
		aCoder.encode(self.isDownloaded, forKey:"isDownloaded")
		aCoder.encode(self.isUnpacking, forKey:"isUnpacking")
		aCoder.encode(self.downloadInfo, forKey:"downloadInfo")
		aCoder.encode(self.version, forKey:"version")
		aCoder.encode(self.fileName, forKey:"fileName")
		aCoder.encode(self.price, forKey:"price")
		aCoder.encode(self.position, forKey:"position")
	}
	
	// MARK: - Functionality
	static let kEpisodeStateKey = "EpisodeStateKey"
	func save() {
		UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: "\(EpisodeState.kEpisodeStateKey)-\(self.id)")
		UserDefaults.standard.synchronize()
	}
	
	static func getBy(id: Int) -> EpisodeState {
		let data = UserDefaults.standard.object(forKey: "\(EpisodeState.kEpisodeStateKey)-\(id)") as! Data?
		var episodeState: EpisodeState?
		if let data = data {
			episodeState = NSKeyedUnarchiver.unarchiveObject(with: data) as? EpisodeState
		}
		else {
			episodeState = EpisodeState(id: id, isPurchased: false, isDownloaded: false, isUnpacking: false, downloadInfo: nil, version: 0, fileName: "", price: "", position: 0.0)
		}
		// ?? EpisodeState() for safety: episodeState will never be nil
		return episodeState ?? EpisodeState()
	}
}
