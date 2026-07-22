//
//  DownloadInfo.swift
//  Mahabharata
//
//  Created by Class Generator by romandeveloper on 2017.
//  Copyright (c) 2017 Iron Water Studio. All rights reserved.
//

import Foundation
import UIKit

class DownloadInfo: NSObject, NSCoding {
	var bytesReceived: Int64
	var bytesTotal: Int64

	init(bytesReceived: Int64, bytesTotal: Int64) {
		self.bytesReceived = bytesReceived
		self.bytesTotal = bytesTotal
	}

	convenience override init() {
		self.init(bytesReceived:0, bytesTotal:0)
	}

	override var description: String {
		return [
			"BytesReceived: \(bytesReceived)",
			"BytesTotal: \(bytesTotal)"
			].joined(separator: ", ")
	}

	// MARK: - NSCoding
	required convenience init?(coder aDecoder: NSCoder) {
		let bytesReceived = aDecoder.decodeInt64(forKey: "bytesReceived")
		let bytesTotal = aDecoder.decodeInt64(forKey: "bytesTotal")
		self.init(bytesReceived:bytesReceived, bytesTotal:bytesTotal)
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.bytesReceived, forKey:"bytesReceived")
		aCoder.encode(self.bytesTotal, forKey:"bytesTotal")
	}
}

extension DownloadInfo {
	var progress: CGFloat {
		bytesTotal > 0 ? CGFloat(bytesReceived) / CGFloat(bytesTotal) : 0
	}
}
