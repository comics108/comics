//
//  MusicState.swift
//  Mahabharata
//
//  Created by Class Generator by Olga Zhegulo on 2018.
//  Copyright (c) 2018 Iron Water Studio. All rights reserved.
//

import Foundation

class MusicState: NSObject, NSCoding {
	let id: Int
	var isDownloaded: Bool
	var downloadInfo: DownloadInfo?
	var fileName: String

	init(id: Int, isDownloaded: Bool, downloadInfo: DownloadInfo?, fileName: String) {
		self.id = id
		self.isDownloaded = isDownloaded
		self.downloadInfo = downloadInfo
		self.fileName = fileName
	}

	convenience override init() {
		self.init(id:Int(), isDownloaded:Bool(), downloadInfo:nil, fileName:String())
	}

	override var description: String {
		return [
			"Id: \(id)",
			"IsDownloaded: \(isDownloaded)",
			"DownloadInfo: " + (downloadInfo != nil ? "\(downloadInfo!)" : "nil"),
			"FileName: \(fileName)"
			].joined(separator: ", ")
	}

	// MARK: - NSCoding
	required convenience init?(coder aDecoder: NSCoder) {
		let id = aDecoder.decodeInteger(forKey: "id")
		let isDownloaded = aDecoder.decodeBool(forKey: "isDownloaded")
		let downloadInfo = aDecoder.containsValue(forKey: "downloadInfo") ? aDecoder.decodeObject(forKey: "downloadInfo") as? DownloadInfo : nil
		let fileName = aDecoder.decodeObject(forKey: "fileName") as! String
		self.init(id:id, isDownloaded:isDownloaded, downloadInfo:downloadInfo, fileName:fileName)
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.id, forKey:"id")
		aCoder.encode(self.isDownloaded, forKey:"isDownloaded")
		if let downloadInfo = self.downloadInfo { aCoder.encode(downloadInfo, forKey: "downloadInfo") }
		aCoder.encode(self.fileName, forKey:"fileName")
	}
	
	// MARK: - Functionality
	static let kMusicStateKey = "MusicStateKey"
	func save() {
		UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: "\(MusicState.kMusicStateKey)-\(self.id)")
		UserDefaults.standard.synchronize()
	}
	
	static func getBy(id: Int) -> MusicState {
		let data = UserDefaults.standard.object(forKey: "\(MusicState.kMusicStateKey)-\(id)") as! Data?
		var state: MusicState?
		if let data = data {
			state = NSKeyedUnarchiver.unarchiveObject(with: data) as? MusicState
		}
		else {
			state = MusicState(id: id, isDownloaded: false, downloadInfo: nil, fileName: "")
		}
		
		return state!
	}
}
