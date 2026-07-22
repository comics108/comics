//
//  Episode+Extension.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 22 Oct 2019.
//  Copyright © 2019 Iron Water Studio. All rights reserved.
//

import Foundation

extension Episode {
	var shouldPurchase: Bool {
		//return !String.isNilOrWhiteSpace(product)
        return false
	}
}

extension Episode: DownloadItem {
	var url: URL? {
		if let url = URL(string: MahabharataRequestManager.absoluteURL(relativeUrl: file)) {
			return url
		}
		return nil
	}
	
	var fileName: String {
		(self.file as NSString).lastPathComponent
	}
}

extension Episode {
	var state: EpisodeState {
		return EpisodeState.getBy(id: self.id)
	}
}

extension Episode {
	enum ProgressState {
		case none, soon, free, shouldPurchase(String), downloading(DownloadInfo), bought, unpacking, downloaded
	}
	
	static func getState(episode: Episode, bookPurchased: Bool) -> ProgressState {
		if String.isNilOrWhiteSpace(episode.file) {
			return .soon
		}
		
		let episodeState = episode.state
		
		if episodeState.isDownloaded {
			if episodeState.isUnpacking {
				return .unpacking
			} else {
				return .downloaded
			}
		}
		else {
			if let downloadInfo = episodeState.downloadInfo {
				return .downloading(downloadInfo)
			}
			else {
				if episode.shouldPurchase && (!episodeState.isPurchased && !bookPurchased)
				{
					return .shouldPurchase(!String.isNilOrWhiteSpace(episode.price) ? episode.price : Local("Episodes.Buy"))
				}
				else if episode.shouldPurchase && (episodeState.isPurchased || bookPurchased) {
					return .bought
				}
				else {
					return .free
				}
			}
		}
	}
}
